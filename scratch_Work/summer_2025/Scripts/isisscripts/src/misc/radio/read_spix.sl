define read_spix()
%!%+
%\function{read_spix}
%\synopsis{reads the FITS file created with write_spix}
%\usage{Stuct_Type \code{spix} = read_spix( String_Type \code{filename});}
%\seealso{make_spix, write_spix, plot_spix}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: (filename) = (); }
  { help(_function_name()); return; }


  variable spixm = fits_read_table ( filename );

  variable spix    = struct {
    spec_map       = spixm.spec_map,
    lo_map         = spixm.lo_map,
    hi_map_shifted = spixm.hi_map_shifted,
    stdev          = spixm.stdev,
    avg_lum        = spixm.avg_lum,
    weights        = spixm.weights,
    avg_shift      = [fits_read_key(filename , "avg_xshift" ),fits_read_key(filename , "avg_yshift" )],
    shift_weight   = fits_read_key(filename , "shift_weight" ),
    ra_px_center   = fits_read_key(filename , "ra_px_center" ),
    ra_steps       = fits_read_key(filename , "ra_steps" ),
    dec_px_center  = fits_read_key(filename , "dec_px_center" ),
    dec_steps      = fits_read_key(filename , "dec_steps" ),
    major          = fits_read_key(filename , "major" ),
    minor          = fits_read_key(filename , "minor" ),
    posang         = fits_read_key(filename , "posang" ),
    source         = fits_read_key(filename , "source" ),
    date           = fits_read_key(filename , "date" )
  };

  return spix;
}
