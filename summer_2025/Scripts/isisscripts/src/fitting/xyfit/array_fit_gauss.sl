%%%%%%%%%%%%%%%%%%%%%%%%
define array_fit_gauss()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{array_fit_gauss}
%\synopsis{performs a gaussian fit on given x- or xy-data}
%\usage{Struct_Type array_fit_gauss(x [,y] [,dy] [,c] [,s] [,a] [,o]);}
%\qualifiers{
%\qualifier{frz}{boolean array determining which parameters (c,s,a,o) are frozen}
%\qualifier{keep}{keeps the data and fit function (be careful, needs to be deleted for the next fit}
%\qualifier{plot}{plot the given data and oplot the fit}
%\qualifier{oplot}{only oplot the fit}
%}
%\description
%   Tries to fit the given data by a gaussian and an offset. If the y-data is
%   omitted, the given x-data is interpreted as y-data. The x-values are then
%   generated as indices of the y-data.
%   The uncertainties of the y-data can be passed to the fit algorithm by the
%   `dy' parameter. If not given the errors are calculated assuming Poisson
%   statistics.
%   The four remaining parameters are the starting values:
%     c - center position
%     s - sigma
%     a - area
%     o - offset in y-direction
%   They may also be given by an array as parameter `c' in the order shown
%   above. The same order is used for the freeze status qualifier `frz'.
%   Performing the fit is done with the actual choosen fit method. The result
%   is returned as a structure of the form
%     Struct_Type { center, sigma, area, offset, chisqr }
%   where chisqr is the reduced chi-square value of the best fit.
%!%-
{
  variable x,y,dy,c,s,a,o;
  switch(_NARGS)
    { case 1: (y) = (); x = [0:length(y)-1]; }
    { case 2: (x,y) = (); }
    { case 3: (x,y,dy) = (); }
    { case 4: (x,y,dy,c) = (); }
    { case 5: (x,y,dy,c,s) = (); }
    { case 6: (x,y,dy,c,s,a) = (); }
    { case 7: (x,y,dy,c,s,a,o) = (); }
    { help(_function_name()); return; }
  if (typeof(y) == Null_Type) { y = x; x = [0:length(y)-1]; }
  if (length(c) > 1)
  {
    if (length(c) > 3) o=c[3];
    if (length(c) > 2) a=c[2];
    c=c[0];
    s=c[1];
  }
  else ifnot (length(c)==1) { throw RunTimeError, sprintf("error (%s): first starting value must be either a single integer or an array of length four",_function_name); }
  variable frz = qualifier("frz",[0,0,0,0]);
  ifnot (length(x)==length(y)) { throw RunTimeError, sprintf("error (%s): x- and y-arrays must be of equal length",_function_name); }
  ifnot (length(frz)==4) { vmessage("warning (%s): freeze qualifier must be an array of length four",_function_name); frz=[0,0,0,0]; }
  % starting values if not given
  variable dx = 0; if (min(x) < 1.) dx = 1.-min(x); % x values must be greater 1
  if ((not __is_initialized(&dy)) || typeof(dy) == Null_Type) dy = sqrt(y);
  else ifnot(length(y)==length(dy)) { throw RunTimeError, sprintf("error (%s): y- and dy-arrays must be of equal length",_function_name); }
  if ((not __is_initialized(&c)) || typeof(c) == Null_Type) c = x[where_max(x+dx)]+dx; % center
  else c = c+dx;
  if ((not __is_initialized(&s)) || typeof(s) == Null_Type) s = .5*(max(x)-min(x)); % sigma
  if ((not __is_initialized(&a)) || typeof(a) == Null_Type) a = (max(y)-min(y)); % area
  if ((not __is_initialized(&o)) || typeof(o) == Null_Type) o = 0.; % offset
  % store current fit specifications
  variable ff = get_fit_fun;
  variable fm = get_fit_method;
  variable freep = freeParameters;
  freeze(freep);
  % define counts
  variable id = define_counts(x+dx,make_hi_grid(x+dx),y,dy);
  variable mffC = sprintf("constant(%d)",id);
  variable mffG = sprintf("gauss(%d)",id);
  % define fit function and starting values
  fit_fun(mffC + " + " + mffG);
  set_par(mffC + ".factor",o,frz[3],0,0);
  set_par(mffG + ".center",c,frz[0],min(x+dx),max(x+dx));
  set_par(mffG + ".sigma",s,frz[1],0,DOUBLE_MAX);
  set_par(mffG + ".area",a,frz[2],0,0);
  % do the fit
  variable stat;
  ()=fit_counts(&stat;fit_verbose=-2);
  % return values
  variable ret = struct {
    center = get_par(mffG + ".center")-dx-.5*mean(make_hi_grid(x)-x),
    sigma = get_par(mffG + ".sigma"),
    area = get_par(mffG + ".area"),
    offset = get_par(mffC + ".factor"),
    chisqr = stat.statistic / (stat.num_bins - stat.num_variable_params)
  };
  % eventually plot
  if (qualifier_exists("plot")) plot(x,y);
  if (qualifier_exists("oplot") || qualifier_exists("plot"))
  {
    variable model = get_model_counts(id);
    oplot(model.bin_lo-dx,model.value);
  }

   if (not qualifier_exists("keep")){ 
      % delete data and restore previous options
      delete_data(id);
      fit_fun(ff);
      set_fit_method(fm);
      thaw(freep);
   }

  return ret;
}
