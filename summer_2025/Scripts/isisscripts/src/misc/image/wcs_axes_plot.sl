require( "xfig" );
require( "wcsfuns" ); 

private define get_tic_pos_dezimal(x)
{
  variable n = qualifier("n",5); % preferred number of major tics
  
  variable coverage  = abs(max(x)-min(x));
  variable fac       = 10^floor(log10(coverage ));
  variable steps     = [  1, 2, 5, 10, 20, 50];
  variable min_steps = [0.2, 1, 1,  2, 10, 10];
  do { % allow the situation of many tic marks:
    steps *= 0.1; min_steps *= 0.1;
    variable nr = coverage/(steps*fac);
    variable i = where_min (abs(n -  nr) );
  } while (i == 0);

  variable major = min(x)-(min(x) mod (steps[i]*fac)) + [-1 : 1+ceil(nr[i])]*(steps[i]*fac);
  variable minor = min(x)-(min(x) mod (min_steps[i]*fac))
    + [-1 : 1+ceil( coverage/(min_steps[i]*fac) )]*(min_steps[i]*fac);
  return major, minor;
}

#ifnexists WCSaxis_Type
typedef struct { ra , dec, x, y, label, major, maj_ra, maj_dec, minor, min_ra, min_dec} WCSaxis_Type;
#endif

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define wcs_axes_plot ()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{wcs_axes_plot}
%\synopsis{gets WCS coordinates of axes and returns xfig plot object}
%\usage{xfig_plot_object = wcs_axes_plot (String_Type image_filename); }
%\altusage{xfig_plot_object = wcs_axes_plot (image, wcs); }
%\qualifiers{
%\qualifier{width}{set plot width}
%\qualifier{height}{[=14] set plot height, unless width and height are both
%                     set, the other one is calculated based on the
%                     format of the image (currently CDELT1 != CDELT2
%                     is not taken into account, but only #pixels)}
%\qualifier{x1label}{[=WCS of major] set ticlabels of x1-axis}
%\qualifier{x2label}{[=0] set ticlabels of x2-axis}
%\qualifier{y1label}{[=WCS of major] set ticlabels of y1-axis}
%\qualifier{y2label}{[=0] set ticlabels of y2-axis}
%\qualifier{axis_color}{[="white"] set the color of the axes}
%\qualifier{x1major}{set WCS values for major tics of x1-axis.
%                     similar qualifiers exist for x2, y1, and y2-axes.
%                     unless x1 and x2 are both set, the qualifier affects
%                     both x-axes. the same holds for the y-axes and the
%                     minor qualifiers.}
%\qualifier{x1minor}{set WCS values for minor tics of x1-axis.
%                     similar qualifiers exist for x2, y1, and y2 axes}
%\qualifier{return_axes}{set qualifier to additionally return
%                     data (Assoc_Type) including axes information.
%                     the returned object \code{wcsaxes} can be accessed
%                     with \code{wcsaxes["x1"]} (keys are ["x1","x2","y1","y2"])}
%\qualifier{info}{print the WCS (RA-DEC) ranges of the axes
%                     (helpful for setting minor and major by hand)}
%}
%\description
%    Creates an xfig plot object based on a sky image with WCS coordinates
%    and determines the major and minor tics as well as the tic labels.
%    The underlying coordinates in the xfig plot are pixels (with integers
%    corresponding to the pixel centers).
%    The tic marks of each axis correspond to the "leading" (most varying)
%    coordinate along this axis (see wcs.xtype). There can/will be problems
%    when poles (and similar things) are within the field of view.
%    It is possible (and recommended) to specify major and minor tics and
%    the ticlabels (e.g., in order to use sexagesimal labels) of each axis
%    using the available qualifiers.
%    The alternative usage allows to specify the image and the wcs
%    information separately. They can be given either as a string of the
%    filename or directly as the image (array) and the WCS struct. In the
%    latter case they can be modified before.
%
%    WARNINGS:
%     - check WCS coordinates (the wcsfuns module uses less keywords
%       than, e.g., ds9)
%     - when plotting sub-images (i.e., cutting the image before
%       calling this function), make sure that the WCS structure is
%       consistent (e.g., modified center pixel)
%\example
%    variable filename = "img.fits";
%    variable p = wcs_axes_plot (filename);
%    p.plot_png (log(img); cmap="ds9b");
%    p.render("img.pdf");
%
%    % if, e.g., WCS has to be modified/corrected:
%    variable wcs = fitswcs_get_img_wcs(filename);
%    wcs.cdelt[1] *= -1; % can be necessary if a keyword was not read
%    variable p = wcs_axes_plot ( filename, wcs );
%
%    % use sexagesimal axis labels (example for declination from 44° 8' - 44° 20')
%    variable dec_major = [8:20:2]; % arcmin
%    variable y1major = 44 + dec_major / 60.0;
%    variable y1minor = 44 + [8:20:1] / 60.0; % minor in 1' steps
%    variable dec_ticlabels = array_map (String_Type, &sprintf, "$44^\\circ\\,%02d'$", dec_major);
%    variable p = wcs_axes_plot (filename; y1major = y1major, y1minor = y1minor, y1label = dec_ticlabels);
%    
%!%-
{
  variable img, wcs;
  
  switch(_NARGS)
  { case 1 : (img)       = (); wcs = img;}
  { case 2 : (img,wcs)   = (); }
  { help(_function_name()); return; }

  variable info = qualifier_exists("info");
  variable clr  = qualifier("axis_color","white");

  variable x,y;
  if (typeof(img) == String_Type) {
    try {
      x = fits_read_key (img, "ZNAXIS1"); % check if x and y swapped?
      y = fits_read_key (img, "ZNAXIS2");
    }
    catch AnyError: { vmessage("%s: error: could not read image size (keywords ZNAXIS1, ZNAXIS2) from file\n\ttry alternative usage and provide image",_function_name); };
  }
  else {
    variable size = array_shape(img);
    x = size[1]; y = size[0];
  }
  
  if (typeof(wcs) == String_Type) {
    try { wcs = fitswcs_get_img_wcs(wcs); }
    catch AnyError: { vmessage("%s: error: could not read WCS from file\n\ttry alternative usage and provide wcs directly",_function_name); };
  }
  %%%%%%%%%% get plot format %%%%%%%%%%%%
  % (unless both width and height are specified, the format is
  % calculted using the image dimensions)
  % -> currently CDELT1 != CDELT2 is not taken into account
  variable pw = qualifier("width",  14);
  variable ph = qualifier("height", 14);
  if (qualifier_exists("width")){
      ifnot (qualifier_exists("height"))
      ph = pw / (x+1.0) * (y+1); % added 0.5 on both sides (pixel centers are integer)
  }
  else {
    pw = ph / (y+1.0) * (x+1);
  }
  
  variable p = xfig_plot_new (pw,ph);
  
  p.world(-0.5 ,x+0.5, -0.5, y+0.5);
  % added 0.5 on both sides (pixel centers are integer)  

  %%%%%%%%%%%%%%%%%%%%%%%%%%% determine wcs of coordinate axis
  variable x0 = Integer_Type[y+1];
  variable y0 = Integer_Type[x+1];
  variable x_arr = [0:x]-0.5;
  variable y_arr = [0:y]-0.5;

  variable axes = Assoc_Type[WCSaxis_Type];
  variable k;
  foreach k (["x1","x2","y1","y2"]) axes[k] = @WCSaxis_Type;
  
  ( axes["x1"].y, axes["x1"].x ) = ( y0-0.5   , x_arr    );
  ( axes["x2"].y, axes["x2"].x ) = ( y0+y+0.5 , x_arr    );
  ( axes["y1"].y, axes["y1"].x ) = ( y_arr    , x0-0.5   );
  ( axes["y2"].y, axes["y2"].x ) = ( y_arr    , x0+x+0.5 );
  
  foreach k (axes) using ("values") {
    (k.ra , k.dec) = wcsfuns_deproject (wcs, k.y , k.x ); k.ra = pos_modulo(k.ra,360);
  }
  if (info){
    message("WCS coordinates of the plot axes:");
    foreach k (["x1","x2","y1","y2"]) {
      vmessage ("%s\tWCS (from %s): %.4e - %.4e\n\tWCS (from %s): %.4e - %.4e",
		k, wcs.ctype[1], min_max(axes[k].ra), wcs.ctype[0], min_max(axes[k].dec) );
    }
  }
  
  %%% get values for minor and major tics (in RA DEC)
  variable xmajor, xminor;
  (xmajor, xminor) = get_tic_pos_dezimal ([axes["x1"].ra,  axes["x2"].ra ]; n = pw/2.8);
  variable x1major = qualifier("x1major", qualifier("x2major", xmajor ) );
  variable x2major = qualifier("x2major", qualifier("x1major", xmajor ) );
  variable xmajor_is_set = qualifier_exists("x1major") or qualifier_exists("x2major") ;
  variable x1minor = qualifier("x1minor", qualifier("x2minor", xmajor_is_set ? 0 : xminor ) );
  variable x2minor = qualifier("x2minor", qualifier("x1minor", xmajor_is_set ? 0 : xminor ) );
  axes["x1"].maj_ra = x1major;
  axes["x1"].min_ra = x1minor;
  axes["x2"].maj_ra = x1major;
  axes["x2"].min_ra = x1minor;
    
  variable ymajor, yminor;
  (ymajor, yminor) = get_tic_pos_dezimal ([axes["y1"].dec, axes["y2"].dec]; n = ph/2.5);
  variable y1major = qualifier("y1major", qualifier("y2major", ymajor ) );
  variable y2major = qualifier("y2major", qualifier("y1major", ymajor ) );
  variable ymajor_is_set = qualifier_exists("y1major") or qualifier_exists("y2major") ;
  variable y1minor = qualifier("y1minor", qualifier("y2minor", ymajor_is_set ? 0 : yminor ) );
  variable y2minor = qualifier("y2minor", qualifier("y1minor", ymajor_is_set ? 0 : yminor ) );
  axes["y1"].maj_dec = y1major;
  axes["y1"].min_dec = y1minor;
  axes["y2"].maj_dec = y1major;
  axes["y2"].min_dec = y1minor;

  
  %%% calculate x,y values of tic marks
  foreach k (["x1","x2"]) {
    axes[k].maj_dec = interpol (axes[k].maj_ra, axes[k].ra, axes[k].dec);
    axes[k].min_dec = interpol (axes[k].min_ra, axes[k].ra, axes[k].dec);
    
    ( ,axes[k].major) = wcsfuns_project (wcs, axes[k].maj_ra, axes[k].maj_dec);
    ( ,axes[k].minor) = wcsfuns_project (wcs, axes[k].min_ra, axes[k].min_dec);
  }

  foreach k (["y1","y2"]) {
    axes[k].maj_ra = interpol (axes[k].maj_dec, axes[k].dec, axes[k].ra);
    axes[k].min_ra = interpol (axes[k].min_dec, axes[k].dec, axes[k].ra);
    
    ( axes[k].major,) = wcsfuns_project (wcs, axes[k].maj_ra, axes[k].maj_dec);
    ( axes[k].minor,) = wcsfuns_project (wcs, axes[k].min_ra, axes[k].min_dec);
  }

  %%%%%%%%% set tic labels
  % here it is currently assumed that the most varying coordinate on the x-axes is
  % RA (or wcs.ctype[1]) and DEC (or wcs.ctype[0]) for the y-axes
  axes["x1"].label = qualifier("x1label", axes["x1"].maj_ra  );
  axes["x2"].label = qualifier("x2label", 0 );
  axes["y1"].label = qualifier("y1label", axes["y1"].maj_dec );
  axes["y2"].label = qualifier("y2label", 0 );
  
  %%%%%%%%% set axes parameters
  p.x1axis(; major = axes["x1"].major, minor=axes["x1"].minor, ticlabels=axes["x1"].label, color=clr);
  p.x2axis(; major = axes["x2"].major, minor=axes["x2"].minor, ticlabels=axes["x2"].label, color=clr);
  p.y1axis(; major = axes["y1"].major, minor=axes["y1"].minor, ticlabels=axes["y1"].label, color=clr);
  p.y2axis(; major = axes["y2"].major, minor=axes["y2"].minor, ticlabels=axes["y2"].label, color=clr);

  if (qualifier_exists("return_axes"))
    return p, axes;
  else
    return p;
}

