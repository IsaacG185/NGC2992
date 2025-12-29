%%%%%%%%%%%%%%%%%
define luminosity()
%%%%%%%%%%%%%%%%%
%!%+
%\function{luminosity}
%\synopsis{computes a source luminosity assuming the current fit-function and a distance}
%\usage{Double_Type luminosity(Double_Type Emin, Emax, d);}
%\qualifiers{
%\qualifier{factor}{[=\code{1.001}] step of logarithmic energy grid}
%\qualifier{Emin}{minimum energy of (extended) grid}
%\qualifier{Emax}{maximum energy of (extended) grid}
%}
%\description
%    returns \code{4pi (d kpc)^2 * int_Emin^Emax E*S_E(E) dE}  (in erg/s)
%
%    Use flux2lum to calculate luminosities for extragalactic sources.
%
%\seealso{energyflux, flux2lum}
%!%-
{
  variable Emin, Emax, d;
  switch(_NARGS)
  { case 3: (Emin, Emax, d) = (); }
  { help(_function_name()); return; }

  return 4 * PI * (d*3.08568025e21)^2   % kpc -> cm
         * energyflux(Emin, Emax;; __qualifiers) * 1.60217646e-9;   % keV -> erg
}
