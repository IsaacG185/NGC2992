%%%%%%%%%%%%%%%
define log_grid()
%%%%%%%%%%%%%%%
%!%+
%\function{log_grid}
%\synopsis{generate a logarithmic histogram grid}
%\usage{(bin_lo[], bin_hi[]) = log_grid(min, max, nbins);}
%\description
%    This function is an shorthand form of:\n
%       \code{(log_bin_lo, log_bin_lo) = linear_grid( log(min), log(max), nbins );}\n
%       \code{bin_lo = exp( log_bin_lo );}\n
%       \code{bin_hi = exp( log_bin_hi );}
%\seealso{linear_grid}
%!%-
{
  variable mn, mx, nbins;
  switch(_NARGS)
  { case 3: (mn, mx, nbins) = (); }
  { help(_function_name()); return; }

  variable log_bin_lo, log_bin_hi;
  (log_bin_lo, log_bin_hi) = linear_grid( log(mn), log(mx), nbins );
  return (exp(log_bin_lo), exp(log_bin_hi));
}
