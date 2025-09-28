
private define try_fits_read_key_or_fill (file, key, fill)
{
  return fits_key_exists (file, key) ? fits_read_key (file, key) : fill;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define read_difmap_fits ()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{read_difmap_fits}
%\synopsis{read a fits image provided by DIFMAP}
%\usage{Struct_Type img_struct = read_difmap_fits(String_Type \code{fitsfile_name})}
%\qualifiers{
%\qualifier{fit_noise}{fit properties of the image noise}
%}
%\description
%    This function reads a .fits file provided by DIFMAP and returns
%    a structure containing the image and keywords.
%    The returned structure can be used as input for the function
%    \code{plot_vlbi_map}.
%\seealso{plot_vlbi_map}
%!%-
{
  switch(_NARGS)
  { case 1:   variable fitsfile = (); }
  { help(_function_name()); return; }
  
  variable s = struct {
    img           = fits_read_img(fitsfile),

    src_name      = try_fits_read_key_or_fill (fitsfile, "OBJECT", NULL),
    date_mjd      = MJDofDateString( try_fits_read_key_or_fill (fitsfile, "DATE-OBS", "0000-01-01")),
    date_year,
    date_str,

    ra_center     = try_fits_read_key_or_fill (fitsfile, "CRVAL1",0),            % right ascension of the center
    ra_px_center  = try_fits_read_key_or_fill (fitsfile, "CRPIX1",0),            % right ascensin center pixel
    ra_steps      = try_fits_read_key_or_fill (fitsfile, "CDELT1",0)*(3.6e+6),   % RA in mas corresponding to one pixel

    dec_center    = try_fits_read_key_or_fill (fitsfile, "CRVAL2",0),            % declination of the center
    dec_px_center = try_fits_read_key_or_fill (fitsfile, "CRPIX2",0),            % declination center pixel
    dec_steps     = try_fits_read_key_or_fill (fitsfile, "CDELT2",0)*(3.6e+6),   % DEC in mas corresponding to one pixel
    
    beam_smaj     = try_fits_read_key_or_fill (fitsfile, "BMAJ",0)*(3.6e+6)/2.0, % clean beam semi (!) major axis in mas
    beam_smin     = try_fits_read_key_or_fill (fitsfile, "BMIN",0)*(3.6e+6)/2.0, % clean beam semi (!) minor axis ins mas
    beam_pang     = try_fits_read_key_or_fill (fitsfile, "BPA" ,0)/180*PI,        % clean beam postion angle

    mu            = NULL,
    sigma         = NULL,
    sigma_difmap  = try_fits_read_key_or_fill (fitsfile, "NOISE", _NaN),
  };

  s.date_str     = strftime_MJD( "%Y-%m-%d", s.date_mjd );
  s.date_year    = yearOfMJD ( s.date_mjd );
  
  % remove 2 DIFMAP extra dimensions (FREQ and STOKES):
  variable shape = array_shape(s.img);
  shape = shape[ where( shape > 1 ) ];
  if ( length(shape) == 2 )
    reshape (s.img, shape);
  else
    throw RunTimeError, sprintf("%s: multiple images for different FREQ or STOKES?\n\t-> modify the function %s",
				_function_name(), _function_name());

  if (qualifier_exists("fit_noise"))
    (s.mu,s.sigma) = fit_gauss_to_img_noise (s.img);

  return s;
}
