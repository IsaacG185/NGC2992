%%%%%%%%%%%%%%%%%%%%
define wienhump_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{wienhump (fit-function)}
%\synopsis{describes a Wien hump}
%\description
%    Describes a Wien hump with peaks at 3kT.
%\seealso{bbody}
%!%-
{
  variable norm = par[0];
  variable tempAng=_A(par[1]);
  
  return norm*(((2*bin_hi^2+2*tempAng*bin_hi+tempAng^2)*exp(-tempAng/bin_hi))/(tempAng^3*bin_hi^2)-((2*bin_lo^2+2*tempAng*bin_lo+tempAng^2)*exp(-tempAng/bin_lo))/(tempAng^3*bin_lo^2));
}

add_slang_function("wienhump", ["norm", "kT [keV]"]);


%%%%%%%%%%%%%%%%%%%%%%%%%
define wienhump_default(i)
%%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return ( 1, 0,  0, 1e10); }
  { case 1: return ( 1, 0, 1e-2,  1e2); }
}

set_param_default_hook("wienhump", &wienhump_default);
