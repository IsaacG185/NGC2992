%%%%%%%%%%%%%%%%%%%%%%%%
define quadratic_xyfit()
%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["a [coefficient of x^2]", "b [coefficient of x]", "c [additive constant]"]; } % fit parameters
  { case 3: (xref, yref, par)=(); }
  { return help(_function_name); }

  @yref = par[0]*(@xref)^2 + par[1]*(@xref) + par[2];
}

define quadratic_xyfit_default(i)
{
  switch(i)
  { case 0: return (1, 0, -1e5, 1e5); } % coefficient of x^2
  { case 1: return (1, 0, -1e5, 1e5); } % coefficient of x
  { case 2: return (0, 0, -1e5, 1e5); } % additive constant
}
