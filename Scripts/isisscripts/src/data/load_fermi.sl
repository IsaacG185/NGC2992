% -*- mode: slang; mode: fold -*-

private define fermi_new_centered_energy_grid(lo,hi,cener) %{{{
{
   variable i,n = length(lo);
   variable nlo = Double_Type[n];
   variable nhi = @nlo;
   
   nlo[0] = lo[0];
   nhi[0] = 2.0*cener[0]-nlo[0];
   
   _for i(1,n-1,1)
   {
      nlo[i] = nhi[i-1];
      nhi[i] = 2.0*cener[i]-nlo[i];      
   }      
   return nlo,nhi;
}
%}}}
private define log_interpol(new_x,x,y) %{{{
{
   return exp(interpol(log(new_x),log(x),log(y));;__qualifiers);
}
%}}}
private define integrate_diff_flux(dat,mo) %{{{
% ****** Differtial -> Integrated Flux ****** %
{
   variable n = length(dat.bin_lo);
   variable corr_fac = Double_Type[n];
   variable i,new_x,new_y,f_e_center,integ_flux;
   _for i(0,n-1,1)
   {
      new_x = exp([log(dat.bin_lo[i]):log(dat.bin_hi[i]):#10]);
      new_y = log_interpol(new_x,mo.ener,mo.flux);
      f_e_center = log_interpol(0.5*(dat.bin_lo[i]+dat.bin_hi[i]),mo.ener,mo.flux);   

      integ_flux = integrate_trapez(new_x,new_y);

      corr_fac[i] = integ_flux / (f_e_center * (dat.bin_hi[i]-dat.bin_lo[i]));      
   }

   variable integ_bin = (dat.bin_hi-dat.bin_lo)*corr_fac;
   
   variable str = struct{bin_lo=dat.bin_lo,bin_hi=dat.bin_hi,value=dat.flux*integ_bin,err=dat.err*integ_bin};
   
   return str, corr_fac;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_fermi()%{{{
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_fermi}
%\synopsis{loads fermi data produced by the "Fermi-SED Script"@Remeis}
%\usage{Integer_Type data_id = load_fermi(String_Type filename);}
%\qualifiers{
%\qualifier{rmf_factor}{[=10]: define a fine RMF to properly evaluate the model}
%}
%\description
%  Loads fermi data produced by the "Fermi-SED Script"@Remeis. Note
%  that special care is taken here, as the energy bins are relatively
%  large. Therefore the function set_bin_corr_factor is used to
%  calculate a correction factor. This factor is used automatically
%  for loading the data. In order to plot the data properly,
%  plot_data/unfold has to be used.
%  WARNING: Use clear_all to delete the correction factors (as well 
%  as the data). This is necessary as otherwise the correction factors 
%  are applied to a newly loaded dataset with the same ID.
%
%  This function is not working if you have computed a Fermi spectrum
%  with Fermipy!
%
%\seealso{load_fermi_spectrum,load_fermi_catalog}
%!%-
{
   variable in_fil;
   switch(_NARGS)
   { case 1: in_fil = ();}
   { help(_function_name()); return; }
   
   variable raw_dat = fits_read_table(in_fil);
   % make sure that no "strange" bins enter the analysis (SED analysis; Nela)
   struct_filter(raw_dat, where(raw_dat.center_energy >0.0)); 
   
   if ( raw_dat.center_energy == NULL )
   {verror ( "\n  ***** Error: Unable to open file %s.\n", in_fil );return NULL; }
   
   variable blo,bhi;
   (blo,bhi) =  fits_read_col(in_fil+"[2]","Bin Low Edge", "Bin High Edge");

   variable model = fits_read_table(in_fil+"[3]");

   % convert the bins such that for the new grid: 
   (blo,bhi) = fermi_new_centered_energy_grid(blo,bhi,raw_dat.center_energy);

   % make it keV here!!
   variable GeV2keV = 1e6;
   
   variable str_dat = struct{bin_lo=blo*GeV2keV,bin_hi=bhi*GeV2keV,flux=@raw_dat.dn_de/GeV2keV, err=@raw_dat.dn_de_error/GeV2keV};
   %struct_filter(str_dat, where(str_dat.err >0.0));   
   variable str_mo = struct{ener=model.center_energy*GeV2keV, flux=model.model/GeV2keV};
   
   Minimum_Stat_Err=1.e-20;   

   % properly Bin-Integrate the values
   variable dat, corr_factor;
   (dat,corr_factor) = integrate_diff_flux(str_dat,str_mo);

   % load data and set the correction factor
   variable fermi_id = define_counts(_A(dat));
   set_bin_corr_factor(fermi_id,corr_factor);
      
   set_data_exposure(fermi_id,1.);
   ignore_list(fermi_id, where ( dat.value == 0.));

   assign_rmf (make_fine_rmf(fermi_id,qualifier("rmf_factor",10)),fermi_id);

   return fermi_id;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_fermi_spectrum()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_fermi_spectrum}
%\synopsis{loads fermi data produced by any fermipy script}
%\usage{Integer_Type data_id = load_fermi_spectrum(String_Type filename);}
%\qualifiers{
%\qualifier{rmf_factor}{[=10]: define a fine RMF to properly evaluate the model}
%\qualifier{ts_min}{[=9]: set TS threshold for spectral bins to be loaded in as data points.}
%}
%\description
%  Loads fermi data produced by any Fermi spectrum produced with fermipy. Note
%  that special care is taken here, as the energy bins are relatively
%  large. Therefore the function set_bin_corr_factor is used to
%  calculate a correction factor. This factor is used automatically
%  for loading the data. In order to plot the data properly,
%  plot_data/unfold has to be used.
%
%  A note regarding upper limits: you can set yourself at which significance
%  you consider a spectral to be valid and not use the 2 sigma upper limit (UL).
%  The default value is TS = 9, which is ~3 sigma. The SED plot produced by 
%  the Fermi-LAT analysis script has a lower threshold, which is why you might
%  get less data points in your spectrum, when you load it in isis with the
%  default value of 'ts_min'. 
%  Spectral bins with a lower TS value will be treated as upper limits and 
%  not loaded in isis. For plotting purposes, the upper limits need to be 
%  added from the [*]_sed.fits file (column e2dnde_ul) and multiplied by a factor
%  of 1.60218e-6 to convert from MeV to erg.
%
%  This function supersedes the previous function 'load_fermi', which can only
%  be used to load the Fermi Spectra produced by the original "Fermi-SED"
%  script.
%
%  WARNING: Use clear_all to delete the correction factors (as well 
%  as the data). This is necessary as otherwise the correction factors 
%  are applied to a newly loaded dataset with the same ID.
%
%
%
%\seealso{load_fermi}
%!%-
{
        variable in_fil;
        switch(_NARGS)
        { case 1: in_fil = ();}
        { help(_function_name()); return; }

        variable raw_dat = fits_read_table(in_fil); % Energy of input bins are given in MeV!
        % Filter out 'strange' bins and upper limits
        variable tsfilter = qualifier("ts_min",9);
        struct_filter(raw_dat, where(raw_dat.e_ref>0.0));
        struct_filter(raw_dat, where(raw_dat.ts>=tsfilter));

        if (raw_dat.e_ref == NULL){
                vmessage("* Error: Unable to open file, no spectral bins detected in %s \n", in_fil);
        }

        % Load Model flux
        variable model = fits_read_table(in_fil+"[2]");

        % convert bins to fit to new grid
        variable blo, bhi;
        (blo, bhi) = fermi_new_centered_energy_grid(raw_dat.e_min, raw_dat.e_max, raw_dat.e_ref);

        % Convert from MeV to keV
        variable MeV2keV = 1e3;

        variable str_dat = struct{bin_lo=blo*MeV2keV, bin_hi=bhi*MeV2keV, flux=@raw_dat.dnde/MeV2keV, err=@raw_dat.dnde_err/MeV2keV};
        variable str_mo = struct{ener=model.energy*MeV2keV, flux=model.dnde/MeV2keV};

        Minimum_Stat_Err=1.e-20;

        % properly bin-integrate the values
        variable dat, corr_factor;
        (dat, corr_factor) = integrate_diff_flux(str_dat, str_mo);

        % Load data and set the correction factor
        variable fermi_id = define_counts(_A(dat));
        set_bin_corr_factor(fermi_id, corr_factor);

        set_data_exposure(fermi_id, 1.);
        ignore_list(fermi_id, where(dat.value==0.));
        assign_rmf(make_fine_rmf(fermi_id, qualifier("rmf_factor",10)), fermi_id);

        return fermi_id;
}



private define get_corr_factor(dat,gam) %{{{
{
   variable ec = 0.5*(dat.bin_lo+dat.bin_hi);   
   return
     ( dat.bin_hi^(1.-gam) - dat.bin_lo^(1.-gam))
     / ( (ec^(-gam)) * (dat.bin_hi - dat.bin_lo) * (1 - gam));   
}

%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_fermi_catalog() %{{{
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_fermi_catalog}
%\synopsis{loads Fermi data from a catalog for a given source}
%\usage{Integer_Type data_id = load_fermi_catalog(String_Type sourcename);
%}
%\qualifiers{
%\qualifier{list}{return list of available sources}
%\qualifier{ul}{Load includes upper limits}
%\qualifier{catalog}{specify the catalog (default: 2FGL_point_source@Remeis) }
%\qualifier{fgl3}{Use this when reading in the 3FGL catalog, either with 
%                   the catalog qualifier or without }
%}
%\description
%  WARNING: Use clear_all to delete the correction factors (as well 
%  as the data). This is necessary as otherwise the correction factors 
%  are applied to a newly loaded dataset with the same ID.
%
%\seealso{load_fermi}
%!%-
{

   variable src=NULL;
   switch(_NARGS)
   { case 0: ifnot(qualifier_exists("list")) { help(_function_name()); return; } }
   { case 1: src = (); }
   { help(_function_name()); return; }
   
   variable path_to_data = NULL;

   if (qualifier_exists("catalog"))
   {
      path_to_data = qualifier("catalog");
      if(stat_file(path_to_data)==NULL)
      {
	 vmessage("error (%s): Fermi catalog not at %s", _function_name(),path_to_data);
	 return -1;
      }
   }
   else
   {      

       if (qualifier_exists("fgl3"))
       {
     try {
	   foreach path_to_data ([local_paths.fermi_catalog_3fgl])
      if(stat_file(path_to_data)!=NULL)  break;   
     } catch NotImplementedError: { vmessage("error (%s): local_paths.fermi_catalog_3fgl not defined",_function_name()); return NULL; };
	   if(stat_file(path_to_data)==NULL)
	   { 
	       vmessage("error (%s): Fermi catalog not found on the system", _function_name());
	       return -1;
	   }
       }
       else
       {
	   try {
	   foreach path_to_data ([local_paths.fermi_catalog])
      if(stat_file(path_to_data)!=NULL)  break;   
     } catch NotImplementedError: { vmessage("error (%s): local_paths.fermi_catalog not defined",_function_name()); return NULL; };
	   if(stat_file(path_to_data)==NULL)
	   { 
	       vmessage("error (%s): Fermi catalog not found on the system", _function_name());
	       return -1;
	   }
       }
   }


   
   variable r = fits_read_table (path_to_data);   
   
   if (qualifier_exists("list"))
   return r.source_name;
   


   Minimum_Stat_Err=1e-20;
   struct_filter(r, where(r.source_name==src);dim=0);
  


   ifnot (length(r)>0)
   { 
      vmessage("error (%s): Source %s not found", _function_name(),src);
      return -1;
   }
   else if (length(r) > 1)
   {
      % although name should be unique, make sure nothing strange happens
      vmessage("error (%s): Source %s not unique!", _function_name(),src);
      return -1;
   }

   variable dat,i;
   if (qualifier_exists("fgl3"))
   {
       variable fluxes_unc = [
       r.unc_flux100_300[0,0],
       r.unc_flux100_300[0,1],
       r.unc_flux300_1000[0,0],
       r.unc_flux300_1000[0,1],
       r.unc_flux1000_3000[0,0],
       r.unc_flux1000_3000[0,1],
       r.unc_flux3000_10000[0,0],
       r.unc_flux3000_10000[0,1],
       r.unc_flux10000_100000[0,0],
       r.unc_flux10000_100000[0,1],
       ];
       variable temperr = Double_Type[0];
       _for i(0,4,1)
       {


	   if (isnan(fluxes_unc[2*i]) == 1 )
	   {
	       temperr = [temperr,0.0];
	   }
	   else
	   {
	       temperr = [temperr,max([abs(fluxes_unc[2*i]),fluxes_unc[2*i+1]])];
	   }
	   
       }
       dat = struct
       {
	   bin_lo = [100,300,1000,3000,10000]         * 1e3, % convert from MeV to keV
	   bin_hi = [    300,1000,3000,10000, 100000] * 1e3,
	   value  = [
	   r.flux100_300[0],
	   r.flux300_1000[0],
	   r.flux1000_3000[0],
	   r.flux3000_10000[0],
	   r.flux10000_100000[0],
	   ],
	   err = temperr,
       };
       }
       else
       {
	   dat = struct
	   {
	       bin_lo = [30,100,300,1000,3000,10000]         * 1e3, % convert from MeV to keV
	       bin_hi = [   100,300,1000,3000,10000, 100000] * 1e3,
	       value  = [r.flux30_100[0],
	       r.flux100_300[0],
	       r.flux300_1000[0],
	       r.flux1000_3000[0],
	       r.flux3000_10000[0],
	       r.flux10000_100000[0]
	       ],
	       err    = [r.unc_flux30_100[0],
	       r.unc_flux100_300[0],
	       r.unc_flux300_1000[0],
	       r.unc_flux1000_3000[0],
	       r.unc_flux3000_10000[0],
	       r.unc_flux10000_100000[0]
	       ]
	   };
	   }       
	   
	   if (not qualifier_exists("ul"))
	   {

	       if (length(dat.err) == 0)
	       {
		   vmessage("Only Upper Limits found, cannot load data");
		   
	       }
	   }


	   % warning: this is only a crude estimation, i.e., plotted values
	   % might not fit 100% the residuals!!
	   
	   variable gam = r.spectral_index[0];
	   variable corr_factor = get_corr_factor(dat,gam);
	   
	   dat = _A(dat); % change grid to angstrom, and do corresponding reversement of values
	   variable fermi_id = define_counts(dat);
	   set_bin_corr_factor(fermi_id,corr_factor);

	   % ignore upper limits (err=0) and unvalid bins
	   set_data_exposure (fermi_id,1); % should be already by default (but to be sure)

	   %IS THIS CAUSING TROUBLE? PROBABLY NOT
	   assign_rmf (make_fine_rmf(fermi_id,qualifier("rmf_factor",10)),fermi_id); % define a fine RMF

	   if (not qualifier_exists("ul"))
	   {
	       ignore_list (fermi_id, where(dat.err==0 or isnan(dat.value))); 

	   }


	   return fermi_id;
       
}

%}}}
