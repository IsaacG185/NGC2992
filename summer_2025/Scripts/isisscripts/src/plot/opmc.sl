define opmc()
{
  variable id, ids;
  switch(_NARGS)
  { case 0: ids = all_data; }
  { case 1: ids = (); ids = [ids]; }
  { message("usage: opmc([ids]);"); return; }

  foreach id (ids) { oplot_model_counts(id); }
}
