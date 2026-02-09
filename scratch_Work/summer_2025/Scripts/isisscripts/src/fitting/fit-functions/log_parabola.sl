require("gsl","gsl"); 

%!%+
%\function{log_par}
%\synopsis{log-log parabolic fit function}
%\description
%    Fit function of the form F(x)= exp ( a*(log(x) - center)^2 + peak );
%    For fitting the function is implemented in integrated from.
%    \code{center} has to be specified in the unit in which the bins are given.
%    The function is a parabola in the log-log space of the unit of the bins.
%    Currently the function only works for negative curvature \code{a<0}.
%
%    For a log-parabola in the energy/frequency regime the function \code{log_par_en}
%    has to be used.
%    
%\seealso{log_par_en}
%!%-

define log_par_fit (lo, hi, par)
{
  variable t = par[0];
  variable s = par[1];
  variable a = par[2];

  if (a == 0) return t*(hi-lo);
  s = log(s);
  t = log(t);
  
  variable L = log(lo);
  variable H = log(hi);

  variable inv_sqrt_a = 1./sqrt(abs(a));
  variable b = 1.-2*a*s;
  if (a < 0)
  {
    return exp(t+a*s^2 - 0.25* (b^2)/a )*0.5*(sqrt(PI)* (gsl->erf(0.5* (2*a*L+b)*inv_sqrt_a)-
							       gsl->erf(0.5* (2*a*H+b)*inv_sqrt_a)))*inv_sqrt_a;
  }
  if (a > 0)
  {
    message("a>0 does not work yet (complex error function required, Faddeeva function)");
    return -exp(t+a*s^2)*0.5*(sqrt(PI)* exp((-0.25* (b^2)/a))* (gsl->erf(0.5* (2*a*L+b)*inv_sqrt_a)-
							       gsl->erf(0.5* (2*a*H+b)*inv_sqrt_a)))*inv_sqrt_a;
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%
define log_par_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return    1, 0, 1e-30, 1e10; }
  { case 1: return    2, 0, 1e-10, 1e30; }
  { case 2: return   -1, 0,  -1e4,    0; }
}

add_slang_function("log_par", ["peak","center","curvature"], [0]);
set_param_default_hook("log_par", "log_par_defaults");



%!%+
%\function{log_par_en}
%\synopsis{log-log parabolic fit function in the energy/frequency regime}
%\description
%    Fit function of the form F(nu)= exp ( a*(log(nu) - center)^2 + peak );
%    For fitting the function is implemented in integrated from.
%    \code{center} has to be specified in Hz. The bins are expected to be
%    given in Angstrom (as it is typically the case in ISIS).
%    Currently the function only works for negative curvature \code{a<0}.
%    
%\seealso{log_par}
%!%-

define log_par_en_fit (bin_lo, bin_hi, par)
{
  variable s = par[1] * 4.135667516e-18;% convert s from Hz to keV (multiply with h = 4.135667516e-18 [keV * s] )
  return reverse( log_par_fit (_A(bin_hi) , _A(bin_lo) , [par[0], s, par[2]] ));
}

%%%%%%%%%%%%%%%%%%%%%%%%
define log_par_en_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return    1, 0, 1e-30, 1e10; }
  { case 1: return    1e18, 0, 1e-10, 1e30; }
  { case 2: return   -1, 0,  -1e4,    0; }
}

add_slang_function("log_par_en", ["peak [ph/cm^2/s^1/keV at center]","center [Hz]","curvature"], [0]);
set_param_default_hook("log_par_en", "log_par_en_defaults");

