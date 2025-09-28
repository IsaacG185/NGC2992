define opmf()
{
  variable id, ids;
  switch(_NARGS)
  { case 0: ids = all_data; }
  { case 1: ids = (); ids = [ids]; }
  { message("usage: opmf([ids]);"); return; }

  foreach id (ids) { oplot_model_flux(id); }
}
