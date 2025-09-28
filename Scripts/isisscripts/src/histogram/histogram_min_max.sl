%%%%%%%%%%%%%%%%%%%%%%%%
define histogram_min_max()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{histogram_min_max}
%\synopsis{computes a histogram between minimum and maximum value}
%\usage{Struct_Type h = histogram_min_max(Double_Type X[, Double_Type dx]);}
%\qualifiers{
%\qualifier{log}{use a logarithmic grid with the following number of bins:}
%\qualifier{N}{[=100] number of bins of logarithmic or linear grid}
%}
%\description
%    The return value is a \code{{ bin_lo, bin_hi, value, err }} structure which
%    can directly be used with, e.g., \code{hplot_with_err}, \code{define_counts}, etc.
%\seealso{histogram}
%!%-
{
  variable X, dx=NULL;
  switch(_NARGS)
  { case 1: X = (); }
  { case 2: (X, dx) = (); }
  { return help(_function_name()); }

  variable h = struct { bin_lo, bin_hi, value, err };
  variable mn, mx; (mn, mx) = min_max( X[ where(not isnan(X) and not isinf(X)) ] );
  if(qualifier_exists("log"))
  {
    if(mn<=0)  mn = min( X[ where(not isnan(X) and not isinf(X) and X>0) ] );
    (h.bin_lo, h.bin_hi) = log_grid(mn, mx, qualifier("N", 100));
  }
  else
  { if(dx==NULL)  dx = (mx-mn)/qualifier("N", 100);
    h.bin_lo = [mn : mx : dx];
    h.bin_hi = make_hi_grid(h.bin_lo);
  }
  h.value  = histogram(X, h.bin_lo, h.bin_hi);
  h.err = sqrt(h.value);  % Poisson statistics (in the Gaussian limit)
  return h;
}
