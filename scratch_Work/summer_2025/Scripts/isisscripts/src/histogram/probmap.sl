private define w2m(obj, val, dim) {
  % dimension dependent boundaries
  variable mn, mx, bins, ddim;
  (mn,mx,bins,ddim) = (dim == 'x' ? (&obj.world.xMin, &obj.world.xMax, &obj.world.xbins, &obj.world.dx)
		                  : (&obj.world.yMin, &obj.world.yMax, &obj.world.ybins, &obj.world.dy));
  % loop over all input values and convert
  variable con = Integer_Type[length(val)], i;
  _for i (0, length(val)-1 ,1)
    con[i] = int(ceil((val[i] - @mn) / @ddim) - 1);

  return length(con) == 1 ? con[0] : con;
}

private define m2w(obj, val, dim) {
  % dimension dependent boundaries
  variable mn, mx, bins, ddim;
  (mn,mx,bins,ddim) = (dim == 'x' ? (&obj.world.xMin, &obj.world.xMax, &obj.world.xbins, &obj.world.dx)
		                  : (&obj.world.yMin, &obj.world.yMax, &obj.world.ybins, &obj.world.dy));
  % loop over all input values and convert
  variable con = Double_Type[length(val)], i;
  _for i (0, length(val)-1 ,1)
    con[i] = (val[i] + .5)*@ddim + @mn;

  return length(con) == 1 ? con[0] : con;
}


% 2d gauss
private define probmap_2dgauss(x,y,mux,muy,sigx,sigy) {
  return exp(-.5*( (sigx == 0 ? 0 : ((x-mux)/sigx)^2) + (sigy == 0 ? 0 : ((y-muy)/sigy)^2))) / (2*PI*(sigx == 0 ? 1 : sigx)*(sigy == 0 ? 1 : sigy));
}


% normalization functions
private define probmap_calcmap_maxNorm(raw, sum) { variable mx = 1.*max(sum);  return (mx == 0. ? 1. : 1./mx); }

% calculate the probability map from the given data
private define probmap_calcmap(obj) {
  % set world if not done yet
  ifnot (obj.world_defined()) {
    obj.xrange(min(array_flatten(array_struct_field(obj.data.raw, "x") - array_struct_field(obj.data.raw, "dx"))),
	       max(array_flatten(array_struct_field(obj.data.raw, "x") + array_struct_field(obj.data.raw, "dx"))));
    obj.yrange(min(array_flatten(array_struct_field(obj.data.raw, "y") - array_struct_field(obj.data.raw, "dy"))),
	       max(array_flatten(array_struct_field(obj.data.raw, "y") + array_struct_field(obj.data.raw, "dy"))));
  }

  % recalculate map if needed
  if (obj.data.needsUpdate) {
    variable i, d, sum = Double_Type[obj.world.ybins, obj.world.xbins];
    % loop over data
    _for i (0, length(obj.data.raw)-1, 1)
    {
      % calculate lower left corner of the error ellipse
      variable x0 = w2m(obj, obj.data.raw[i].x - 3*obj.data.raw[i].dx, 'x');
      variable y0 = w2m(obj, obj.data.raw[i].y - 3*obj.data.raw[i].dy, 'y');
      % calculate upper right corner where error is given
      variable x1 = @x0, y1 = @y0, n;
      n = where(obj.data.raw[i].dx != 0.);
      x1[n] = w2m(obj, obj.data.raw[i].x[n] + 3*obj.data.raw[i].dx[n], 'x');
      n = where(obj.data.raw[i].dy != 0.);
      y1[n] = w2m(obj, obj.data.raw[i].y[n] + 3*obj.data.raw[i].dy[n], 'y');
      % loop over coordinates
      _for d (0, length(x0)-1, 1) {
	% loop over error ellipse
	variable x,y;
	_for x (x0[d], x1[d], 1) _for y (y0[d], y1[d], 1) {
          if (0 <= x < obj.world.xbins && 0 <= y < obj.world.ybins) {
	    sum[y,x] += probmap_2dgauss(x, y, .5*(x0[d]+x1[d]), .5*(y0[d]+y1[d]), 1.*(x1[d]-x0[d])/6, 1.*(y1[d]-y0[d])/6);
	    % count point?
	    if (struct_field_exists(obj.data, "npoints"))
	      obj.data.npoints[y,x] += 1;
	  }
	}
      }
    }
    variable normFun = obj.norm_fun;
    obj.data.map = sum * @normFun(obj.data.raw, sum ;; struct_field_exists(obj.data, "npoints") ? struct { npoints = @(obj.data.npoints) } : NULL);
    
    obj.data.needsUpdate = 0;
  }
}


% retrieve the probability density map
private define probmap_getmap_method(nargs) {
  variable obj;
  switch(nargs)
    { case 1: (obj) = (); }

  probmap_calcmap(obj);
  return obj.data.map;
}


