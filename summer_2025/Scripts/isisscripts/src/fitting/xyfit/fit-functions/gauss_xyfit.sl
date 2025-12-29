%%%%%%%%%%%%%%%%%%
define gauss_xyfit()
%%%%%%%%%%%%%%%%%%
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["center [center]", "area [area]", "sigma [sigma]"];} % fit parameters
  { case 3: (xref, yref, par) = (); }
  { return help(_function_name); }

  @yref = par[1] / (2*PI*sqrt(par[2])) * exp ( -0.5* ( (@xref - par[0])/par[2] )^2 );
}

define gauss_xyfit_default(i)
{
  switch(i)
  { case 0: return (1   , 0, -1e5  , 1e5); }
  { case 1: return (1   , 0, -1e5  , 1e5); }
  { case 2: return (0.01, 0,  1e-10, 1e5); }
}
