define plot_with_err()
%!%+
%\function{plot_with_err}
%\synopsis{plots data points with their errorbars}
%\usage{plot_with_err(x, [xErr,] y, yErr);
%\altusage{plot_with_err(Struct_Type s);}
%}
%\qualifiers{
%\qualifier{xerr}{change 3-argument-syntax to \code{plot_with_err(x, xErr, y);}}
%\qualifier{xminmax}{changes the meaning of \code{xErr} -- and \code{x}, if \code{xErr} is not a list}
%\qualifier{yminmax}{changes the meaning of \code{yErr} -- and \code{y}, if \code{yErr} is not a list}
%\qualifier{minmax}{equivalent to both \code{x}- and \code{yminmax}}
%\qualifier{i}{index-array of subset of data points to be plotted}
%\qualifier{set_xrange=frac}{ (default: 0.05): set the \code{xrange} from the lowest to highest x-value
%                  with additional padding (given as a fraction fo the x-range) on both sides}
%\qualifier{set_yrange=frac}{ (default: 0.05): set the \code{xrange} from the lowest to highest y-value
%                  with additional padding (given as a fraction of the y-range) on both sides}
%\qualifier{set_ranges}{equivalent to both \code{set_xrange} and \code{set_yrange}}
%\qualifier{overplot}{The data will be overplotted.}
%\qualifier{connect_points}{data points are also connected}
%\qualifier{histogram}{draw histogram lines, too}
%\qualifier{error_color}{draw error bars in a different color}
%}
%\description
%    In order to use asymetric errors for x and/or y,
%    the correspondig \code{Err} argument has to be a list \code{{ Err1, Err2 }}.
%    If one of the \code{minmax} qualifiers is used,
%    the corresponding \code{Err} list contains directly minimum and maximum values.
%
%    If one of the \code{minmax} qualifiers is used, but \code{Err} is not a list,
%    the value and \code{Err} arguments actually mean minimum and maximum values.
%    The actual value is infered to be the mean of minimum and maximum.
%\examples
%    % examples with symmetrical errorbars:\n
%     plot_with_err(x,       y, yErr);\n
%     plot_with_err(x, xErr, y, yErr);\n
%     plot_with_err(x, xErr, y,     ; xerr);\n
%    \n
%     % examples with unspecified x and/or y value:\n
%      plot_with_err(xMin, xMax, y   , yErr; xminmax);  % => x = (xMin+xMax)/2\n
%      plot_with_err(x[, xErr],  yMin, yMax; yminmax);  % => y = (yMin+yMax)/2\n
%      plot_with_err(xMin, xMax, yMin, yMax;  minmax);  % => [both inferences]\n
%      s = struct { bin_lo=x-xErr, bin_hi=x+xErr, value=y, err=yErr };\n
%      plot_with_err(s);
%    \n
%    % examples with asymmetrical errorbars:
%     plot_with_err(x, {xErr1, xErr2}, y,  {yErr1, yErr2});\n
%     plot_with_err(x, {xMin,  xMax }, y,  {yMin,  yMax}; minmax);\n
%    \n
%    % example combining the above features:\n
%     plot_with_err(xMin, xMax, y, {yMin, yMax}; minmax);  % => x = (xMin+xMax)/2\n
%\seealso{[o][h]plot_with_err, [o][h]plot}
%!%-
{
  variable plot_options = get_plot_options();  % will be overwritten after possibly setting {x/y}range

  variable s, x, xErr=NULL, y, yErr=NULL;
  switch(_NARGS)
  { case 1:
      s = ();
      x    = (s.bin_lo + s.bin_hi)/2.;
      xErr = (s.bin_hi - s.bin_lo)/2.;
      y    =  s.value;
      if(struct_field_exists(s, "err"))    yErr = s.err;  % <- standard
      else if(struct_field_exists(s, "error"))  yErr = s.error;  % <- convenient (?)
      if(plot_options.use_bin_density)
      { y /= (s.bin_hi-s.bin_lo);
        if(yErr!=NULL)  yErr /= (s.bin_hi-s.bin_lo);
      }
  }
  { case 2:
      vmessage("warning (%s): only two arguments specified, trying normal plot", _function_name());
      (x, y) = ();
      plot(x, y);
      return;
  }
  { case 3:
      if(qualifier_exists("xerr"))
        (x, xErr, y      ) = ();
      else
        (x,       y, yErr) = ();
  }
  { case 4: (x, xErr, y, yErr) = (); }
  { help(_function_name()); return; }

  variable xminmax = _NARGS>1 && (qualifier_exists("minmax") || qualifier_exists("xminmax"));
  variable yminmax = _NARGS>1 && (qualifier_exists("minmax") || qualifier_exists("yminmax"));
  variable xMin, xMax, yMin, yMax;
  if(xErr==NULL)
    (xMin, xMax) = (x, x);
  else
    if(typeof(xErr)!=List_Type)
      if(xminmax)
       (xMin, xMax, x) = (x, xErr, (x+xErr)/2.);
      else
       (xMin, xMax) = (x-xErr, x+xErr);
    else
      if(xminmax)
        (xMin, xMax) = (xErr[0], xErr[1]);
      else
        (xMin, xMax) = (x-xErr[0], x+xErr[1]);

  if(yErr==NULL)
    (yMin, yMax) = (y, y);
  else
    if(typeof(yErr)!=List_Type)
      if(yminmax)
        (yMin, yMax, y) = (y, yErr, (y+yErr)/2.);
      else
        (yMin, yMax) = (y-yErr, y+yErr);
    else
      if(yminmax)
        (yMin, yMax) = (yErr[0], yErr[1]);
      else
        (yMin, yMax) = (y-yErr[0], y+yErr[1]);

  % select data points
  variable i = qualifier("i");
  if(i!=NULL)
    (x,    xMin,    xMax,    y,    yMin,    yMax   ) =
    (x[i], xMin[i], xMax[i], y[i], yMin[i], yMax[i]);

  % set ranges
  variable pad = qualifier("set_ranges");
  variable xpad = qualifier("set_xrange", pad);
  if(qualifier_exists("set_xrange") || qualifier_exists("set_ranges"))
  {
    variable qx = (plot_options.logx ? struct { logpad } : struct { pad });
    set_struct_fields(qx, (xpad!=NULL ? xpad : 0.05));
    xrange(min_max([xMin, xMax];; qx));
  }
  variable ypad = qualifier("set_yrange", pad);
  if(qualifier_exists("set_yrange") || qualifier_exists("set_ranges"))
  {
    variable qy = (plot_options.logy ? struct { logpad } : struct { pad });
    set_struct_fields(qy, (ypad!=NULL ? ypad : 0.05));
    yrange(min_max([yMin, yMax];; qy));
  }

  plot_options = get_plot_options();  % only after possibly setting {x/y}range

  % draw points (has indeed to be before selection of visible data points!)
  variable hist = qualifier_exists("histogram");
  connect_points( qualifier_exists("connect_points") || hist);
  plot_bin_integral;
  variable col = plot_options.start_color;
  if(qualifier_exists("overplot"))
  { col = plot_options.color;
    if(hist)
      ohplot(xMin, xMax, y);
    else
      oplot(x, y);
  }
  else
    if(hist)
      hplot(xMin, xMax, y);
    else
      plot(x, y);
  connect_points(-1);

%  % draw histogram lines
%  if(qualifier_exists("histogram"))
%    color(col), ohplot(xMin, xMax, y);

  % select visible data points
  i = where(    xMin<=plot_options.xmax and xMax>=plot_options.xmin
            and yMin<=plot_options.ymax and yMax>=plot_options.ymin);
  (x,    xMin,    xMax,    y,    yMin,    yMax   ) =
  (x[i], xMin[i], xMax[i], y[i], yMin[i], yMax[i]);

  % draw error bars
  variable n_minus_1 = length(x)-1;
  variable err_col = qualifier("error_color", col);
  ifnot(xErr==NULL || hist)
    _for i (0, n_minus_1, 1)
      color(err_col), oplot([xMin[i], xMax[i]], y[[i,i]]);
  if(yErr!=NULL)
    _for i (0, n_minus_1, 1)
      color(err_col), oplot(x[[i,i]], [yMin[i], yMax[i]]);

  % restore previous options
  ()=change_plot_options(; connect_points=plot_options.connect_points,
			   color=col+1,
			   start_color=plot_options.start_color,
			   use_bin_density=plot_options.use_bin_density
			);
}
