%%%%%%%%%%%%%%%%%%%%%%%
define rebin_error_hook(orig_cts, orig_stat_err, grouping)
%%%%%%%%%%%%%%%%%%%%%%%
{
  return sqrt(rebin_array(orig_stat_err^2, grouping));
}
