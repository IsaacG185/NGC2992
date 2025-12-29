% ################################################################# %
% ####################   FITS_SAVE_FIT  ########################### %
% ################################################################# %


% =================== %
% NULL value for the FITS table
private variable null_var = " ";
private variable empty_var = "";

% field for each parameter
private variable fits_struct = ["value","lim","freeze","tie","units","fun","conf"];
% field seperator for 2d String in fits table
private variable sep_var = "\n";
% NULL value for CONF
private variable null_conf = 0;
% =================== %
public variable silent = -1;

% =================== %
define fits_conv_to_legal_char(aba_str)
% =================== %
%!%+
%\function{fits_conv_to_legal_char}
%\synopsis{converts a string into legal characters to be used as a FITS column name}
%\usage{String_Type legal_str = fits_conv_to_legal_char(String_Type str);}
%
%\seealso{fits_save_fit}
%!%-
  %
  % ********* WARNING: 'fits_save_fit' relies heavily on that function: Keep that
  %                    in mind when changing it!
  %
{
  aba_str = strtrans (aba_str,".", "");
  aba_str = strtrans (aba_str,"()", "_");
  return aba_str;
}

% =================== %
private define _fits_save_fit_extname(i,n)
  % =================== %
{
  % same extname for all files:
  return "fits_save_fit_"+string(i+1)+"-"+string(n);
}

% =================== %
define fits_save_fit_write()
% =================== %
%!%+
%\function{fits_save_fit_write}
%\synopsis{writes a FITS table with info on model and observation}
%\usage{fits_save_fit_write([, Struct/String_Type conf]);}
%\description
%
%   This function saves information about the model and the observation
%   in a FITS table. It uses the structure created by
%   fits_save_fit_struct. Using self-created structures might lead to
%   strange results. See "help fits_savs_fit" for more information.
%
%\seealso{fits_save_fit,fits_load_fit_struct}
%!%-
{
  variable name,str;
  switch (_NARGS)
  { case 2: (name, str) = (); }
  { help(_function_name()); return;  }
  % number of columns allowed by FITS
  variable _n_up = 998;
  % split if length of str exceeds this value
  variable strs = [split_struct_cols(str,_n_up)];
  variable n = length(strs);

  fits_write_binary_table(name, _fits_save_fit_extname(0,n), strs[0]);

  variable i;
  _for i(0, n-2,1)
  {
    fits_append_binary_table(name, _fits_save_fit_extname(i+1,n), strs[i+1]);
  }
  return;
}

% =================== %
private define _fits_save_fit_make_struct(p)
  % =================== %
{
  % convert the names to "FITS conform style"
  variable name = fits_conv_to_legal_char(p.name);

  % write limits into
  variable lim = Double_Type[1,2];
  lim[0,0] = p.min;
  lim[0,1] = p.max;
  % write limits into
  variable l_conf = Double_Type[1,2];
  l_conf[0,0] = null_conf;
  l_conf[0,1] = null_conf;
  % l_conf=null_conf;

  variable np = @Struct_Type(fits_struct);
  np.value = p.value;
  np.lim = lim;
  np.conf = l_conf;
  np.freeze = p.freeze;
  np.tie = [p.tie];
  np.units = [p.units]; % assures that the complete string and not only the first Char is written
  np.fun = [p.fun]; % same as above

  % write hard limits if desired
  if (qualifier_exists("hard_limits"))
  {
    variable hard_lim = Double_Type[length(p.min),2];
    hard_lim[*,0] = p.hard_min;
    hard_lim[*,1] = p.hard_max;
    np = struct_combine (np, struct{limhard=hard_lim} );
  }

  variable names = get_struct_field_names(np);
  variable n = length(names);

  % get the name of the parameter
  variable str_names = name + "_" + names;

  variable str = @Struct_Type([str_names]);

  variable i;
  _for i(0, n-1, 1)
  {
    set_struct_field(str, str_names[i], get_struct_field(np, names[i]));
  }

  return str;
}

% =================== %
private define _fits_save_fit_check_values(p)
  % =================== %
{
  p.tie = ( p.tie == NULL) ? 0 : p.tie;
  p.fun = ( p.fun == NULL) ? null_var : p.fun;
  p.hard_min = ( p.hard_min <= -DOUBLE_MAX ) ? -DOUBLE_MAX : p.hard_min;
  p.hard_max = ( p.hard_max >= DOUBLE_MAX ) ? DOUBLE_MAX : p.hard_max;
  p.units = ( p.units == "") ? null_var : p.units;
  return p;
}

