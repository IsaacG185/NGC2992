#ifeval is_defined("tbnew") || is_defined("TBnew")

define tbnew_metal_fit(lo, hi, par)
{                     %  H,      He,       C,       N        O,      Ne,      Na,      Mg,      Al,      Si,       S,      Cl,      Ar,      Ca,      Cr,      Fe,      Co,      Ni,
  variable tbnew_par1 = [1, 9.77e-2,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0];
  variable tbnew_par2 = [0,       0, 2.40e-4, 7.59e-5, 4.90e-4, 8.71e-5, 1.45e-6, 2.51e-5, 2.14e-6, 1.86e-5, 1.23e-5, 1.32e-7, 2.57e-6, 1.58e-6, 3.24e-7, 2.69e-5, 8.32e-8, 1.12e-6];  % wilm
%      			          0, 3.63e-4, 1.12e-4, 8.51e-4, 1.23e-4, 2.14e-6, 3.80e-5, 2.95e-6, 3.55e-5, 1.62e-5, 3.16e-7, 3.63e-6, 2.29e-6, 4.68e-7, 4.68e-5, 8.32e-8, 1.78e-6];  % angr
  variable other_tbnew_par = [0.2, 1, 0.025, 0.25, 3.5, 1, 1, 0.5, 1, 0.6, 1, 0.25, 0.2, 0.02, 0.1, 0.6, 0.5, 1, 0.003, 0.03, 0.3, 0.05, 0.04, 0];
  variable par1 = [-par[0]*tbnew_par1, other_tbnew_par];
  variable par2 = [-par[1]*tbnew_par2, other_tbnew_par];
#ifeval is_defined("tbnew")
  return  tbnew_fit(lo, hi, par1) * tbnew_fit(lo, hi, par2);
#else
  return  TBnew_fit(lo, hi, par1) * TBnew_fit(lo, hi, par2);
#endif
}
add_slang_function("tbnew_metal", ["NH_HHe", "NH_met"]);

private define tbnew_metal_defaults(i)
{
  return (1e22, 0, 0, 1e24);
}
set_param_default_hook("tbnew_metal", &tbnew_metal_defaults);

#endif