% retrieve one point within the probability map
private define probmap_getpoint_method(nargs) {
  variable obj,x,y;
  switch(nargs)
    { case 3: (obj,x,y) = (); }
    { message("Usage: probmap.getpoint(x, y);"); return; }

  probmap_calcmap(obj);

  ifnot (obj.world.xMin <= x <= obj.world.xMax && obj.world.yMin <= y <= obj.world.yMax) {
    message("error (probmap.getpoint): coordinates are out of world"); return; 
  }
  return obj.data.map[w2m(y,obj,'y'),w2m(x,obj,'x')];
}


% add the given data to the map (including error ellipses)
private define probmap_add_method(nargs) {
  variable obj, x, y, dx, dy;
  switch(nargs)
    { case 3: (obj,x,y) = (); dx = Integer_Type[length(x)]; dy = dx; }
    { case 4: (obj,x,y,dy) = (); dx = Integer_Type[length(x)]; }
    { case 5: (obj,x,y,dx,dy) = (); }
    { message("Usage: probmap.add(x, y[, dx, dy]);"); return; }

  obj.data.raw = [obj.data.raw, struct { x=x, y=y, dx=dx, dy=dy }];
  
  obj.data.needsUpdate = 1;

  return length(obj.data.raw);
}


% delete the data identified by its index from the map
private define probmap_delete_method(nargs) {
  variable obj, i;
  switch(nargs)
    { case 2: (obj,i) = (); }
    { message("Usage: probmap.delete(index);"); return; }

  ifnot (0 <= i < length(obj.data.raw)) { message("error (probmap.delete): given index is out of range"); return; }
  obj.data.raw = array_remove(obj.data.raw, i);
  
  obj.data.needsUpdate = 1;
}


% set the xrange
private define probmap_xrange_method(nargs) {
  variable obj, x0, x1;
  if (nargs == 3) {
    (obj,x0,x1) = ();
    if (obj.world.xMin == NULL && obj.world.xMax == NULL) {
      if (x0 < x1) {
        obj.world.xMin = 1.*x0;
        obj.world.xMax = 1.*x1;
	obj.world.dx = 1.*(x1-x0)/obj.world.xbins;
      } else { message("error (probmap.xrange): min has to smaller than max"); }
    } else { message("error (probmap.xrange): range has been defined already"); }
  } else { message("error (probmap.xrange): ranges not given"); }
}


% set the yrange
private define probmap_yrange_method(nargs) {
  variable obj, y0, y1;
  if (nargs == 3) {
    (obj,y0,y1) = ();
    if (obj.world.yMin == NULL && obj.world.yMax == NULL) {
      if (y0 < y1) {
        obj.world.yMin = 1.*y0;
        obj.world.yMax = 1.*y1;
        obj.world.dy = 1.*(y1-y0)/obj.world.ybins;
      } else { message("error (probmap.yrange): min has to smaller than max"); }
    } else { message("error (probmap.yrange): range has been defined already"); }
  } else { message("error (probmap.yrange): ranges not given"); }
}


% find the most probable path between two given points
private define probmap_calcpath_estimate(x0, y0, x1, y1) { return 0.; }
private define probmap_calcpath_method(nargs) {
  variable obj, x0, y0, x1, y1;
  if (nargs != 5) { message("error (probmap.calcpath): coordinates not given properly (x0,y0,x1,y1)"); return; }
  (obj, x0, y0, x1, y1) = ();
  % convert into map coordinates
  variable goX = w2m(obj,x0,'x'), goY = w2m(obj,y0,'y');
  if (goX < 0 || goX > obj.world.xbins-1 || goY < 0 || goY > obj.world.ybins-1)
    { message("error (probmap.calcpath): starting point out of range"); return; }
  variable desX = w2m(obj,x1,'x'), desY = w2m(obj,y1,'y');
  if (desX < 0 || desX > obj.world.xbins-1 || desY < 0 || desY > obj.world.ybins-1)
    { message("error (probmap.calcpath): ending point out of range"); return; }
  probmap_calcmap(obj);
  variable infind = where(obj.data.map == 0.);
  variable nmap = @obj.data.map;
  nmap[infind] = -_Inf;
  variable best = aStar(nmap, goY, goX, desY, desX;; struct_combine(__qualifiers, struct { estimate = &probmap_calcpath_estimate, max, meanCost }));
  return struct { x = m2w(obj,best.y,'x'), y = m2w(obj,best.x,'y'), prob = best.cost };
}


% check if the world has been defined yet
private define probmap_worlddefined_method(nargs) {
  variable obj;
  if (nargs == 1) {
    (obj) = ();
    return (obj.world.xMin != NULL
         && obj.world.xMax != NULL
         && obj.world.yMin != NULL
         && obj.world.yMax != NULL
    );
  }
}


