require( "xfig" );
require( "gcontour" );
require( "png" ); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert pixel to mas
private define convMAS(pix,ref_pix,del) {
  return (pix - ref_pix+0.5)*del*3.6e6;}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define overplot_clean_model() 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{overplot_clean_model}
%\synopsis{creates an overlay of an clean VLBI image and the modelfit components}
%\usage{overplot_clean_model(String_Type \code{cleanfile}, String_Type \code{modfile}, String_Type \code{outputfile});}
%\qualifiers{
%\qualifier{ra_mas}{[={20,-20}] {left,right} limits of image in mas}
%\qualifier{dec_mas}{[={-20,20}] {top,bottom} limits of image in mas}
%\qualifier{plot_size}{[=15] size of plot}
%\qualifier{n_sigma}{[=3.0] lowest contour of clean image}
%\qualifier{sourcename}{[=default] name of the source, by default the name is read from the .fits file,\n
% 				set to NULL for not plotting a source name}
%\qualifier{obs_date}{[=default] the observation date, by default the observation date is read from the .fits file, \n
%				set to NULL for not plotting a observation date, set to "mjd" when MJD format required}
%\qualifier{cont_color}{[="gray"] color of contours of clean image}
%\qualifier{cont_scl}{[="2"] set factor to change the separation between contour levels}
%\qualifier{cont_lvl}{[=[c1,c2,..] set contour levels [Jy] manually, overwrites other contour parameters}
%\qualifier{model_color}{[="black"] color of Gaussian ellipses}
%\qualifier{center_symbol}{[="+"] symbol stating the ellipse center, set to NULL for no symbol}
%\qualifier{comp_label}{[=0] set to 1 when labelling of components depending on distance from [0,0]
% 				is requested}
%\qualifier{ind_inverse}{[=0] if the labels should be in inverse order set to 1}
%\qualifier{label_alt}{[=NULL] give list of alternative labels}
%\qualifier{label_color}{[="red"] color of component labels}
%\qualifier{ex_counterjet}{[=0]	set to 1 if counterjet components (and core) should be excluded and define
% 				the corresponding quadrant of the plot via the CJ-coordinates}
%\qualifier{counterjet_ra}{[=NULL] define counterjet coordinates in mas}
%\qualifier{counterjet_dec}{[=NULL] define counterjet coordinates in mas}
%}
%\description
%    This function creates an overlay of a VLBI-clean image and the corresponding\n
%    model of Gaussian components which are over-plotted as ellipses.\n
%    The required input format are fits-file for both the clean and the modelfit images.
%    The format of the output file depends on the suffix of the given\n
%    \code{filename}. Possible formats of the output file are PDF, EPS,\n
%    PNG, GIF, etc.
%    If labelling = 1 is set, the components are labeled with J0,J1,J2,... depending on 
%    their distance to [0,0].
%    The counterjet components (and core) can be excluded by defining the corresponding 
%    quadrant of the the plot via counterjet_ra and _dec.
%!%-
{
variable cleanfile,modfile,outputfile;
  switch(_NARGS)
  { case 3: (cleanfile,modfile,outputfile) = (); }
  { help(_function_name()); return; }
%%%%%%%%%%%%
variable ra_mas		= qualifier("ra_mas", [20,-20]);
variable dec_mas	= qualifier("dec_mas", [-20,20]); 
variable nsigma    	= qualifier("n_sigma",3.0);
variable sourcename	= qualifier("sourcename", fits_read_key (cleanfile, "OBJECT"));
variable obs_date       = qualifier("obs_date", fits_read_key (cleanfile, "DATE-OBS") );
variable comp_label	= qualifier("comp_label", 0);
variable label_color	= qualifier("label_color", "red");
variable ex_counterjet	= qualifier("ex_counterjet",0);
variable counterjet_ra 	= qualifier("counterjet_ra", NULL);
variable counterjet_dec = qualifier("counterjet_dec", NULL);
variable ind_inverse	= qualifier("ind_inverse",0);
variable label_alt	= qualifier("label_alt", NULL);
%%%%
variable mjd = fits_read_key(cleanfile,"DATE-OBS");
variable Y, m, d;
()=sscanf(mjd, "%4d-%2d-%2d", &Y, &m, &d);
mjd = MJDofDate(Y, m, d);
if (obs_date == "mjd"){ obs_date = string(mjd);}
%%%
variable image		= fits_read_img(cleanfile)[0,0,*,*];
variable noise		= fits_read_key(cleanfile,  "NOISE");
variable min_treshhold 	= 1e-9;
variable rms_image 	= nsigma*noise;
% %find reference pixel in map and create array:
variable  pix1 = fits_read_key(cleanfile,"CRPIX1");
variable  pix2 = fits_read_key(cleanfile,"CRPIX2");
variable  delta1 = fits_read_key(cleanfile,"CDELT1");
variable  delta2 = fits_read_key(cleanfile,"CDELT2");
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
variable model = fits_read_table(modfile);
variable factor = 3.6e6;
variable RA = model.deltax*factor;
variable Decl = model.deltay*factor;
%% Counterjet exclusion:
%% The user defines the quadrant where the CJ and core components are located.
%% This quadrant is excluded in the following calculations.
variable excl;
if (ex_counterjet==1){
	%1.Quadrant:
	if (max(counterjet_ra)<=0 and (min(counterjet_dec)>=0)){
% 	theta = +0-90
	excl = wherenot(RA<=0.0 and Decl>=0);
	}
	%2.Quadrant:
	if (min(counterjet_ra)>=0 and (min(counterjet_dec)>=0)){
% 	theta = -0-90% 	
	excl = wherenot(RA>=0.0 and Decl>=0);	
	}
	%3.Quadrant:
	if (min(counterjet_ra)>=0 and (max(counterjet_dec)<=0)){
% 	theta -90-180
	excl = wherenot(RA>=0.0 and Decl<=0);
	}
	%4.Quadrant:
	if (max(counterjet_ra)<=0 and (max(counterjet_dec)<=0)){
% % 	theta = +90-180
	excl = wherenot(RA<=0.0 and Decl<=0);
	}
model = struct_filter (model,excl;copy);
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% add field for distance and sort components by distance
model = struct_combine (model, struct{distance=Double_Type[length(model.flux)]});
%%%%
variable distance = sqrt((model.deltax*factor)^2+(model.deltay*factor)^2);
variable a;
for (a=0; a<length(model.flux); a++) {model.distance[a]=distance[a];};

variable model_sort = struct_filter(model, array_sort(model.distance);copy);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
image[where(image < min_treshhold)] = min_treshhold;
variable x, y;
(x,y)= get_coordinatearrays_of_image(image);
(x,y)=(convMAS(x,pix1,delta1),convMAS(y,pix2,delta2));
variable xplotmin = ra_mas[0]; variable xplotmax = ra_mas[1];
variable yplotmin = dec_mas[0]; variable yplotmax = dec_mas[1];
variable xmin =  wherelast (x[0,*]>xplotmin);
variable xmax =  wherefirst (x[0,*]<xplotmax);
variable ymin =  wherelast(y[*,0] < yplotmin);
variable ymax =  wherefirst(y[*,0]> yplotmax);
image   = image [[ymin:ymax],[xmin:xmax]];
x   = x [[ymin:ymax],[xmin:xmax]];
y   = y [[ymin:ymax],[xmin:xmax]];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % ellipses (in new order!)
variable smaj = factor*model_sort.major_ax;
variable smin = factor*model_sort.minor_ax;
variable posangle = (model_sort.posangle/180.) * PI;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% fit background noise (for details see plot_vlbi_map)
    variable lo,hi;
    variable map = image;
    variable map_min = min(map);
    variable map_max = max(map);
    (lo,hi) = log_grid(1e-5,map_max+(1e-5-map_min),500);
    variable nr = histogram (map-map_min+1e-5,lo,hi);
    
    variable px_dat = define_counts(lo,hi,nr,sqrt(nr)+1);
    fit_fun("gauss");
    % guessing good start parameters for the fit from the statistics of the map
    % works well if only a small region of the image is jet emission
    set_par("gauss(1).center",median(map-map_min+1e-5)        , 0 , 1e-6, 10           );
    set_par("gauss(1).area"  ,0.99*length(map)                , 0 , 1   , 2*length(map));
    set_par("gauss(1).sigma" ,quantile (0.84, _reshape(map-map_min+1e-5,length(dup))) - get_par("gauss(1).center")
	    , 0 , 1e-6, 1 );
    exclude(all_data);
    include(px_dat); % other methods/checks to find best fit?
    variable stat, fitmeth = get_fit_method;
    ()=fit_counts(&stat);
    if ( stat.statistic/(stat.num_bins-stat.num_variable_params) > 8)
    {
      if (Fit_Verbose >= 0) vmessage("Reduced chi-square > 8\t\t--> fitting continued");
      set_fit_method ("subplex"); ()=fit_counts;
      set_fit_method ("mpfit"); ()=fit_counts;
      set_fit_method (fitmeth);
    }
    
    variable  mu    = get_par("gauss(1).center") +map_min-1e-5;
    variable  sigma = get_par("gauss(1).sigma" );
    delete_data(px_dat);
    variable clrcut       = qualifier("clrcut",1);
    variable clrmin  = qualifier("clrmin",clrcut ? mu+nsigma*sigma : map_min);
    variable clrmax  = qualifier("clrmax",map_max);

    variable cl    = qualifier("cont_scl", 2.);
    variable n_pos = int(log( (map_max - mu) / (nsigma*sigma)) / log(cl));
    variable n_neg = int(log( (mu - map_min) / (nsigma*sigma)) / log(cl));
    variable lvls  = qualifier("cont_lvl", mu + [-(cl^[0:n_neg]),cl^[0:n_pos]]*nsigma*sigma );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % define plot 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
variable i,j;
variable width = qualifier("plot_size",15.);
variable height = width/abs(xplotmin-xplotmax)*abs(yplotmax-yplotmin);
variable plot = xfig_plot_new(width, height);
plot.world(xplotmin, xplotmax, yplotmin, yplotmax);	% world coordinates in mas
plot.xlabel("relative RA [mas]");
plot.ylabel("relative DEC [mas]");
variable major_ticks = [-100:100:5];
variable minor_ticks= [-100:100:1];
plot.x1axis(; major=major_ticks, minor= minor_ticks);
plot.y1axis(; major=major_ticks, minor= minor_ticks);

%% adding source and date
  if (sourcename != NULL){
    variable name_label = xfig_new_text(sourcename;color="black");
    name_label.scale(1.3);
    name_label.translate(vector(0.15*width,0.96*height,0));
    plot.add_object(name_label);
  }
  if (obs_date != NULL){
    variable date_label = xfig_new_text(obs_date;color="black");
    date_label.scale(1.3);
    date_label.translate(vector(0.85*width,0.96*height,0));
    plot.add_object(date_label);
  }
%% % labelling the components:
variable ii;
if (comp_label ==1 and label_alt!=NULL and length(label_alt)!=length(model_sort.distance)){print("number of labels does not match number of components");}
if (comp_label ==1 and label_alt!=NULL and length(label_alt)==length(model_sort.distance)){
for (ii=0; ii<length(label_alt); ii++){
		if (xplotmin >model_sort.deltax[ii]*factor> xplotmax and yplotmin <model_sort.deltay[ii]*factor< yplotmax){
		plot.xylabel(model_sort.deltax[ii]*factor, model_sort.deltay[ii]*factor, string(label_alt[ii]), 0.5, 0.5;color=qualifier("label_color","red"));};
	};}
variable index = [0:length(model_sort.distance)];
if (ind_inverse == 1){index = [(length(model_sort.distance)-1):0:-1];}
if (comp_label ==1 and label_alt==NULL){
	for (ii=0; ii<length(model_sort.distance); ii++){
		if (xplotmin >model_sort.deltax[ii]*factor> xplotmax and yplotmin <model_sort.deltay[ii]*factor< yplotmax){
		plot.xylabel(model_sort.deltax[ii]*factor, model_sort.deltay[ii]*factor, "J"+string(index[ii]), 0.5, 0.5;color=qualifier("label_color","red"));};
	};}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % plot contours of clean image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



variable xref = pix1-xmin; variable yref = pix2-ymin;
% % determine contour levels

% % 
variable linewidth = Integer_Type[length(lvls)]; linewidth[*] = 1;
variable line = Integer_Type[length(lvls)]; line[*] = 0;
variable col = String_Type[length(lvls)]; col[*] = qualifier("cont_color","gray") ;
% % plot contours
 variable gcl = gcontour_compute(map, lvls);
_for i (0, length(gcl)-1, 1) {
  _for j (0, length(gcl[i].x_list)-1, 1) {
    plot.plot(convMAS(gcl[i].x_list[j],xref,delta1),
	     convMAS(gcl[i].y_list[j],yref,delta2);
	     width=linewidth[i], line=line[i], color=col[i]);
  }
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % overplot Gaussian modelcomponents
variable phi=[0:2*PI:#200]; 
variable ex, ey;
_for i (0, length(model_sort.deltax)-1,1){
(ex, ey) = (ellipse(smaj[i]/2.0,smin[i]/2.0,PI/2.0-posangle[i],phi) );
plot.plot(model_sort.deltax[i]*factor,model_sort.deltay[i]*factor; sym=qualifier("center_symbol", "+"), symcolor=qualifier("model_color","black")); 
plot.plot(model_sort.deltax[i]*factor+ex,model_sort.deltay[i]*factor+ey) ;
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % plot beam
variable beam_maj      = fits_read_key (cleanfile, "BMAJ")*(3.6e+6)/2.0; % clean beam major axis in mas (semi major!)
variable beam_min      = fits_read_key (cleanfile, "BMIN")*(3.6e+6)/2.0; % clean beam minor axis in mas (semi minor!)
variable beam_ang      = fits_read_key (cleanfile, "BPA")/180*PI; % clean beam postion angle

variable beam = xfig_new_ellipse(beam_min,beam_maj);  % major axis to north, pos_angle = 0
variable beam_clr = "gray";
beam.set_pen_color(beam_clr);
beam.rotate(vector(0,0,1),beam_ang); % rotation for position angle in rad ("rotate" rotates clock wise)
beam.scale((1.*width) /abs(-convMAS(xmin,pix1,delta1)+convMAS(xmax,pix1,delta1)) ,
	   (1.*height)/abs(-convMAS(ymin,pix2,delta2)+convMAS(ymax,pix2,delta2)) , 0); 
beam.translate(vector(1.5-beam_maj*width/(xmax-xmin),1.5+beam_maj*height/(ymax-ymin),0));
beam.area_fill=20;
beam.fill_color=xfig_lookup_color(beam_clr);
plot.add_object(beam);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xfig_new_hbox_compound (plot, 0.4).render(outputfile);
%%
}

