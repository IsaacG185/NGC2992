require( "xfig" );
require( "gcontour" );
require( "png" ); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert pixel to mas
private define convMAS(pix,ref_pix,del) {
  return (pix - ref_pix+0.5)*del*3.6e6;}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define stacking_vlbi_images() 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{stacking_vlbi_images}
%\synopsis{stack VLBI images of same size}
%\usage{stacking_vlbi_images(Array_Type \code{string(cleanfiles)}, String_Type \code{outputfile});}
%\qualifiers{
%\qualifier{ra_mas}{[={20,-20}] {left,right} limits of image in mas}
%\qualifier{dec_mas}{[={-20,20}] {top,bottom} limits of image in mas}
%\qualifier{plot_size}{[=15] size of plot}
%\qualifier{n_sigma}{[=3.0] lowest contour of clean image}
%\qualifier{sourcename}{[=default] name of the source, by default the name is read from the
%                             .fits file, set to NULL for not plotting a source name}
%\qualifier{obs_date1}{[=default] observation date, by default the date of the first
%                              observation is used}
%\qualifier{obs_date2}{[=default] 2nd observation date, by default the date of the last
%                              observation is used}
%\qualifier{cont_scl}{[="2"] set factor to change the separation between contour levels}
%\qualifier{cont_lvl}{[=[c1,c2,..] contour levels [Jy] manually, overwrites other contour parameters}
%\qualifier{major}{specify a vector for the major tic marks of the plot}
%\qualifier{minor}{specify a vector for the minor tic marks of the plot}
%}
%\description
%    This function creates a stacked image of individual VLBI-clean images.\n 
%    Important note: all images need to be of the same size! Different beam sizes are 
%    NOT recognized or corrected.\n
%    The required input format are fits-file for both the clean and the modelfit images.
%    The format of the output file depends on the suffix of the given\n
%    \code{filename}. Possible formats of the output file are PDF, EPS,\n
%    PNG, GIF, etc.
%!%-
{
variable cleanfiles, outputfile;

  switch(_NARGS)
  { case 2: (cleanfiles,outputfile) = (); }
  { help(_function_name()); return; }
  %%%%%%%%%%%%
  variable nsigma    	  = qualifier("n_sigma",3.0);
  variable sourcename	  = qualifier("sourcename", fits_read_key (cleanfiles[0], "OBJECT"));
  variable comp_label	  = qualifier("comp_label", 0);
  variable label_color	  = qualifier("label_color", "red");
  variable ra_mas         = qualifier("ra_mas",  [ 20,-20]);
  variable dec_mas	  = qualifier("dec_mas", [-20, 20]); 

  % MB: the following variables are not used?
  %  variable ex_counterjet  = qualifier("ex_counterjet",0);
  %  variable counterjet_ra  = qualifier("counterjet_ra", NULL);
  %  variable counterjet_dec = qualifier("counterjet_dec", NULL);
  %  variable ind_inverse    = qualifier("ind_inverse",0);
  %  variable label_alt      = qualifier("label_alt", NULL);

  variable n = length(cleanfiles);

  variable obs_date = array_map (String_Type, &fits_read_key,   cleanfiles, "DATE-OBS");
  variable mjd      = array_map (Double_Type, &MJDofDateString, obs_date);
  variable obs_date1       = qualifier("obs_date1", strftime_MJD("%Y-%m-%d", min(mjd))  );
  variable obs_date2       = qualifier("obs_date2", strftime_MJD("%Y-%m-%d", max(mjd))  );

  % MB: estimate noise from all images:
  %  variable noise_i  = array_map (Double_Type, &fits_read_key, cleanfiles, "NOISE");
  %  variable noise    = hypot(noise_i);
  
  variable ii;
  _for ii (0,n-1,1){
    variable file = fits_read_img(cleanfiles[ii])[0,0,*,*];
    %%% add images:
    variable image;
    if (ii==0) {image =@file;}
    else image +=@file;
  }

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit background noise in order to determine contour levels
  % (for details see plot_vlbi_map)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % MB:    this should be done before cutting (and modifying the image), because
  %        then more background emission is included and the fitted noise value
  %        is less affected from significant jet emission
  variable map_min = min(image);
  variable map_max = max(image);
  variable mu, sigma;
  (mu,sigma) = fit_gauss_to_img_noise (image);
  variable cl    = qualifier("cont_scl", 2.);
  variable n_pos = int(log( (map_max - mu) / (nsigma*sigma)) / log(cl));
  variable n_neg = int(log( (mu - map_min) / (nsigma*sigma)) / log(cl));
  variable lvls  = qualifier("cont_lvl", mu + [-(cl^[0:n_neg]),cl^[0:n_pos]]*nsigma*sigma );

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % get coordinates and cut image
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable  pix1   = fits_read_key(cleanfiles[0],"CRPIX1");
  variable  pix2   = fits_read_key(cleanfiles[0],"CRPIX2");
  variable  delta1 = fits_read_key(cleanfiles[0],"CDELT1");
  variable  delta2 = fits_read_key(cleanfiles[0],"CDELT2");
  variable x, y;
  (x,y) = get_coordinatearrays_of_image(image);
  (x,y) = (convMAS(x,pix1,delta1),convMAS(y,pix2,delta2));
  variable xplotmin =  ra_mas[0]; variable xplotmax =  ra_mas[1];
  variable yplotmin = dec_mas[0]; variable yplotmax = dec_mas[1];
  variable xmin =  wherefirst (x[0,*] <= xplotmin);
  variable xmax =  wherelast  (x[0,*] >= xplotmax);
  variable ymin =  wherefirst (y[*,0] >= yplotmin);
  variable ymax =  wherelast  (y[*,0] <= yplotmax);
  image   = image [[ymin:ymax],[xmin:xmax]];
  x       = x     [[ymin:ymax],[xmin:xmax]];
  y       = y     [[ymin:ymax],[xmin:xmax]];

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % define plot 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable i,j;
  variable width = qualifier("plot_size",15.);
  variable height = width/abs(xplotmin-xplotmax)*abs(yplotmax-yplotmin);
  variable plot = xfig_plot_new(width, height);
  plot.world(xplotmin, xplotmax, yplotmin, yplotmax);	% world coordinates in mas
  plot.xlabel("relative RA [mas]");
  plot.ylabel("relative DEC [mas]");

  if (qualifier_exists("major") or qualifier_exists("minor"))
  {
    variable major_ticks = qualifier("major", [-100:100:5]);
    variable minor_ticks = qualifier("minor", [-100:100:1]);
    plot.xaxis(; major=major_ticks, minor= minor_ticks);
    plot.yaxis(; major=major_ticks, minor= minor_ticks);
    plot.y2axis(; ticlabels=0);
    plot.x2axis(; ticlabels=0);
  }
  
  % add source and date:
  variable xpos_text = 0.06;
  variable ypos_text = 0.93;
  if (sourcename != NULL){
    plot.xylabel(xpos_text,ypos_text, sourcename, -0.5,0.5; world0, color="black");
  }
  plot.xylabel(1-xpos_text,ypos_text, obs_date1+" to \n"+obs_date2, 0.5,0.5; world0, color="black");

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % plot contours of clean image
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable xref = pix1-xmin; variable yref = pix2-ymin;
  variable linewidth = Integer_Type[length(lvls)]; linewidth[*] = 1;
  variable line = Integer_Type[length(lvls)]; line[*] = 0;
  variable col = String_Type[length(lvls)]; col[*] = qualifier("cont_color","black") ;
  % % plot contours
  variable gcl = gcontour_compute(image, lvls);
  _for i (0, length(gcl)-1, 1) {
    _for j (0, length(gcl[i].x_list)-1, 1) {
      plot.plot(convMAS(gcl[i].x_list[j],xref,delta1),
		convMAS(gcl[i].y_list[j],yref,delta2);
		width=linewidth[i], line=line[i], color=col[i]);
    }
  }

  plot.render(outputfile);
}
