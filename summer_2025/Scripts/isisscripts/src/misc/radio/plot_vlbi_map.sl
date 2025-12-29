require( "xfig" );
require( "gcontour" );
require( "png" ); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINITION OF WCS SYSTEM FOR AXIS SCALING %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
  private define mJy_wcs_func (map, cd)
  {
    variable mu = cd.mu, sigma = cd.sigma, nsigma = cd.nsigma, mx = cd.max, mn = cd.min;
    variable clrcut = cd.clrcut, neglog = cd.neglog, frac   = cd.frac;
    variable lim    = mu+nsigma*sigma;
    variable scl    = clrcut ? 1 : frac*log (mx/lim)/(lim-mn)/(1.-frac);
    variable shft   = log ((lim-mu)/sigma) - lim*scl ; 

    variable is_array = typeof (map)==Array_Type;
    variable x = 1.0*[@map]; % make sure that it is Double_Type, otherwise TypeMismatchError possible
    variable i1 = where(x >  lim);
    variable i2;
    if (neglog)
    {
      i2 = where(-lim <= x <= lim);
      variable i3 = where(x <  -lim);
      x[i2] = clrcut ? lim*scl : x[i2] * scl;
      x[i3] = clrcut ? lim*scl : -log( (-x[i3]+mu)/sigma ) + shft;
    }
    else
    {
      i2 = where(x <=  lim);
      x[i2] = clrcut ? lim*scl : x[i2] * scl;
    }
    x[i1] = log( (x[i1]-mu)/sigma ) - shft;
    return is_array ? x : x[0] ;
  }

  private define mJy_wcs_invfunc (map,cd)
  {
    variable mu = cd.mu, sigma = cd.sigma, nsigma = cd.nsigma, mx = cd.max, mn = cd.min;
    variable clrcut = cd.clrcut, neglog = cd.neglog, frac   = cd.frac;
    variable lim    = mu+nsigma*sigma;
    variable scl    = clrcut ? 1 : frac*log (mx/lim)/(lim-mn)/(1.-frac);
    variable shft   = log ((lim-mu)/sigma) - lim*scl ; 
    lim    = lim * scl;

    variable is_array = typeof (map)==Array_Type;
    variable x = 1.0*[@map];
    variable i1 = where(x >  lim);
    variable i2;
    if (neglog)
    {
      i2 = where(-lim <= x <= lim);
      variable i3 = where(x <  -lim);
      x[i2] = x[i2] / scl;
      x[i3] = -exp(-(x[i3]-shft))*sigma +mu;
    }
    else
    {
      i2 = where(x <=  lim);
      x[i2] = x[i2] / scl;
    }
    x[i1] = exp(x[i1]+shft)*sigma + mu;
    return is_array ? x : x[0] ;
  }

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREVIOUSLY USED: atan for axis scaling:
%%%%%%
%  private define mJy_wcs_func (x,cd) {atan(x/20.);}
%  private define mJy_wcs_invfunc (x,cd) {tan(x)*20.;}
%  xfig_plot_add_transform ("mJy", &mJy_wcs_func, &mJy_wcs_invfunc, struct{mu=mu,sigma=sigma,nsigma=nsigma};);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define plot_vlbi_map()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_vlbi_map}
%\synopsis{creates an image of the VLBI map with transparent background using a .fits file (provided by DIFMAP)}
%\usage{plot_vlbi_map(String_Type \code{fitsfile}, [String_Type \code{fitsfile (polflux)}], String_Type \code{filename})}
%\altusage{plot_vlbi_map(Struct_Type \code{img_struct}, String_Type \code{filename})}
%\qualifiers{
%\qualifier{color_scheme [="ds9b"]}{  select a color scheme for the image}
%\qualifier{dec_frac [={0.0,1.0}]}{   declination range of the image by
%                                selecting a fraction of the file's range}
%\qualifier{ra_frac [={0.0,1.0}]}{    right ascension range of the image by
%                                selecting a fraction of the file's range}
%\qualifier{dec_mas [={min,max}]}{    set declination range of the image directly in mas.
%                                overwrites \code{dec_frac}}
%\qualifier{ra_mas [={min,max}]}{     set right ascension range of the image directly in mas
%                                (analog to \code{dec_mas})}
%\qualifier{fit_noise [=1]}{          fit the noise of a map}                                
%\qualifier{n_sigma [=3.0]}{          start color scaling at \code{n_sigma*sigma}}
%\qualifier{cont_scl [=2.0]}{         set factor to change the separation between\n
%                                contour levels, the levels are placed at:\n
%                                \code{cont_scl^[0,1,...]*n_sigma*sigma}}
%\qualifier{cont_lvl [=[c1,c2,..]}{   set contour levels [Jy] manually, overwrites\n
%                                other contour parameters}
%\qualifier{cont_width [=2]}{         set width of contour lines}
%\qualifier{plot_cont [=1]}{          set to 0 in order to plot without contour lines}
%\qualifier{cont_depth [=2]}{         set contour-line depth}
%\qualifier{plot_vec [=0]}{           set to 1 in order to plot with vectors
%                                (requires second fits file with polarized flux density)}
%\qualifier{vec_density [=5]}{        density of EVPA vectors; possible values: [1..10]}
%\qualifier{vec_width [=1]}{          width of EVPA vectors}
%\qualifier{vec_color [="black"]}{    color of EVPA vectors}
%\qualifier{plot_clr_img [=1]}{       set to 0 in order to plot without colored image}
%\qualifier{plot_clr_key [=1]}{       set to 0 in order to plot without key for color scale}
%\qualifier{plot_scale_arrows [=1]}{  set to 1 in order to plot with arrows denoting the size scalesin the map}
%\qualifier{clrcut [=0]}{             set to 1 in order to start the color scale at the
%                                significant emission (i.e., no color scaling below)}
%\qualifier{clrmin [=min(image)]}{    set minimum value [Jy] for color scale (see png_gray_to_rgb)}
%\qualifier{clrmax [=max(image)]}{    set maximum value [Jy] for color scale (see png_gray_to_rgb)}
%\qualifier{clrmu [from fit_gauss_to_img_noise]}{set noise level of the image [Jy] for color scale
%                                (mean value of regions without significant emission)}
%\qualifier{clrsig [from fit_gauss_to_img_noise]}{set width of noise (1-sigma) [Jy] for color scale,
%                                for identical color scale (e.g., in order to compare
%                                different images) the following qualifiers have to be set:
%                                clrmin, clrmax, clrmu, clrsig}
%\qualifier{colmap_depth}{            set depth of png map}
%\qualifier{bkg_white}{               set white map below clrmin, if clrcut is set, clrmin equals
%                                n_sigma above the mean background.}
%\qualifier{quadratic}{               create a quadratic image, by default the scaling is such that
%                                scaling in RA and DEC is equal}
%\qualifier{plotsize [=14]}{          size of the plot (scaling of image relative to font size)}
%\qualifier{src_name [=default]}{     set the name of the source, by default the name\n
%                                is read from the .fits file
%                                set to NULL for not plotting a source name}
%\qualifier{obs_date [=default]}{     set the observation date, by default the observation\n
%                                date is read from the .fits file
%                                set to NULL for not plotting a observation date}
%\qualifier{axis_color [="gray"]}{    set axis color}
%\qualifier{source_color [="gray"]}{  set color of source name}
%\qualifier{date_color [="gray"]}{    set color of observation date}
%\qualifier{date_depth [=1]}{         set depth of observation date}
%\qualifier{source_depth [=1]}{       set depth of source name}
%\qualifier{cont_color [="gray"]}{    set color of contour lines}
%\qualifier{neg_cont_color [="gray"]}{set color of contour lines below noise level}
%\qualifier{date_xy [=[0.95,0.95]]}{  set world0 coordinates of date string}
%\qualifier{plot_beam [=1]}{          set to 1 in order to plot the beam}
%\qualifier{plot_components}{         set to plot model components on top of image}
%\qualifier{model_circs}{             set to plot model component circles on top of image}
%\qualifier{pos_comp_color [="seagreen"]}{set for color of model components with positive flux}
%\qualifier{neg_comp_color [="seagreen"]}{set for color of model components with negative flux}
%\qualifier{beam_color [="gray"]}{    set color of the beam}
%\qualifier{no_labels}{:	        plot no labels}
%\qualifier{colmap_label}{:	        set label of colormap}
%\qualifier{neglog [=0]}{             use log scale for negative flux values}
%\qualifier{frac [=0.1]}{:	        fraction to which the linear region below n_sigma*sigma
%                                is scaled in the color scale (if clrcut != 0)}
%\qualifier{funit [="mJy"]}{          unit of the color scale bar, can be changed from "mJy" to "Jy"}
%\qualifier{xyunit [="mas"]}{         unit of the x/y labels, can be changed between "mas", "arcsec", "arcmin" and "deg";
%                                       assumption: FITS header sets unit "mas"}
%\qualifier{return_xfig}{             set qualifier to return the xfig object(s) instead than
%                                rendering directly}
%}
%\description
%    This function creates an image of a jet using the .fits file provided
%    by DIFMAP.
%    Alternatively a structure with the required fields (as obtained
%    with the function \code{read_difmap_img}) can be given directly to
%    \code{plot_vlbi_map} instead of the name of a fits file.
%    The color scheme can be selected and contour lines are calculated.
%    The format of the output file depends on the suffix of the given
%    \code{filename}. Possible formats of the output file are PDF, EPS,
%    PNG, GIF, etc.
%
%    If plot_vlbi_map is called with three arguments, the first two of them beiing maps,
%    the code will determine the noise level of the second map and cut the first
%    map at the given sigma level. A typical application would be to plot the
%    distribution of electric vectors or the degree of polarization only where
%    the polarized flux is significant.
%\seealso{read_difmap_fits,fit_gauss_to_img_noise}
%!%-
{
  variable s,pol,filename;
  switch(_NARGS)
  { case 2: (s,filename) = (); }
  { case 3: (s,pol,filename) = (); }
  { help(_function_name()); return; }

  variable color_scheme = qualifier("color_scheme", "ds9b");
  variable dec_frac     = qualifier("dec_frac",{0.,1.});
  variable ra_frac      = qualifier("ra_frac",{0.,1.});
  variable fit_noise    = qualifier("fit_noise",1); 
  variable nsigma       = qualifier("n_sigma",3.0);  
  variable plot_cont    = qualifier("plot_cont",1);
  variable cont_depth   = qualifier("cont_depth",2);
  variable plot_vec     = qualifier("plot_vec",0);
  variable plot_pdeg     = qualifier("plot_pdeg",0);  
  variable plot_clr_img = qualifier("plot_clr_img",1);
  variable plot_clr_key = qualifier("plot_clr_key",1);
  variable plot_scale_arrows = qualifier("plot_scale_arrows",0);  
  variable clrcut       = qualifier("clrcut",0);
  variable bkg_white    = qualifier("bkg_white",0);  
  variable no_labels	= qualifier("no_labels");
  variable colmap_label	= qualifier("colmap_label",NULL);
  variable funit	= qualifier("funit","mJy");
  variable xyunit	= qualifier("xyunit","mas");  
  variable frac         = _max ( 1e-6, _min(1, qualifier("frac"  ,0.1)) );
  variable neglog       = qualifier("neglog",0);  
  variable plot_components = qualifier("plot_components");
  variable comps;

  % if filename instead of struct provided read the fitsfile:
  if (typeof(s) == String_Type)
  {
    if ((plot_cont or plot_clr_img) and fit_noise!=0) {
      comps = fits_read_table(s);
      s = read_difmap_fits (s ; fit_noise);
    }
    else {
      comps = fits_read_table(s);
      s = read_difmap_fits (s);
    }
  }

  variable unit_fac,unit_lab_x,unit_lab_y;
  switch (xyunit)
  { case "mas" : unit_fac=1.; }
  { case "arcsec" : unit_fac=1./1e3; }
  { case "arcmin" : unit_fac=1./1e3/60; }
  { case "deg" : unit_fac=1./1e3/3600; }  
  unit_lab_x=sprintf("Relative RA [%s]",xyunit);
  unit_lab_y=sprintf("Relative DEC [%s]",xyunit);  
  
  % correct ra/dec steps and beam smaj/smin for given unit
  s.ra_steps *= unit_fac;
  s.dec_steps *= unit_fac;
  s.beam_smaj *= unit_fac;
  s.beam_smin *= unit_fac;  
  
  if (plot_cont==1 and fit_noise==0)
    throw RunTimeError, sprintf("%s: provided structure includes no proper noise information for contour determination. Set plot_cont=0 instead!", _function_name());
  
  s.src_name   = qualifier("src_name", s.src_name );
  s.date_str   = qualifier("obs_date", s.date_str );

  variable map          = @(s.img); % in order not to modify the original image. 
  variable shape = array_shape(map);
  if ( length(shape) == 2 )
  {
    variable dec_len = shape[0] - 1;
    variable ra_len  = shape[1] - 1;
  }
  else
  {
    throw RunTimeError, sprintf("%s: multiple images for different FREQ or STOKES?\n\t-> modify the function %s",
				_function_name(), _function_name());
  }
  
  if (plot_cont or plot_clr_img)
  {
    variable map_min = min(map);
    variable map_max = max(map);

    if (s.mu == NULL or s.sigma == NULL)
      vmessage(sprintf("%s: provided structure includes no proper noise information", _function_name()));
%      throw RunTimeError, sprintf("%s: provided structure includes no proper noise information", _function_name());

    variable clrmin = qualifier("clrmin", clrcut ? s.mu+nsigma*s.sigma : map_min);
    variable clrmax  = qualifier("clrmax", map_max );
    variable clrmu   = qualifier("clrmu",  (s.mu!=NULL ? s.mu : 0 ));
    variable clrsig  = qualifier("clrsig", (s.sigma!=NULL ? s.sigma : 1e-3));

    if (qualifier_exists("bkg_white")) map[where(map<clrmin)]=-1000; % set white background level
    
    variable cd = struct{mu=clrmu,sigma=clrsig,nsigma=nsigma,max=clrmax,min=clrmin,clrcut=clrcut,
      frac = frac, neglog=neglog};
  }

  % cut maps on user demand --------
  variable idx_cut_x,idx_cut_y;
  ifnot (qualifier_exists("ra_mas") or qualifier_exists("dec_mas"))
  {
    idx_cut_x = [int(dec_len*dec_frac[0]):int(dec_len*dec_frac[1])];
    idx_cut_y = [int(ra_len*ra_frac[0]):int(ra_len*ra_frac[1])];
    map = map[idx_cut_x,idx_cut_y];
  }
  % if map has been cut, the index of the center pixel has to be corrected:
  variable ra_px_center  = s.ra_px_center  - int(ra_len*ra_frac[0]);   % right ascensin center pixel
  variable dec_px_center = s.dec_px_center - int(dec_len*dec_frac[0]); % declination center pixel
  
  variable axis_clr = qualifier("axis_color","gray"); 
  variable axis_dep = qualifier("axis_depth",100); 
  variable map_shape = array_shape(map);
  variable ra_min  = -( ra_px_center  - 0.5                 )*s.ra_steps; % adding half pixel (0.5) such that pixel centers correspond to integers for WCS conversion
  variable ra_max  =  ( map_shape[1]  - (ra_px_center-0.5)  )*s.ra_steps;
  variable dec_min = -( dec_px_center - 0.5                 )*s.dec_steps;
  variable dec_max =  ( map_shape[0]  - (dec_px_center-0.5) )*s.dec_steps;

  if (qualifier_exists("ra_mas") or qualifier_exists("dec_mas"))
  {
    variable ra_mas = qualifier("ra_mas",  {ra_min,ra_max});
    if (ra_mas[0] < ra_mas[1]) { (ra_mas[0],ra_mas[1]) = (ra_mas[1],ra_mas[0]);}
    ra_mas  = { _min( ra_mas[0],ra_min) ,  _max(  ra_mas[1],ra_max) };
    variable dec_mas = qualifier("dec_mas", {dec_min,dec_max});
    if (dec_mas[0] > dec_mas[1]) { (dec_mas[0],dec_mas[1]) = (dec_mas[1],dec_mas[0]);}
    dec_mas = { _max(dec_mas[0],dec_min) , _min(dec_mas[1],dec_max) };
    idx_cut_x = [int(dec_mas[0]/s.dec_steps + (dec_px_center-0.5) ) : int(dec_mas[1]/s.dec_steps + (dec_px_center-0.5) )-1];
    idx_cut_y = [int( ra_mas[0]/ s.ra_steps + ( ra_px_center-0.5) ) : int( ra_mas[1]/ s.ra_steps + ( ra_px_center-0.5) )-1];      
    map = map[idx_cut_x,idx_cut_y];
    ra_px_center  -= int( ra_mas[0]/s.ra_steps  + (ra_px_center-0.5) );    
    dec_px_center -= int(dec_mas[0]/s.dec_steps + (dec_px_center-0.5) );
    ra_min  =  ra_mas[0];  ra_max = ra_mas[1];
    dec_min = dec_mas[0]; dec_max = dec_mas[1];
  }

  if (plot_cont)
  {
    variable cl    = qualifier("cont_scl", 2.);
    variable n_pos = int(log( (map_max - s.mu) / (nsigma*s.sigma)) / log(cl));
    variable n_neg = int(log( (s.mu - map_min) / (nsigma*s.sigma)) / log(cl));
    variable lvls  = qualifier("cont_lvl", s.mu + [-(cl^[0:n_neg]),cl^[0:n_pos]]*nsigma*s.sigma );
    variable  gct  = gcontour_compute(map,lvls);  
  }

  variable image_size  = qualifier("plotsize",14);

  variable pwidth  = abs(ra_min  - ra_max);
  variable pheight = abs(dec_min - dec_max);
  if (qualifier_exists("quadratic")){pwidth = 1; pheight = 1;} % create quadratic image
  variable image_scale = _max(pwidth, pheight);
  pwidth  *= image_size/image_scale;
  pheight *= image_size/image_scale;

  variable w1 = xfig_plot_new (pwidth, pheight);
  w1.world( ra_min , ra_max, dec_min, dec_max ;color=axis_clr);
  w1.axis(; color =axis_clr, depth=axis_dep, ticlabels2=0);

  if (plot_scale_arrows) {
    variable forw_arr = xfig_create_arrow(; arrow_type=2, arrow_style=1);
    variable back_arr = xfig_create_arrow(; arrow_type=2, arrow_style=1);
    w1.add_object(xfig_new_polyline([-2,10], [0,0]; forward_arrow=forw_arr,backward_arrow=back_arr));
  }

  if (plot_clr_img)
  {
    map = mJy_wcs_func(map,cd);
    variable colmap = png_get_colormap(color_scheme);
    %colmap[0] = 16777215; % set base always to white
    png_add_colormap ("ds9b",colmap);

    % do w1.plot_png separately to account for alpha channel: 
    variable rgbmap = png_gray_to_rgb (map, colmap;
				       gmin = mJy_wcs_func(clrmin,cd),
				       gmax = mJy_wcs_func(clrmax,cd));
    % make white background transparent for overlay images
    variable alpha = @rgbmap;    
    alpha[where(rgbmap==0xFFFFFF)]=0;
    alpha[where(rgbmap!=0xFFFFFF)]=255;
    variable r=(rgbmap & 0x00FF0000) shr 16;
    variable g=(rgbmap & 0x0000FF00) shr 8;
    variable b=(rgbmap & 0x000000FF) shr 0;

    variable random = rand_int(1,1e3,1)[0];
    png_write_flipped (sprintf("%spng_alpha_%u.png",xfig_get_tmp_dir,random), (alpha<<24)+(r<<16)+(g<<8)+b, 1);
    w1.plot_png(sprintf("%spng_alpha_%u.png",xfig_get_tmp_dir,random);
		cmap=color_scheme,
		gmin = mJy_wcs_func(clrmin,cd),
		gmax = mJy_wcs_func(clrmax,cd),
	        depth = qualifier("colmap_depth",100)); % image in the background, other components should have smaller depth
  }
  variable i,ii,k;
  if (plot_cont)
  {
    map_shape = array_shape(map);
    _for i(0,length(lvls)-1,1)
      _for k(0,length(gct[i].x_list)-1,1) 
      {
	if (lvls[i] > s.mu)
	  w1.plot( (gct[i].x_list[k]+0.5) / map_shape[1] * ( ra_max-  ra_min) +  ra_min,
		   (gct[i].y_list[k]+0.5) / map_shape[0] * (dec_max- dec_min) + dec_min;
		   color= qualifier("cont_color","gray"), depth=cont_depth,width=qualifier("cont_width",2));
        else
	  w1.plot( (gct[i].x_list[k]+0.5) / map_shape[1] * ( ra_max-  ra_min) +  ra_min,
		   (gct[i].y_list[k]+0.5) / map_shape[0] * (dec_max- dec_min) + dec_min;
		   color=qualifier("neg_cont_color","gray"),line = 1, depth=cont_depth,width=qualifier("cont_width",2));
	% added 0.5 in order to have pixel centers as integers in WCS conversion
      }
  }

  %%%% if two maps are loaded, use the second one and its noise level to cut the first map  %%%%
  % the first map (EVPA map) will not be plotted in color scale but translated to EVPA vectors

  
  if (plot_vec and _NARGS==2) throw RunTimeError, sprintf("%s: second difmap fits file for polarized flux required for plotting EVPA vectors.", _function_name()); 
  else if (plot_vec and _NARGS==3)
  {
    variable P = read_difmap_fits (pol ; fit_noise); % load fits map with polarized flux
    variable pmap = @(P.img);
    pmap = pmap[idx_cut_x,idx_cut_y]; % cut P-map to same shape as loaded map
    %vmessage("pmap: ra_size=%u   dec_size=%u",length(pmap[0,*]),length(pmap[*,0]));
    %vmessage("pmap: min=%.3f   max=%.3f   P.mu+nsigma*P.sigma=%.3f",min(pmap),max(pmap),P.mu+nsigma*P.sigma);
    map[where(pmap<P.mu+nsigma*P.sigma)]=0.0; % set map to zero where P-map is below noise-defined threshold, map size remains the same.

    %vmessage("chimap: %u  entries == 0",length(where(map == 0.0)));
    %vmessage("chimap: %u  entries != 0",length(where(map != 0.0)));    
    map = map * PI/180.0; % deg -> rad
    variable arrows = xfig_new_polyline_list ();
    variable ra_dim = length(map[0,*]);
    variable dec_dim = length(map[*,0]);
    %vmessage("ra_min=%.3f  ra_max=%.3f  dec_min=%.3f  dec_max=%.3f",ra_min,ra_max,dec_min,dec_max);
    variable ra_pos = Double_Type[0];
    variable dec_pos = Double_Type[0];
    variable ra_dist = Double_Type[0];
    variable dec_dist = Double_Type[0];        
    _for i (0,dec_dim-1,1) {
      _for ii (0,ra_dim-1,1) {
	if (map[i,ii] != 0.0) {	  
	  dec_pos = [dec_pos,dec_min+(i+0.5)*s.dec_steps];
	  ra_pos = [ra_pos,ra_min+(ii+0.5)*s.ra_steps];
	  variable len_vec = min([abs(ra_min-ra_max),abs(dec_min-dec_max)])*0.2*(pmap[i,ii]/max(pmap));
	  ra_dist = [ra_dist,sin(map[i,ii])*len_vec/2.];
	  dec_dist = [dec_dist,cos(map[i,ii])*len_vec/2.];
	  %vmessage("sin(%.3f)=%.3f   cos(%.3f)=%.3f",map[i,ii]*180./PI,sin(map[i,ii]),map[i,ii]*180./PI,cos(map[i,ii]));
	}
      }
    }
    if ( 1<= qualifier("vec_density",5) <= 10 ) variable idx = int([0:length(ra_pos)-1:#int(length(ra_pos)/(11.-qualifier("vec_density",5)))]);
    else throw RunTimeError, sprintf("%s: qualifier \"vec_density\" requires values within [1,10]", _function_name());
    ra_pos=ra_pos[idx];
    dec_pos=dec_pos[idx];
    ra_dist=ra_dist[idx];
    dec_dist=dec_dist[idx];    
    _for i (0,length(ra_pos)-1,1) w1.plot([ra_pos[i]-ra_dist[i],ra_pos[i]+ra_dist[i]],[dec_pos[i]-dec_dist[i],dec_pos[i]+dec_dist[i]];line=0,width=qualifier("vec_width",1),color=qualifier("vec_color","black"),depth=0); 
  }

    
  ifnot (qualifier_exists("no_labels")){
  w1.xlabel(unit_lab_x);
  w1.ylabel(unit_lab_y);}
  
  if (s.src_name != NULL)
  {
    w1.xylabel(0.05,0.95,s.src_name,-0.5,0.5; world0, depth=qualifier("source_depth",1), color=qualifier("source_color","gray"));
  }
  if (s.date_str != NULL)
  {
    w1.xylabel(qualifier("date_xy",[0.95,0.95])[0],qualifier("date_xy",[0.95,0.95])[1],s.date_str, 0.5,0.5; world0, depth=qualifier("date_depth",1), color=qualifier("date_color","gray"));
  }

  if (qualifier("plot_beam",1) == 1) {
    variable beam = xfig_new_ellipse(s.beam_smin,s.beam_smaj);  % major axis to north, pos_angle = 0
    %  vmessage("minor: %f \tmajor: %f\tangle %f",s.beam_smin,s.beam_smaj,s.beam_pang);  % major axis to north, pos_angle = 0
    variable beam_clr = qualifier("beam_color","gray");
    beam.set_pen_color(beam_clr);
    beam.rotate(vector(0,0,1),s.beam_pang); % rotation for position angle in rad ("rotate" rotates counter clockwise),
    beam.scale( pwidth/abs(ra_max-ra_min) , pheight/abs(dec_max-dec_min) , 0);
    %  vmessage("RA:  %f-%f",ra_min,ra_max);
    %  vmessage("DEC: %f-%f",dec_min,dec_max);
    beam.translate(vector(0.5-s.beam_smaj*pwidth/(ra_max-ra_min),0.5+s.beam_smaj*pheight/(dec_max-dec_min),0));
    beam.area_fill=20;
    beam.fill_color=xfig_lookup_color(beam_clr);
    w1.add_object(beam);
  }
  
  if (qualifier_exists("plot_components")) {
    comps.deltax *= 3.6e6;
    comps.deltay *= 3.6e6;
    variable pos_comps = struct_filter(comps, where(comps.flux > 0); copy);
    variable neg_comps = struct_filter(comps, where(comps.flux < 0); copy);
    w1.plot(pos_comps.deltax, pos_comps.deltay; sym="+",width=2,color=qualifier("pos_comp_color","seagreen"),depth=1);
    w1.plot(neg_comps.deltax, neg_comps.deltay; sym="*",width=2,color=qualifier("neg_comp_color","seagreen"),depth=1);
    if (qualifier_exists("model_circs")) {
      _for k (0,length(pos_comps.deltax)-1,1) w1.plot(pos_comps.deltax[k], pos_comps.deltay[k];
						      sym="circle",size=3.*pos_comps.major_ax[k]*3.6e6,width=2,color=qualifier("pos_comp_color","seagreen"),depth=1);
      _for k (0,length(neg_comps.deltax)-1,1) w1.plot(neg_comps.deltax[k], neg_comps.deltay[k];
						      sym="circle",size=3.*pos_comps.major_ax[k]*3.6e6,width=2,color=qualifier("neg_comp_color","seagreen"),depth=1);
    }
  }
  

  if (plot_clr_key && plot_clr_img)
  {
    xfig_plot_add_transform ("mJy", &mJy_wcs_func, &mJy_wcs_invfunc, cd;);
    variable w2 = xfig_plot_new (pwidth/25., pheight);
    if (clrcut)
    {
      w2.world (0, 1, clrmin*(funit=="mJy" ? 1000 : 1), clrmax*(funit=="mJy" ? 1000 : 1) );
      w2.y1axis (;ticlabels=0, wcs="log", color = "white");
      w2.y2axis (;on,wcs="log",color="black");
    }
    else
    {
      variable minor=Double_Type[0];
      variable major=Double_Type[0];
      variable majbase, minbase;
      variable logmin = nint(floor(log10(clrmu+nsigma*clrsig)));
      variable logmax = nint(floor(log10(clrmax)));
      if (logmax-logmin < 4) { majbase = [1,2,5]; minbase = [3,4,6,7,8,9];}
      else  { majbase = [1]; minbase = [2:9];}
    
      variable j;
      if (logmax-logmin < 10) % arbitrary value to avoid giant loops, if logmin --> -inf
      { _for j(logmin, logmax,1)
	{
	  major = [major, (10^j)*majbase];
	  minor = [minor, (10^j)*minbase];
	}
      }
      if (neglog) {
	minor = [minor[where(minor != 0)],-minor[where(minor != 0)]];
	major = [0,major[where(clrmu+nsigma*clrsig <= major <= clrmax)],-major[where(clrmin <= -major <= clrmu-nsigma*clrsig)]];
      }
      else {
	minor = [minor, major[where(clrmu+nsigma*clrsig > major)], -minor, -major];
	major = [0,major[where(clrmu+nsigma*clrsig <= major <= clrmax)]];
      }
      variable tl = major;
      if(funit=="mJy") tl *= 1000;
      w2.world (0, 1, clrmin, clrmax);
      w2.y1axis (;      wcs="mJy", color = "white", major=major, minor=minor, ticlabels=0 );
      w2.y2axis (;  on, wcs="mJy", color = "black", major=major, minor=minor, ticlabels=tl);
    }
    w2.xaxis (;off);
    if (qualifier_exists("no_labels")==0 and colmap_label==NULL){ w2.y2label ("Total Intensity ["+(funit=="mJy" ? funit : "Jy")+"/beam]");}
    else if (qualifier_exists("no_labels")==0 and colmap_label != NULL) w2.y2label(colmap_label);
    
    variable scale_array = _reshape([mJy_wcs_func(clrmin, cd):
		     mJy_wcs_func(clrmax, cd):#256],[256,1]);
%    scale_array = mJy_wcs_invfunc (scale_array,cd);
    w2.plot_png (scale_array; cmap = color_scheme);
    if (qualifier_exists("return_xfig"))
      return w1,w2;
    else
      xfig_new_hbox_compound (w1, w2, 0.4).render(filename);
  }
  else
  {
    if (qualifier_exists("return_xfig"))
      return w1;
    else
      w1.render(filename);
  }
}

