private define rename_model_component(name){
  variable ss = string_matches(name, "\(.*\)\(([0-9]+)\.\)\(.*\)"R);
  variable model_name = ss[1];
  variable model_param = ss[3];
  return strlow(model_name) + "_" + strlow(model_param);
}

private define initialize_return_struct(conffile, n_files){
  variable dfs = struct{
    index     = Integer_Type[n_files],
    name      = String_Type[n_files],
    value     = Double_Type[n_files],
    min       = Double_Type[n_files],
    max       = Double_Type[n_files],
    conf_min  = Double_Type[n_files],
    conf_max  = Double_Type[n_files],
    buf_below = Double_Type[n_files],
    buf_above = Double_Type[n_files],
    tex       = String_Type[n_files]
  };

  variable df0 = fits_read_table(conffile);

  variable ret = struct{
    conf_filename = String_Type[n_files],
    chi2red = Double_Type[n_files],
    parnames = String_Type[length(df0.name)],
    datafield_names = get_struct_field_names(dfs)
  };

  variable ii;
  _for ii (0, length(df0.name)-1, 1) {
    ret.parnames[ii] = rename_model_component(df0.name[ii]);
    ret = create_struct_field(ret, ret.parnames[ii], COPY(dfs));
  }
  
  return ret;
}

define collect_conf_files(conffiles){
%!%+
%\function{collect_conf_files}
%\synopsis{Collect multiple confidence limit files from fit_pars}
%\usage{df = collect_conf_files(conffiles);}
%\description
%    This function can be used to collect multiple output files from
%    fit_pars and produce an easily readable data structure from it.
%    It is important that all spectra are fit with the same model.
%    The output, explained based on the example of
%    tbnew_simple*powerlaw is as follows: 
%    
%    struct{ tbnew_simple_nh = struct{value = Double_Type[nfiles],
%                                     conf_min = Double_Type[nfiles], 
%                                     conf_max = Double_Type[nfiles]},
%            powerlaw_norm = struct{value = Double_Type[nfiles],
%                                   conf_min = ..., conf_max = ...},
%            powerlaw_phoindex = ... }
%            
%    where nfiles is the number of conffiles given and the entries of
%    the arrays value, conf_min, conf_max, etc. are the data fields of the
%    confidence limit files created by fit_pars. In addition, the
%    output contains the conffile names, the reduced chi^2, an array
%    of the parameters, and an array of the data field names.
%\example
%    variable conffiles = glob("*_conf.fits");
%    variable df = collect_conf_files(conffiles);
%    variable dummy_time = [0:length(conffiles)-1];
%    variable P = tiky_plot_new;
%    P.plot(dummy_time, df.powerlaw_phoindex.value, {0,0},
%         {df.powerlaw_phoindex.conf_min, df.powerlaw_phoindex.conf_max};
%         minmax);
%    
%\seealso{get_struct_field}
%!%-
  variable n_files = length(conffiles);
  
  variable ret = initialize_return_struct(conffiles[0], n_files);

  variable file_idx, par_idx, df_idx;
  _for file_idx (0, n_files-1, 1){
    variable conf_filename = conffiles[file_idx];

    ret.conf_filename[file_idx] = conf_filename;
    ret.chi2red[file_idx] = fits_read_key(conf_filename, "CHI2RED");
    
    variable df = fits_read_table(conf_filename);
    _for par_idx (0, length(ret.parnames)-1, 1){
      variable parfield = get_struct_field(ret, ret.parnames[par_idx]);
      _for df_idx (0, length(ret.datafield_names)-1, 1){
	variable entry = get_struct_field(parfield, ret.datafield_names[df_idx]);
	variable value = get_struct_field(df, ret.datafield_names[df_idx])[par_idx];
	entry[file_idx] = value;
      }
    }
  }
  return ret;
}
