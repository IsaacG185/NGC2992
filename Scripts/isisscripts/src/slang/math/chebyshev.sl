% predeclaration for a recursive function
define chebyshev_poly();

define chebyshev_poly(x,n) 
%!%+
%\function{chebyshev_poly}
%\synopsis{Returns the Chebyshev polynomial T(n,x) of the first kind of order n}
%\usage{Double_Type[] chebyshev_poly(Double_Type[] x, n)}
%\description
%    Evaluates the Chebyshev Polynomial of the first kind of order n
%    via the recurrence relation
%    
%    T(0,x) = 1
%    T(1,x) = x
%    T(n,x) = 2*x*T(n-1,x) - T(n-2,x)
%\example
%    x = [-1.:1.:#100];
%    chebyshev_poly(x,n); % returns 5th order Chebyshev polynomial evaluated
%                         % on [-1,1)
%\seealso{cheby_sum}
%!%-
{
  if (n==0) return 1;
  if (n==1) return x;
  return 2*x*chebyshev_poly(x,n-1) - chebyshev_poly(x, n-2);
}


define cheby_sum(coeffs, x)
%!%+
%\function{cheby_sum}
%\synopsis{Returns a weighted sum of Chebyshev polynomials up to a given order}
%\usage{Double_Type[] cheby_sum(Double_Type[] [a0,a1,...aN], Double_Type[] x)}
%\description
%    Return the value of the expression
%
%    a0*T(0,x) + a1*T(1,x) + a2*T(2,x) + ... + aN*T(N,x)
%
%    Where T are Chebyshev polynomials of the first kind of order 1...N.
%
%    This is array-safe in x and implemented to be much more efficient than
%    explicitly using multiple calls of chebyshev_poly()!
%\example
%    x = [-1.:1.:#100];
%    cheby_sum(x,[0, 1., 2.]); % returns chebyshev_poly(x,1)
%                              %    + 2.*chebyshev_poly(x,2)
%                         % on [-1,1)
%\seealso{chebyshev_poly}
%!%-
{
  % get the maximum order from coeffs
  variable ord = length(coeffs)-1;

  % trivial return
  if (ord == 0) return coeffs[0]*ones(length(x));

  % build a vector of the evaluated chebyshev polynomials without
  % the coefficients
  variable evals = Double_Type[length(x),ord+1];

  evals[*,0] = 1;
  evals[*,1] = x;

  variable ii;
  for (ii=2; ii<ord+1; ii++) {
    % use the recursion relation
    evals[*,ii] = 2*x*evals[*,ii-1] - evals[*,ii-2];
  }

  % multiply with the coefficients (did not do this earlier so we could
  % take advantage of recursion)
  for (ii=0; ii<ord+1; ii++) {
    evals[*,ii] *= coeffs[ii];
  }

  % return the sum over the 2nd dimension
  return sum(evals, 1);
}
