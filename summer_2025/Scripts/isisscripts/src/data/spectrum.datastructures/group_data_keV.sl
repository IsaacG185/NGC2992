%%%%%%%%%%%%%%%%%%%%%
define group_data_keV(id, deltaE)
%%%%%%%%%%%%%%%%%%%%%
{
  group_data(id, 1);
  variable d = get_data_counts(id);
  variable E = _A(1) / ((d.bin_lo+d.bin_hi)/2);
  rebin_data(id,  int( (-1)^int(E/deltaE) ) );
}
