define multiplot_data_m_lam_counts()
{
  variable ids, xmin=NULL, xmax=NULL;
  switch(_NARGS)
  { case 1: ids = (); }
  { case 3: (ids, xmin, xmax) = (); }
  {%else:
      message("usage: plot_m_lambda(ids[, m_lam_min, m_lam_max]); % where ids = [id1, id2, ...];");
      return;
  }

  multiplot(0*[ids]+1);
  xrange(xmin, xmax);
  xlabel(`order m  \x  wavelength \gl  [\A]`);
  plot_bin_integral;
  variable m;
  for(m=1; m<=length(ids); m++)
  {
    ylabel("counts/bin (m="+string(m)+")");
    variable data = get_data_counts([ids][m-1]);
    hplot(m*data.bin_lo, m*data.bin_hi, data.value);
  }
}
