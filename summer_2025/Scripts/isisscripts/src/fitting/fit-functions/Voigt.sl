%%%%%%%%%%%%%%%%
define Voigt_fit(lo, hi, par)
%%%%%%%%%%%%%%%%
%!%+
%\function{Voigt (fit-function)}
%\synopsis{implements the bare convolution of a Gaussian and a Lorentzian}
%\description
%    The \code{Voigt} fit-function uses the bare parameters of the
%    convolved Gaussian and Lorentzian profiles G and L:
%
%    \code{G(x; sigma) = 1/[sqrt(2 pi)*sigma] * exp(-(x/sigma)^2/2)}\n
%    \code{L(x; gamma) = gamma/pi * 1 / [x^2 + gamma^2]}\n
%    \code{V(x; sigma, gamma) = int dt G(t; sigma) * L(x-t; gamma)}
%
%    Unlike ISIS' internal \code{voigt} fit-function,
%    which implements a Voigt profile in astrophysical context
%    associating enerigies with \code{x} in the above formula,
%    \code{Voigt} uses \code{x} in wavelength units or any unit
%    associated with the "spectrum" through \code{define_counts}.
%\seealso{voigt, voigt_profile}
%!%-
{
  variable norm   = par[0];
  variable center = par[1];
  variable sigma  = par[2];
  variable gamma  = par[3];

  variable IVIN = Isis_Voigt_Is_Normalized;
  Isis_Voigt_Is_Normalized = 1;
%   variable dx = 1-_min(min(lo), center);
%   center += dx;
%   variable y = reverse(eval_fun2("voigt", _A(lo+dx, hi+dx), [N, center, 4*PI*gamma, sqrt(2)*Const_c/1e5*sigma/center]));
   variable y = reverse(eval_fun2("voigt", _A(lo, hi), [norm, center, 4*PI*gamma, sqrt(2)*Const_c/1e5*sigma/center]));
  Isis_Voigt_Is_Normalized = IVIN;
  return y;
}
add_slang_function("Voigt", ["norm", "center", "sigma", "gamma"], [0]);

        %%%%%%%%%%%%%%%%%%%%%
private define Voigt_defaults(i)
        %%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: struct {value=1, freeze=0, min=0,    max=10, hard_min=-_Inf, hard_max=_Inf, step=0, relstep=1e-4}; } % norm
  { case 1: struct {value=1, freeze=0, min=0,    max=10, hard_min=-_Inf, hard_max=_Inf, step=0, relstep=1e-4}; } % center
  { case 2: struct {value=1, freeze=0, min=1e-3, max=10, hard_min=1e-38, hard_max=_Inf, step=0, relstep=1e-4}; } % sigma
  { case 3: struct {value=1, freeze=0, min=0,    max=10, hard_min=0,     hard_max=_Inf, step=0, relstep=1e-4}; } % gamma
}

set_param_default_hook("Voigt", &Voigt_defaults);
