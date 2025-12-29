define linear_regression()
%!%+
%\function{linear_regression}
%\synopsis{computes a linear regression fit}
%\usage{Struct_Type = linear_regression(Double_Type[] x, y[, err]);}
%\description
%    \code{err} is the uncertainty of the \code{y} values.
%    If \code{err} is not specified, all data points are weighted equally.
%
%    The parameters \code{a} and \code{b} of the best fit \code{y = a + b*x}
%    are   \code{a = (Sy*Sxx - Sx*Sxy)/D}\n
%      and \code{b = (S *Sxy - Sx*Sy )/D}\n
%    where \code{S  = sum(1/err^2)}\n
%          \code{Sx = sum(x/err^2)},  \code{Sxx = sum(x*x/err^2)}\n
%          \code{Sy = sum(y/err^2)},  \code{Sxy = sum(x*y/err^2)}\n
%      and \code{D = S*Sxx - Sx^2}.
%
%    The returned structure contains the fields \code{a} and \code{b},
%    and the errors \code{da} and \code{db}, respectively,
%    as well as the reduced chi square \code{chisq} of the fit.
%\seealso{linear_fit_xerr_yerr_data}
%!%-
{
  variable x, y, err;
  switch(_NARGS)
  { case 2: (x, y) = (); err = Integer_Type[length(y)] + 1; }
  { case 3: (x, y, err) = (); }
  { return help(_function_name()); }

  variable err2 = sqr(err);
  variable S   = sum( 1 /err2);
  variable Sx  = sum( x /err2);
  variable Sy  = sum( y /err2);
  variable Sxx = sum(x*x/err2);
  variable Sxy = sum(x*y/err2);

  variable D = S*Sxx - Sx^2;
  variable a = (Sy*Sxx-Sx*Sxy)/D;
  variable b = (S*Sxy-Sx*Sy)/D;
  return struct {
    a  = a,
    b  = b,
    da = sqrt(Sxx/D),
    db = sqrt(S/D),
    chisq = sumsq((a+b*x-y)/err) / (length(x)-2)  % <- should rather be called chisq_red or red_chi2
  };
}