% =================== %
define _fsf_add_string(str,na,info)
  % =================== %
{

  variable s = get_struct_field(str,na);
  variable t;
  variable datset = qualifier("datset",0) ;

  variable key = qualifier("key",NULL);
  ifnot (key == NULL)
  { % === %
    variable n = fits_get_num_hdus(info);

    variable i;
    _for i(0,n-1,1)
    {
      if(key=="MJDREF") { t = fits_read_key_int_frac(info+"["+string(i)+"]",key); }
      else { t = fits_read_key(info+"["+string(i)+"]",key); }
      if (t != NULL) break;
      }
    % check if the key word exists
    if (t == NULL)
    {
      if( silent == -1) vmessage(" *** Warning: key %s not contained in %s",key, info);
      t = null_var;
      if (qualifier_exists("double")) t = 0.;

      }
    % write the string
    info = t;
  }
  % === %

  % INTEGRAL speciality!!!! -> TFIRST and TLAST are set
  if ( (key == "TSTART" or key == "TSTOP") and ( typeof(info) == String_Type))  info = 0.;

  if( typeof(info) == String_Type) {
    s = s + (s==empty_var?empty_var:sep_var) + info;
    %   set_struct_field(str,na,s);
   }
  else {
    s[0,datset] = info ;
    %    set_struct_field(str,na,s);
   }
  set_struct_field(str,na,s);
  return str;
}

