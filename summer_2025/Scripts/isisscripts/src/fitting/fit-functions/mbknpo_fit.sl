define mbknpo_fit(bin_lo, bin_hi, par)
%!%+
%\function{mbknpo_fit}
%\synopsis{Fitting a multiplicative broken powerlaw to data in energy space}
%\usage{fit_fun("mknpo");}
%\description
%    This function can be used to cut a relxill spectrum off at low
%    energies (e.g., Steiner et al., ApJL 969, L30, 2024, Ubach et
%    al., ApJ 976, 38, 2024).
%\seealso{relxill}
%!%-
{
  variable norm = par[0];
  variable B = par[1];
  variable I = par[2];

  variable energy_grid_keV = .5*(_A(bin_hi) + _A(bin_lo));
  array_reverse(energy_grid_keV);
  
  %% max() not array proof?
  variable ii, maxs = Double_Type[length(energy_grid_keV)];
  _for ii (0, length(energy_grid_keV)-1, 1){
    maxs[ii] = max([energy_grid_keV[ii], B]);
  }

  % XSPEC terminology: mdefine mbknpo (max(E,B)-B)/abs(E-B+0.0000001)+(1-(max(E,B)-B)/abs(E-B+0.0000001))(E/B)^I : mul
  variable bknpo = (maxs-B)/abs(energy_grid_keV-B+0.0000001) +
    (1-(maxs-B)/abs(energy_grid_keV-B+0.0000001))*(energy_grid_keV/(1.*B))^I;
  
  return norm * bknpo;
}

define mbknpo_default(i)
{
  switch(i)
  { case 0: return (1   , 0   , 0   , 1e10); }
  { case 1: return (1   , 0   , 0   , 1000); }
  { case 2: return (1   , 0   , -5  , 5   ); }
}

add_slang_function("mbknpo", ["norm", "B", "I"]);
set_param_default_hook("mbknpo", &mbknpo_default);
