require( "gsl","gsl" ); 

%%%%%%%%%%%%%%%%%%%%
define kendall_tau_censored()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{kendall_tau_censored}
%\synopsis{calculation of Kendall rank correlation coefficient}
%\usage{Struct_Type cc = kendall_tau(Double_Type x[], Double_Type y[]);}
%\altusage{Struct_Type cc = kendall_tau(Double_Type x[], Double_Type y[], Char_Type y_is_upper_limit[]);}
%\altusage{Struct_Type cc = kendall_tau(Double_Type x[], Char_Type x_is_upper_limit[], Double_Type y[], Char_Type y_is_upper_limit[]);}
%\description
%    This function calculates the Kendall rank correlation coefficient \code{tau},
%    as defined by M. G. Kendall (1938, Biometrika, 30, 81), between two
%    arrays of equal length.
%    The result \code{tau} is within the interval [-1,1], where 1 means a perfect
%    agreement between both rankings, -1 means perfect disagreement, and values
%    around 0 indicate that both arrays are independent.
%    The value of \code{tau} is the difference of concordant and discordant pairs
%    divided by the total number of pairs.
%    In the definition of Helser (Dennis R. Helsel, "Nondetects and Data Analysis",
%    Wiley, 2005) only the number of determined (valid) pairs is used instead of
%    the total number. The structure returned by this function includes the values
%    of \code{tau}, \code{sigma}, and \code{pval} in both ways.
%
%    The value \code{sigma} characterizes the expected width of the distribution of \code{tau}
%    for random data. (If the "gsl" module is not available, the p-value is not calculated.
%    It can be obtained from \code{tau} and \code{sigma}.)
%
%    See statistic module for further functions: require("stats");
%\examples
%    variable x = [1:2:#100];
%    variable y = grand(100)+x;
%    variable cc_no_limits   = kendall_tau_censored(x,y);
%    variable cc_incl_limits = kendall_tau_censored(x,y,nint(urand(100)));
%\seealso{kendall_tau, pearson_r, spearman_r, spearmanrho, correlation_coefficient}
%!%-
{
  variable x, x_is_lim, y, y_is_lim;
  variable i,j;
  variable n;
  variable tau = 0;

  variable nondet_x = 0;
  variable nondet_y = 0;

  switch(_NARGS)
  { case 2: (x,y) = ();
    n = length(x);
    _for i (1,n-1,1)
      _for j (0,i-1,1)
      {
	tau += sign(x[i] - x[j]) * sign(y[i] - y[j]);
	if ((x[i] == x[j])) nondet_x +=1;
	if ((y[i] == y[j])) nondet_y +=1;
      }
  }
  { case 3: (x, y, y_is_lim) = ();
    n = length(x);
    _for i (1,n-1,1)
      _for j (0,i-1,1)
      {
	tau +=   sign(x[i] - x[j]) * ( (y_is_lim[i] ? 0 : 1)*(y[j] < y[i] ? 1 : 0) - (y_is_lim[j] ? 0 : 1)*(y[i] < y[j] ? 1 : 0) );
	if ((x[i] == x[j])) nondet_x +=1;
	if ((y[i] == y[j]) or (y_is_lim[i] and y[i]>y[j]) or (y_is_lim[j] and y[j]>y[i])) nondet_y +=1;
      }
  }
  { case 4: (x, x_is_lim, y, y_is_lim) = ();
    n = length(x);
    _for i (1,n-1,1)
      _for j (0,i-1,1)
      {
	tau += ( (x_is_lim[i] ? 0 : 1)*(x[j] < x[i] ? 1 : 0) - (x_is_lim[j] ? 0 : 1)*(x[i] < x[j] ? 1 : 0)) *
	  ( (y_is_lim[i] ? 0 : 1)*(y[j] < y[i] ? 1 : 0) - (y_is_lim[j] ? 0 : 1)*(y[i] < y[j] ? 1 : 0) );
	if ((x[i] == x[j]) or (x_is_lim[i] and x[i]>x[j]) or (x_is_lim[j] and x[j]>x[i])) nondet_x +=1;
	if ((y[i] == y[j]) or (y_is_lim[i] and y[i]>y[j]) or (y_is_lim[j] and y[j]>y[i])) nondet_y +=1;
      }
  }
  { help(_function_name()); return; }

  variable ktau = tau/ (0.5*n*(n-1));
  variable sigma = sqrt( (4*n+10) / (9.0*n*(n-1)) );

  variable nr_valid_pairs = sqrt( (0.5*n*(n-1) - nondet_x) * (0.5*n*(n-1) - nondet_y) );
  variable htau = tau/ nr_valid_pairs;
  variable n_red = 0.5*(1+sqrt(1+8*nr_valid_pairs));
  variable hsigma = sqrt( (4*n_red+10) / (9.0*n_red*(n_red-1)) );
  
  variable pval  = gsl-> erfc (sqrt(2)* abs(ktau/sigma) *0.5);
  variable hpval = gsl-> erfc (sqrt(2)* abs(htau/hsigma) *0.5);

  return struct {
    kendall_tau   = ktau,
    kendall_sigma = sigma,
    kendall_pval  = pval,
    helser_tau    = htau,
    helser_sigma  = hsigma,
    helser_pval   = hpval
  };
}