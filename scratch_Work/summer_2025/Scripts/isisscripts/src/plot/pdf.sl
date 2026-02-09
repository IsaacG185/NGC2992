define pdf()
{
  variable ids;
  switch(_NARGS)
  { case 0: ids = all_data; }
  { case 1: ids = (); ids = [ids]; }
  { message("usage: pdf([ids]);"); return; }

  plot_bin_density;
  plot_data_flux(ids[0]);
  variable i;
  _for i (1, length(ids)-1, 1) { oplot_data_flux(ids[i]); }
}
