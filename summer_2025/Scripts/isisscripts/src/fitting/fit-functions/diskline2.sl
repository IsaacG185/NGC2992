require("xspec");


%%%%%%%%%%%%%%%%%%%%
define diskline2_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{diskline2}
%\synopsis{describes a line emission from a relativistic accretion disk}
%\description
%    norm    = photons/cm**2/s in the spectrum\n
%    LineE   = line energy\n
%    Betor10 = power law dependence of emissivity.
%              If this parameter is 10 or greater then the accretion
%              disk emissivity law (1-sqrt(6/R))/R**3 is used.
%              Otherwise the emissivity scales as R**par2.\n
%    Rin     = inner radius (units of GM/c**2)\n
%    Rout    = outer radius (units of GM/c**2)\n
%    Incl    = inclination (degrees)\n
%    (The original diskline model uses Rin(M) and Rout(M).)
%\seealso{diskline / Fabian et al., MNRAS 238, 729.}
%!%-
{
  return diskline_fit(bin_lo, bin_hi, par);
}

add_slang_function("diskline2", ["norm", "LineE [keV]", "Betor10", "Rin", "Rout", "Incl [deg]"]);
