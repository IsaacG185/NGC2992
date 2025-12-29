require( "fitswcs" );

private define get_arcmin_area(file){

   variable wcs = fitswcs_get_img_wcs(file);
   variable keys = fits_read_key_struct(file,"naxis1","naxis2");

   variable xarcmin = abs(wcs.cdelt[0]*keys.naxis1)*60.;
   variable yarcmin = abs(wcs.cdelt[1]*keys.naxis2)*60.;

   
   return xarcmin*yarcmin;
}

private define write_dummy_bkg_ctsmap(fsrc,fbkg){

   variable src = fits_read_img(fsrc);

   variable wcs = fitswcs_get_img_wcs(fsrc);

   fits_write_image(fbkg,"IMAGE",src*0+1.0);

   fitswcs_put_img_wcs(fbkg,wcs);
   
   
}


private define local_eval_simputfile(ff_par,Simput,RA,Dec,fbkg,Src_Name,srcflux){ 

   variable emin = qualifier("emin",0.5);
   variable emax = qualifier("emax",10.);
   
   variable simput_str = get_simputfile_struct(Simput,RA,Dec,srcflux;emin=emin,emax=emax);
   simput_str.Src_Name = Src_Name;
   simput_str.ImageFile = fbkg;
   simput_str.ISISFile = ff_par;
   
   simput_str.Elow = 0.1;
   simput_str.Eup = 15;
   simput_str.Estep = 0.001;
   
   if (qualifier_exists("overwrite") || (stat_file(simput_str.Simput)==NULL)) {
      eval_simputfile(simput_str);
   } else {
      vmessage("Skipping creating of SIMPUT File %s as it already exists",Simput);
   }
   
}

private define get_bkg_src_flux(fpar,fbkg){

   
   variable arcmin_area = qualifier("arcmin_area",1.);

   variable emin = qualifier("emin",0.5);
   variable emax = qualifier("emax",10.);
      
   load_par(fpar);
   variable flu = energyflux(emin,emax;cgs);
   variable img_area = get_arcmin_area(fbkg);

   return flu*img_area/arcmin_area;
}

%%%%%%%%%%%%%%%%%%%%%%%
define write_simput_dummy_bkg(fsimput,fsrc,fpar){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{write_simput_dummy_bkg}
%\synopsis{plots a sky image, including an optional scale and/or grid}
%\usage{write_simput_dummy_bkg(fsimput,fsrc,fpar);}
%\description
%    fsimput:  Name of the ouput simput-File
%    fsrc:     Name of a SRC-FITS-Image (with FK5 WCS Header)
%    fpar:     ISIS-par File (with proper normalization) of the BKG
%\qualifiers{
%\qualifier{src_name}{["BKG"] name of the source in the SIMPUT file}
%\qualifier{overwrite}{if given, already exsiting simput files are overwritten}
%\qualifier{arcmin_area}{=[1.0] area in arcmin specifying the flux for the given spectrum }
%}
%\seealso{xfig_plot_new,fitswcs_get_img_wcs}
%!%-

   variable srcName = qualifier("src_name","BKG");
   
   variable fbkg = "dummy_tmp_simput_bkg.bkg";
   write_dummy_bkg_ctsmap(fsrc,fbkg);
   
   variable ra=0.0,dec=0.0;
%   if (fits_read_key(fbkg,"RADESYS") != "FK5"){
%      verror("wcs coords in %s not in FK5. Exiting ... ",fbkg);
%   }
   ra = fits_read_key(fbkg,"CRVAL1");
   dec = fits_read_key(fbkg,"CRVAL2");

   variable bkg_flux = get_bkg_src_flux(fpar,fbkg);
   local_eval_simputfile(fpar,fsimput,ra,dec,fbkg,srcName,bkg_flux;;__qualifiers());
   
   () = system("rm -f $fbkg"$);
}


