define simput_athenacrab(flux){   
%!%+
%\function{simput_athenacrab}
%\synopsis{returns command to create a standard Athena Crab Simput File}
%\usage{String_Type cmd = simput_athenacrab(Double_Type flux);}
%\description
%    Flux has to be given in Crab. The naming convention is that the
%    flux (in micro Crab = 1e-6 Crab or in erg/cm^2/s if unit=cgs) is
%    encoded in the filename. The spectrum has an absorption of 4E21
%    cm^-2, norm of 9.5 ph/kev/cm^2/s at 1keV, and powerlaw index of
%    2.1. The source position is RA=Dec=0.
%\qualifiers{
%\qualifier{unit}{crab or cgs, default: crab}
%\qualifier{dir}{To append a full directory path, default: cwd}
%\qualifier{logEgrid}{use a logarithmic energy grid (from Elow to
%            Eup with Nbins), default: no}
%\qualifier{Nbins}{number of energy bins created from Elow to Eup,
%            default: 1000}
%}
%!%-
  variable unit = qualifier("unit", "crab");

  variable crabnorm = 2.0521231034620645e-08; % To get a flux of 9.5ph/kev/cm^2/s at 1keV
  
  variable srcname, plFlux;
  if (unit == "cgs"){
    srcname = sprintf("athenacrab_flux%ecgs.simput", flux);
    plFlux = sprintf("plFlux=%e", flux);
  } else {
    srcname = sprintf("athenacrab_flux%07imuCrab.simput", nint(1e6*(flux)));
    plFlux = sprintf("plFlux=%e", flux*crabnorm);
  }
  srcname = qualifier("dir", "") + srcname;
  
  variable energy_string = sprintf("logEgrid=%s Nbins=%i", 
				   qualifier("logEgrid", "no"), qualifier("Nbins", 1000));

  variable simputcom = "simputfile " + 
    "simput=" + srcname + " RA=0.0 Dec=0.0 " + 
    "Emin=2. Emax=10. plPhoIndex=2.1 NH=0.4 " +
    energy_string + " " + plFlux + 
    " clobber=yes";
  
  return simputcom;
}
