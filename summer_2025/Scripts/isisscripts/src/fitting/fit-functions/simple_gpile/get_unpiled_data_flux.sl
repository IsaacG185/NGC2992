
define get_unpiled_data_flux()
{
  % process arguments
  variable id;
  switch(_NARGS)
  { case 1:  id = (); }
  { message("usage: get_unpiled_data_flux(id);"); return; }

  variable f = get_data_flux(id);
  Isis_Active_Dataset = id;
  variable pm = eval_fun(f.bin_lo, f.bin_hi);
  variable fitFun = get_fit_fun();
  fit_fun(get_unpiled_fit_fun());
  Isis_Active_Dataset = id;
  variable  m = eval_fun(f.bin_lo, f.bin_hi);
  fit_fun(fitFun);
  f.value *= m/pm;
  f.err *= m/pm;
  return f;
}
