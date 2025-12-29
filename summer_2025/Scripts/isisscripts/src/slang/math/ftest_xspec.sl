require( "gsl", "gsl" );

%%%%%%%%%%%%%%%%%%
define ftest_xspec()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{ftest_xspec}
%\synopsis{calculates the F-test probability as in xspec}
%\usage{Double_Type ftest_xspec(chisq2, dof2, chisq1, dof1)}
%\description
%    The new chi-square and DOF, chisq2 and dof2,
%    should come from adding an extra model component
%    to (or thawing a frozen parameter of)
%    the model which gave chisq1 and dof1.
%    If the F-test probability is low then it is
%    reasonable to add the extra model component.
%
%    WARNING: It is not correct to use the F-test statistic
%    to test for the presence of a line
%    (see Protassov et al astro-ph/0201457).
%!%-
{
  variable chi2, dof2, chi1, dof1;
  switch(_NARGS)
  { case 4: (chi2, dof2, chi1, dof1) = (); }
  { return help(_function_name()); }

  if (chi2 > chi1) {
    vmessage("warning %s: Fit did not improve! chi2 should be smaller than chi1!",_function_name());
    return -_NaN;}
  if (dof2 > dof1) {
    vmessage("warning %s: DOF increased! dof2 should be less than dof1!",_function_name());
    return -_NaN;}
  return gsl->beta_inc(dof2/2., (dof1-dof2)/2., chi2*1./chi1);
}

