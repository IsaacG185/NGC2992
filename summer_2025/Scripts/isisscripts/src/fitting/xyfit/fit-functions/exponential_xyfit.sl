%%%%%%%%%%%%%%%%%%%%%%%%%%%
define exponential_xyfit()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{exponential_xyfit}
%\synopsis{linear xy fit function to be used with xyfit_fun}
%\usage{xyfit_fun ("exponential");}
%\description
%    This function is not meant to be called directly!
%    
%    Calling \code{xyfit_fun ("exponential");} sets up a powerlaw fit
%    function for xy-data. It has the form \code{y = norm*x^{-index}}
%\seealso{xyfit_fun, define_xydata, plot_xyfit, linear_regression}
%!%-
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["norm", "y0", "roll"]; } % fit parameters
  { case 3: (xref, yref, par)=(); }
  { return help(_function_name); }

  @yref = par[0] * (exp((@xref/par[2])) - 1 ) + par[1] ;
}

define exponential_xyfit_default(i)
{
  switch(i)
  { case 0: return (1, 0, -1e5, 1e5); }
  { case 1: return (0, 0, -1e5, 1e5); }
  { case 2: return (1, 0, -1e5, 1e5); }
}
