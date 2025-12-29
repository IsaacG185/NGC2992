%%%%%%%%%%%%%%%%%%%%
define fits_plot_rmf()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_plot_rmf}
%\synopsis{plots a redistribution matrix from a compressed RMF file}
%\usage{fits_plot_rmf(String_Type RMFfile);
%\altusage{(interpol_matrix_density, Ebounds, energ) = fits_plot_rmf(RMFfile; getvalues)}
%}
%\qualifiers{
%\qualifier{nx}{number of pixels in x-direction [default=400]}
%\qualifier{ny}{number of pixels in x-direction [default=300]}
%\qualifier{getvalues}{retrieves the interpolated matrix density}
%\qualifier{noplot}{skip plotting, but retrieves the interpolated matrix density}
%}
%\seealso{fits_read_rmf}
%!%-
{
  variable RMFfile;
  switch(_NARGS)
  { case 1: RMFfile = (); }
  { help(_function_name()); return; }

  variable rmf = fits_read_rmf(RMFfile);

  variable EMIN, EMAX, ELO, EHI;
  (EMIN, ELO) = get_grid(rmf.ebounds.bin_lo, rmf.energy.bin_lo);
  (EMAX, EHI) = get_grid(rmf.ebounds.bin_hi, rmf.energy.bin_hi);

  % bin density
  variable r_density = rmf.matrix / ((EMAX-EMIN) * (EHI-ELO));

  % new grid
  variable x = [ rmf.ebounds.bin_hi[0] : rmf.ebounds.bin_lo[-1] : #qualifier("nx", 400)];
  variable y = [ rmf.energy.bin_hi[0]  : rmf.energy.bin_lo[-1]  : #qualifier("ny", 300) ];
  variable r2_density = interpol2D(x, y, rmf.ebounds.center, rmf.energy.center, r_density);

  % bin integrated
  variable r2 =  r2_density * (x[1]-x[0]) * (y[1]-y[0]);

  ifnot(qualifier_exists("noplot"))
  { xlabel("EBOUNDS [keV]");
    ylabel("energy [keV]");
    plot_image(log(1+max(r2))-log(1+r2), , x, y);
  }

  if(qualifier_exists("getvalues") || qualifier_exists("noplot"))
    return r2, x, y;
}
