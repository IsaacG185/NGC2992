require( "xfig" );
require( "png" ); 

private define write_movie_img_png(fname,img,cmap){ %{{{

   variable rgb_img,pl,fov,t;
   if (not qualifier_exists("labels")){
      rgb_img  = png_gray_to_rgb(img, cmap) ;
      png_write_flipped(fname, rgb_img) ;

   } else {
   
      pl = xfig_plot_new(10,10);
      if (qualifier_exists("gmax"))
	pl.plot_png (img; cmap="hot",gmax=qualifier("gmax"));
      else
	pl.plot_png (img; cmap="hot");
      fov = qualifier("fov",1.);
      pl.world(-fov/2,fov/2,-fov/2,fov/2);
      pl.xaxis(;off,color="white");
      pl.yaxis(;off,color="white");
      pl.plot([0,0],[0,1];world0,color="white",width=2);
      pl.plot([1,1],[0,1];world0,color="white",width=2);
      pl.plot([0,1],[0,0];world0,color="white",width=2);
      pl.plot([0,1],[1,1];world0,color="white",width=2);

      t = qualifier("t",NULL);
      if (t != NULL){
	  pl.add_object(xfig_new_text(
				      sprintf(`$t=%.3f$\,ksec`,t*1e-3)
				     ;color="white",fontsize=`small`),
		       0.96,0.96,0.5,0.5;world0);
      }
      
      pl.render(fname);
   }
}
%}}}



%%%%%%%%%%%%%%%%%%%%%%%
define make_movie_from_evtList(fevt,dt,output){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{make_movie_from_evtList}
%\synopsis{makes a simple movie from a given event list}
%\usage{Double_Type total_img = make_movie_from_evtList(string eventFile, double dt, string movieFile);}
%\description
%    Make a movie from the eventlist "eventFile". The time (in
%    seconds) of each frame is adjusted by "dt". The output file is
%    written to "movieFile" (best use a mp4 file). 
%\qualifiers{
%\qualifier{cmap}{["hot"] color map}
%\qualifier{thres}{[0.0] threshold of counts/frame, when a frame should be discarded}
%\qualifier{fps}{frames per secondswitch on the scale}
%\qualifier{size}{[10,10] size of the image in cm}
%\qualifier{tstart}{start time of the movie (sec)}
%\qualifier{tstop}{end time of the movie (sec)}
%\qualifier{labels}{draw some labels (white frame and time in ksec)}
%}
%\seealso{xfig_plot_new,fitswcs_get_img_wcs}
%!%-

   variable evt = fits_read_table(fevt);
   
   variable fpng = qualifier("fpng","evt_img_%06d.png");
   variable fps = qualifier("fps",30);
   variable tstart = qualifier("tstart",min(evt.time));
   variable tstop = qualifier("tstop",max(evt.time));
   
   variable nx = max(evt.rawx)+1, ny=max(evt.rawy)+1;
   variable img = Double_Type[nx,ny];
   
   variable i, n = int((tstop-tstart)/dt)+1;
   
   variable ind,t0,t1,id;
   variable img_sum = @img;

   img_sum[*,*]=0;

   variable gmax=0.0;
   
   variable t = Double_Type[0];
   variable img_ar = Array_Type[0];
   variable img_tmp = Array_Type[1];
   _for i(0,n-1,1){
   
      t0 = tstart+i*dt;
      t1 = tstart+(i+1)*dt;
      ind = where( t0 <= evt.time < t1);
      
      img[*,*] = 0;
      foreach id(ind){
	 img[evt.rawx[id],evt.rawy[id]]++;
      }      

      if (sum(img) > qualifier("thres",0.0)){
	 gmax = max([gmax,max(img)]);
	 img_tmp[0] = [@img];
	 img_ar = [img_ar,img_tmp];
	 t = [t,0.5*(t0+t1)];
	 img_sum += img;
      }
      
   }

   variable cmap = qualifier("cmap","hot");
   
   variable npng = length(img_ar);
   _for i(0,npng-1,1){
      if (qualifier_exists("labels"))
	write_movie_img_png(sprintf(fpng,i),log(img_ar[i]),cmap
		      ;labels,t=t[i],gmax=log(gmax) );
      else
	write_movie_img_png(sprintf(fpng,i),log(img_ar[i]),cmap;
			    gmax=log(gmax) );
   }

      
      
   variable cmd = sprintf("ffmpeg -y -f image2 -r %.2f -i %s %s"$,fps,fpng,output);
   message(cmd);
   () = system(cmd);

   _for i(0,npng-1,1){
      () = remove(sprintf(fpng,i));
   }

   return img_sum;
}
%}}}

