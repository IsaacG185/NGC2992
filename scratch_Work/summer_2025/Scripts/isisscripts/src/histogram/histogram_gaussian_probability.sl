define histogram_gaussian_probability()
%!%+
%\function{histogram_gaussian_probability}
%\usage{Double_Type[] histogram_gaussian_probability(Double_Type[] x, sigma, lo[, hi])}
%\description
%    While \code{histogram(x, lo[, hi])} increases the histogram bin \code{j}
%    where \code{lo[j] <= x[i] < hi[j]} by one for every \code{x[i]},
%    \code{histogram_gaussian_probability(x, lo[, hi])} adds the
%    the Gaussian proability of events with mean \code{x[i]}
%    and standard deviation \code{sigma[i]} to all bins.
%
%    Note that this function acts like a convolution
%    and therefore introduces an additional broadening.
%\example
%    variable n=10000, x=grand(n), sigma=ones(n);
%    variable lo=[-3:3:0.05],  hi=make_hi_grid(lo);
%    hplot(lo, hi, histogram(x, lo, hi));
%    ohplot(lo, hi, histogram_gaussian_probability(x, sigma, lo, hi));
%    % The first distribution follows N(0, 1),
%    % but the second one follows N(0, sqrt(1^2 + sigma^2)) = N(0, sqrt(2)).
%\seealso{histogram}
%!%-
{
  variable x, sigma, lo, hi;
  switch(_NARGS)
  { case 3: (x, sigma, lo) = (); hi = make_hi_grid(lo); }
  { case 4: (x, sigma, lo, hi) = (); }
  { return help(_function_name()); }

  variable handle_gauss = fitfun_handle("gauss");

  variable offset = 1-min(lo);
  lo += offset;  % in order to call eval_fun2
  hi += offset;  % with valid wavelength grid

  variable i, h=0*lo;
  _for i (0, length(x)-1, 1)
    h += eval_fun2(handle_gauss, lo, hi, [1, x[i]+offset, sigma[i]]);
  return h;
}

