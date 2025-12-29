%%%%%%%%%%%%%%%%
define dummy_fit(lo, hi, par)
%%%%%%%%%%%%%%%%
{
  return 0*lo + 1.;
}

%%%%%%%%%%%%
define dummy_default(i)
%%%%%%%%%%%%
{
  switch(i)
  {    case 0: return (0.0, 0, 0.0, 1e+4);}
}

add_slang_function ("dummy", ["const"]);
set_param_default_hook("dummy", &dummy_default);
