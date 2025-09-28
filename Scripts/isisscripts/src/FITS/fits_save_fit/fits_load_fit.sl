define fits_load_fit()
%!%+
%\function{fits_load_fit}
%\synopsis{defines the data and model of a FITS file written by 'fits_save_fit'}
%\usage{Integer_Type = fits_load_fit(String_Type filename[, Integer_Type index = 0]);}
%\qualifiers{
%  \qualifier{loadfun}{data load function (defualt = &load_data)
%            The following format is neccessary: 
%            Argument: String_Type Filename
%            Return:   Dataset ID}
%  \qualifier{nodata}{do not load the data}
%  \qualifier{norebin}{do not notice and rebin the data}
%  \qualifier{nomodel}{do not define the model}
%  \qualifier{noff}{do not set the fit function. Instead
%            only values of existing parameters
%            of the current model are loaded and
%            set. Maybe more useful in combination
%            with 'nodata' to just restore actual
%            fit parameters without overwritting
%            any additional (not saved) components}
%  \qualifier{noeval}{do not evaluate the model}
%  \qualifier{noerr}{do not load the systematic error fraction}
%  \qualifier{toeval}{structure of qualifiers
%            passed to 'eval_counts'}
%  \qualifier{strct}{reference to a variable to return the
%            structure loaded by fits_load_fit_struct}
%  \qualifier{ROC}{array of values to set
%            Rmf_OGIP_Compliance for each
%            spectrum before loading
%            (default values = 2)}
%}
%\description
%  This function restores the fit saved previously
%  by 'fits_save_fit'. That includes the loaded
%  data and the used model, which is evaluated at
%  the end.
%\seealso{fits_save_fit, fits_load_fit_struct, fits_list_fit_pars}
%!%-
{
  variable fitsfile, ind;
  switch(_NARGS)
    { case 1: (fitsfile) = (); ind = 0; }
    { case 2: (fitsfile, ind) = (); }
    { help(_function_name()); return; }

  % load fits structure
  variable fit = fits_load_fit_struct(fitsfile);

  % extract spectrum filenames and load the data
  variable dataind = Integer_Type[0];
  variable i;
  variable loadfun = qualifier("loadfun",&load_data);
  ifnot (qualifier_exists("nodata"))
  {
    % note: use same delimiter as in 'fits_save_fit'!
    variable specfiles = strchop(fit.data[ind], '\n', 0);
    variable backfiles = strchop(fit.bkg[ind], '\n', 0);
    variable binlists = strchop(fit.rebin[ind], '\n', 0);
    variable notlists = strchop(fit.notice_list[ind], '\n', 0);
    % loop over instruments
    variable roc = qualifier("ROC", ones(length(specfiles))*2);
    _for i (0, length(specfiles)-1, 1)
    {
      Rmf_OGIP_Compliance = roc[i];
      if (specfiles[i] == " "){
	vmessage("WARNING [fits_load_fit]: Data set no. %d has no spectrum file, ignoring", i) ;
	continue ;
      }
      dataind = [dataind, (@loadfun)( specfiles[i] ;; __qualifiers) ];

       if (backfiles[i] == " "){
	  vmessage("WARNING [fits_load_fit]: Data set no. %d has no background", i) ;	  
       } else {
	  () = define_back(dataind[i], backfiles[i]);
       }

       Rmf_OGIP_Compliance = 2;

       
       %set the systematic error fraction
       ifnot (qualifier_exists("noerr"))
	 {
	    % Extract sys_err values
	    variable sys_err = fits_read_table(fitsfile + "[1]").sys_err;
	    sys_err = strchop(sys_err[0], '\n', 0);
	    
	    % set sys_err values for each dataset
	    variable j=0;
	    _for j (0, length(sys_err)-1, 1)
	      {
		 set_sys_err_frac(all_data[-1-j], string2sys_err_array(sys_err[-1-j]));
	      }
	 }
       
       
       
      % notice and rebin the data
      ifnot (qualifier_exists("norebin"))
      {
	rebin_data(dataind[-1], rebin_human2isis(binlists[i]));
	ignore(dataind[-1]);
	notice_list(dataind[-1], notice_human2isis(notlists[i]));
      }
    }
  }

  % define the fit function and model
  ifnot (qualifier_exists("nomodel") || typeof(fit.fit_fun) == Null_Type)
  {
    ifnot (qualifier_exists("noff")) fit_fun(fit.fit_fun[ind]);
    % get all model parameters
    variable params = get_params;
    % loop over parameter structure
    % and restore values accordingly
    % note: use same field names than 'fits_save_fit'!
    _for i (0, length(params)-1, 1)
    {
      variable par = fits_conv_to_legal_char(params[i].name);
      if (struct_field_exists(fit, par + "_value"))
      {
        if (struct_field_exists(fit, par + "_lim"))
        {
          params[i].min = get_struct_field(fit, par + "_lim")[ind,0];
          params[i].max = get_struct_field(fit, par + "_lim")[ind,1];
	}
        params[i].value = get_struct_field(fit, par + "_value")[ind];
        params[i].fun = get_struct_field(fit, par + "_fun")[ind];
        if (strlen(params[i].fun) < 2) params[i].fun = NULL;
        params[i].tie = get_struct_field(fit, par + "_tie")[ind];
        params[i].freeze = get_struct_field(fit, par + "_freeze")[ind];
        params[i].units = get_struct_field(fit, par + "_units")[ind];
      }
    }
    set_params(params);
  }

  % evaluate the model
  ifnot (qualifier_exists("nodata") || qualifier_exists("noeval"))
  {
    ()=eval_counts(;; qualifier("toeval"));
  }

  % eventually return the fit-structure
  if (qualifier_exists("strct")) {
    variable strct = qualifier("strct");
    @strct = fit;
  }
  
  return dataind;
}
