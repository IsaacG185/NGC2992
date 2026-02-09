define gauss_2d_fit(bin_lo, bin_hi, par)
{
  variable x0 = par[0];
  variable y0 = par[1];
  variable sx = par[2];
  variable sy = par[3];
  variable A  = par[4];

  variable XX, YY;
  (XX, YY) = get_2d_data_grid();

  return A * exp( -(XX-x0)^2/(2*sx^2) -(YY-y0)^2/(2*sy^2) ) / (2*PI*sx*sy);
}

define gauss_2d_defaults(i)
{
  switch(i)
  { case 0: return 0, 0, 0, 0; }
  { case 1: return 0, 0, 0, 0; }
  { case 2: return 1, 0, 1e-3, 1e3; }
  { case 3: return 1, 0, 1e-3, 1e3; }
  { case 4: return 1, 0, 0, 0; }
}

add_slang_function("gauss_2d", ["x0", "y0", "sx", "sy", "A"]);
set_param_default_hook("gauss_2d", "gauss_2d_defaults");
