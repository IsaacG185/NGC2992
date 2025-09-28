%%%%%%%%%%%%%%%%%%%%%%%%%%%
define linear_xyfit()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{linear_xyfit}
%\synopsis{linear xy fit function to be used with xyfit_fun}
%\usage{xyfit_fun ("linear");}
%\description
%    This function is not meant to be called directly!
%    
%    Calling \code{xyfit_fun ("linear");} sets up a linear fit
%    function for xy-data. It has the form \code{y = a*x + b},
%    where \code{a} and \code{b} are the two fit parameters.
%\seealso{xyfit_fun, define_xydata, plot_xyfit, linear_regression}
%!%-
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["a [coefficient of x]", "b [additive constant]"]; } % fit parameters
  { case 3: (xref, yref, par)=(); }
  { return help(_function_name); }

  @yref = par[0] * @xref + par[1];
}

define linear_xyfit_default(i)
{
  switch(i)
  { case 0: return (1, 0, -1e5, 1e5); }
  { case 1: return (0, 0, -1e5, 1e5); }
}
