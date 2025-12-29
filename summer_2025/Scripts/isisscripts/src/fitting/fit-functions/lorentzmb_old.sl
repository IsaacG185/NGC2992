%%%%%%%%%%%%%%%%%%%%%%%%
define lorentzmb_old_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{lorentzmb_old (fit-function)}
%\synopsis{implements a Lorentzian profile}
%\description
%    \code{L(f)  =  1/pi * [2 R^2 Q f0] / [f0^2 + 4 Q^2 (f-f0)^2]}\n
%    [Eq. (1) in Pottschmidt et al. (2003), A&A 407, 1039-1058]\n
%    where:\n
%    \code{ R } = normalization constant\n
%    \code{ Q } = quality factor\n
%    \code{ f0} = resonance frequency = \code{nu0/sqrt(1 + 1/[4 Q^2])}\n
%    \code{nu0} = peak frequency (maximum of \code{f * L(f)})
%
%    The parameters of the lorentzmb fit-function are
%    "norm" (= \code{R}), "peakfr" (= \code{nu0}) and "quality" (= \code{Q}).
%
%    The integrated fit-function is:\n
%    \code{int L(f) df  =  R^2/pi * arctan{2Q/pi*(f/f0-1)}}
%!%-
{
   variable R  = par[0];
   variable Q  = par[2];
   variable f0 = par[1]/sqrt(1+0.25/Q^2);
   return R^2/PI * ( atan(2.0*Q*(bin_hi/f0-1)) - atan(2.0*Q*(bin_lo/f0-1)) );
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define lorentzmb_old_default(i)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return (0   , 0   , 0   , 1   ); }
  { case 1: return (1   , 0   , 1e-5, 1e+3); }
  { case 2: return (0.5 , 0   , 0   , 10  ); }
}

add_slang_function("lorentzmb_old", ["norm", "peakfr [Hz]", "quality"]);
set_param_default_hook("lorentzmb_old", &lorentzmb_old_default);
