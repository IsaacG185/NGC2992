#ifeval _isis_version < 20000

%%%%%%%%%%%%%%%%%%%%%
define voigt_profile()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{voigt_profile}
%\synopsis{computes a normalized Voigt profile}
%\usage{Double_Type voigt_profile(Double_Type x, [[N,] x0,] sigma, gamma)}
%\description
%    The Voigt profile V is the convolution
%    of a Gaussian profile (with width \code{sigma>0})\n
%       \code{G(x; sigma)  =  exp{-x^2/(2 sigma^2)} / [sqrt(2 pi) sigma]}\n
%    and a Lorentzian profile (with width gamma>0)\n
%       \code{L(x; gamma)  =  gamma/pi / (x^2 + gamma^2)}\n
%    i.e.:\n
%       \code{V(x; sigma, gamma)  =  int G(t; sigma) * L(x-t; gamma) dt}
%
%    The \code{voigt_profile} function computes\n
%       \code{N * V(x-x0; sigma, gamma)}\n
%    i.e., \code{x0} is the center of the Voigt profile (default: 0)
%    and \code{N} is its normalization (default: 1), i.e.\n
%       \code{int voigt_profile(x, N, x0, sigma, gamma) dx  =  N} .
%
%    Do not confuse this "Voigt profile" with the "Voigt function H(a, u)".
%\seealso{voigt, get_cfun2}
%!%-
{
  variable x, N=1, x0=NULL, sigma, gamma;
  switch(_NARGS)
  { case 3: (x,        sigma, gamma) = (); }
  { case 4: (x,    x0, sigma, gamma) = (); }
  { case 5: (x, N, x0, sigma, gamma) = (); }
  { help(_function_name()); return; }
  if(x0==NULL)  x0 = 0;

  variable IVIN = Isis_Voigt_Is_Normalized;
  Isis_Voigt_Is_Normalized = 1;
   variable dx = 1-_min(min(x), x0);
   x0 += dx;
   variable y = get_cfun2("voigt", Const_keV_A/(x+dx), [N, x0, 4*PI*gamma, sqrt(2)*Const_c/1e5*sigma/x0]);
  Isis_Voigt_Is_Normalized = IVIN;
  return y;
}

#endif
