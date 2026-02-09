require( "xfig" );

define compare_modelfits ()
%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{compare_modelfits}
%\synopsis{to compare modelfit parameters of different epochs}
%\usage{compare_modelfits([array of \code{epoch fitsfiles}]);}
%\qualifiers{
%\qualifier{plottype}{[="overlay"] layout of the comparison plot,
%                               by default it shows the overlay of all component positions,
%                               alternatives are "distancevsmjd","fluxvsdistance","TBvsdistance"}
%\qualifier{fileextent}{[=.eps] output is given by default as .eps-file in working directory}
%\qualifier{outputfile}{give outputfile name and directory by hand}
%\qualifier{sourcename}{[=default] set the name of the source, by default the name is read from the .fits file,\n
%                               set to NULL for not plotting a source name}
%\qualifier{ra_mas}{[=[20,-20]] ra range (for "overlay")}
%\qualifier{dec_mas}{[=[-20,20]] dec range (for "overlay")}
%\qualifier{mjd_min}{[=54101.0] lower limit of time axis (default: 1/1/2007)}
%\qualifier{mjd_max}{[=55927.0] lower limit of time axis (default: 1/1/2012)}
%\qualifier{distance_min}{[=0] lower limit of distance axis in mas}
%\qualifier{distance_max}{[=50] upper limit of distance axis in mas}
%\qualifier{flux_min}{[=1e-5] lower limit of flux axis in Jy}
%\qualifier{flux_max}{[=2] upper limit of flux axis in Jy}
%\qualifier{TB_min}{[=10^5] lower limit of brightness temperature axis in K}
%\qualifier{TB_max}{[=10^15] upper limit of brightness temperature axis in K}
%\qualifier{linestyle}{[=default] set to 0 if the flux values should not be conntected (or to another value for
%                               another line style}
%\qualifier{ex_comps}{[=0] set to 1 if components should be excluded and define
%                               the corresponding quadrant of the plot via the ex_comps-coordinates}
%\qualifier{ex_comps_ra}{[=NULL] quadrant coordinates in mas where components should be excluded}
%\qualifier{ex_comps_dec}{[=NULL] define quadrant coordinates in mas where components should be excluded}
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
%    quadrant of the the plot via ex_comps_ra and _dec.
%!%-
{
variable epochs;
  switch(_NARGS)
  { case 1: (epochs) = (); }
  { help(_function_name()); return; }
%%%%%%%%%%%%%%%
variable plottype       = qualifier("plottype", "overlay");
variable sourcename     = qualifier("sourcename", fits_read_key (epochs[0], "OBJECT"));
variable ra_mas         = qualifier("ra_mas", [20,-20]);
variable dec_mas        = qualifier("dec_mas", [-20,20]);
variable fileextent     = qualifier("fileextent", "eps");
variable mjd_min        = qualifier("mjd_min", 54101.0); %1.1.2007
variable mjd_max        = qualifier("mjd_max", 55927.0); % 1.1.2012
variable distance_min   = qualifier("distance_min", 0);
variable distance_max   = qualifier("distance_max", 50);
variable flux_min       = qualifier("flux_min",1e-3); % in Jy
variable flux_max       = qualifier("flux_max", 2);
variable ex_comps       = qualifier("ex_comps",0);
variable ex_comps_ra    = qualifier("ex_comps_ra", NULL);
variable ex_comps_dec   = qualifier("ex_comps_dec", NULL);
variable TB_min         = qualifier("TB_min", 10^5);
variable TB_max         = qualifier("TB_max", 10^15);
variable outputfile     = qualifier("outputfile", NULL);
%%%%%%%%%%%%%%%%%%%%
variable i,k;
variable factor = 3.6e6;
%%%%
variable pl = xfig_plot_new(15., 15.);
%%%%%
_for i (0, length(epochs)-1,1){
variable model = fits_read_table(epochs[i]);
variable RA = model.deltax*factor;
variable Decl = model.deltay*factor;
%%%%
variable excl;
if (ex_comps==1){
        %1.Quadrant:
        if (max(ex_comps_ra)<=0 and (min(ex_comps_dec)>=0)){
%       theta = +0-90
        excl = wherenot(RA<=0.0 and Decl>=0);}
        %2.Quadrant:
        if (min(ex_comps_ra)>=0 and (min(ex_comps_dec)>=0)){
%       theta = -0-90%
        excl = wherenot(RA>=0.0 and Decl>=0);}
        %3.Quadrant:
        if (min(ex_comps_ra)>=0 and (max(ex_comps_dec)<=0)){
%       theta -90-180
        excl = wherenot(RA>=0.0 and Decl<=0);}
        %4.Quadrant:
        if (max(ex_comps_ra)<=0 and (max(ex_comps_dec)<=0)){
% %     theta = +90-180
        excl = wherenot(RA<=0.0 and Decl<=0);}
model = struct_filter (model,excl;copy);
}
variable date_ = fits_read_key(epochs[i],"DATE-OBS");
variable mjd = fits_read_key(epochs[i],"DATE-OBS");
variable Y, m, d; ()=sscanf(mjd, "%4d-%2d-%2d, %2d:%2d", &Y, &m, &d);
mjd = MJDofDate(Y, m, d);
variable distance =  sqrt((model.deltax*factor)^2+ (model.deltay*factor)^2);
variable frequency = fits_read_key(epochs[i],"CRVAL3")/1.e9; %in GHz
variable TB = 1.22*1e+12*model.flux/(frequency^2*(model.major_ax*factor)*(model.minor_ax*factor)); % see Condon et al. 1982
%%%%%% overlay
if (plottype=="overlay"){
pl.world(max(ra_mas), min(ra_mas), min(dec_mas), max(dec_mas));
pl.xlabel("relative RA [mas]");
pl.ylabel("relative DEC [mas]");
pl.xylabel(0.85,0.85,sourcename; world00);
variable major_ticks = [-100:100:5];
variable minor_ticks= [-100:100:1];
pl.x1axis(; major=major_ticks, minor= minor_ticks);
pl.y1axis(; major=major_ticks, minor= minor_ticks);

pl.xylabel(0.8,0.85-(i+1)/20.,string(date_)+" ("+string(mjd)+")"; color=i+1, world00);
pl.plot(0.63,0.85-(i+1)/20.; sym="+", symcolor=i+1, world00);
pl.plot(model.deltax*factor,model.deltay*factor; sym="+", symcolor=i+1);


variable phi=[0:2*PI:#200]; 
variable ex, ey;
variable smaj = factor*model.major_ax;
variable smin = factor*model.minor_ax;
variable posangle = (model.posangle/180.) * PI;
variable ii;
_for ii (0, length(model.deltax)-1,1){
(ex, ey) = ellipse(smaj[ii]/2.0,smin[ii]/2.0,PI/2.0-posangle[ii],phi);
pl.plot(model.deltax[ii]*factor+ex,model.deltay[ii]*factor+ey; color=i+1) ;
}
}
%%%
if (plottype=="distancevsmjd"){
pl.world( mjd_min, mjd_max,distance_min,distance_max);
pl.xlabel("Epoch [MJD]");
pl.ylabel("Distance [mas]");
major_ticks = [-100:100:5];
minor_ticks= [-100:100:1];
pl.y1axis(; major=major_ticks, minor= minor_ticks);
_for k (0, length(model.deltax)-1,1){
pl.plot(mjd, distance[k]; sym=i+1, symcolor=i+1);}
pl.xylabel(0.8,0.85-(i+1)/20.,string(date_)+" ("+string(mjd)+")"; color=i+1, world00);
pl.plot(0.63,0.85-(i+1)/20.; sym=i+1, symcolor=i+1, world00);
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (plottype=="fluxvsdistance"){
model = struct_combine (model, struct{distance=Double_Type[length(model.flux)]});
variable a;
for (a=0; a<length(model.flux); a++) {model.distance[a]=distance[a];};
variable model_sort = struct_filter(model, array_sort(model.distance);copy);
pl.world( distance_min,distance_max,flux_min, flux_max; ylog);
pl.ylabel("Flux [Jy]");pl.xlabel("Distance [mas]");
pl.plot(model_sort.distance,model_sort.flux;  sym=i+1, symcolor=i+1, line= qualifier("linestyle",2), color = i+1);
pl.xylabel(0.8,0.85-(i+1)/20.,string(date_)+" ("+string(mjd)+")"; color=i+1, world00);
pl.plot(0.63,0.85-(i+1)/20.; sym=i+1, symcolor=i+1, world00);}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (plottype=="TBvsdistance"){
model = struct_combine (model, struct{TB=Double_Type[length(model.flux)]});
variable b;for (b=0; b<length(model.flux); b++) {model.TB[b]=TB[b];};
%
model = struct_combine (model, struct{distance=Double_Type[length(model.flux)]});
for (a=0; a<length(model.flux); a++) {model.distance[a]=distance[a];};
model_sort = struct_filter(model, array_sort(model.distance);copy);
pl.world( distance_min,distance_max,TB_min, TB_max; ylog);
pl.ylabel("$T_B$ [K]"R);pl.xlabel("Distance [mas]");
pl.plot(model_sort.distance,model_sort.TB;  sym=i+1, symcolor=i+1, line= qualifier("linestyle",2), color = i+1);
pl.xylabel(0.8,0.85-(i+1)/20.,string(date_)+" ("+string(mjd)+")"; color=i+1, world00);
pl.plot(0.63,0.85-(i+1)/20.; sym=i+1, symcolor=i+1, world00);
}
%%%%%
}% for-loop reading in all files
if (outputfile!=NULL){xfig_new_hbox_compound (pl, 0.4).render(outputfile);}
else{
xfig_new_hbox_compound (pl, 0.4).render(sourcename+"_"+plottype+"."+fileextent);}
}

