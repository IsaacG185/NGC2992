define lorentz_xyfit()
%!%+
%\function{lorentz_xyfit}
%\synopsis{Lorentzian xy fit function to be used with xyfit_fun}
%\usage{xyfit_fun ("lorentz");}
%\description
%    Calling \code{xyfit_fun ("lorentz");} sets up a Lorentzian fit
%    function for xy-data. It has the form 
%    \code{y = norm * sigma/(2pi) * 1/((x-center)^2 + (sigma/2)^2)}
%\example
%    variable id = define_xydata(x, y, yerr);
%    xyfit_fun("lorentz");
%    () = fit_counts;
%    variable xfit, yfit;
%    (xfit, yfit) = eval_xyfun([min(x) : max(x) : #1000]);
%    plot(xfit, yfit);
%\seealso{xyfit_fun, define_xydata, plot_xyfit, linear_regression}
%!%-
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["norm", "center [center]", "sigma [sigma]"];} % fit parameters
  { case 3: (xref, yref, par) = (); }
  { return help(_function_name); }

  @yref = par[0] * par[2]/(2*PI) * 1./((@xref - par[1])^2 + (par[2]/2.)^2);
}

define lorentz_xyfit_default(i)
{
  switch(i)
  { case 0: return (0.01, 0, -1e10 , 1e10); }
  { case 1: return (0   , 0,     0 , 1e5); }
  { case 2: return (1   , 0,  1e-6 , 1e6); }
}
