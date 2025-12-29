% These are approximations for the lower and upper confidence bounds derived
% for a Poisson distribution with n counts and a confidence limit S as
% calculated by Gehrels 1986
private define gehrels_error_upper_7(n, S) {
  return n + S * sqrt(n + 3./4.) + (S^2 + 3.)/4.;
}

private define gehrels_error_upper_9(n, S) {
  return (n + 1.) * ( 1. - 1. / (9. * (n+1.)) + S / ( 3. * sqrt(n+1.)) ) ^3;
}

private define gehrels_error_upper_10(n, S) {
  return n + S * sqrt(n+1.) + (S^2 + 2.)/3.;
}

private define gehrels_error_lower_11(n, S) {
  return n - S * sqrt(n - 1./4.) + (S^2 - 1.)/4.;
}

private define gehrels_error_lower_12(n, S) {
  return n * ( 1. - 1./(9. * n) - S/(3 * sqrt(n)))^3;
}

private define gehrels_error_lower_13(n, S) {
  return n - S * sqrt(n) + (S^2 - 1.)/3.;
}

private define gehrels_error_lower_14(n, S, beta, gamma) {
  return n * ( 1 - 1./(9*n) - S/(3 * sqrt(n)) + beta * n^gamma)^3;
}

private define __calc_gehrels_beta(CL) {
  return -3.3002e-04 / (0.23377524 * (CL-1.00474780)) + 0.00198147;
}

private define __calc_gehrels_gamma(CL) {
  return -0.72681571 / (5.81655865*(CL-0.85566045)) -5.7704e-05 / (0.10719164*(CL-1.00160824)) -1.18709242;
}

private define __CL_to_S(CL) {
  return sqrt(2) * erfinv(2 * CL - 1);
}


%!%+
%\function{gehrels_upper_confidence}
%\synopsis{Calculate upper confidence bounds according to Gehrels, 1986}
%\usage{Double_Type gehrels_upper_confidence(Double_Type n, Double_Type CL);}
%\description
%    Estimate the upper bound of the confidence interval given by the level
%    CL and the number of counts n.
%    It uses equation 9 in Gehrels, 1986.
%    Please note that the confidence level must be in [0.8413,0.9995].
%\seealso{gehrels_lower_confidence, gehrels_confidence}
%!%-
define gehrels_upper_confidence(n, CL) {
  if ( CL < 0.8413 || CL > 0.9995 ) {
    throw UsageError, "CL must be in [0.8413,0.9995]";
  }
  variable S = __CL_to_S(CL);
  return gehrels_error_upper_9(n, S);
}


%!%+
%\function{gehrels_lower_confidence}
%\synopsis{Calculate lower confidence bounds according to Gehrels, 1986}
%\usage{Double_Type gehrels_lower_confidence(Double_Type n, Double_Type CL);}
%\description
%    Estimate the lower bound of the confidence interval given by the level
%    CL and the number of counts n.
%    It uses equation 14 in Gehrels, 1986.
%    Please note that the confidence level must be in [0.8413,0.9995].
%    The values for beta and gamma necessary for the calculation are
%    interpolated using a single parametric powerlaw for beta and a double
%    parametric powerlaw for gamma which was fitted to the data given in
%    table 3 of Gehrels, 1986.
%    Reading the source code is encounraged.
%\seealso{gehrels_lower_confidence, gehrels_confidence}
%!%-
define gehrels_lower_confidence(n, CL) {
  if ( CL < 0.8413 || CL > 0.9995 ) {
    throw UsageError, "CL must be in [0.8413,0.9995]";
  }
  variable S = __CL_to_S(CL);
  variable beta, gamma;
  if ( S == 1.0 ) {
    beta = 0.0;
    gamma = 0.0;
  } else {
    beta = __calc_gehrels_beta(CL);
    gamma = __calc_gehrels_gamma(CL);
  }
  if ( CL <= 0.85566045 ) {
    beta = 0.0;
  }
  return gehrels_error_lower_14(n, S, beta, gamma);
}

%!%+
%\function{gehrels_confidence}
%\synopsis{Calculate lower and upper confidence bounds according to Gehrels, 1986}
%\usage{Double_Type[2] conf = gehrels_confidence(Integer_Type n, Double_Type CL);}
%\description
%    Estimate the lower and upper bounds of the confidence interval given by
%    the level CL and the number of counts n using
%    \code{gehrels_lower_confidence} and \code{gehrles_upper_confidence}.
%    Please also read the documentation of these two functions.
%    The first entry in the retured array is the lower bound, the second one
%    the upper bound.
%\seealso{gehrels_lower_confidence, gehrles_upper_confidence}
%!%-
define gehrels_confidence(n, CL) {
  variable ret = Double_Type[2];
  ret[0] = gehrels_lower_confidence(n, CL);
  ret[1] = gehrels_upper_confidence(n, CL);
  return ret;
}

%!%+
%\function{gehrels_error}
%\synopsis{Calculate lower and upper error according to Gehrels, 1986}
%\usage{Double_Type[2] err = gehrels_error(Integer_Type n, Double_Type CL);}
%\description
%    Same as \code{gehrels_confidence} but returns the errors instead.
%\seealso{gehrels_lower_confidence, gehrles_upper_confidence}
%!%-
define gehrels_error(n, CL) {
  variable ret = gehrels_confidence(n, CL);
  ret[0] = n - ret[0];
  ret[1] = ret[1] - n;
  return ret;
}
