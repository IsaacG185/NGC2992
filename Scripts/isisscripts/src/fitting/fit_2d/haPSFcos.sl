%%%%%%%%%%%%%%%%%%%
define haPSFcos_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%
{
  variable x0 = par[0];
  variable y0 = par[1];
  variable prefactor = par[2];
  variable c  = par[3];
  variable phase = par[4];

  variable XX, YY;
  (XX, YY) = get_2d_data_grid();

  variable phi = atan2(YY-y0, XX-x0);
  return prefactor * cos(c*phi + phase);
}

add_slang_function("haPSFcos", ["x0", "y0", "prefactor", "c", "phase"]);
% set_param_default_hook("haPSFcos", "haPSFcos_defaults");
