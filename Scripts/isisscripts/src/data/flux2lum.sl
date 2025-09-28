%%%%%%%%%%%%%%%%
define flux2lum()
%%%%%%%%%%%%%%%%
%!%+
%\function{flux2lum}
%
%\synopsis{Calculates the source luminosity}
%\usage{Double_Type lum = flux2lum (Double_Type flux, Double_Type z);}
%\qualifiers{
%\qualifier{silent}{         If set, the program will not display adopted
%                       cosmological parameters at the terminal.}
%\qualifier{h0}{[=70] Hubble parameter in km/s/Mpc}
%\qualifier{omega_m}{[=0.3] Matter density, normalized to the closure density,
%                       default is 0.3. Must be non-negative.}
%\qualifier{omega_lambda}{[=0.7] Cosmological constant, normalized to the
%                       critical density.}
%\qualifier{omega_k}{[=0] curvature constant, normalized to the critical density.
%                       Default is 0, indicating a flat universe.}
%\qualifier{q0}{[=-0.55] Deceleration parameter, numeric scalar = -R*(R'')/(R')^2}
%}
%\description
%    This function calculates the luminosity of a source
%    given a \code{flux} in erg/s/cm^2 as well as a redshift \code{z} using
%    the cosmological parameters specified by the qualifiers
%    (which are passed to the function \code{cosmo_param}). The
%    distance is calculated with the function \code{lumdist}.
%    \code{Flux} and \code{z} can be scalars or vectors. Use
%    energyflux to calculate the flux.
%\example
%    variable flux=3e-13;
%    variable z=0.0705;
%    variable l = flux2lum(flux,z);
%\seealso{energyflux, cosmo_param, lumdist}
%!%-
{ 
  variable fl1 = NULL;
  variable redz = NULL;
  
  switch(_NARGS)
  { case 2: (fl1, redz) = ();}
  { help(_function_name()); return; }
  
  % 1. Get distance from Z
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable dist = lumdist (redz ;; __qualifiers); % in Mpc
  variable Mpc_in_cm = 3.08567758e24;
  dist *= Mpc_in_cm;
  
  % 2. Calculate Luminosity
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  variable lumi = fl1*4*PI*dist^2;
  return lumi;  
}