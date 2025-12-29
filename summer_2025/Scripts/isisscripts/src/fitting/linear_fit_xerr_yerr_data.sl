%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define linear_fit_xerr_yerr_data()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{linear_fit_xerr_yerr_data}
%\synopsis{fits a linear function to data points with both x- and y-errors}
%\usage{(Double_Type a, b) = linear_fit_xerr_yerr_data(Double_Type X[], Xerr[], Y[], Yerr[][, Double_Type b0]);
%\altusage{(Double_Type a, aerr, b, berr) = linear_fit_xerr_yerr_data(Double_Type X[], Xerr[], Y[], Yerr[][, Double_Type b0]; with_errors);}
%}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{n}{number of iterations}
%\qualifier{with_errors}{The 90% confidence interval (Delta chi^2 = 2.7) is computed as well.}
%}
%\description
%    The data points \code{(X[i]+-Xerr[i], Y[i]+-Yerr[i])}
%    are iteratively fitted with the linear function \code{y = a + b*x}.
%    If no initial value for the slope b is specified,
%       \code{b0 = s * [max(Y)-min(Y)]/[max(X)-min(X)]}
%    is used.
%    The best fit is found iteratively after the algorithm
%    by Fasano & Vio (1988), BICDS 35, p.191.
%\seealso{linear_regression}
%!%-
{
  variable X, Xerr, Y, Yerr, a, b;

  switch(_NARGS)
  { case 4: (X, Xerr, Y, Yerr   ) = (); b = (max(Y)-min(Y))/(max(X)-min(X)); }
  { case 5: (X, Xerr, Y, Yerr, b) = (); }
  { help(_function_name()); return; }

  variable i, W, avX, avY, alpha, beta, gamma;
  if(qualifier_exists("verbose"))  vmessage("b=%g", b);
  for(i=0; i<qualifier("n", 20); i++)
  {
    W = 1/(b^2*Xerr^2 + Yerr^2);
    avX = weighted_mean(X, W);
    avY = weighted_mean(Y, W);
    a = avY - b * avX;
    alpha = sum( W^2 *  Xerr^2 * (Y-avY) * (X-avX) );
    beta  = sum( W^2 * (Yerr^2 * (X-avX)^2 - Xerr^2 * (Y-avY)^2) );
    gamma = sum( W^2 *  Yerr^2 * (Y-avY) * (X-avX) );
    b = (-beta + sqrt(beta^2+4*alpha*gamma))/(2*alpha);
    if(qualifier_exists("verbose"))  vmessage("a=%g, b=%g", a, b);
  }

  if(qualifier_exists("with_errors"))
  {
    variable deltaChi2 = 2.7055;
    variable delta_a = sqrt(deltaChi2 / sum( W ) );
    variable delta_b = sqrt(deltaChi2 / sum( ( X^2*Yerr^4 + 3*b^2*Xerr^4*Y^2 + 3*b^2*Xerr^4*a^2 - Xerr^2*Y^2*Yerr^2 - Xerr^2*a^2*Yerr^2 - 3*X^2*b^2*Xerr^2*Yerr^2
					      -2*X*b^3*Xerr^4*Y + 2*X*b^3*Xerr^4*a - 6*b^2*Xerr^4*Y*a + 2*Xerr^2*Y*a*Yerr^2 + 6*X*b*Xerr^2*Y*Yerr^2 - 6*X*b*Xerr^2*a*Yerr^2
					     )/(b^2*Xerr^2+Yerr^2)^3 ) );
    return (a, delta_a, b, delta_b);
  }
  else
    return (a, b);
}
