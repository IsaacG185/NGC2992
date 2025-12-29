%%%%%%%%%%%%%%%%
define step1_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%
%!%+
%\function{step1 (fit-function)}
%\synopsis{a step function which is 1 above x0}
%\description
%    If one bin encloses \code{x0}, the value of step1 function
%    is the fraction of the bin which is above \code{x0}.
%\seealso{step2}
%!%-
{
  variable value = 0*bin_lo;
  value[where(bin_lo>=par[0])] = 1;

  variable i = where(bin_lo < par[0] < bin_hi);
  value[i] = (bin_hi[i]-par[0])/(bin_hi[i]-bin_lo[i]);
  return value;
}

add_slang_function("step1", ["x0"]);
