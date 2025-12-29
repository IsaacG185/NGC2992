define pdc()
{
  variable i, ids;
  switch(_NARGS)
  { case 0: ids = all_data; }
  { case 1: ids = (); ids = [ids]; }

  plot_bin_integral;
  plot_data_counts(ids[0]);
  _for i (1, length(ids)-1, 1) { oplot_data_counts(ids[i]); }
}
