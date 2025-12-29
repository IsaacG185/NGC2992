#ifeval is_defined("tbnew") || is_defined("TBnew_fit")
define tbnew_simple_fit(lo, hi, par)
{
  variable abs_NH = abs(par[0]);
  variable exp_minus_tau =
#ifeval is_defined("tbnew")
    tbnew_fit
#else
    TBnew_fit
#endif
    (lo, hi, [
    abs_NH, % nH
         1, % He
         1, % C
         1, % N
         1, % O
         1, % Ne
         1, % Na
         1, % Mg
         1, % Al
         1, % Si
         1, % S
         1, % Cl
         1, % Ar
         1, % Ca
         1, % Cr
         1, % Fe
         1, % Co
         1, % Ni
       0.2, % H2
         1, % rho
     0.025, % amin
      0.25, % amax
       3.5, % PL
         1, % H_dep
         1, % He_dep
       0.5, % C_dep
         1, % N_dep
       0.6, % O_dep
         1, % Ne_dep
      0.25, % Na_dep
       0.2, % Mg_dep
      0.02, % Al_dep
       0.1, % Si_dep
       0.6, % S_dep
       0.5, % Cl_dep
         1, % Ar_dep
     0.003, % Ca_dep
      0.03, % Cr_dep
       0.3, % Fe_dep
      0.05, % Co_dep
      0.04, % Ni_dep
         0  % redshift
  ]);
  return (par[0]>=0 ? exp_minus_tau : 1./exp_minus_tau);
}
add_slang_function("tbnew_simple", ["nH [10^22/cm^2]"]);

private define tbnew_simple_defaults(i)
{
  return (1, 0, 0, 100);
}
set_param_default_hook("tbnew_simple", &tbnew_simple_defaults);

#endif
