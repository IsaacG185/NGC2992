%%%%%%%%%%%%%%%%%%%%%%%%
define energyflux()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{energyflux}
%\synopsis{evaluates the energy flux of the current fit model in a given energy range}
%\usage{Double_Type energyflux(Double_Type Emin, Emax)}
%\qualifiers{
%\qualifier{factor}{[=\code{1.001}] step size of the logarithmic energy grid}
%\qualifier{Emin}{minimum energy of (extended) grid}
%\qualifier{Emax}{maximum energy of (extended) grid}
%\qualifier{cgs}{return flux in erg/cm^2/s}
%}
%\description
%    This function calculates the energy flux of the current best fit model
%    in keV/cm^2/s by integrating over the model on a logarithmic energy grid. 
%    The logarithmic step size of the model is given by the \code{factor}
%    qualifier.
%    
%    In other words, energyflux returns\n
%      \code{int_{Emin}^{Emax} E * S_E(E) dE}  (in keV/s/cm^2)
%    where \code{S_E(E)} (in 1/s/cm^2/keV) is defined by \code{fit_fun}.
%    
%    If the fit-function is a convolution model, e.g., Compton reflection,
%    it may be necessary to use an extended grid defined by the \code{Emin} 
%    and \code{Emax} qualifiers.
%
%    Note: While physicists generally use the term ``flux density'' for 
%    the quantity returned by this function, with the exception of radio
%    astronomy astronomers generally call the returned value the ``flux''.
%    The change in function name is based on the experience that most
%    users of isisscripts did not recognize that this function is what
%    they required.
%
%\seealso{eval_fun, eval_fun_keV, luminosity}
%!%-
{
  variable Emin, Emax;
  switch(_NARGS)
  { case 2:  (Emin, Emax) = (); }
  { help(_function_name()); return; }

  variable Elo = qualifier("Emin", Emin);
  variable Ehi = qualifier("Emax", Emax);
  if(Elo > Emin) { 
    vmessage("warning (%s): extending grid from Emin = %S keV to Emin = %S keV", _function_name(), Elo, Emin);
    Elo = Emin;
  }
  if(Ehi < Emax) { 
    vmessage("warning (%s): extending grid from Emax = %S keV to Emax = %S keV", _function_name(), Ehi, Emax);
    Ehi = Emax;
  }
  variable default_factor = 1.001;
  variable factor = qualifier("factor", default_factor);
  if(factor<=1) { 
    vmessage("warning (%s): factor = %S <= 1 is not allowed, using factor = %S", _function_name(), factor, default_factor);
    factor = default_factor;
  }
  variable n = int( log(double(Ehi)/Elo)/log(factor) +1 );
  (Elo, Ehi) = log_grid(Elo, Ehi, n);
  variable photons_s_cm2 = eval_fun_keV(Elo, Ehi);
  variable keV_s_cm2 = photons_s_cm2 * .5*(Elo+Ehi);
  variable totflux=sum( keV_s_cm2[where(Emin <= Elo and Ehi <= Emax)] );

  if (qualifier_exists("cgs")) {
      totflux=totflux*1.60217646e-9;   % keV -> erg
  }
  return totflux;
}
