require("gslfft","gsl");
require("gsl","gsl");

%%%%%%%%% subroutine for calculating a 2D-Gaussian profile (beam) with position angle
%%%%%%%%% (add this function as a separate usable funtion to the isisscripts?)
private define mb_gauss_2d (x, y, major, minor, theta, x0, y0)
{
  variable a =  sin(theta)^2/(2.0*major^2) + cos(theta)^2/(2.0*minor^2);
  variable b =  sin(2*theta)/(4.0*major^2) - sin(2*theta)/(4.0*minor^2);
  variable c =  cos(theta)^2/(2.0*major^2) + sin(theta)^2/(2.0*minor^2);

  variable A = 1/(2*PI*major*minor);
  return A * exp (- ( a*(x-x0)^2 + 2*b*(x-x0)*(y-y0) + c*(y-y0)^2 ) );
}

%%%%%%%%%%%%%%%%%%%%%%%%
define radio_mod2img ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{radio_mod2img}
%\synopsis{creates an image using a model and a beam}
%\usage{Struct_Type img = radio_mod2img( Struct_Type \code{mdl}, Double_Type \code{beam});}
%\qualifiers{
%\qualifier{src_name}{[=NULL] name of the source}
%\qualifier{date_mjd}{[=_NaN] observation date (MJD)}
%\qualifier{obs_date}{[=NULL] observation date (string). if only date_mjd or only obs_date
%                         are set, the other one is calculated.}
%\qualifier{nrpix_ra}{[=512] number of pixels for right ascension}
%\qualifier{nrpix_dec}{number of pixels in declination (by default calculated from RA-DEC-range)}
%\qualifier{ra}{[=[ra_min,ra_max]]  RA range in mas}
%\qualifier{dec}{[=[dec_min,dec_max]] DEC range in mas, by default the RA-DEC-range is
%                         calculated from the distribution of model components and the beam size}
%\qualifier{delt}{[=[ra_delt,dec_delt]] resolution in mas/pixel, overwrites nrpix qualifiers}
%\qualifier{sigma}{[=1e-3*max(img)] value for 1 sigma (used by plot_vlbi_map)}
%}
%\description
%    This function uses a model to generate an image and convolves it with the beam.
%    Here the "beam" is simply a Gaussian profile, which is given as an array:
%    \code{beam = [smajor_axis,sminor_axis,position_angle];}
%    The model has to have the fields:
%        \code{flux}   flux of each model component [Jy]
%        \code{ra}     relative RA of component (change to delta_x?)
%        \code{dec}    relative RA of component (change to delta_y?)
%        \code{smajor} component size (smajor axis) [mas] (0 for point source)
%        \code{sminor} component size (sminor axis) [mas]
%        \code{pang}   position angle of component's smajor axis
%    Currently the last two fields (\code{sminor}, and \code{pang}) are
%    ignored and only circular components (\code{smajor}) are used.
%\example
%    variable mdl = struct {
%        flux   = [0.6 , 0.9,  0.2,  1.2,  3],
%        ra     = [2   , 1.4,  0.7, 0.25,  0],
%        dec    = [1   , 0.6, 0.35,  0.1,  0],
%        smajor = [0.3 , 0.2,    0,    0,  0],
%        sminor = [0.3 , 0.2,    0,    0,  0],
%       pang   = [0    ,   0,    0,    0,  0] };
%    variable beam = [0.2, 0.07, 0.4];
%    variable img = radio_mod2img (mdl, beam);
%    plot_vlbi_map (img, "test.pdf");
%\seealso{plot_vlbi_map, read_difmap_fits}
%!%-
{
  variable mdl, beam_val;
  switch (_NARGS)
  { case 2: (mdl,beam_val) = (); }
  { help(_function_name()); return; }

  %%%%%%%% use beam:
  variable smajor = beam_val[0];
  variable sminor = beam_val[1];
  variable theta  = beam_val[2];

  variable ra_r  = qualifier ("ra",  [min( mdl.ra  - mdl.smajor - 5*smajor), max( mdl.ra  + mdl.smajor + 5*smajor)]);
  variable ra_min = max(ra_r);    variable ra_max = min(ra_r); % RA decreasing to west
  variable dec_r = qualifier ("dec", [min( mdl.dec - mdl.smajor - 5*smajor), max( mdl.dec + mdl.smajor + 5*smajor)]);
  variable dec_min = min(dec_r);  variable dec_max = max(dec_r);

  variable nrpix_ra  = qualifier("nrpix_ra",  512);
  variable nrpix_dec = qualifier("nrpix_dec", nint (512.0*abs(double(dec_max-dec_min)/(ra_max-ra_min)) ));
  
  variable RA, DEC;
  variable ra_delt,dec_delt;
  variable delt = qualifier("delt",NULL);
  variable ra_grid, dec_grid;

  if (delt == NULL)
  {
    ra_grid  = [ra_min :ra_max :#nrpix_ra ];
    dec_grid = [dec_min:dec_max:#nrpix_dec];
    ra_delt  = (ra_max  - ra_min)  / nrpix_ra ;
    dec_delt = (dec_max - dec_min) / nrpix_dec;
  }
  else
  {
    switch (length(delt))
    { case 1: ra_delt = delt[0]; dec_delt = delt[0]; }
    { case 2: ra_delt = delt[0]; dec_delt = delt[1]; }
    { throw RunTimeError, sprintf("%s: no proper stepsize (delt) provided", _function_name()); }
    
    ra_grid  = [ra_min :ra_max :ra_delt ];
    dec_grid = [dec_min:dec_max:dec_delt];
  }
  (RA, DEC) = get_grid( ra_grid, dec_grid);

  %%%%%%% create image and fill it with the model components:
  variable img_size = array_shape(RA);
  variable img = Double_Type[img_size[0],img_size[1]];
  variable nr_cmp = length (mdl.flux);
  variable i;
  _for i (0, nr_cmp-1, 1)
  {
    if (mdl.smajor[i] < 0.3*_min(abs(ra_delt),abs(dec_delt))) % point source
    {
      img[where( (RA + 0.5*ra_delt < mdl.ra[i] <= RA - 0.5*ra_delt) and (DEC - 0.5*dec_delt < mdl.dec[i] <= DEC + 0.5*dec_delt))]
	+= mdl.flux[i];
    }
    if (mdl.smajor[i] >= 0.3*_min(abs(ra_delt),abs(dec_delt))) % spherical (!) Gaussian component (add case for elliptical)
    {
      
      variable valx = 0.5 * ( gsl->erf(( ra_grid - 0.5*ra_delt - mdl.ra[i] )/(sqrt(2)*mdl.smajor[i])) -
			    gsl->erf(( ra_grid + 0.5*ra_delt - mdl.ra[i] )/(sqrt(2)*mdl.smajor[i])));
      variable valy = 0.5 * ( gsl->erf(( dec_grid + 0.5*dec_delt - mdl.dec[i] )/(sqrt(2)*mdl.smajor[i])) -
			      gsl->erf(( dec_grid - 0.5*dec_delt - mdl.dec[i] )/(sqrt(2)*mdl.smajor[i])));
      
      variable valXX, valYY;  (valXX, valYY) = get_grid(valx, valy);
      img += mdl.flux[i] * valXX * valYY;
    }
  }

  variable b_nr = ceil(5*smajor/_min(abs(ra_delt),abs(dec_delt)));
  variable beam = mb_gauss_2d ( get_grid([-b_nr:b_nr]*ra_delt, [-b_nr:b_nr]*dec_delt),
				smajor, sminor, theta, 0, 0 );
  beam /= max(beam); % keep peak flux (or keep total flux by /=sum(beam))

  variable date_mjd =  qualifier( "date_mjd", _NaN );
  variable date_str =  qualifier( "obs_date", (isnan(date_mjd) ? NULL : strftime_MJD( "%Y-%m-%d", date_mjd ) ) );
  if (isnan(date_mjd) && date_str != NULL) date_mjd = MJDofDateString (date_str);
    
  variable res = struct {
%    trueimg= img,
%    beam = beam,
    img= gsl->convolve (img, beam),

    src_name      = qualifier( "src_name", NULL ),
    date_mjd      = date_mjd,
    date_str      = date_str,
    
    ra_center     = 0,
    ra_px_center  = -sign( ra_min  *ra_delt ) * ( abs( ra_min /ra_delt )),
    ra_steps      = ra_delt,
    
    dec_center    = 0,
    dec_px_center = -sign( dec_min *dec_delt) * ( abs( dec_min/dec_delt)),
    dec_steps     = dec_delt,
    
    beam_smaj     = smajor,
    beam_smin     = sminor,
    beam_pang     = theta,
    
    mu            = 0.0,
    sigma
  };
  
  res.sigma = qualifier("sigma",1e-3*max(res.img)); 
  
  return res;
}
