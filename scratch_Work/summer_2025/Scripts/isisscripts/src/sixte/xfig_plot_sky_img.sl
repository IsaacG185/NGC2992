require( "xfig" );
require( "wcsfuns" );

private define deg2dms_rounded(deg){
   variable d,m,s;
   (d,m,s) =  deg2dms(deg;;__qualifiers);
   if (s > 59.99){	 
      m++;
      s = 0.0;
      if (m == 60) {
	 m=0;
	 d++;
      }
   }
   return d,m,s;
}

private define slog(a){
   return log(a+1);   
}

private define _xfig_plot_sky_img(img0){ %{{{
   variable img = img0;
   if (typeof(img0) == String_Type)
     img = fits_read_img(img0);
   
   variable dims;
   (dims, ,) = array_info(img);
   
   variable size = qualifier("size",[10,10./dims[1]*dims[0] ]);
   variable pl = xfig_plot_new(size[0],size[1]);
   variable cmap = qualifier("cmap","hot");

   variable func;
   if (qualifier_exists("png"))     {  %% plot external image
      pl.plot_png(qualifier("png"));      

   } else    {	     
      if (qualifier_exists("lin")) {
	 pl.plot_png (img; cmap=cmap);
      }
      else if (qualifier_exists("func")){
	 func = qualifier("func",&log);
	 pl.plot_png (@func(img); cmap=cmap,
		      gmin=@func(qualifier("gmin",min(img);))
		     );
      }   
      else {
	 pl.plot_png (slog(img); cmap=cmap,
		      gmin=log(qualifier("gmin",log(2)))
		     );
      }
   }
   

   variable fimg,wcs,lab,wi,arcmin,xar,yar,img_size;
   variable del=0.04;
   variable col_scale = qualifier("scale_color","white");
   if (qualifier_exists("scale")){
      fimg = qualifier("ref_img",img0);
      wcs = fitswcs_get_img_wcs(fimg);
      arcmin = qualifier("arcmin",5);

      img_size = array_shape(img);
      
      wi = (arcmin/60.) / (abs(wcs.cdelt[1])*img_size[1]);

      xar = [1-del-wi,1-del];
      yar = [0.05,0.05];
      pl.plot(xar,yar;color=col_scale,width=3,world0);
      
      lab = sprintf(`$%.0f'$`,arcmin);
      pl.add_object(xfig_new_text(lab;color=col_scale,size=`\footnotesize`),
		    0.5*(xar[0]+xar[1]),yar[0],0,-1.1;world0);
		    
   }
   
   pl.yaxis(; off);
   pl.xaxis(; off);
   return pl;
}
%}}}


