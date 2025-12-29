%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_save_data_model_flux()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_save_data_model_flux}
%\synopsis{saves ISIS spectral data into a FITS file}
%\usage{fits_save_data_model_flux([filename[, ids]]);}
%!%-
{
  variable ids=all_data, filename=NULL;
  switch(_NARGS)
  { case 0: ; }
  { case 1: filename = (); }
  { case 2: (filename, ids) = (); }
  { help(_function_name()); return; }
  if(filename==NULL)  filename = "data_model_flux.fits";

  variable F = fits_open_file(filename, "c");
  variable id;
  foreach id ([ids])
  { variable d = get_data_counts(id);
    variable f = get_data_flux(id);
    fits_write_binary_table(F, "spectrum$id"$, struct {
      bin_lo   = d.bin_lo,
      bin_hi   = d.bin_hi,
      value    = d.value,
      err      = d.err,
      model    = get_model_counts(id).value,
      flux     = f.value/(f.bin_hi-f.bin_lo),
      flux_err = f.err / (f.bin_hi-f.bin_lo)
    }, struct {
      TUNIT1 = "A",
      TUNIT2 = "A",
      TUNIT3 = "counts/bin",
      TUNIT4 = "counts/bin",
      TUNIT5 = "counts/bin",
      TUNIT6 = "photons/s/cm^2/A",
      TUNIT7 = "photons/s/cm^2/A",
    });
  }
  fits_close_file(F);
}