% =================== %
define fits_save_fit_struct()
% =================== %
%!%+
%\function{fits_save_fit_struct}
%\synopsis{saves the model and info of the observation to a structure}
%\usage{Struct_Type str = fits_save_fit_struct([, Struct/String_Type conf]);}
%\description
%
%   This function saves information about the model and the observation
%   in a structure table. Using fits_save_fit_write it can be written to a
%   fits file. See "help fits_save_fit" for more information.
%
%\seealso{fits_save_fit,fits_load_fit_write}
%!%-
{

  % get input parameters
  variable str = Struct_Type[0];
  variable conf_dat = NULL;
  variable info = qualifier("info",Struct_Type[0]);
  silent = qualifier_exists("silent") ? 1 : -1;
  switch (_NARGS)
  { case 1: (conf_dat) = (); }
  { _NARGS > 1: help(_function_name()); return;  }

  if (_typeof(conf_dat) == String_Type) conf_dat = fits_read_table(conf_dat);

  % =============  PARAMS ==================
  variable params = get_params();
  if (params == NULL)
  {
    if (silent != 1)
    {
      message(" *** Warning: No model has been loaded!");
      message(" *** No parameter values and confidence limits will be included.");
     }
   }
  else
  {

    variable param;
    foreach param(params)
    {
      % write NULL etc. correctly
      param = _fits_save_fit_check_values(param);
      % get the structures
      str = is_struct_type(str)==1?
	struct_combine(str,_fits_save_fit_make_struct(param;;__qualifiers)):
	_fits_save_fit_make_struct(param;;__qualifiers);
      }

    % =============  CONF ==================

    if (_typeof(conf_dat) == Struct_Type)
    {
      variable c,i,conf_name;
      _for i(0,length(conf_dat.name)-1,1)
      {
	conf_name=fits_conv_to_legal_char(conf_dat.name[i]);

	if ( length( where (get_struct_field_names(str) == conf_name+"_value") ) > 0)
	{

	  variable single_c = Double_Type[1,2];
	  single_c[0,0] = conf_dat.conf_min[i];
	  single_c[0,1] = conf_dat.conf_max[i];

	  set_struct_field(str,conf_name+"_value",conf_dat.value[i]);
	  set_struct_field(str,conf_name+"_conf",single_c);

	    }
	else
	{
	  vmessage(" *** Warning: confidence levels of %s could not be assigned",
		   conf_dat.name[i]);
	    }
	 }
      }

   }

  % =============  INFO ==================

  variable mi = struct{
    fit_fun=empty_var,
    tstart=0.,
    tstop=0.,
    tstart_mjd=0.,
    tstop_mjd=0.,
    exposure=0.,
    data=empty_var,
    bkg=empty_var,
    instrument=empty_var,
    target=empty_var,
    telescope=empty_var,
    filter=empty_var,
    date_obs=empty_var,
    date_end=empty_var,
    obs_id=empty_var,
    rebin=empty_var,
    notice_list=empty_var,
    chi_red=0.,
    chi=0.,
    dof=0,
    fit_statistic=empty_var,
    cwd=[getcwd],
    mjdref=0.,
    sys_err=empty_var
  };

  % write info of the data
  variable dummy_fpt;
  if (all_data == NULL){
     
     mi.exposure = Double_Type[1,1];
    mi.tstart = Double_Type[1,1]; mi.tstop = Double_Type[1,1]; mi.mjdref = Double_Type[1,1] ;
    mi.tstart_mjd = Double_Type[1,1]; mi.tstop_mjd = Double_Type[1,1];
    mi.tstart[0,0]=0.;
    mi.tstop[0,0]=0.;
    mi.tstart_mjd[0,0]=0.;
    mi.tstop_mjd[0,0]=0.;
    mi.exposure[0,0]=0.;
     
  } else {
    variable len = length(all_data);

    % ==== INTEGRAL  ====
    % check if one of the intruments is INTEGRAL
    variable integral = 0;
    variable all_dat_info = Struct_Type[len];
    _for i(0,len-1,1)
    {
      all_dat_info[i] = get_data_info(all_data[i]);
      if ( (all_dat_info[i].file != "") &&
	   (_fits_open_file(&dummy_fpt,all_dat_info[i].file,"r") == 0 ) )% make sure data files exist and is fits
      {
	if (fits_read_key(all_dat_info[i].file,"TELESCOP") == "INTEGRAL")
	  integral = 1;
       }
    }

    % merged integral does not have useful TSTART and TSTOP, TFIRST
    % and TLAST:
    % -> add more fields
    if (integral == 1)
    {
      variable mi_integ = @Struct_Type(["tfirst_mjd","tlast_mjd"]);
      set_struct_fields(mi_integ,0.,0.);
      variable tfirst_mjd = Double_Type[1,len];
      variable tlast_mjd = Double_Type[1,len];
      mi_integ.tfirst_mjd = Double_Type[1,len]; mi_integ.tlast_mjd = Double_Type[1,len] ;
     }

    % ===================

    variable exposure = Double_Type[1,len];
    mi.tstart = Double_Type[1,len]; mi.tstop = Double_Type[1,len]; mi.mjdref = Double_Type[1,len] ;
    mi.tstart_mjd = Double_Type[1,len]; mi.tstop_mjd = Double_Type[1,len];

    _for i(0,len-1,1)
    {
      variable dat_info = all_dat_info[i];
      % make sure data files exist and
      if ( access( dat_info.file, F_OK ) == 0 )
      {
	mi = _fsf_add_string(mi,"data",dat_info.file);
	mi = _fsf_add_string(mi,"bkg",dat_info.bgd_file);
	mi = _fsf_add_string(mi,"instrument",dat_info.instrument);

	% make sure data files is fits
	if( _fits_open_file(&dummy_fpt,dat_info.file,"r") == 0 )
	{
	  mi = _fsf_add_string(mi,"telescope",dat_info.file;key="TELESCOP");
	  mi = _fsf_add_string(mi,"sys_err",sys_err_array2string(get_sys_err_frac(all_data[i])));
	  mi = _fsf_add_string(mi,"date_obs",dat_info.file;key="DATE-OBS");
	  mi = _fsf_add_string(mi,"date_end",dat_info.file;key="DATE-END");
	  mi = _fsf_add_string(mi,"obs_id",dat_info.file;key="OBS_ID");
	  mi = (integral==1)
	    ? _fsf_add_string(mi,"target",dat_info.file;key="NAME")
	      : _fsf_add_string(mi,"target",dat_info.file;key="OBJECT");
	  mi = _fsf_add_string(mi,"filter",dat_info.file;key="FILTER");
	  mi = _fsf_add_string(mi,"tstart",dat_info.file;key="TSTART",datset=i,double);
	  mi = _fsf_add_string(mi,"tstop",dat_info.file;key="TSTOP",datset=i,double);
	  mi = _fsf_add_string(mi,"mjdref",dat_info.file;key="MJDREF",datset=i,double);

	  mi.tstart_mjd[0,i] = mi.tstart[0,i]/86400. + mi.mjdref[0,i];
	  mi.tstop_mjd[0,i] = mi.tstop[0,i]/86400. + mi.mjdref[0,i];
	  
	  if (integral == 1)  % ====  INTEGRAL  =====  %
	  {
	    mi_integ = _fsf_add_string(mi_integ,"tfirst_mjd",dat_info.file;key="TFIRST",datset=i,double);
	    mi_integ = _fsf_add_string(mi_integ,"tlast_mjd",dat_info.file;key="TLAST",datset=i,double);
	    if (mi_integ.tfirst_mjd[0,i] != mi_integ.tlast_mjd[0,i])
	    {
	      mi_integ.tfirst_mjd[0,i] += mi.mjdref[0,i];
	      mi_integ.tlast_mjd[0,i] += mi.mjdref[0,i];
	    }
	  }
	}
      }
      
      exposure[0,i] = get_data_exposure(all_data[i]);
      
      variable reb = null_var, notice = null_var;
      if (length(dat_info.notice_list) > 0)
      {
	reb = rebin_isis2human(dat_info.rebin);
	notice = notice_isis2human(dat_info.notice_list);
      }
      mi.rebin = mi.rebin+(i>0?sep_var:"")+reb;
      mi.notice_list = mi.notice_list+(i>0?sep_var:"")+notice;

     }
    variable target = dat_info.target;

    if (integral == 1) mi = struct_combine(mi,mi_integ);

    mi.exposure = exposure;

    mi.fit_statistic=get_fit_statistic;
    if((strtok(mi.fit_statistic,";")[0] == "chisqr") || (strtok(mi.fit_statistic,";")[0] == "cash") )
    {
      variable tmp_stat, tmp_verb;
      tmp_verb = Fit_Verbose;Fit_Verbose=-1;
      () = eval_counts(&tmp_stat);
      Fit_Verbose=tmp_verb;

      mi.chi = tmp_stat.statistic;
      mi.dof = tmp_stat.num_bins-tmp_stat.num_variable_params;
      mi.chi_red = mi.chi/mi.dof;
     }
  }
  % make sure that all Strings are written complete
  mi.data = [mi.data];mi.bkg = [mi.bkg];mi.instrument = [mi.instrument]; mi.telescope=[mi.telescope];
  mi.date_obs=[mi.date_obs];mi.date_end=[mi.date_end];mi.target=[mi.target];mi.filter=[mi.filter];
  mi.rebin=[mi.rebin];mi.notice_list=[mi.notice_list];mi.obs_id=[mi.obs_id];mi.fit_statistic=[mi.fit_statistic];
  mi.fit_fun=[mi.fit_fun];mi.sys_err=[mi.sys_err];

  % write fit function
  if (get_fit_fun()!=NULL) mi.fit_fun = [get_fit_fun()];

  if (is_struct_type(info) == 1)
  {
    mi = struct_combine(mi,info);
  }

  % write the fits file
  if (is_struct_type(str) == 1) str = struct_combine(mi,str);
  else str = mi;

  return str;
}