%%%%%%%%%%%%%%%%%%%%%%%
define xfig_plot_sky_img(fimg){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{xfig_plot_sky_img}
%\synopsis{plots a sky image, including an optional scale and/or grid}
%\usage{Xfig_Plot_object pl = xfig_plot_sky_img(String_type fits_img);}
%\description
%    This function uses xfig to plot a sky image, with a given color
%    scale ("hot" by default). With a separate qualifier, a scale can
%    be switched on. The 
%\qualifiers{
%\qualifier{cmap}{["hot"] color map}
%\qualifier{scale}{switch on the scale}
%\qualifier{arcmin}{[=5] length of the scale in arcmin}
%\qualifier{lin}{linear image scale instead of logarithmic}
%\qualifier{func}{giva a reference to an arbitrary function to be applied to the image}
%\qualifier{size}{[10,10] size of the image in cm}
%\qualifier{ref_img}{[fits_img] if not given as direct argument, a reference FITS image has to be provided for the scale (filename!)}
%\qualifier{grid}{draw a grid and corresponding labels}
%\qualifier{step_ra}{[=1] step size of the RA-grid (given in min)}
%\qualifier{step_ra}{[=5] step size of the Dec-grid (given in arcmin)}
%\qualifier{grid_color}{[#BBBBBB] color of the grid}
%\qualifier{scale_color}{[white] color of the scale}
%}
%\seealso{xfig_plot_new,fitswcs_get_img_wcs}
%!%-

   
   variable pl = _xfig_plot_sky_img(fimg;;__qualifiers());

   variable size = array_shape(fits_read_img(fimg));
   variable p_xmin = 0.5;
   variable p_xmax = size[1]+0.5;
   variable p_ymin = 0.5;
   variable p_ymax = size[0]+0.5;

   if (not (qualifier_exists("grid"))) {
      return pl;
   }
   

   variable wcs = fitswcs_get_img_wcs (fimg);
   variable gridclr = qualifier("grid_color","#BBBBBB");

   variable arcmin_ra = qualifier("step_ra",1.);
   variable arcmin_dec = qualifier("step_dec",5.);
   

   variable ramin,ramax,dmin,dmax;
   (ramin,dmin) = wcsfuns_deproject(wcs,p_xmin,p_ymin);
   (ramax,dmax) = wcsfuns_deproject(wcs,p_xmax,p_ymax);
   if (ramin < 0){
      ramin +=360;
   }
   if (ramax < 0){
      ramax +=360;      
   }
    
   pl.world(0,size[1],0,size[0]);
   
   variable xmaj_hms = [[int(ramin*24./360):
			 int(ramax*24./360)+1:
			 arcmin_ra/60.]];
   
   variable xmaj = xmaj_hms*360./24.;
   
   variable ymaj = [[int(dmin):int(dmax)+1:arcmin_dec/60.]];

   variable ii,d,m,s;
   variable n = length(xmaj);
   variable xlab = String_Type[n];
   _for ii(0,n-1,1){
      (d,m,s) =  deg2dms_rounded(xmaj[ii];hours);
      xlab[ii] = sprintf("$%i\mathrm{h}%02i\mathrm{m}%02i\mathrm{s}$"R,
			 d,m,nint(s));
   }
   
   variable ny = length(ymaj);
   variable ylab = String_Type[ny];
   _for ii(0,ny-1,1){
      (d,m,s) =  deg2dms_rounded(ymaj[ii]);
      ylab[ii] = sprintf("$%i^\circ%02i'%02i''$"R,d,m,nint(s));
   }

   variable xmaj1_wcs,xmaj2_wcs,ymaj1_wcs,ymaj2_wcs;
   ( ,xmaj1_wcs)= wcsfuns_project(wcs,xmaj,xmaj*0+dmin);
   ( ,xmaj2_wcs)= wcsfuns_project(wcs,xmaj,xmaj*0+dmax);
   (ymaj1_wcs, )= wcsfuns_project(wcs,ymaj*0+ramin,ymaj);
   (ymaj2_wcs, )= wcsfuns_project(wcs,ymaj*0+ramax,ymaj);
   
   pl.axis(;on,color=gridclr);
 
   pl.x1axis(;major=xmaj1_wcs,color=gridclr,ticlabels=xlab);
   pl.y1axis(;major=ymaj1_wcs,color=gridclr,ticlabels=ylab);
   pl.x2axis(;major=xmaj2_wcs,color=gridclr,ticlabels=0);
   pl.y2axis(;major=ymaj2_wcs,color=gridclr,ticlabels=0);

   variable ra,dec,fac = 0.5;
     ra = [ramin-(ramax-ramin)*fac:
	   ramax+(ramax-ramin)*fac:#200];
   dec = [dmin-(dmax-dmin)*fac:
	  dmax+(dmax-dmin)*fac:#200];   

   variable pos_y,pos_x;
   variable src_pos = qualifier("src",NULL);
   if (src_pos != NULL){
      (pos_y,pos_x) = wcsfuns_project (wcs, src_pos[0],src_pos[1]);
      pl.plot(pos_x,pos_y;width=1,line=1,color=qualifier("src_color","white"),
	      depth=10,sym="+");      
   }
      
   variable v;
   foreach v (ymaj)   {      
      (pos_y,pos_x) = wcsfuns_project (wcs, ra,dec*0 + v);
      pl.plot(pos_x,pos_y;  width=1,line=1,color=gridclr,depth=10);
   }
   foreach v (xmaj)  {
      (pos_y,pos_x) = wcsfuns_project (wcs, ra*0+v,dec);
      pl.plot(pos_x,pos_y;  width=1,line=1,color=gridclr,depth=10);
   }
   
   return pl;
}

%}}}