% visible object methodes, which have to call
% internal methods to handle the stack correctly
% -> the calling object itself gets passed to
%    that functions
private define probmap_add() {
  variable args = __pop_args(_NARGS);
  return probmap_add_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_delete() {
  variable args = __pop_args(_NARGS);
  return probmap_delete_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_xrange() {
  variable args = __pop_args(_NARGS);
  return probmap_xrange_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_yrange() {
  variable args = __pop_args(_NARGS);
  return probmap_yrange_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_getmap() {
  variable args = __pop_args(_NARGS);
  return probmap_getmap_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_getpoint() {
  variable args = __pop_args(_NARGS);
  return probmap_getpoint_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_calcpath() {
  variable args = __pop_args(_NARGS);
  return probmap_calcpath_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define probmap_worlddefined() {
  variable args = __pop_args(_NARGS);
  return probmap_worlddefined_method(__push_args(args), _NARGS ;; __qualifiers);
}


%%%%%%%%%%%%%%%%%%%%%
define probmap() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{probmap}
%\synopsis{histogram-like function for 2d-data including uncertainties}
%\usage{Struct_Type probmap([Double_Type x0, x1, y0, y1]);}
%\qualifiers{
%    \qualifier{xbins}{number of bins in x-direction (preferred over 'bins')}
%    \qualifier{ybins}{number of bins in y-direction (preferred over 'bins')}
%    \qualifier{bins}{number of bins in both directions (default: 201)}
%}
%\description
%    Using this object, a histogram of multiple xy-datasets
%    including uncertainties for both, x- and y-direction,
%    can be created. The uncertainties are handled as 2d-
%    gaussians with sigma_x and sigma_y equal to the given
%    errors.
%
%    Calling this function creates a structure with the
%    following functions among other fields:
%      add      - adds xy-data to the map and returns the dataset
%                 number of the added data
%                 Usage: probmap.add(Double_Type[] x, y[, dy]);
%                     or probmap.add(Double_Type[] x, y[, dx, dy]);
%      delete   - deletes data identified by its dataset number
%                 Usage: probmap.delete(Integer_Type number);
%      xrange   - sets the x-range
%                 Usage: probmap.xrange(Double_Type xMin, xMax);
%      yrange   - sets the y-range
%                 Usage: probmap.yrange(Double_Type yMin, yMax);
%      npoints  - count the number of xy-data added in each point
%                 of the map. If set the density map is available
%                 at .data.npoints, and it is passed as qualifier
%                 'npoints' to the norm_fun (see next qualifier).
%      norm_fun - reference to a function used for normalization.
%                 The parameters are an array of all datasets,
%                 given as a structure (x,y,dx,dy), and the
%                 histogram map resulting by adding all data.
%                 The function has to return either a single
%                 normalization factor or a map of factors.
%                 Default factor: 1./max(histogram)
%      getmap   - calculates the histogram map from the added data
%                 and returns it as 2d-array
%                 Usage: probmap.getmap();
%      getpoint - returns the value of the histogram map at a
%                 specific point
%                 Usage: probmap.getpoint(x,y);
%      calcpath - calculates the path with the highest averaged
%                 probability between to points using the
%                 A*-algorithm returning a structure with the
%                 best path (x,y)
%\example
%    % creata a new map and set x- and y-range
%    variable pm = probmap(0.1, 100, 0, 20);
%    % add two xy-datasets including uncertainties
%    pm.add(x1, y1, dx1, dy1);
%    pm.add(x2, y2, dx2, dy2);
%    % plot the resulting histogram
%    plot_image(pm.getmap());
%\seealso{histogram2d, histogram_gaussian_probability, aStar}
%!%-
  variable obj = struct {
    add           = &probmap_add,
    delete        = &probmap_delete,
    xrange        = &probmap_xrange,
    yrange        = &probmap_yrange,
    getmap        = &probmap_getmap,
    getpoint      = &probmap_getpoint,
    calcpath      = &probmap_calcpath,
    world_defined = &probmap_worlddefined,
    world         = struct { xMin, xMax, yMin, yMax, dx, dy, xbins, ybins },
    norm_fun      = &probmap_calcmap_maxNorm,
    data          = struct { raw = Struct_Type[0], map, needsUpdate = 0 }
  };
   
  % initialize map
  obj.world.xbins = qualifier("xbins", qualifier("bins", 201));
  obj.world.ybins = qualifier("ybins", qualifier("bins", 201));
  obj.data.map = Double_Type[obj.world.ybins, obj.world.xbins];

  % count point density?
  if (qualifier_exists("npoints"))
    obj.data = struct_combine(obj.data, struct { npoints = Integer_Type[obj.world.ybins, obj.world.xbins] });

  % set world if given
  if (_NARGS == 4) {
    variable x0, x1, y0, y1;
    (x0,x1,y0,y1) = ();
    obj.xrange(x0, x1);
    obj.yrange(y0, y1);
  };

  return obj;
}