% =================== %
define fits_save_fit()
% =================== %
%!%+
%\function{fits_save_fit}
%\synopsis{saves the model and info of the observation to a FITS table}
%\usage{fits_save_fit(String_Type filename[, Struct/String_Type conf]);}
%\description
%
%   This function saves information about the model and the observation
%   in a FITS table. This routine combines the calls of
%   \code{fits_save_fit_struct} and \code{fits_save_fit_write}.
%
%   Additionally, confidence intervals can be given in form of a
%   structure, containig the fields
%   \code{name}:      name of the parameter like given in fit_fun(...)
%   \code{value}:     best fit value of the parameter (might have changed
%                     during error calculation)
%   \code{conf_min}:  lower confidence limit
%   \code{conf_max}:  upper confidence limit
%
%   Therefore, the conf-Structure would, e.g., look like
%
%   variable conf = struct {
%                 name = ["powerlaw(1).index","powerlaw(1).norm"],
%                 value = [2,1e-4],
%                 conf_min = [1.8,1e-5],
%                 conf_max = [2.2,2e-4]
%                 };
%
%   Alternatively, the filename of a FITS table created by
%   pvm_fit_pars or the structure returned by pvm_fit_pars can be given.
%
%
%   The values of the model are overwritten, as the error calculation
%   should only yield values equal or better than the original ones.
%
%\qualifiers{
%\qualifier{info=Struct_Type}{appends the given structure to the table}
%\qualifier{hard_limits}{also saves all hard limits of the parameters}
%\qualifier{silent}{no warnings are printed to STDOUT}
%}
%\seealso{fits_load_fit_struct,fits_write_TeX_table,save_par,pvm_fit_pars,fits_save_fit_struct,fits_write_fits_struct,fits_list_fit_pars}
%!%-
{
  % get input parameters
  variable name;
  variable str;
  variable conf_dat = NULL;
  variable info = qualifier("info",Struct_Type[0]);

  switch (_NARGS)
  { case 1: (name) = (); str = fits_save_fit_struct(;;__qualifiers);}
  { case 2: (name, conf_dat) = (); str = fits_save_fit_struct(conf_dat;;__qualifiers);}
  { help(_function_name()); return; }

  fits_save_fit_write(name,str);

  return;
}
