%%%%%%%%%%%%%%%%
define make_spix()
%%%%%%%%%%%%%%%%
%!%+
%\function{make_spix}
%\synopsis{creates a spectral index map using two .fits files (provided by DIFMAP)}
%\usage{make_spix(String_Type \code{name_lo}, String_Type \code{name_hi});}
%\qualifiers{
%\qualifier{iterations}{[=1] set number of translations to average over}
%\qualifier{cc}{[=cc.fits] name of the cross correlation map.  Will generate
%                              one if the file does not exist.}
%\qualifier{lothreshold}{[=NULL] if image has a pixel below this value it's set to
%                              this value. also criterion for showing spectral index if
%                              req_both_bands is set to 1}
%\qualifier{hithreshold}{[=NULL] if image has a pixel below this value it's set to
%                              this value. also criterion for showing spectral index if
%                              req_both_bands is set to 1}
%\qualifier{shift}{[={NULL,NULL}] define the shift of the second image wrt the first
%                              in format {x,y} in mas}
%\qualifier{crpix_shift}{[=0.] Extra shift for converting mas in pixel. In the past, 0.5 was used, 
%					but default is now  0., as only a relative is needed}
%\qualifier{dec_step}{[=NULL] pixel size in declination (value>0). 
%				 	Default value is the largest pixel size of the two images}
%\qualifier{dec_size}{[=NULL] mapsize size in declination. 
%					Default value is the largest map size of the two images}
%\qualifier{ra_step}{[=NULL] pixel size in right ascension (value>0). 
%					Default value is the largest pixel size of the two images}
%\qualifier{ra_size}{[=NULL] mapsize size in right ascension
%					Default value is the largest map size of the two images}
%\qualifier{beam}{[=[NULL,NULL,NULL]] defines beam for restoring the two images 
%						[semi-major axis, semi-minor axis, position angle] 
%						in mas (major and minor axis) and degree (position angle)}
%\qualifier{req_both_bands}{[=0] only make calculations if both bands are above the
%                              noise level}
%\qualifier{fit_noise}{[=1] set to 0 to use fits header for noise information}
%\qualifier{lo_nsigma}{[=3] number of standard deviations from mean to define
%                              noise limit.  Only matters if fit_noise==1,
%                              overrides lothreshold}
%\qualifier{hi_nsigma}{[=3] number of standard deviations from mean to define
%                              noise limit.  Only matters if fit_noise==1,
%                              overrides hithreshold}
%\qualifier{n_beams}{[=3] size of beam to exclude from core on correlation
%                              calculation}
%\qualifier{excl_core}{[=1] set to 0 if you do not want the program to
%                              automatically exclude the core from correlation calculations}
%\qualifier{overwrite}{overwrite the restore fits files (if already existing)}
%}
%\description
%    This function creates a spectral index (F=v^a) map from two fits files provided by
%    DIFMAP.  A cross correlation fits image is generated and the images are shifted
%    by the best (iterations) translations and the spectral index, etc. are
%    calculated for each translations. The values are averaged with the weights
%    given by the corresponding value in the cc image.
%    If the provided images do not have the same size, resolution and beam, the
%    functions difmap_restore and enclosing_ellipse are used to obtain images with
%    these properties. It is also possible to specify a desired map size and 
%    pixel size for both axes individually, otherwise  the default value from the comparison 
%    of both images will be used. Note, that changing the pixel size may require changing the maps size as well.
%
%    It returns a structure that holds the information for the following values\n
%    Use the structure as an input to\n
%    struct_name.spec_map      ->   matrix of calculated spectral index values\n
%    struct_name.stdev         ->   matrix of weighted stdevs of calculated values\n
%    struct_name.avg_lum       ->   matrix of weighted average of the summed BRIGHTNESS of the images\n
%    struct_name.weights       ->   matrix of sum of weights used for calculations in each pixel\n
%    struct_name.avg_shift     ->   average shifts in a 2-element array [x_shift,y_shift]\n
%    struct_name.shift_weight  ->   weights for calculating avg shift [x_weight,y_weight]\n
%    struct_name.avg_shift_pixel -> average shift in pixel [x_shift_pixel, y_shift_pixel]\n
%    struct_name.ra_px_center  ->   x index of center pixel\n
%    struct_name.ra_steps      ->   x mas per pixel\n
%    struct_name.dec_px_center ->   y index of center pixel\n
%    struct_name.dec_steps     ->   y mas per pixel\n
%    struct_name.major         ->   semi major axis of beam in mas
%    struct_name.minor         ->   semi minor axis of beam in mas
%    struct_name.source        ->   source name
%    struct_name.date          ->   dates of images
%    struct_name.posang        ->   position angle of beam in degrees
%\seealso{plot_spix, write_spix, read_spix, difmap_restore, enclosing_ellipse}
%!%-
{
  variable name_lo, name_hi;
  switch(_NARGS)
  { case 2: (name_lo, name_hi) = (); }                                          
  { help(_function_name()); return; }
  
  variable naxis1_lo = fits_read_key (name_lo, "NAXIS1");
  variable cdelt1_lo = fits_read_key (name_lo, "CDELT1");
  variable naxis2_lo = fits_read_key (name_lo, "NAXIS2");
  variable cdelt2_lo = fits_read_key (name_lo, "CDELT2");
  variable bmaj_lo   = fits_read_key (name_lo, "BMAJ")  ;
  variable bmin_lo   = fits_read_key (name_lo, "BMIN")  ;
  variable bpa_lo    = fits_read_key (name_lo, "BPA")   ;

  variable naxis1_hi = fits_read_key (name_hi, "NAXIS1");
  variable cdelt1_hi = fits_read_key (name_hi, "CDELT1");
  variable naxis2_hi = fits_read_key (name_hi, "NAXIS2");
  variable cdelt2_hi = fits_read_key (name_hi, "CDELT2");
  variable bmaj_hi   = fits_read_key (name_hi, "BMAJ")  ;
  variable bmin_hi   = fits_read_key (name_hi, "BMIN")  ;
  variable bpa_hi    = fits_read_key (name_hi, "BPA")   ;
  
  %% check if beams, map sizes, and resolution are identical in both images
  %% and create images with such properties if this is not the case
  if (
      naxis1_lo  !=  naxis1_hi or cdelt1_lo  !=  cdelt1_hi or
      naxis2_lo  !=  naxis2_hi or cdelt2_lo  !=  cdelt2_hi or
      bmaj_lo    !=  bmaj_hi   or bmin_lo    !=  bmin_hi   or
      bpa_lo     !=  bpa_hi    
     )
  {
    vmessage("Beam, map size, or resolution are not identical in both images!");
    vmessage("Using function difmap_restore to obtain two comparable images.");
    variable new_smajor, new_sminor, new_posang; % semimajor axis, difmap uses major axis -> *0.5
    if(qualifier_exists("beam")) {
	variable new_beam = qualifier("beam");
	new_smajor = new_beam[0];
	new_sminor = new_beam[1];
	new_posang = new_beam[2];
    }
    else {
	vmessage("Calculating enclosing beam.");
	(new_smajor, new_sminor, new_posang) = enclosing_ellipse( 3.6e6*0.5*bmaj_lo, 3.6e6*0.5*bmin_lo, bpa_lo/180.*PI,
							      3.6e6*0.5*bmaj_hi, 3.6e6*0.5*bmin_hi, bpa_hi/180.*PI);
	new_posang*=180./PI;
   }
    variable ra_pixel   = _max(naxis1_lo,naxis1_hi);
    variable dec_pixel  = _max(naxis2_lo,naxis2_hi);
    variable ra_length  = 3.6e6*_max( abs(naxis1_lo*cdelt1_lo) , abs(naxis1_hi*cdelt1_hi) );
    variable dec_length = 3.6e6*_max( abs(naxis2_lo*cdelt2_lo) , abs(naxis2_hi*cdelt2_hi) );
    variable restore_qualifiers = struct {xsize = ra_pixel , xstep = ra_length / ra_pixel ,
			      ysize = dec_pixel, ystep = dec_length/dec_pixel};
    if(qualifier_exists("ra_step"))
	restore_qualifiers.xstep = qualifier("ra_step");
    if(qualifier_exists("ra_size"))
	restore_qualifiers.xsize = qualifier("ra_size");
    if(qualifier_exists("dec_step"))
	restore_qualifiers.ystep = qualifier("dec_step");
    if(qualifier_exists("dec_size"))
	restore_qualifiers.ysize = qualifier("dec_size");

    if (qualifier_exists("overwrite")) restore_qualifiers = struct_combine (restore_qualifiers, "overwrite");
    name_lo = difmap_restore (name_lo, new_smajor, new_sminor, new_posang;; restore_qualifiers);
    name_hi = difmap_restore (name_hi, new_smajor, new_sminor, new_posang;; restore_qualifiers);
    if (name_lo == NULL or name_hi == NULL)
    {
      vmessage("ERROR %s: could not restore both images!\nYou can try to provide restored images.", _function_name());
      return NULL;
    }
  }

  %% insert filenames and other values
  variable name_corr      = qualifier("cc","cc.fits");     %name of the cross correlation coefficient
  variable N              = qualifier("iterations", 1);    %pick the best N transformations to average over
  variable req_both_bands = qualifier("req_both_bands",0); %spix just for pixels in which both bands above noise
  variable fit_noise      = qualifier("fit_noise",1);      %only does something if req_both_bands==1 (otherwise fitting in plot_spix messes up)
  variable lo_nsigma      = qualifier("lo_nsigma",3);      %only does something if fit_noise==1
  variable hi_nsigma      = qualifier("hi_nsigma",3);      %only does something if fit_noise==1  
  variable excl_core      = qualifier("excl_core",1);
  variable n_beams        = qualifier("n_beams",3);        %only does something if excl_core==1
  variable name_lo_corr   = name_lo;                       %names for files used in cc calculation. If region is excluded this changes to new file with excluded region
  variable name_hi_corr   = name_hi;                       %names for files used in cc calculation. If region is excluded this changes to new file with excluded region

  %% 2D arrays for images, correlation coefficients, etc
  variable mlo = fits_read_img(name_lo);  mlo = mlo[0,0,*,*]; % remove the 2 DIFMAP dimensions for FREQ and STOKES
  variable mhi = fits_read_img(name_hi);  mhi = mhi[0,0,*,*]; 
  variable length_x     = length(mlo[*,0]);
  variable length_y     = length(mlo[0,*]);
  variable weights      = Double_Type[length_x,length_y];  %sum of weights used per pixel for normalizing
  variable spec_map     = Double_Type[length_x,length_y];
  variable spec_map_2   = Double_Type[length_x, length_y]; %expectation value of values squared - for stdev
  variable avg_lum      = Double_Type[length_x, length_y]; %weighted average BRIGHTNESS over translations
  variable stdev        = Double_Type[length_x, length_y];
  variable avg_shift    = [0,0];
  variable shift_weight = 0;
  variable corrcoff;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %PERFORMING CROSS CORRELATION CALCULATIONS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %% use beam from x image to make region file to exclude region from correlation calculation
  variable major     = fits_read_key (name_lo, "BMAJ")*(3.6e+6)/2.0; % clean beam major axis in mas (semi major!), used at end of script
  variable minor     = fits_read_key (name_lo, "BMIN")*(3.6e+6)/2.0; % clean beam minor axis ins mas (semi minor!), used at end of script
  variable posang    = fits_read_key (name_lo, "BPA");               % clean beam postion angle in degrees, used at end of script
  variable ra_steps  = fits_read_key (name_lo, "CDELT1")*(3.6e+6);   % RA in mas corresponding to one pixel, used at end of script
  variable dec_steps = fits_read_key (name_lo, "CDELT2")*(3.6e+6);   % DEC in mas corresponding to one pixel, arbitrarily chosen, used at end of script
  variable major_pix = n_beams*major / dec_steps;
  variable minor_pix = n_beams*minor / dec_steps;

  variable in_shift = qualifier("shift", {NULL,NULL});

  %% prepare files for excluding core
  if(excl_core==1 and in_shift[0]==NULL and in_shift[1]==NULL){
    %generate filenames which don't exist yet
    variable exclude_reg  = "exclude.reg";  while (stat_file(exclude_reg) != NULL)  exclude_reg="X"+exclude_reg;
    variable lo_tmp_fits  = "lo_tmp.fits";  while (stat_file(lo_tmp_fits) != NULL)  lo_tmp_fits="X"+lo_tmp_fits;
    variable hi_tmp_fits  = "hi_tmp.fits";  while (stat_file(hi_tmp_fits) != NULL)  hi_tmp_fits="X"+hi_tmp_fits;
    variable lo_lst_fits  = "lo_lst.fits";  while (stat_file(lo_lst_fits) != NULL)  lo_lst_fits="X"+lo_lst_fits;
    variable hi_lst_fits  = "hi_lst.fits";  while (stat_file(hi_lst_fits) != NULL)  hi_lst_fits="X"+hi_lst_fits;
    variable lo_excl_fits = "lo_excl.fits"; while (stat_file(lo_excl_fits) != NULL) lo_excl_fits="X"+lo_excl_fits;
    variable hi_excl_fits = "hi_excl.fits"; while (stat_file(hi_excl_fits) != NULL) hi_excl_fits="X"+hi_excl_fits;

    %generating region file -> an ellipse for each band
    variable temp = where_max(mlo);
    variable dec_beam_center  = temp[0]  /  length(mlo[0,*]) ;
    variable ra_beam_center = temp[0] mod length(mlo[0,*]) ;
    variable reg_file = fopen(exclude_reg,"w");
    fprintf(reg_file, "-ellipse(%i,%i,%f,%f,%f)\n",nint(ra_beam_center+1.0), nint(dec_beam_center+1.0), major_pix, minor_pix, posang+90); %adding 1 because ds9 starts at (1,1)
    
    temp = where_max(mhi);
    dec_beam_center  = temp[0]  /  length(mhi[0,*]) ;
    ra_beam_center = temp[0] mod length(mhi[0,*]) ;
    fprintf(reg_file, "-ellipse(%i,%i,%f,%f,%f)\n",int(ra_beam_center+1.0), int(dec_beam_center+1.0), major_pix, minor_pix, posang+90); %adding 1 because ds9 starts at (1,1)
    ()=fclose(reg_file);
    
    %generating fits files with region excluded
    ()=fits_write_image_hdu(lo_tmp_fits,"TEMP",mlo);
    ()=fits_write_image_hdu(hi_tmp_fits,"TEMP",mhi);
    ()=system("fim2lst "+lo_tmp_fits+" "+lo_lst_fits+" > /dev/null");
    ()=system("fim2lst "+hi_tmp_fits+" "+hi_lst_fits+" > /dev/null");
    ()=system("ftcopy \'"+lo_lst_fits+"[regfilter(\""+exclude_reg+"\")]\' "+lo_excl_fits);
    ()=system("ftcopy \'"+hi_lst_fits+"[regfilter(\""+exclude_reg+"\")]\' "+hi_excl_fits);
    name_lo_corr = lo_excl_fits;
    name_hi_corr = hi_excl_fits;
  }

  %% if the shift is defined, don't go about finding or generating CC map
  if(in_shift[0]!=NULL or in_shift[1]!=NULL)
  {
    if(in_shift[0]==NULL or in_shift[1]==NULL)
    {
      message("Must give both shift coordinates {x,y}");
      return NULL;
    }
    %in_shift[0] = nint(in_shift[0]/(fits_read_key(name_lo, "CDELT1")*(3.6e+6))+0.5); % converting RA  shift from mas to pixels
    %in_shift[1] = nint(in_shift[1]/(fits_read_key(name_lo, "CDELT2")*(3.6e+6))+0.5); % converting DEC shift from mas to pixels
    %RS edit: make +0.5 term optional as it should not be necessary for VLBI maps from Difmap
    in_shift[0] = nint(in_shift[0]/(fits_read_key(name_lo, "CDELT1")*(3.6e+6))+qualifier("crpix_shift",0.)); % converting RA  shift from mas to pixels
    in_shift[1] = nint(in_shift[1]/(fits_read_key(name_lo, "CDELT2")*(3.6e+6))+qualifier("crpix_shift",0.)); % converting DEC shift from mas to pixels
    if(abs(in_shift[0])>length_x or abs(in_shift[1])>length_y)
    {
      message("Shifts must be within image boundaries");
      return NULL;
    }
    corrcoff = Integer_Type[2*length_x-1,2*length_y-1];
    corrcoff[*,*] = 1;
  }
  else{
    if (stat_file(name_corr) == NULL){
      ()=system(sprintf("echo \'%s\\n%s\\n%s\\n%d\\n%d\\n%d\\n%d\\n\' | /home/grossberger/fpipe/target/bin/FPImages2CC > /dev/null 2>&1",
			name_lo_corr,name_hi_corr,name_corr,length_x,length_y,length_x,length_y));
    }
    if (stat_file(name_corr) == NULL){
      vmessage("ERROR %s: Cross correlation failed! No file %s!\n\tCheck program FPImages2CC!",_function_name(), name_corr);
      return NULL;
    }
    corrcoff = fits_read_img(name_corr);
  }

  %% clean up from excluding core
  if(excl_core==1 and in_shift[0]==NULL and in_shift[1]==NULL){
    ()=remove(exclude_reg );
    ()=remove(lo_tmp_fits );
    ()=remove(hi_tmp_fits );
    ()=remove(lo_lst_fits );
    ()=remove(hi_lst_fits );
    ()=remove(lo_excl_fits);
    ()=remove(hi_excl_fits);
  }
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %FITTING NOSE ON BOTH IMAGES
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  variable lothreshold = qualifier("lothreshold",NULL);  %if given image has a pixel below this value, it's set to this value
  variable hithreshold = qualifier("hithreshold",NULL);

  %% better threshold levels are only done if req_both_bands==1 so fitting in
  %% plot_spix doesn't mess up (only use brightness scaling if req_both_bands==0)
  %% 
  %% only do calculation if threshold is not predefined
  if(req_both_bands==1){
%     if(lothreshold==NULL) lothreshold = fits_read_key(name_lo, "NOISE");
%     if(hithreshold==NULL) hithreshold = fits_read_key(name_hi, "NOISE");
    if(fit_noise==1){
      variable mu , sigma;
      if(lothreshold==NULL){
	message("Fit for first image noise:");
	(mu,sigma) = fit_gauss_to_img_noise (mlo);
	lothreshold = mu + lo_nsigma*sigma;
      }
      if(hithreshold==NULL){	
	message("Fit for second image noise:");
	(mu,sigma) = fit_gauss_to_img_noise (mhi);
	hithreshold = mu + hi_nsigma*sigma;
      }
    }
  }
  
  %% if neither threshold is set by another method, set them to 1e-5
  if(lothreshold==NULL) lothreshold=1e-5;
  if(hithreshold==NULL) hithreshold=1e-5;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %CALCULATING SPECTRAL INDEX, ETC
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %% make log maps, remove noise
  variable log_mlo = log(_max (mlo, lothreshold));
  variable log_mhi = log(_max (mhi, hithreshold));
  variable fac = log(fits_read_key(name_lo,"CRVAL3")/1.e9)-log(fits_read_key(name_hi,"CRVAL3")/1.e9); %width of frequency range on log scale 
  
  %% initializing limits of translated arrays
  variable limhi_left,  limhi_right,  limhi_top,  limhi_bottom;
  variable limlo_left,  limlo_right,  limlo_top,  limlo_bottom;
  variable left, right, top, bottom;

  %% finding and sorting the best translations
  variable a;
  if( in_shift[0]!=NULL or in_shift[1]!=NULL ){
    a = (in_shift[1]+length_y-1)*length(corrcoff[0,*]) + in_shift[0]+length_x-1;
  }
  else if (N==1){                                               %avoid forcing shift in both directions if only one shift 
    a = where_max(corrcoff);
  }
  else{
    a = @corrcoff;
    variable b;
    if(length((corrcoff[0,*]-1)/2 mod 2 == 1)) b=0;            %which cc values are set to 0 depends on whether there are an even or odd number of pixels in a row       
    else b=1;
    a[[b:length(a[*,0])-1-b:2],            *            ]=0;   %set every element of the ccc map that we can't translate to to zero so it's
    a[          *             , [b:length(a[0,*])-1-b:2]]=0;   %not chosen as a shift when the array is sorted
    a = _reshape(a,[length(a[*,*]),1])[*,0];                   %put corr. coeff into 1d array
    a = array_sort(a)[[-N:]];                                  %gives 1d index of N top corr. coeff
  }
  
  %% translate hi image wrt lo image, calculate spectral index, record weights used per pixel
  %% ONE ITERATION PER TRANSLATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable mhi_temp, mlo_temp, log_mlo_temp, log_mhi_temp, spec_map_temp, spec_map_2_temp, avg_lum_temp, weights_temp, good_points;
  variable x, y, index;
  foreach index (a){
    x= index  /  length(corrcoff[0,*])-length_y+1;
    y= index mod length(corrcoff[0,*])-length_x+1;

    %% defining limits for translated images
    limhi_left   = -min([0,x]);
    limhi_right  = length_x-1-max([0,x]);
    limhi_top    = length_y-1-max([0,y]);
    limhi_bottom = -min([0,y]);
    
    limlo_left   = max([0,x]);
    limlo_right  = length_x-1+min([0,x]);
    limlo_top    = length_y-1+min([0,y]);
    limlo_bottom = max([0,y]);

    if(in_shift[0]!=NULL or N==1){
      left   = limlo_left;
      right  = limlo_right;
      top    = limlo_top;
      bottom = limlo_bottom;
    }
    else{
      left   = abs(x)/2;
      right  = length_x-1-abs(x)/2;
      top    = length_y-1-abs(y)/2;
      bottom = abs(y)/2;
    }

    if(req_both_bands==1){
      %% making temporary arrays
      mlo_temp     = mlo    [ [limlo_left:limlo_right] , [limlo_bottom:limlo_top] ];
      mhi_temp     = mhi    [ [limhi_left:limhi_right] , [limhi_bottom:limhi_top] ];
      log_mlo_temp = log_mlo[ [limlo_left:limlo_right] , [limlo_bottom:limlo_top] ];
      log_mhi_temp = log_mhi[ [limhi_left:limhi_right] , [limhi_bottom:limhi_top] ];
      
      spec_map_temp   = Double_Type [ right-left+1, top-bottom+1 ];
      spec_map_2_temp = Double_Type [ right-left+1, top-bottom+1 ];
      avg_lum_temp    = Double_Type [ right-left+1, top-bottom+1 ];
      weights_temp    = Double_Type [ right-left+1, top-bottom+1 ];
      
      %% calculating temporary values
      good_points = where( mlo_temp > lothreshold+1e-10  and  mhi_temp > hithreshold+1e-10);
      
      spec_map_temp[good_points]  = corrcoff[length_x+x-1,length_y+y-1] * (log_mlo_temp[good_points] - log_mhi_temp[good_points])/fac;
      spec_map_2_temp[good_points]= corrcoff[length_x+x-1,length_y+y-1] *((log_mlo_temp[good_points] - log_mhi_temp[good_points])/fac)^2;
      avg_lum_temp[good_points]   = corrcoff[length_x+x-1,length_y+y-1] *     (mlo_temp[good_points] + mhi_temp[good_points]);
      weights_temp[good_points]   = corrcoff[length_x+x-1,length_y+y-1];
      
      %% adding temporary values to actual arrays
      spec_map   [[left:right],[bottom:top]] += spec_map_temp;
      spec_map_2 [[left:right],[bottom:top]] += spec_map_2_temp;
      avg_lum    [[left:right],[bottom:top]] += avg_lum_temp;
      weights    [[left:right],[bottom:top]] += weights_temp;
      
      avg_shift    += corrcoff[length_x+x-1, length_y+y-1]*[x,y];
      shift_weight += corrcoff[length_x+x-1, length_y+y-1];
    }
    else{
      spec_map [[left:right],[bottom:top]] += corrcoff[length_x+x-1,length_y+y-1] / fac *
	(  log_mlo[[limlo_left:limlo_right],[limlo_bottom:limlo_top]] -
	   log_mhi[[limhi_left:limhi_right],[limhi_bottom:limhi_top]]   );
      
      spec_map_2[[left:right],[bottom:top]] += (spec_map[[left:right],[bottom:top]])^2;
      
      avg_lum[[left:right],[bottom:top]] += corrcoff[length_x+x-1,length_y+y-1] *
	( mlo[ [limlo_left:limlo_right] , [limlo_bottom:limlo_top] ] +
	  mhi[ [limhi_left:limhi_right] , [limhi_bottom:limhi_top] ]   );
      
      weights[[left:right],[bottom:top]] += corrcoff[length_x+x-1,length_y+y-1];
      
      avg_shift    += corrcoff[length_x+x-1, length_y+y-1]*[x,y];
      shift_weight += corrcoff[length_x+x-1, length_y+y-1];
    }
  }
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %% finish calculating various values
  avg_lum    /= weights;
  avg_shift  /= shift_weight;
  spec_map   /= weights;
  spec_map_2 /= weights;
  good_points = where(abs(spec_map_2 - spec_map^2)>1e-10);   %takes care of "nan" due to errors from machine precision
  stdev[good_points] = sqrt(spec_map_2[good_points] - spec_map[good_points]^2);
  
  %% anything that was divided by zero is set to 0
  variable indx = where( weights < 1e-5 );
  spec_map  [indx] = 0;
  spec_map_2[indx] = 0;
  stdev     [indx] = 0;
  avg_lum   [indx] = 0;
  
  %% shift map_high according to the avg_shift for return
  variable j;
  _for j(0,length_y-1,1) mhi[*,j] = shift(mhi[*,j], -nint(x));
  _for j(0,length_x-1,1) mhi[j,*] = shift(mhi[j,*], -nint(y));
  
  %% ouputting for use by plot_spix
  return struct{
    spec_map       = spec_map,
    lo_map         = mlo,
    hi_map_shifted = mhi,
    stdev          = stdev,
    avg_lum        = avg_lum,
    avg_shift      = avg_shift,
    shift_weight   = shift_weight,
    avg_shift_pixel = [-nint(x), -nint(y)], %shift in pixel
    weights        = weights,
    ra_px_center   = fits_read_key (name_lo, "CRPIX1"),     % declination center pixel
    ra_steps       = ra_steps,                              % RA in mas corresponding to one pixel
    dec_px_center  = fits_read_key (name_lo, "CRPIX2"),     % declination center pixel
    dec_steps      = dec_steps,                             % DEC in mas corresponding to one pixel
    major          = major,                                 % clean beam major axis in mas (semi major!)
    minor          = minor,                                 % clean beam minor axis ins mas (semi minor!)
    posang         = posang,                                % clean beam postion angle in degrees
    source         = fits_read_key (name_lo, "OBJECT"),     % source name
    date           = strftime_MJD( "%Y-%m-%d", MJDofDateString(fits_read_key (name_lo, "DATE-OBS"))) +" / "+
                     strftime_MJD( "%Y-%m-%d", MJDofDateString(fits_read_key (name_hi, "DATE-OBS"))),
    hithreshold    = hithreshold,
    lothreshold    = lothreshold,
  };
}

