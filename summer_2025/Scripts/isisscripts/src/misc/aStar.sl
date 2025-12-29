% estimates path from (x0,y0) to (x1,y1) by their distance
private define aStar_estimateCost(x0, y0, x1, y1) { return sqrt(floor(x0*x1 + y0*y1)); }

% returns length of best path starting at (x,y)
private define aStar_pathLength(cameFrom, x, y) {
  variable len = 1;
  while (cameFrom[x,y] != NULL) {
    (x,y) = (cameFrom[x,y].x,cameFrom[x,y].y);
    len++;
  }
  return len;
}

% returns best path starting at (x,y) and its cost
private define aStar_constructPath(cameFrom, costMap, x, y) {
  variable pathX = x, pathY = y, cost = costMap[x,y];
  % follow path backwards
  while (cameFrom[x,y] != NULL) {
    (x,y) = (cameFrom[x,y].x,cameFrom[x,y].y);
    pathX = [pathX,x]; pathY = [pathY,y];
    ifnot (qualifier_exists("noSum")) cost += costMap[x,y];
  }
  return struct { x = pathX, y = pathY, cost = cost };
}

%%%%%%%%%%%%%%%%%%%%%
define aStar() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{aStar}
%\synopsis{pathfinding algorithm A*}
%\usage{Struct_Type aStar(Double_Type[][] graph, Integer_Type startX, startY, endX, endY);}
%\qualifiers{
%    \qualifier{max}{find the most expensive path instead of the cheapest one}
%    \qualifier{meanCost}{costs are normalized by the best path length to any point
%               in the graph, resulting in a mean cost on a path}
%    \qualifier{estimate}{reference to a function, which estimates the cost between
%               two nodes in the graph (parameters: x0, y0, x1, y1). By
%               default, the distance between both nodes is used}
%    \qualifier{plot}{plots the graph and the working progress at each step. Nodes
%               in the open list are shown in red, in the closed list in
%               blue, nodes of infinite cost in green and the best path,
%               finally, in black. The function sleeps 0.01 seconds after
%               each step or the value given with this qualifier}
%}
%\description
%    Pathfinding algorithm with high performance and accuracy by
%      Hart, Nilsson & Raphael, "A Formal Basis for the Heuristic
%      Determination of Minimum Cost Paths", IEEE Transactions on
%      Systems Science and Cybernetics SSC4 (2), 100–107, 1968
%                               
%    The A* algorithm (called A Star) finds the shortest (or in general
%    cheapest) path between to nodes in a graph. The algorithm looks for
%    the best way following the lowest known heuristic cost. This cost
%    has to be estimated at each new discovered node and is, by default,
%    the straight-line distance between both points. The runtime and
%    accuracy of the search strongly depends on the choice of this
%    estimation.
%
%    The 'graph' has to be given as 2d-array defining the cost at each
%    point (node). Infinite costs (_Inf) are allowed and corresponds to
%    insuperable borders. The starting node and goal node habe to be
%    given as array indices 'startX', 'startY' and 'endX', 'endY',
%    respectively.
%
%    The returned structure contains
%      x    - x-indices of the best path
%      y    - y-indices of the best path
%      cost - summed costs along the best path
%!%-
  variable map, x0, y0, x1, y1;
  switch (_NARGS)
    { case 5: (map,x0,y0,x1,y1) = (); }
    { help(_function_name); return; }

  % type checks
  ifnot (length(array_shape(map)) == 2) { vmessage("error (%s): given map has to be a 2d-array", _function_name); return; }
  ifnot (__is_numeric(map)) { vmessage("error (%s): given map has to contain numerical values", _function_name); return; }
  ifnot (typeof(x0) == Integer_Type && typeof(y0) == Integer_Type && typeof(x1) == Integer_Type && typeof(y1) == Integer_Type)
    { vmessage("error (%s): given nodes have to be integer numbers", _function_name); return; }
  % check if given nodes lie within the map
  ifnot (0 <= x0 < length(map[*,0])) { vmessage("error (%s): x0 lies out of given map", _function_name); return; }
  ifnot (0 <= y0 < length(map[0,*])) { vmessage("error (%s): y0 lies out of given map", _function_name); return; }
  ifnot (0 <= x1 < length(map[*,0])) { vmessage("error (%s): x1 lies out of given map", _function_name); return; }
  ifnot (0 <= y1 < length(map[0,*])) { vmessage("error (%s): y1 lies out of given map", _function_name); return; }
  % qualifiers
  variable estimateFun = qualifier("estimate", &aStar_estimateCost);
  if (typeof(estimateFun) != Ref_Type) { vmessage("error (%s): estimate qualifier has to be a reference", _function_name); return; }
  variable doplot = qualifier("plot", NULL);
  if (qualifier_exists("plot") && doplot == NULL) doplot = .01;
  
  % initialise open and closed lists
  variable openList_x = x0, openList_y = y0, openList_f = 0.;
  variable closedList_x = Integer_Type[0], closedList_y = Integer_Type[0];
  % initialise cost map
  variable costMap = Double_Type[length(map[*,0]),length(map[0,*])] + _Inf; % cost from starting node to current node
  costMap[x0,y0] = map[x0,y0];
  % initialise map of navigated nodes
  variable cameFrom = Struct_Type[length(map[*,0]),length(map[0,*])];
  % repeat until best way is found or no solution exists
  if (doplot != NULL) point_style(4);
  while (length(openList_x) > 0) {
    % get node corresponding to best f-value
    variable i = (qualifier_exists("max") ? where_max(openList_f)[0] : where_min(openList_f)[0]);
    variable node = struct { x = openList_x[i], y = openList_y[i], f = openList_f[i] };
    % if node is the destination return the best path
    if (node.x == x1 && node.y == y1) {
      variable best = aStar_constructPath(cameFrom, costMap, x1, y1; noSum);
      if (doplot != NULL) {
	color(1);
        oplot(best.y,best.x);
      }
      return best;
    }
    % move actual indices from open to closed list
    closedList_x = [closedList_x, node.x];
    closedList_y = [closedList_y, node.y];
    if (doplot != NULL) { color(4); oplot(node.y,node.x); }
    openList_x = array_remove(openList_x, i);
    openList_y = array_remove(openList_y, i);
    openList_f = array_remove(openList_f, i);
    % loop over neighbors of the actual node
    variable n;
    foreach n ({[0,1],[1,0],[0,-1],[-1,0]}) {
      variable neigh = struct { x = node.x + n[0], y = node.y + n[1] };
      if (0 <= neigh.x < length(map[*,0]) && 0 <= neigh.y < length(map[0,*])) {
        % proceed if neighbor is not in closed list
        if (wherefirst(closedList_x == neigh.x and closedList_y == neigh.y) == NULL)
        {
	  if (isinf(map[neigh.x,neigh.y])) { if (doplot != NULL) color(3); }	  
	  else {
	    if (doplot != NULL) color(2);
    	    % tentative cost to get to the neighbor node
	    variable cost;
	    if (qualifier_exists("meanCost")) {
    	      variable len = aStar_pathLength(cameFrom, node.x, node.y) + 1;
  	      cost = costMap[node.x,node.y]*(len-1)/len + map[neigh.x,neigh.y]/len;
	    } else cost = costMap[node.x,node.y] + map[neigh.x,neigh.y];
	    % add neighbor to open list if not already in it or costs are better than before
	    if (wherefirst(openList_x == neigh.x and openList_y == neigh.y) == NULL
		|| (qualifier_exists("max") ? cost > costMap[neigh.x,neigh.y] : cost < costMap[neigh.x,neigh.y])) {
	      openList_x = [openList_x, neigh.x]; openList_y = [openList_y, neigh.y]; openList_f = [openList_f, cost + @estimateFun(neigh.x, neigh.y, x1, y1)];
	      costMap[neigh.x,neigh.y] = cost;
	      cameFrom[neigh.x,neigh.y] = node;
	    }
	  }
	  if (doplot != NULL) {
	    oplot(neigh.y,neigh.x);
	    sleep(doplot);
	  }
        }
      }
    }
  };
  % no solution exists
  return aStar_constructPath(cameFrom, costMap, x1, y1; noSum);
}
