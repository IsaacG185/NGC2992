define cholesky_decomposition() %{{{
%!%+
%\function{cholesky_decomposition}
%\synopsis{Decompose a matrix into the product of a lower triangular matrix and its transpose}
%\usage{Double_Type cd[n,n] = cholesky_decomposition(Double_Type m[n,n])}
%\description
%    The Cholesky decomposition is a decomposition of a symmetric, positive-definite
%    matrix into the (matrix) product of a lower triangular matrix and its transpose:
%      m = cd # transpose(cd).
%    The Cholesky–Banachiewicz algorithm is used here to carry out the decomposition.
%\notes
%    The Cholesky decomposition can be used to generate correlated variables that obey
%    a given covariance matrix. See the example section for details.
%\example
%    m = Double_Type[3,3]; m[0,*] = [ 9,-3,-6]; m[1,*] = [-3,10, 5]; m[2,*] = [-6, 5, 6];
%    print(m);                       % symmetric, positive-definite matrix
%    cd = cholesky_decomposition(m);
%    print(cd);                      % lower triangular matrix
%    print(cd#transpose(cd));        % matrix product of 'cd' and its transpose
%
%    % From three uncorrelated normal variables 'g', generate three correlated normal
%    % variables 'x' that obey the covariance matrix 'm':
%
%    g = Double_Type[3,100000];
%    g[0,*] = grand(100000); g[1,*] = grand(100000); g[2,*] = grand(100000);
%    (cov_mat, cor_mat) = covariance_correlation_matrix(g);
%    print(cov_mat); % the covariance matrix of 'g' shows that there are no correlations
%
%    x = cd#g;
%    (cov_mat, cor_mat) = covariance_correlation_matrix(x);
%    print(cov_mat); % the covariance matrix of 'x' is indeed (almost) 'm'
%\seealso{covariance_correlation_matrix}
%!%-
{
  if(_NARGS!=1)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  variable m = ();
  m *= 1.; % cast to Double_Type
  variable info = struct{ dims, ndims, type };
  (info.dims, info.ndims, info.type) = array_info(m);
  if(info.ndims!=2 || info.dims[0]!=info.dims[1] || info.type!=Double_Type)
    throw UsageError, sprintf("Usage error in '%s': The argument has to be a square matrix composed of Double_Types.", _function_name());
  variable cd = 0.*Double_Type[info.dims[0],info.dims[1]]; % Cholesky decomposed matrix initialized with zeros
  variable i, j;
  _for i(0, info.dims[0]-1, 1)
  {
    _for j(0, i, 1)
    {
      variable ind = [0:j-1:1];
      variable temp = m[i,j] - sum(cd[i,ind]*cd[j,ind]);
      if(i>j)
	cd[i,j] = temp/cd[j,j];
      else if(temp>0)
	cd[i,j] = sqrt(temp);
      else
	throw UsageError, sprintf("Usage error in '%s': The argument has to be a symmetric positive-definite matrix.", _function_name());
    }
  }
  return cd;
}%}}}
