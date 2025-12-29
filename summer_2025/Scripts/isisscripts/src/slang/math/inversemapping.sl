define inversemapping()
%!%+
%\function{inversemapping}
%\synopsis{computes the inverse of a 2d mapping numerically}
%\usage{(x, y) = inversemapping(&getxy, cache, x_, y_);}
%\description
%   (cache.x_, cache.y_) = getxy(cache.x, cache.y);
%   (x_, y_) = getxy(x, y);
%!%-
{
  variable getxy, cache, x_, y_;
  switch(_NARGS)
  { case 4: (getxy, cache, x_, y_) = (); }
  { help(_function_name()); return; }

  variable verbose = qualifier_exists("verbose");
  variable F = qualifier("stderr", stderr);

  if(verbose)  ()=fprintf(F, "# trying to invert x_=%f, y_=%f\n", x_, y_);

  loop(10)
%  forever
  {
    variable d2 = (x_-cache.x_)^2 + (y_-cache.y_)^2;
    variable all_i = array_sort(d2);
    variable i = all_i[[0:2]];

    variable ptr=1;
    while(   cache.x[all_i[ptr]] == cache.x[i[0]]
	  && cache.y[all_i[ptr]] == cache.y[i[0]])
      ptr++;
    i[1] = all_i[ptr];
    ptr++;
    while(   cache.x[all_i[ptr]] == cache.x[i[1]]
	  && cache.y[all_i[ptr]] == cache.y[i[1]])
      ptr++;
    i[2] = all_i[ptr];

    if( (cache.x[i[0]] == cache.x[i[1]] && cache.x[i[1]] == cache.x[i[2]]) )
    { ptr=3;
      while(cache.x[all_i[ptr]] == cache.x[i[0]])  ptr++;
      i[2] = all_i[ptr];
    }
    if( (cache.y[i[0]] == cache.y[i[1]] && cache.y[i[1]] == cache.y[i[2]]) )
    { ptr=3;
      while(cache.y[all_i[ptr]] == cache.y[i[0]])  ptr++;
      i[2] = all_i[ptr];
    }

    variable cachex  = cache.x [i];
    variable cachey  = cache.y [i];
    variable cachex_ = cache.x_[i];
    variable cachey_ = cache.y_[i];

    if(verbose)
    { variable tmpcache = struct_filter(cache, i; copy);
      print_struct(F, struct_combine(tmpcache, struct{ d2 = d2[i] }));
      % connect_points(0); pointstyle(-4);
      % plot([cachex_, x_], [cachey_, y_]);
      % xylabel(cachex[0], cachey[0], string(d2[i[0]]));
      % xylabel(cachex[1], cachey[1], string(d2[i[1]]));
      % xylabel(cachex[2], cachey[2], string(d2[i[2]]));
      % oplot([x_], [y_]);
    }

    variable dx_dx, dx_dy,  dy_dx, dy_dy,  x, y;
    %  x'1  =  x'0  +  (x1-x0) * dx'/dx  +  (y1-y0) * dx'/dy
    %  x'2  =  x'0  +  (x2-x0) * dx'/dx  +  (y2-y0) * dx'/dy
    (dx_dx, dx_dy) = solve_2d_system_of_equations( cachex[1]-cachex[0],  cachey[1]-cachey[0],  cachex_[1]-cachex_[0],
                                                   cachex[2]-cachex[0],  cachey[2]-cachey[0],  cachex_[2]-cachex_[0]
  					         );
    if(dx_dx==NULL)
    { vmessage("error (%s): cannot solve equations for dx'/dx, dx'/dy", _function_name());
      return NULL, NULL;
    }
    else
    { %  y'1  =  y'0  +  (x1-x0) * dy'/dx  +  (y1-y0) * dy'/dy
      %  y'2  =  y'0  +  (x2-x0) * dy'/dx  +  (y2-y0) * dy'/dy
      (dy_dx, dy_dy) = solve_2d_system_of_equations( cachex[1]-cachex[0],  cachey[1]-cachey[0],  cachey_[1]-cachey_[0],
                                                     cachex[2]-cachex[0],  cachey[2]-cachey[0],  cachey_[2]-cachey_[0]
    					           );
      if(dy_dx==NULL)
      { vmessage("error (%s): cannot solve equations for dy'/dx, dy'/dy", _function_name());
	return NULL, NULL;
      }

      %  x'  =  x'0  +  (x-x0) * dx'/dx  +  (y-y0) * dx'/dy
      %  y'  =  y'0  +  (x-x0) * dy'/dx  +  (y-y0) * dy'/dy
      (x, y) = solve_2d_system_of_equations( dx_dx,  dx_dy,  x_ - cachex_[0] + dx_dx * cachex[0] + dx_dy * cachey[0],
    					     dy_dx,  dy_dy,  y_ - cachey_[0] + dy_dx * cachex[0] + dy_dy * cachey[0]
				           );
      if(x==NULL)
      { vmessage("error (%s): cannot solve equations for x, y", _function_name());
	return NULL, NULL;
      }

      if(verbose)  ()=fprintf(F, "extrapolation => (x=%f, y=%f)\n", x, y);

      variable maxd2 = (max(cachex)-min(cachex))^2 + (max(cachey)-min(cachey))^2;
      variable meancachex = mean(cachex);
      variable meancachey = mean(cachey);
      variable d2_mean = (x-meancachex)^2+(y-meancachey)^2;

      variable x__, y__, d2_=0;
      do
      {
	if((isnan(d2_) || d2_>=d2[i[2]]) && d2_mean > maxd2)
	{ if(verbose)  ()=fprintf(F, "replacing (x=%f, y=%f) ", x, y);
	  x = (x+meancachex)/2;
	  y = (y+meancachey)/2;
	  if(verbose)  ()=fprintf(F, "by (x=%f, y=%f)\n", x, y);
	}
	% oplot(x, y);
        (x__, y__) = @getxy(x, y);
        d2_ = (x_-x__)^2 + (y_-y__)^2;

	if(verbose)  ()=fprintf(F, "(x=%f, y=%f) => (x_=%f, y_=%f), d2=%f\n", x, y, x__, y__, d2_);

        ifnot(isnan(d2_))
        {
          cache.x  = [cache.x , x  ];
          cache.y  = [cache.y , y  ];
          cache.x_ = [cache.x_, x__];
          cache.y_ = [cache.y_, y__];

          if(d2_ < qualifier("eps", 1e-3)^2)
          { if(verbose)  ()=fprintf(F, "success: (x=%f, y=%f) => (x_=%f, y_=%f)\n", x, y, x__, y__);
            return x, y;
          }
	}
      } while((isnan(d2_) || d2_>=d2[i[2]]) && d2_mean>maxd2);

#iffalse
	if(verbose)  ()=printf("warning (%s): extrapolation from (mean{x}=%f, mean{y}=%f) to (x=%f, y=%f) to far, rescaling to ", _function_name(), meancachex, meancachey, x, y);
	x = meancachex + (x-meancachex)*sqrt(10.*maxd2/d2_mean);
	y = meancachey + (y-meancachey)*sqrt(10.*maxd2/d2_mean);
	if(verbose)  ()=printf("(x=%f, y=%f)\n", x, y);

	(x__, y__) = @getxy(x, y);
	d2_ = (x_-x__)^2 + (y_-y__)^2;
        if(isnan(d2_))
      	  vmessage("warning (%s): function evaluation for (x=%f, y=%f) returned nan", _function_name(), x, y);
        else
        {
          cache.x  = [cache.x , x  ];
          cache.y  = [cache.y , y  ];
          cache.x_ = [cache.x_, x__];
          cache.y_ = [cache.y_, y__];

          if(d2_ < qualifier("eps", 1e-3)^2)
          { if(verbose)  vmessage("success (%s): (x=%f, y=%f) => (x_=%f, y_=%f)", _function_name(), x, y, x__, y__);
	    return x, y;
	  }
        }
	  d2_mean = (x-meancachex)^2+(y-meancachey)^2;
	  ()=printf("d2_mean=%f\n", d2_mean);
	} while(d2_mean > 100. * maxd2);
      }

%      if(verbose)
%      {
%	()=printf("x=%f, y=%f => x_=%f, y_=%f\n", x, y, x__, y__);
%        ()=printf("old distances^2: %f %f %f\n", d2[i[0]], d2[i[1]], d2[i[2]]);
%        ()=printf("new distances^2: %f\n", d2_);
%      }
#endif

      if(   isnan(d2_)
	 || (d2_ >= d2[i[2]])
	 || (cache.x[i[0]] == cache.x[i[1]] && cache.x[i[1]] == x) || (cache.y[i[0]] == cache.y[i[1]] && cache.y[i[1]] == y)
	)
      {
        if(verbose)
	{ if(isnan(d2_))
	    ()=fprintf(F, "# nan\n");
	  else
	    if( (d2_ >= d2[i[2]]) )
	      ()=fprintf(F, "# no improvement => finer grid required\n");
  	    else
	      ()=fprintf(F, "# degeneracy => finer grid required\n");
	  ()=fprintf(F, "dx'/dx = %f,  dx'/dy = %f,  dy'/dx = %f,  dy'/dy = %f\n", dx_dx, dx_dy, dy_dx, dy_dy);
	}

	variable X = cache.x[i];
	variable Y = cache.x[i];
	ifnot(isnan(d2_) || d2_ >= 2*d2[i[2]])
	  (X, Y) = ([x,X], [y,Y]);

	variable x1, y1;
	variable n = 4, improved=0;
	while(not improved and n<=8)
	{ if(verbose)  ()=fprintf(F, "%d x %d grid\n", n, n);
  	  foreach x1 ([1.5*min(X)-0.5*max(X) : 1.5*max(X)-0.5*min(X) : #n])
	    foreach y1 ([1.5*min(Y)-0.5*max(Y) : 1.5*max(Y)-0.5*min(Y) : #n])
	    { (x__, y__) = @getxy(x1, y1);
              cache.x  = [cache.x , x1 ];
              cache.y  = [cache.y , y1 ];
              cache.x_ = [cache.x_, x__];
              cache.y_ = [cache.y_, y__];
              if( (x_-x__)^2 + (y_-y__)^2 < d2[i[2]]
		   and (x1!=cache.x[i[0]] ||  y1!=cache.y[i[0]])
		   and (x1!=cache.x[i[1]] ||  y1!=cache.y[i[1]])
		)
		improved = 1;
	      if(verbose)  ()=fprintf(F, "(x=%f, y=%f) => (x_=%f, y_=%f), d2=%f (%d)", x1, y1, x__, y__, (x_-x__)^2 + (y_-y__)^2, improved);
	    }
	  n *= 2;
	}
	ifnot(improved)
	{ if(verbose)  ()=fprintf(F, "8 x 8 grid search did not improve result");
	  return NULL, NULL;
	}
      }
    }
  }

  return NULL, NULL;
}
