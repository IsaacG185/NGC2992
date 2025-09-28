define multiplot_flux_counts_res()
%!%+
%\function{multiplot_flux_counts_res}
%\synopsis{creates a plot of model flux, data counts and residuals in 3 panels}
%\usage{multiplot_flux_counts_res(data_ind[, rel_size]);}
%\description
%    If data_ind is an array of data-indices, the data will be rebinned
%    to the grid of the first index.
%!%-
{
  variable data_ind, rel_size = [2, 3, 1];
  switch(_NARGS)
  { case 1:  data_ind = (); }
  { case 2: (data_ind, rel_size) = (); }
  { help(_function_name()); return; }

  variable f = get_model_flux(1);
  variable d = get_data_counts([data_ind][0]);
  variable m = get_model_counts([data_ind][0]);
  variable i;
  _for i (1, length(data_ind)-1, 1)
  { variable tmp_d = get_data_counts(data_ind[i]);
    variable tmp_m = get_model_counts(data_ind[i]);
    d.value += rebin(d.bin_lo, d.bin_hi,  tmp_d.bin_lo, tmp_d.bin_hi, tmp_d.value);
    d.err = sqrt(d.err^2 + rebin(d.bin_lo, d.bin_hi,  tmp_d.bin_lo, tmp_d.bin_hi, tmp_d.err)^2);
    m.value += rebin(m.bin_lo, m.bin_hi,  tmp_m.bin_lo, tmp_m.bin_hi, tmp_m.value);
  }
  variable res = (d.value-m.value)/d.err;

  variable plot_opt = get_plot_options();
  multiplot(rel_size);
  ylabel(`Flux [ph/s/cm\u2\d/\A]`);
  plot_bin_density;
  hplot(f);

  plot_bin_integral;
  ylabel("Counts [/bin]");
  hplot(d);
  ohplot(m);

  xlabel(`Wavelength [\A]`);
  ylabel(`\gx`);
  ylin;
  hplot(d.bin_lo, d.bin_hi, res);
  oplot([plot_opt.xmin, plot_opt.xmax], [0, 0]);

  set_plot_options(plot_opt);
}
