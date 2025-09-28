define covariance_correlation_matrix() %{{{
%!%+
%\function{covariance_correlation_matrix}
%\synopsis{Compute the covariance and correlation matrices of a set of variables}
%\usage{(Double_Types cov_mat[n,n], cor_mat[n,n]) = covariance_correlation_matrix(Double_Type a[n,N])}
%\description
%    This function estimates the covariance and correlation matrices of a set of
%    random variables. Consider a sample 'a' of 'N' column vectors of length 'n':
%    a = Double_Type[n,N]. Each of the 'n' rows of 'a' may represent the realization
%    of a random variable. The 'n' times 'n' covariance matrix 'cov_mat' between
%    these 'n' variables is
%      cov_mat[i,j] = 1/(N-1) * sum( (a[i,*]-mean(a[i,*]))*(a[j,*]-mean(a[j,*])).
%    The 'n' times 'n' correlation matrix 'cor_mat' is
%      cor_mat[i,j] = cov_mat[i,j]/sigma_i/sigma_j
%    where 'sigma_i' is the square root of the variance of 'a_i':
%      sigma_i = sqrt( 1/(N-1) * sum( (a[i,*]-mean(a[i,*]))^2 ) ).
%\notes
%    The Cholesky decomposition of the covariance matrix can be used to generate
%    correlated variables that obey a given covariance matrix. See the example
%    section for details.
%\example
%    % From three uncorrelated normal variables 'g', generate three correlated normal
%    % variables 'x' that obey the covariance matrix 'm':
%
%    g = Double_Type[3,100000];
%    g[0,*] = grand(100000); g[1,*] = grand(100000); g[2,*] = grand(100000);
%    (cov_mat, cor_mat) = covariance_correlation_matrix(g);
%    print(cov_mat); % the covariance matrix of 'g' shows that there are no correlations
%    print(cor_mat);
%
%    m = Double_Type[3,3]; m[0,*] = [ 9,-3,-6]; m[1,*] = [-3,10, 5]; m[2,*] = [-6, 5, 6];
%    cd = cholesky_decomposition(m);
%    x = cd#g; % matrix product of 'cd' and 'g'
%    (cov_mat, cor_mat) = covariance_correlation_matrix(x);
%    print(cov_mat); % the covariance matrix of 'x' is indeed (almost) 'm'
%    connect_points(0); plot(x[0,*],x[2,*]);
%\seealso{cholesky_decomposition}
%!%-
{
  if(_NARGS!=1)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  variable a = ();
  a *= 1.; % cast to Double_Type
  variable info = struct{ dims, ndims, type };
  (info.dims, info.ndims, info.type) = array_info(a);
  if(info.ndims!=2 || info.dims[1]<2 || info.type!=Double_Type)
    throw UsageError, sprintf("Usage error in '%s': The argument has to be a Double_Type[n,N] with N>1.", _function_name());
  variable i, j;
  variable len = info.dims[0];
  variable means = Double_Type[len], sigmassqr = Double_Type[len], sigmas = Double_Type[len];
  _for i(0, len-1, 1)
  {
    means[i] = mean(a[i,*]);
    sigmassqr[i] = sum((a[i,*]-means[i])^2);
    sigmas[i] = sqrt(sigmassqr[i]);
  }
  variable cov_mat = Double_Type[len,len]; % covariance matrix
  variable cor_mat = Double_Type[len,len]; % correlation matrix
  _for i(0, len-1, 1)
  {
    _for j(0, i, 1)
    {
      if(i==j)
	cov_mat[i,j] = sigmassqr[i];
      else
	cov_mat[i,j] = sum((a[i,*]-means[i])*(a[j,*]-means[j]));
      cov_mat[j,i] = cov_mat[i,j];
      cor_mat[i,j] = cov_mat[i,j]/sigmas[i]/sigmas[j];
      cor_mat[j,i] = cor_mat[i,j];
    }
  }
  return (1./(info.dims[1]-1.)*cov_mat, cor_mat);
}%}}}
