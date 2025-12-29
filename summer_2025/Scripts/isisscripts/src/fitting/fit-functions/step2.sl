%%%%%%%%%%%%%%%%
define step2_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%
%!%+
%\function{step2 (fit-function)}
%\synopsis{a step function which is 1 between x1 and x2}
%    If one bin encloses \code{x0} or \code{x2}, the value of the step2 function
%    is the fraction of the bin which is between \code{x1} and \code{x2}.
%\seealso{step1}
%!%-
{
  variable value = 0*bin_lo;

  % par[0]  bin_lo                  bin_hi  par[1]
  % {       [----------------------------]       }
  value[ where(par[0] < bin_lo and bin_hi < par[1]) ] = 1;

  %         bin_lo  par[0]          bin_hi  par[1]
  %         [       {--------------------]       }
  variable i = where(bin_lo < par[0] < bin_hi < par[1]);
  value[i] = (bin_hi[i]-par[0])/(bin_hi[i]-bin_lo[i]);

  % par[0]  bin_lo          par[1]  bin_hi
  % {       [--------------------}       ]
  i = where(par[0] < bin_lo < par[1] < bin_hi);
  value[i] = (par[1]-bin_lo[i])/(bin_hi[i]-bin_lo[i]);

  %         bin_lo  par[0]  par[1]  bin_hi
  %         [       {------------}       ]
  i = where(bin_lo < par[0] < par[1] < bin_hi);
  value[i] = (par[1]-par[0])/(bin_hi[i]-bin_lo[i]);

  return value;
}

add_slang_function("step2", ["x1", "x2"]);
