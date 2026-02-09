%%%%%%%%%%%%%%%%
define write_spix()
%%%%%%%%%%%%%%%%
%!%+
%\function{write_spix}
%\synopsis{writes the structure provided by make_spix in a FITS file}
%\usage{write_spix(Stuct_Type \code{spix}, String_Type \code{filename});}
%\seealso{make_spix, read_spix, plot_spix}
%!%-
{
  variable spix, filename;
  switch(_NARGS)
  { case 2: (spix, filename) = (); }
  { help(_function_name()); return; }


  variable spixm   = struct {
    spec_map       = spix.spec_map,
    lo_map         = spix.lo_map,
    hi_map_shifted = spix.hi_map_shifted,
    stdev          = spix.stdev,
    avg_lum        = spix.avg_lum,
    weights        = spix.weights,
  };
  
  variable keys = struct {
    avg_xshift    = spix.avg_shift[0],    % to be corrected
    avg_yshift    = spix.avg_shift[1],    % to be corrected
    shift_weight  = spix.shift_weight,    % to be corrected
    ra_px_center  = spix.ra_px_center,
    ra_steps      = spix.ra_steps,
    dec_px_center = spix.dec_px_center,
    dec_steps     = spix.dec_steps,
    major         = spix.major,
    minor         = spix.minor,
    posang        = spix.posang,
    source        = spix.source,
    date          = spix.date
  };

  fits_write_binary_table(filename, "spix", spixm, keys);
}
