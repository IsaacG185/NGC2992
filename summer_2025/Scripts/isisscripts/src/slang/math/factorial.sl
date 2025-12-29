require("gsl","gsl"); 

define factorial()
%!%+
%\function{factorial}
%\synopsis{calculates n!}
%\usage{Double_Type factorial(Integer_Type n);}
%\description
%    \code{n}!  \code{=  n * (n-1) * ... * 2 * 1}
%
%    Note that \code{n} is always converted to an integer (without rounding);
%    for fractional \code{n} use, e.g., the GSL module's Gamma function.
%\seealso{gsl->gamma}
%!%-
{
  variable n;
  switch(_NARGS)
  { case 1: n = int( () ); }
  { help(_function_name()); return; }

#ifexists gsl->gamma
  return gsl->gamma(n+1);
#else
  return prod([2:n]);
#endif

}
