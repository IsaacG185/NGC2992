define opdf()
{
  variable i, ids;
  switch(_NARGS)
  { case 0: ids = all_data; }
  { case 1: ids = (); ids = [ids]; }

  foreach i (ids) { oplot_data_flux(i); }
}
