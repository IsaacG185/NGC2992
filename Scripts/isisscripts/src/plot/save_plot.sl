define save_plot()
%!%+
%\function{save_plot}
%\synopsis{saves ISIS spectral data into a FITS file}
%\usage{save_plot([filename[, ids]]);}
%\qualifiers{
%\qualifier{A}{Save the data in Angstrom and not in keV.}
%}
%\description
%   This functions saves all data and model points as currently
%   noticed and rebinned to the file 'filename'.fits. Each dataset is
%   stored in an own extension. The current model is save in
%   'filename'.par. By default the name 'save_plot' is chosen.
%   
%   Hereby the values are given in counts/bin and in 
%   photons/s/cm^2/keV. To calculate the flux from the observed 
%   data, the function get_convolved_model_flux() was used.
%   
%   Additionally, information on the instrument, the target, the grating,
%   the filename of the model, the functions used for the model 
%   and the frame time are stored in the header.
%!%-
{
  variable ids=all_data, filename=NULL;
  switch(_NARGS)
  { case 1: filename = (); }
  { case 2: (filename, ids) = (); }
  { help(_function_name()); return; }

   if(filename==NULL)  filename = "save_plot";
  
   %% open the fits file
   variable F = fits_open_file(filename+".fits", "c");
  
   %% get info of the data
   variable data_info;
   variable FitVerbose = Fit_Verbose;
   Fit_Verbose = -1;
   variable fit_stat;
   () = eval_counts(&fit_stat);
   variable chi2 = fit_stat.statistic/(fit_stat.num_bins - fit_stat.num_variable_params);
		    
  variable sd = Struct_Type[length(ids)];
  variable si = Struct_Type[length(ids)];
  variable i,ind;
  variable plotunit = "keV";
  if (qualifier_exists("A")) {
    plotunit = "A";
  }
  
   for (i = 0; i < length(ids); i++) {
      
      
      %%% - get data info - %%%
      data_info = get_data_info(ids[i]);
      variable filt = data_info.notice_list;

      
      
      %%% - get data counts - %%%
      variable d = get_data_counts(ids[i]);
      struct_filter(d,filt);
     if ( not qualifier_exists("A")) {
       d = _A(d);
     }
     
     %%% - get model counts - %%%
     variable m = get_model_counts(ids[i]);
      struct_filter(m,filt);
     if ( not qualifier_exists("A")) {
       m = _A(m);
     }
      
      %%% - get data flux - %%%
      variable mf,mf_re;
      variable f = struct {bin_lo=d.bin_lo,bin_hi=d.bin_hi,
	 value = m.value*0 +1, err = m.value*0+1};
      mf_re = m.value*0 +1;
      try {	 
	 flux_corr(ids[i]);
	 f = get_data_flux(ids[i]);
	 struct_filter(f,filt);
	 if ( not qualifier_exists("A")) {
	    f = _A(f);
	 }
	 
	 % original rebinning
	 rebin_data(ids[i],0);
	 () = eval_counts;
	 % apply flux correction
	 flux_corr_model_counts(ids[i]);
	 mf = get_convolved_model_flux(ids[i]);
	 if ( not qualifier_exists("A")) {
	    mf = _A(mf);
	 }
	 mf_re = rebin(d.bin_lo,d.bin_hi,mf.bin_lo,mf.bin_hi,mf.value);
	 
      } catch AnyError:{
	 message("No flux correction possible for this configuration. \n");
      }
      
      
      % restore binning of the data
      rebin_data(ids[i], data_info.rebin);
      ignore(ids[i]);
      notice_list(ids[i], data_info.notice_list);
      
      %%% - write structures - %%%
      sd[i] = struct {
	 bin_lo     = d.bin_lo,
	 bin_hi     = d.bin_hi,
	 value      = d.value,
	 err        = d.err,
	 model      = m.value,
	 model_flux = mf_re/(f.bin_hi-f.bin_lo),
	 flux       = f.value/(f.bin_hi-f.bin_lo),
	 flux_err   = f.err / (f.bin_hi-f.bin_lo)
      };
      
      
      si[i] = struct {
	 TUNIT1 = plotunit,
	 TUNIT2 = plotunit,
	 TUNIT3 = "counts/bin",
	 TUNIT4 = "counts/bin",
	 TUNIT5 = "counts/bin",
	 TUNIT6 = "photons/s/cm^2/keV",
	 TUNIT7 = "photons/s/cm^2/keV",
	 TUNIT8 = "photons/s/cm^2/keV"
      };
      fits_write_binary_table(F, "spectrum "+string(ids[i]), sd[i], si[i]);
      
      %% - write additionaly data info to the extension - %%%
 
      fits_update_key(F, "NUMDAT",length(ids));
      fits_update_key(F, "MODEL",+filename+".par");
      fits_update_key(F, "FITFUN",get_fit_fun);
      fits_update_key(F, "INSTRUME", data_info.instrument);
      fits_update_key(F, "TARGET", data_info.target);
      fits_update_key(F, "GRATING", data_info.grating);
      fits_update_key(F, "FRAMET", data_info.frame_time);
      fits_update_key(F, "EXPOSURE",get_data_exposure(i+1),"exposure in sec");
      fits_update_key(F, "CHI2RED", chi2, "reduced chi2 of the model");
      fits_update_key(F, "TSTART", data_info.tstart, "start of the observation");
      fits_update_key(F, "SPECPATH", getcwd, "path to the spectral files");
      fits_update_key(F, "SPECNAME", data_info.file, "spectral file");
      fits_update_key(F, "BGDNAME", data_info.bgd_file, "background file");
   }
   %% - write model - %%%
   save_par(filename+".par");
   
   fits_close_file(F);   
   Fit_Verbose = FitVerbose;
}
