%
% routines to determine whether a point is located inside or outside
% a polygon
%

define crossing_number_polygon() 
%!%+
%\function{crossing_number_polygon}
%\usage{cn=crossing_number_polygon(P,V)}
%\synopsis{return the crossing number for a point P in a polygon}
%\description
% Return the crossing number for a point P in a (potentially
% complex polygon defined by the vertex points V).
% The polygon has to be closed, i.e. V.x[n]==V.x[0] and
% V.y[n]==V.y[0] where n is the number of polygon points.
%
% The crossing number is the number of times that a ray starting 
% from point P crosses the polygon.  The point is outside of the
% polygon if the crossing number is even, and inside if the
% crossing number is odd (even-odd rule).
%
% The point P is a struct{x,y}, while the polygon V is 
% defined by its vertex points, which are stored in a
% struct{x[],y[]}
% where the arrays are the x- and y-coordinates.
%
% See the URL below for more explanations.
%
% Based on code by Dan Sunday,
% http://geomalgorithms.com/a03-_inclusion.html
% and patterned after Randolph Franklin (2000),
% http://www.ecse.rpi.edu/Homepages/wrf/research/geom/pnpoly.html
%
%\seealso{winding_number_polygon,point_in_polygon,simplify_polygon}
%!%-
{
    if (_NARGS != 2) {
	help(_function_name());
    }

    variable P,V;
    (P,V)=();

    % number of vertex points
    variable n=length(V.x);
    
    if (n<1) {
	throw UsageError,sprintf("%s: Polygon must have at least 2 vertex points.\n",_function_name());
    }

    if (V.x[0]!=V.x[n-1] or V.y[0]!=V.y[n-1])  {
	throw UsageError,sprintf("%s: Polygon is not closed.\n",_function_name());
    }
    
    if (length(V.x) != length(V.y) ) {
	throw UsageError,sprintf("%s: Vertex arrays x and y must be of same length.\n",_function_name());
    }

    variable cn=0; % crossing number counter
    variable i;
    % loop over all edges of the polygon
    _for i(0, n-2, 1) {
	% upward or downward crossing?
	if (((V.y[i]<=P.y) and (V.y[i+1]>P.y)) or 
	((V.y[i]>P.y) and  (V.y[i+1]<=P.y))) {
	    % edge-ray intersect coordinate
	    variable vt=(P.y-V.y[i])/(V.y[i+1]-V.y[i]);
	    % P.x < intersect x coordinate?
	    if (P.x < V.x[i]+vt*(V.x[i+1]-V.x[i]) ) {
		cn++;
	    }
	}
    }
    return cn;
}

define winding_number_polygon()
%!%+
%\function{winding_number_polygon}
%\usage{wn=winding_number_polygon(P,V)}
%\synopsis{return the winding number for a point P in a polygon}
%\description
% return the winding number for a point P in a (potentially
% complex polygon V)
%
% The winding number counts the number of times the polygon V winds
% around point P. The point is outside if the winding number is 0.
%
% The algorithm used here is as efficient as the determination
% of the crossing number.
%
% The point P is a struct{x,y}, while the polygon is a
% struct{x[],y[]} where the arrays are the x- and y-coordinates.
% The polygon has to be closed, i.e. V.x[n]==V.x[0] and
% V.y[n]==V.y[0] where n is the number of polygon points.
%
% See the URL below for more explanations.
%
% Based on code by Dan Sunday,
% http://geomalgorithms.com/a03-_inclusion.html
%
%\seealso{crossing_number_polygon,point_in_polygon,simplify_polygon}
%!%-
{
    if (_NARGS != 2) {
	help(_function_name());
    }

    variable P,V;
    (P,V)=();

    variable n=length(V.x);

    if (n<2) {
	throw UsageError,sprintf("%s: Polygon must have at least 2 vertex points.\n",_function_name());
    }

    if (V.x[0]!=V.x[n-1] or V.y[0]!=V.y[n-1])  {
	throw UsageError,sprintf("%s: Polygon is not closed.\n",_function_name());
    }
    
    if (length(V.x) != length(V.y) ) {
	throw UsageError,sprintf("%s: Vertex arrays x and y must be of same length.\n",_function_name());
    }
    
    variable wn=0;
    % loop over all edges
    variable i;
    _for i(0, n-2, 1) {
	if (V.y[i]<=P.y) {
	    % start y<=P.y
	    % ...upward crossing?
	    if (V.y[i+1] > P.y) {
		% Is point left of edge?
		if (point_is_left_of_line(V.x[i],V.y[i],V.x[i+1],V.y[i+1],P.x,P.y) > 0) {
		    wn++;
		}
	    }
	} else {
	    % start y>P.y
	    % ...downward crossing?
	    if (V.y[i+1]<=P.y) {
		if (point_is_left_of_line(V.x[i],V.y[i],V.x[i+1],V.y[i+1],P.x,P.y) < 0) {
		    wn--;
		}
	    }
	}
    }
    return wn;
}

define point_in_polygon()
%!%+
%\function{point_in_polygon}
%\usage{ret=point_in_polygon(p0,V);}
%\altusage{ret=point_in_polygon(x,y,Vx,Vy);}
%\synopsis{determine whether a point is in a polygon}
%\qualifiers{
%\qualifier{evenodd}{use the crossing number method}
%\qualifier{crossing}{use the crossing number method}
%\qualifier{winding}{use the winding number method (the default)}
%}
%\description
% The function returns 1 if the point p0 is located inside the
% polygon defined by the vertices V, and 0 if it is located
% outside of the polygon.
%
% The polygon has to be closed, i.e. V.x[n]==V.x[0] and
% V.y[n]==V.y[0] where n is the number of polygon points.
%
% Either the winding number (default) or the even-odd-rule
% define what is meant by inside.
%
% The point is either defined by a struct{x,y} and the vertices
% by a struct{x[],y[]}, or the coordinates can be directly
% given in the respective arrays.
%
% See the URL below for more explanations.
%
% Based on code by Dan Sunday,
% http://geomalgorithms.com/a03-_inclusion.html
%
%\seealso{crossing_number_polygon,point_in_polygon,simplify_polygon}
%!%-
%
{
    variable P,V;
    if (_NARGS==2) {
	(P,V)=();
    } else {
	if (_NARGS==4) {
	    variable x,y,Vx,Vy;
	    (x,y,Vx,Vy)=();
	    P=struct{x=x,y=y};
	    V=struct{x=@Vx,y=@Vy};
	} else {
	    throw UsageError,sprintf("%s: Wrong number of arguments.\n",_function_name());
	}
    }
    if (qualifier_exists("evenodd") or qualifier_exists("crossing")) {
	variable cn=crossing_number_polygon(P,V);
	printf("CN: %i\n",cn);
	return ( (cn mod 2)==1 );
    }

    % winding number method
    variable wn=winding_number_polygon(P,V);
    return ( wn!=0);
}
