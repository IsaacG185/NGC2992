%%%%%%%%%%%%%%%%%%%%
define lorentzmb_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{lorentzmb (fit-function)}
%\synopsis{implements a Lorentzian profile}
%\description
%    \code{L(f)  =  [2 rms^2 Q f0]/[pi/2 + atan(2*Q)] * 1/[f0^2 + 4 Q^2 (f-f0)^2]}\n
%    [see also Eq. (1) in Pottschmidt et al. (2003), A&A 407, 1039-1058]\n
%    where:\n
%    \code{rms} = contribution to the root mean square variability\n
%    \code{ Q } = quality factor\n
%    \code{ f0} = resonance frequency = \code{nu0/sqrt(1 + 1/[4 Q^2])}\n
%    \code{nu0} = peak frequency (maximum of \code{f * L(f)})
%
%    The parameters of the lorentzmb fit-function are
%    "rms" (= \code{rms}), "peakfr" (= \code{nu0}) and "quality" (= \code{Q}).
%
%    The integrated fit-function is:\n
%    \code{int L(f) df  =  rms^2/[pi/2 + atan(2*Q)] * arctan{2Q/pi*(f/f0-1)}}
%!%-
{
   variable rms = par[0];
   variable f = par[1]/sqrt(1.0+1/(4*par[2]^2));
   variable q = par[2];
   return rms^2/(0.5*PI + atan(2*q)) * ( atan( 2.0*q/f*(-bin_lo+f)) - atan( 2.0*q/f*(-bin_hi+f) ) );
}

%%%%%%%%%%%%%%%%%%%%%%%%
define lorentzmb_default(i)
%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return (0   , 0   , 0   , 1   ); }
  { case 1: return (1   , 0   , 1e-5, 1e+3); }
  { case 2: return (0.5 , 0   , 0   , 10  ); }
}

add_slang_function("lorentzmb", ["rms", "peakfr [Hz]", "quality"]);
set_param_default_hook("lorentzmb", &lorentzmb_default);
