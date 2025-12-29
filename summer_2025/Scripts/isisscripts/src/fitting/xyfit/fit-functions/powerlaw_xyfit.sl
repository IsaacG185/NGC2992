%%%%%%%%%%%%%%%%%%%%%%%%%%%
define powerlaw_xyfit()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{powerlaw_xyfit}
%\synopsis{linear xy fit function to be used with xyfit_fun}
%\usage{xyfit_fun ("powerlaw");}
%\description
%    This function is not meant to be called directly!
%    
%    Calling \code{xyfit_fun ("powerlaw");} sets up a powerlaw fit
%    function for xy-data. It has the form \code{y = norm*x^{-index}}
%\seealso{xyfit_fun, define_xydata, plot_xyfit, linear_regression}
%!%-
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["norm", "index"]; } % fit parameters
  { case 3: (xref, yref, par)=(); }
  { return help(_function_name); }

  @yref = par[0] * (@xref)^(-par[1]);
}

define powerlaw_xyfit_default(i)
{
  switch(i)
  { case 0: return (1, 0, -1e5, 1e5); }
  { case 1: return (2, 0, -1, 4); }
}
