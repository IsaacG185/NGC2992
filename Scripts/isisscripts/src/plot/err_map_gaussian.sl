define err_map_gaussian ()
%!%+
%\function{err_map_gaussian}
%\synopsis{plots data points with their errorbars}
%\usage{err_map_gaussian(x, [xErr,] y, yErr);
%\altusage{err_map_gaussian(Struct_Type s);}
%}
%\qualifiers{
%\qualifier{xerr}{               change 3-argument-syntax to \code{err_map_gaussian(x, xErr, y);}}
%\qualifier{xminmax}{            changes the meaning of \code{xErr} -- and \code{x}, if \code{xErr} is not a list}
%\qualifier{yminmax}{            changes the meaning of \code{yErr} -- and \code{y}, if \code{yErr} is not a list}
%\qualifier{minmax}{             equivalent to both \code{x}- and \code{yminmax}}
%\qualifier{x_pixel [=400]}{     number of x-axis bins of the image}
%\qualifier{y_pixel [=400]}{     number of y-axis bins of the image}
%\qualifier{i}{                  index-array of subset of data points to be plotted}
%\qualifier{xmin [=min(x data)]}{minimal value of x-axis}
%\qualifier{xmax [=max(x data)]}{maximal value of x-axis}
%\qualifier{ymin [=min(y data)]}{minimal value of y-axis}
%\qualifier{ymax [=max(y data)]}{maximal value of y-axis}
%\qualifier{min_xerr [=1e-10]}{  minimal error for x-values}
%\qualifier{min_yerr [=1e-10]}{  minimal error for y-values}
%\qualifier{xlog}{               switch to logarithmic x-axis}
%\qualifier{ylog}{               switch to logarithmic y-axis}
%}
%\description
%    Plots a 2D gaussian for each data point. The given errors are used as the
%    width(1 sigma) of the Gaussian profiles. If asymmetric errors are used, the
%    profile is the combination of two Gaussians. The volume of each profile is
%    normalized.
%    
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
%     plot_image( err_map_gaussian([1,2], [0.1,0.3], [1,1], [0.5,0.3];xmin=0,xmax=3,ymin=0,ymax=2) );\n
%    \n
%    % examples with asymmetrical errorbars:
%     plot_image( err_map_gaussian([1], {[0.1],[0.3]}, [1], {[0.1],[0.1]};xmin=0,xmax=2,ymin=0,ymax=2) );\n
%    \n
%\seealso{plot_with_err}
%!%-
{
  variable s, x, xErr=NULL, y, yErr=NULL;
  switch(_NARGS)
  { case 1:
      s = ();
      x    = (s.bin_lo + s.bin_hi)/2.;
      xErr = (s.bin_hi - s.bin_lo)/2.;
      y    =  s.value;
      if(struct_field_exists(s, "err"))    yErr = s.err;  % <- standard
      if(struct_field_exists(s, "error"))  yErr = s.error;  % <- convenient (?)
  }
  { case 2:
      vmessage("warning (%s): only two arguments specified");
      help(_function_name()); return;
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
    (xMin, xMax) = (0, 0);%(x, x);
  else
    if(typeof(xErr)!=List_Type)
      if(xminmax)
       (xMin, xMax, x) = ((x+xErr)/2.-x, xErr-(x+xErr)/2., (x+xErr)/2.);%(x, xErr, (x+xErr)/2.);
      else
       (xMin, xMax) = (xErr, xErr);%(x-xErr, x+xErr);
    else
      if(xminmax)
        (xMin, xMax) = (x-xErr[0], xErr[1]-x);%(xErr[0], xErr[1]);
      else
        (xMin, xMax) = (xErr[0], xErr[1]);%(x-xErr[0], x+xErr[1]);

  if(yErr==NULL)
    (yMin, yMax) = (y, y);
  else
    if(typeof(yErr)!=List_Type)
      if(yminmax)
        (yMin, yMax, y) = ((y+yErr)/2.-y, yErr-(y+yErr)/2., (y+yErr)/2.);%(y, yErr, (y+yErr)/2.);
      else
        (yMin, yMax) = (yErr, yErr);%(y-yErr, y+yErr);
    else
      if(yminmax)
        (yMin, yMax) = (y-yErr[0], yErr[1]-y);%(yErr[0], yErr[1]);
      else
        (yMin, yMax) = (yErr[0], yErr[1]);%(y-yErr[0], y+yErr[1]);

  variable i = qualifier("i");
  if(i!=NULL)
    (x,    xMin,    xMax,    y,    yMin,    yMax   ) =
    (x[i], xMin[i], xMax[i], y[i], yMin[i], yMax[i]);
  
  
  
  variable min_xerr  = qualifier("xerr_min",1e-10);
  variable min_yerr  = qualifier("yerr_min",1e-10);
  variable X = qualifier("x_pixel",400);
  variable Y = qualifier("y_pixel",400);
  variable A = Double_Type[Y,X];
  variable j,k;

  variable y_min = qualifier("ymin",min(y+yMin));
  variable y_max = qualifier("ymax",max(y+yMax));
  variable ylo,yhi;
  if (qualifier_exists("ylog")) (ylo, yhi) = log_grid (y_min, y_max, Y);
  else(ylo, yhi) = linear_grid (y_min, y_max, Y);

  variable x_min = qualifier("xmin",min(x+xMin));
  variable x_max = qualifier("xmax",max(x+xMax));
  variable xlo,xhi;
  if (qualifier_exists("xlog")) (xlo, xhi) = log_grid (x_min, x_max, X);
  else (xlo, xhi) = linear_grid (x_min, x_max, X);
  
  A[*,*]=0.;
  variable B = @A;

  variable fl1,fl2;
  variable ff= get_fit_fun;
  fit_fun( "egauss");
  set_par( "egauss(1).area",          1,  1,             0,          5);
  set_par( "egauss(1).center",    y_min,  0,   -DOUBLE_MAX, DOUBLE_MAX);
  set_par( "egauss(1).sigma",  min_xerr,  0, 1./DOUBLE_MAX, DOUBLE_MAX);

  _for j(0,length(y)-1,1)
  {
    B[*,*]=0.;
    set_par( "egauss(1).center", y[j]);
    set_par( "egauss(1).sigma", max( [yMin[j], min_yerr] ) );
    fl1 = eval_fun_keV(ylo,yhi);
    if(typeof(yErr)==List_Type) % yMax!=yMin
    {
      set_par( "egauss(1).sigma", max( [yMax[j], min_yerr] ) );
      fl2 = eval_fun_keV(ylo,yhi)*(max( [yMax[j], min_yerr] )/max( [yMin[j], min_yerr] ));
      fl2[where(ylo <= y[j])]=0.;      fl1[where(ylo > y[j])]=0.;
      fl1 = (fl1+fl2)*( 2./(1+ (max( [yMax[j], min_yerr] )/max( [yMin[j], min_yerr] ))) );      
    }
    _for k(0,X-1,1) B[*,k]=fl1; 
    set_par( "egauss(1).center", x[j]);
    set_par( "egauss(1).sigma", max( [xMin[j],min_xerr] ) );
    fl1 = eval_fun_keV(xlo,xhi);
    if(typeof(xErr)==List_Type) % xMax!=xMin
    {
      set_par( "egauss(1).sigma", max( [xMax[j], min_xerr] ) );
      fl2 = eval_fun_keV(xlo,xhi)*(max( [xMax[j], min_xerr] )/max( [xMin[j], min_xerr] ));
      fl2[where(xlo <= x[j])]=0.;      fl1[where(xlo > x[j])]=0.;
      fl1 = (fl1+fl2)*( 2./(1+ (max( [xMax[j], min_xerr] )/max( [xMin[j], min_xerr] ))) );      
    }
    _for k(0,Y-1,1) B[k,*] *= fl1;
    A+=B;
  }

  fit_fun(ff);
  return A;
}
