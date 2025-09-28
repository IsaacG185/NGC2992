% -*- mode: slang; mode: fold -*-
require( "xfig" );

private variable steppar_mainkeys = %{{{
  % list of the main keys for steppar
  strlow(["extname",
	  "fit_method",
	  "fit",
	  "statistic",
	  "num_variable_params",
	  "num_bins",
	  "pname",
	  "pidx",
	  "pval",
	  "pmin",
	  "pmax"
	 ]);
%}}}
private define struct_fieldnames_to_lowercase( s ){ %{{{
  % converts the fieldnames of a Struct_Type to lower cases!
  variable fn = get_struct_field_names( s );
  variable ls = @Struct_Type(strlow(fn));

  variable f;
  foreach f(fn){
    set_struct_field( ls, strlow(f), get_struct_field( s, f ) );
  }
  return ls;
}
%}}}


%%%%%%%%%%%%%%%%%%%%
define steppar_save() %{{{
%%%%%%%%%%%%%%
%!%+
%\function{steppar_save}
%\synopsis{Saves steppar information (& keys) to a *.fits file}
%\usage{steppar_save( String_Type file, Struct_Type[] steppar [, keys]);}
%\description
%      Saves the output of 'steppar' to a *.fits file. 
%\seealso{steppar}
%!%-
{
  variable file, sp, keys=NULL;
  switch(_NARGS)
  { case 2: (file, sp) = (); }
  { case 3: (file, sp, keys) = (); }
  { help(_function_name);return;}

  variable nf = length(sp);
  variable extnames;
  if( keys==NULL ){
    keys = struct_array(nf,@Struct_Type(String_Type[0]));
    extnames = array_map( String_Type, &sprintf, "PID%05d",[1:nf] );
  }
  else{
    extnames = array_struct_field ( keys, "extname");
  }
  variable i = wherenot(is_substr(extnames,"PID"));
  extnames[i] = "PID"+extnames[i];
  
  variable fp = fits_open_file(file,"c");
  _for i ( 0, nf-1, 1 ){
    fits_write_binary_table( fp, extnames[i], sp[i], keys[i] );
  }
  fits_close_file(fp);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%
define steppar_load() %{{{
%%%%%%%%%%%%%%
%!%+
%\function{steppar_load}
%\synopsis{loads saved steppar information}
%\usage{ Struct_Type[] steppar = steppar_load( String_Typep[] pat ); }
%\altusage{ Struct_Type[] steppar, keys = steppar_load( String_Type[] pat ; keys ); }
%\qualifiers{
%\qualifier{keys}{If given also the key structure is returned (using fits_read_header).
%                   If keys is a List_Type with keynames, only these keys are read using
%                   fits_read_key_struct, which is faster!}
%\qualifier{ext}{Only loads extension fitting 'ext' (String_Type)!}
%}
%\description
%     Loads a *.fits file storing the steppar information saved with
%     steppar_save. The given string 'pat' can be a single file
%     including several extension, an array with files or used as
%     a pattern for multiple files in globbing format (see glob).
%     
%\seealso{steppar, steppar_save, glob}
%!%-
{
  variable ext = qualifier("ext",NULL);
  variable chatty = qualifier_exists("chatty") ? 1:0;
  
  variable file;
  switch(_NARGS)
  { case 1: file = (); }
  { help(_function_name);return;}

  % Find all files matching the given pattern 'file' and sort them
  file = glob(file);
  file = file[array_sort(file)];
  
  variable sp = Struct_Type[0];
  variable sk = Struct_Type[0];
  
  variable keys = qualifier("keys");

  variable N=0,next;
  variable extind = [*];
  variable extread;
  
  % LOOP over each file
  variable f,i;
  foreach f(file){

    ifnot( access( f, R_OK )==0 ){
      vmessage( "ERROR <%s>: No permission to read file:\n %s",
		_function_name,f);
      continue;
    }
    
    next = fits_nr_extensions (f);
    if( next < 0 ){
      vmessage( "WARNING <%s>: No extension in file:\n %s",
		_function_name,f);
      continue;
    }
    sp   = [ sp, Struct_Type[next] ];
    if( qualifier_exists("keys") != NULL ){
      sk = [ sk, Struct_Type[next] ];
    }

    if( chatty ){
      vmessage(" INFO <%s>: Loading '%s' with %d extensions!",
	       _function_name, f, next );
    }
    
    % LOOP over each extension of current file:
    _for i ( 1, next, 1 ){
      % If a specific extension name is given, only load this extension!
      extread = fits_read_key( sprintf("%s[%d]",f,i), "extname" );
      if( ext != NULL and ext != extread ){
	continue;
      }
      
      sp[i-1+N]   = fits_read_table( sprintf("%s[%d]",f,i); casesen );
      
      % Only read header(keys), if qualifier exists and convert names to lower case
      if( qualifier_exists("keys") ){
	if( typeof(keys) == List_Type ){
	  sk[i-1+N] = fits_read_key_struct( sprintf("%s[%d]",f,i), __push_list(keys) );
	}
	else{
	  sk[i-1+N] = fits_read_header( sprintf("%s[%d]",f,i) );
	  sk[i-1+N] = struct_fieldnames_to_lowercase( sk[i-1+N] );
	}
      }
      
      if( ext == extread ){
	extind = i-1+N;
	break;
      }
    }
    % If a specific extension name is given, stop loading if it was found!
    if( ext == extread ){
      break;
    }
    N += next;
  }
  
  if( ext != NULL and length(extind) == 0 ){
    vmessage("WARNING: <%s>: No extension '%s' found!",_function_name,ext);
    extind = Integer_Type[0];
  }
  
  if( qualifier_exists("keys") )
    return sp[extind],sk[extind];
  else
    return sp[extind];
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define _steppar_get_params() %{{{
{
  variable chatty = qualifier_exists("chatty") ? 1 : 0;
  variable paridx = qualifier("paridx");
  
  variable sp, ind;
  switch(_NARGS)
  { case 2: (sp,ind) = (); }
  { return NULL; }
  
  variable params = get_params;
  variable newparams = Struct_Type[0];
  
  variable i, pname, val;
  _for i ( 0, length(params)-1, 1 ){
    if(qualifier_exists("paridx") && not(any(paridx==params[i].index)) ){
      continue;
    }    
    pname = escapedParameterName(params[i].name);
    if( struct_field_exists( sp, pname ) ){
      val = get_struct_field( sp, pname )[ind];
      if( chatty ){
	vmessage(" Setting: (%.3d) %s = %g  was  %g",
		 params[i].index, params[i].name, val, params[i].value );
      }
      newparams = [ newparams, Struct_Type[1] ];
      newparams[-1] = COPY( params[i] );
      set_struct_field( newparams[-1], "value", val );
    }
  }
  return newparams;
}
%}}}
private define _steppar_get_bestparams() %{{{
{
  variable fv = Fit_Verbose;
  Fit_Verbose = -1;
  variable minchi2 = qualifier("minchi2",eval_stat_counts.statistic);
  Fit_Verbose = fv;

  variable chatty = qualifier_exists("chatty") ? 1 : 0;
  
  variable sp;
  switch(_NARGS)
  { case 1: sp = (); }
  { help(_function_name); return; }

  if( _typeof( sp ) == String_Type )
    sp = steppar_load( sp );
  else ifnot( _typeof(sp)==Struct_Type ){
    vmessage("ERROR: <%s>: Argument has to be String or Struct_Type!",
	     _function_name); return NULL;
  }
  
  % Find indices where chi2 is minimal
  variable imin = NULL;
  variable jmin, chi2, noz;
  variable _vmin, vmin = minchi2;
 
  variable i;
  _for i ( 0, length(sp)-1, 1 ){
    chi2 = get_struct_field( sp[i], "chi2" );
    noz = where(chi2>0);
    _vmin = min(chi2[noz]);
    if( _vmin < vmin){
      vmin = _vmin;
      imin = i;
      jmin = noz[where_min(chi2[noz])][0];
    }
  }
  if( imin == NULL ){
    if( chatty )
      vmessage(" WARNING <%s>: No better parameter set found, which beats chi2=%g",
	       _function_name, minchi2 );
    
    return Struct_Type[0];
  }
  else if ( chatty ){
    vmessage(" INFO <%s>: Better parameter set for '%s' with chi2=%g found (%d,%d)!",
	     _function_name,
	     get_struct_field_names(sp[imin])[0],
	     vmin,imin,jmin
	    );
  }
  return _steppar_get_params( sp[imin], jmin ;; __qualifiers );
}
%}}}%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define steppar_get_bestparams() %{{{
%%%%%%%%%%%%%%
%!%+
%\function{steppar_get_bestparams}
%\synopsis{ Extracts new best fit parameter values out of steppar information }
%\usage{ Struct_Type[] params = steppar_get_bestparams( String_Type[] File );}
%\altusage{ Struct_Type[] params = steppar_get_bestparams( Struct_Type[] steppar );}
%\qualifiers{
%\qualifier{chatty}{Information output}
%\qualifier{minchi2}{Chi2 limit the new parameter set has to beat
%                      to be taken into accounts!
%                      Default: eval_stat_counts.statistic}
%\qualifier{groups}{Allows to extract best parameter sets for defined parameter
%                     groups. 'groups' has to be an Array_Type, where each entry
%                     represents a group and contains an Integer/String array
%                     with the according parameter indices/names.
%                     Useful in combination with 'simultaneous_fit' settings, e.i.
%                     groups = %.model.groups!}
%}
%\description
%      This function searches for the minimal chisqr value within the given
%      files/steppar information and returns a parameter structure with the
%      according parameters (see get_params). With the groups qualifier a
%      groupping can be specified, i.e., the search for a minimal chi2 is
%      done for each individual groups. The returned structure array
%      only contains those parameter, which lead to the better chi2 value.
%      If no better chi2 was found or there was no better chi2 than the
%      specified minchi2 value, the function returns Struct_Type[0].
%
%      ATTENTION:
%      It is neccessary that the model with which the steppar was executed
%      is loaded as this functions uses get_params and only changes those
%      values of the freeParameters as the values of the frozen ones are
%      not saved!
%      If another parameter set is loaded there will be a difference in
%      the new chi2 value this function gives (use 'chatty') and that
%      chi2 an eval_counts will return!
%\seealso{get_params}
%!%-
{
  variable chatty = qualifier_exists("chatty") ? 1 : 0;
  
  variable groups = Array_Type[1];
  groups[0] = [1:get_num_pars];
  groups = qualifier("groups",groups);

  variable sp;
  switch(_NARGS)
  { case 1: sp = (); }
  { help(_function_name); return; }

  if( _typeof( sp ) == String_Type )
    sp = steppar_load( sp );
  else ifnot( _typeof(sp)==Struct_Type ){
    vmessage("ERROR: <%s>: Argument has to be String or Struct_Type!",
	     _function_name); return NULL;
  }
  
  variable escnames, grpind, ind;

  variable newparams = Struct_Type[0];

  % get names of stepped parameter
  variable spnames = String_Type[0];
  variable i, j;
  _for i ( 0, length(sp)-1, 1 ){
    spnames = [ spnames, get_struct_field_names( sp[i] )[0] ];
  }
  % get the parameters for each group
  _for i ( 0, length(groups)-1, 1 ){
    if( chatty and qualifier_exists("groups") ){
      vmessage(" INFO <%s>: Group %d/%d:",
	       _function_name, i+1, length(groups) );
    }

    % ensure that groups are parameter indices!
    grpind    = array_struct_field( get_par_info( groups[i] ), "index" );
    % get escaped parameter names
    escnames  = array_struct_field( get_par_info( groups[i] ), "name" );
    escnames  = array_map( String_Type, &escapedParameterName, escnames );
    % determine steppar array indices
    ind = Integer_Type[0];
    _for j ( 0, length(spnames)-1, 1 ){
      if( any( spnames[j] == escnames ) ){
	ind = [ ind, j ];
      }
    }
    newparams = [ newparams,
		 _steppar_get_bestparams( sp[ind];;struct_combine(__qualifiers,struct{paridx=grpind}))
		];
  }
  return newparams;
}
%}}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define array_split_at_extrema( a ) %{{{
%!%+
%\function{array_split_at_extrema}
%\synopsis{Splits an array into monotone chucks}
%\usage{ Array_Type[] I = array_split_at_extrema( array );}
%!%-
{
  variable I = Array_Type[1];
  I[0] = [0,1];
  
  variable signum = sign((shift(a,1)-a)[[:-2]]);
  signum[where(signum==0)]=1;
  
  variable i, ind=0;
  _for i ( 1, length(signum)-1, 1 ){
    if( signum[i] == signum[i-1] ){
      I[ind] = [ I[ind], i+1 ];
    }
    else{
      ind++;
      I = [ I, Array_Type[1] ];
      I[ind] = [i,i+1];
    }
  }
  return I;
}
%}}}
define steppar_get_conf() %{{{
%%%%%%%%%%%%%%
%!%+
%\function{steppar_get_conf}
%\synopsis{Obtains confidence limits out of steppar information}
%\usage{ Struct_Type[] conf = steppar_get_conf( String_Type[] File );}
%\altusage{ Struct_Type[] conf = steppar_get_conf( Struct_Type[] steppar );}
%\qualifiers{
%\qualifier{chatty}{Information output}
%\qualifier{dchi2}{[=2.71] Delta Chisqr}
%}
%\description
%      Tries to obtain confidence level related to the given 'dchi2'
%      value (default: 2.71) based on the steppar information.
%      To do so this function calculates interpolated intersections
%      of the chi2 landscape and min(chi2)+'dchi2'.
%      Only if 2 or more such intersections are found the confidence
%      limits are set. In case of more then 2 solutions always the
%      minimal/maximal solutions are taken.
%\seealso{interpol}
%!%-
{
  variable chatty = qualifier_exists("chatty") ? 1 : 0;
  variable dchi2   = qualifier("dchi2",2.71);
  
  variable sp;
  switch(_NARGS)
  { case 1: sp = (); }
  { help(_function_name); return; }

  if( _typeof( sp ) == String_Type )
    sp = steppar_load( sp );
  else ifnot( _typeof(sp)==Struct_Type ){
    vmessage("ERROR: <%s>: Argument has to be String or Struct_Type!",
	     _function_name); return;
  }

  variable N = length(sp);
  variable s = struct{
    index, name, value, min, max, conf_min, conf_max    
  };
  s = struct_array( N, s );

  % OBTAIN PAR INDICES
  variable pnames = array_map( String_Type, &escapedParameterName, array_struct_field( get_params, "name" ) );
  
  variable fn, p, pmin, pmax, chimin;
  variable sa, isort;
  variable _isec, isecs;
  variable i,j;
  _for i ( 0, N-1, 1 ){
    fn = get_struct_field_names(sp[i])[0];
    p = get_struct_field( sp[i], fn );
    s[i].min   = min(p);
    s[i].max   = max(p);
    s[i].name  = fn;
    s[i].index = wherefirst( fn == pnames )+1;
    
    chimin = min( sp[i].chi2 );
    sa = array_split_at_extrema(sp[i].chi2);
    isecs = Double_Type[0];
    _for j ( 0, length(sa)-1, 1 ){
      isort = array_sort(sp[i].chi2[sa[j]]);
      _isec = interpol( chimin+dchi2, sp[i].chi2[sa[j]][isort], p[sa[j]][isort] );
      pmin = min(p[sa[j]]);
      pmax = max(p[sa[j]]);
      if( pmin <= _isec <= pmax ){
	isecs = [ isecs, _isec ];
      }
    }
    if( length(isecs) > 1 ){
      s[i].conf_min = isecs[0];
      s[i].conf_max = isecs[-1];
    }
  }
  
  return s;
}
%}}}

%%%%%%%%%%%%%%%
define steppar() %{{{
%%%%%%%%%%%%%%
%!%+
%\function{steppar}
%\synopsis{performs a fit while stepping the value of a fit parameter through a given range}
%\usage{Struct_Type info = steppar(String/Integer_Type par [, Double_Type val1, val2, step] );}
%\altusage{(Struct_Type info, keys) = steppar( String/Integer_Type par [, Double_Type val1, val2, step]; keys);}
%\qualifiers{
%\qualifier{keys}{An additional structure is returned that can be used as FITS header keys}
%\qualifier{frozen}{[=0] Perform steppar also for frozen Parameters.}
%\qualifier{range}{[parmin,parmax] Stepping range. Default is the
%                   minimal/maximal allowed parameter value.}
%\qualifier{nsteps}{[=10] Number of steps the parameter 'par' is
%                   stepped from range[0] to range[1].}
%\qualifier{reset}{If given after each step the initial parameter set, which was
%                    valid before this function was called, is restored.}
%\qualifier{fit}{[=&fit_counts] Reference to the function running the fit algorithm.}
%\qualifier{fitargs}{Arguments required by the 'fit' function. See __push_list for
%                    format information!}
%\qualifier{rerun}{Reruns a stepping procedure based on results of a previous run,
%                    i.e., before each step the according parameter set of the previous
%                    run is loaded, e.g., to improve the results using another fit_method.}
%\qualifier{resume}{Missing steps in the given steppar-file will be calculated based
%                     on the previous steps, i.e., resuming the stepping where it was
%                     stopped.}
%\qualifier{stepping}{Provide user defined grid [Array_Type], e.g., for a log grid (default: linear)}
%\qualifier{check}{[=0] Before each step saved steppar informations of other stepped
%                        parameters are gathered and checked for a parameter set with a
%                        better chi2 (using steppar_get_bestparams). In case a better
%                        parameter set was found the stepping will be restarted.
%                        * ATTENTION: 'save' qualifier is required !!!
%                        * Gathered are steppar-files, which match the pattern
%                          given with 'save',e.g., if save is "steppar_PID00001.fits"
%                          all files "steppar_PID?????.fits" are globed!
%                          Note that the affix "_PID???" is automaticcaly appended to
%                          the save string if it does not exist (see 'save' qualifier!)
%                        * The Integer 'check' is set to is the maximal number of
%                          restarts.
%                        * A parameter set is considered better if
%                          chi2_new < chi2_init * ( 1 - dchi2 )
%                        * NOTE: Parameter grouping is possible (see steppar_get_bestparams)
%                        }
%\qualifier{dchi2}{[=0.1] Percental limit for the chi2 of a new parameter set to be
%                  considered as a better parameter set (see 'check'):
%                  chi2_new < chi2_init * ( 1 - dchi2 ).}
%\qualifier{save}{After each stepping the result is saved in the file given
%                   (as String_Type) with this qualifier. The chi2 of undone steps
%                   are set to 0.! Also note that the filename is appended with
%                   the parameterindex: 'steppar.fits' -> 'steppar_PID00001.fits'}
%\qualifier{force}{Forces to overwrite an existing file given with 'save'.}
%\qualifier{chatty}{Prints fitting information.}
%}
%\description
%    The given parameter is stepped through in the given parameter 'range',
%    which is devided into 'nsteps' equidistant value points. If 'val1', 'val2'
%    and 'step' are given 'range' = ['val1','val2'] and
%    'nsteps' = ('val2'-'val1')/'step'.
%    At each of this points a fit is performed. The fitting starts with the
%    value point closed to the best fit value and alternatingly progresses outwards
%    to each side. The 'reset' qualifier restores the initial parameter set
%    after each step, otherwise the parameter set of the nearest stepping point
%    is used.
%    The 'rerun' qualifier allows to rerun a stepping using the steppar information
%    of a previous run, i.e., at each step the according parameter set of that
%    previous run is loaded before the fit algorithm is started.
%    In case the steppar function was killed, the 'resume' qualifier
%    can be used to resume the stepping (given that 'save' was used!).
%    If the 'save' qualifier is given the results of the stepping are stored
%    as a .fits file after each step! NOTE that the affix "_PID?????" is
%    automatically appended to the filename (if not already included), where
%    the ??? are the ID of the stepped parameter. If the specified file
%    already exists an error is thrown if the 'force' qualifier for overwriting
%    is not set.
%    The 'save' qualifier is also requiered if the 'check' for a better
%    parameter set is enabled, i.e., before each step it is checked if there
%    is a parameter set amongst other stepped parameters with
%    chi2 < chi2_init * ( 1 - 'dchi2') leading to a restart of the stepping
%    using the better parameter set, where chi2_init is the chi2 of the parameter
%    set the stepping was initialized with (which will be updated after a restart).
%    The maximal number of restarts is given by 'check'.
%    This qualifier is useful if several steppar processes are running at the same
%    time saving their results after each step to a fits-file, as in this case
%    a better fit will be automatically applied! NOTE THAT using 'check'
%    can lead to inconsistent steppar resulsts in terms of inital parameter sets,
%    e.g., one steppar process is already finished and afterwards in another one
%    a better parameter set is found leading to a reastart in the remaining
%    steppar processes!
%
%    => After using 'check' either make sure all steppar run with the same initial
%       parameter set or manually extract the best parameter set and run all steppars
%       once more!    
%    
%    The fitting itself is performed using the 'fit' function, to which
%    all qualifiers are passed, which gets the 'fitargs' as arguments (see
%    __push_list).
%    
%    IMPORTANT:
%      steppar is based on the current version of the parameter set!
%       
%    KEYS:
%     fit_method: fit method used for fitting (see get_fit_method)
%     statistic:  chisqr according to the parameter set the function was callled with
%     num_variable_params:
%     num_bins:
%     pval:       initial value of the stepped parameter    
%     pname:      exact name of the stepped parameter
%     %_freeze, %_min, %_max: additional information about the parameters, where
%                             % is the escapedParameterName
%\seealso{}
%!%-
{
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%% QUALIFIERS

  % fkt is a function pointer executed in each step, called
  % with fitargs as arguments (see __push_list)
  variable fit     = qualifier("fit",&fit_counts);
  variable fitargs = qualifier("fitargs",{});
  
  variable frozen = qualifier_exists("frozen") ? 1 : 0;
  variable reset  = qualifier_exists("reset") ? 1 : 0;
  variable nsteps = nint(qualifier("nsteps",10));
  variable range  = qualifier("range");

  variable chatty = qualifier_exists("chatty") ? 1 : 0;
  variable fitverbosity = Fit_Verbose;
  
  variable save   = qualifier("save");
  variable rerun = qualifier("rerun",NULL);
  variable resume = qualifier("resume",NULL);
  variable force  = qualifier_exists("force") ? 1 : 0;

  variable check  = qualifier("check",0);
  variable dchi2  = qualifier("dchi2",0.1);
  if( check and not(qualifier_exists("save")) ){
    vmessage("ERROR <%s>: 'check' requires 'save' qualifier!",
	     _function_name);
    return;
  }
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%  ARGUMENTS
  variable par, val1, val2, step;
  switch(_NARGS)
  { case 1: par = (); }
  { case 4: (par, val1, val2, step) = ();
    range  = [_min(val1,val2),_max(val1,val2)];
    nsteps = nint(abs(val2-val1)/step);
  }
  { help(_function_name); return; }

  ifnot( chatty ){ Fit_Verbose = -1; }
  
  %%% Parameter checks:
  % check for parameter existence (if multiple, chosing first)
  variable parinfo = get_par_info(par)[0];
  if( parinfo == NULL ){
    vmessage("ERROR <%s>: No parameter to given par=%s found!",
	     _function_name,par );
    return NULL;
  }
  par = parinfo.name;
  
  variable pidstr = sprintf("PID%05d",parinfo.index);

  % SAVE: Preparation
  variable path, fname, base;  
  if( qualifier_exists("save") ){
    % rearrange save path
    path = path_dirname(save) + "/";
    fname = path_basename_sans_extname(save);
    ifnot( is_substr(fname,pidstr) ){
      fname += "_" + pidstr;
    }
    fname += ".fits";
    save = path+fname;
    
    % Check Directory Tree (create it if not existent)
    if( access(path,F_OK) == -1 ){
      ()=mkdir_rec(path);
    }
    
    % Does file already exist?
    if( access( save, F_OK) == 0 and force == 0 ){
      vmessage("ERROR: <%s> File('%s') does already exist (Use 'force' qualifier to overwrite!",
	       _function_name, save );
      return NULL;
    }
  }

  % check if frozen
  if( parinfo.freeze == 1 ){
    if( frozen ){
      vmessage("WARNING <%s>: '%s' frozen: continnuing, due to 'frozen' qualifier!",
	       _function_name, par);
    }
    else{
      vmessage("WARNING <%s>: '%s' frozen: QUITTING!",
	       _function_name, par);
      return NULL;
    }
  }
  % Check & set par range
  if( qualifier_exists("range") or _NARGS==4 ){
    range = [ min(range), max(range) ];
    if( range[0] < parinfo.hard_min ){
      vmessage("WARNING <%s>: min(range) = %.3f < parmin = %.3f! Setting min(range) = parmin!",
	       _function_name, range[0], parinfo.hard_min );
      range[0] = parinfo.hard_min;
    }
    if( range[1] > parinfo.hard_max ){
      vmessage("WARNING <%s>: max(range) = %.3f > parmax = %.3f! Setting max(range) = parmax!",
	       _function_name, range[1], parinfo.hard_max );
      range[1] = parinfo.hard_max;
    }
  }
  else{
    range = [ parinfo.min, parinfo.max ];
  }

  variable originalparams = get_params();
  
  % Initializing output struct
  variable ifields, kfields, param, paramname;
  ifields = [ escapedParameterName(par), "chi2", "chi2red" ];
  foreach param (originalparams){
    if(param.freeze==0){
      paramname = escapedParameterName(param.name);
      if(paramname != ifields[0])
	ifields = [ifields, paramname];
    }
  }
  variable info = @Struct_Type(ifields);
  foreach param (ifields){
    set_struct_field(info, param, Double_Type[nsteps]);
  }

  variable init_stat;
  () = eval_counts(&init_stat);

  % Keys
  variable keys = @Struct_Type(steppar_mainkeys);
  keys.extname  = pidstr;
  keys.fit_method = get_fit_method();
  (,keys.fit) = get_variable_name(&fit);
  %keys.statistic = init_stat.statistic;
  keys.num_variable_params = init_stat.num_variable_params;
  keys.num_bins = init_stat.num_bins;
  keys.pname = parinfo.name;
  keys.pidx  = parinfo.index;
  %keys.pval = parinfo.value;
  keys.pmin = parinfo.min;
  keys.pmax = parinfo.max;

  kfields = String_Type[0];
  foreach param (originalparams)
    kfields = [kfields, escapedParameterName(param.name) + ["_freeze", "_min", "_max"]];
  keys = struct_combine( keys, @Struct_Type(kfields) );
  foreach param (originalparams){
    paramname = escapedParameterName(param.name);
    set_struct_field(keys, paramname+"_freeze", param.freeze);
    set_struct_field(keys, paramname+"_min",    param.min);
    set_struct_field(keys, paramname+"_max",    param.max);
  }

  %%% Resume/Rerun file check
  % - In case both qualifiers are given, rerun overwrites resume!
  % - stephistory: Ref-array containing pointer to steppar info
  %                in which paramter set for initialization are
  %                searched ('info' is the current one). If file
  %                check is successfull loaded information is added
  %                to this array.
  % - rsm_sp,rsm_k: Struct_Types which store loaded steppar files
  %                 rsm_sp is set to info to ensure rsm_sp has
  %                 the same struct fields!
  
  variable stephistory = [&info];
  variable rsm_sp = COPY(info);
  variable rsm_k, lsp, lk;
  
  variable refile = qualifier("rerun",qualifier("resume",NULL));
  if( refile != NULL && access( refile, F_OK) == 0 ){
    (lsp,lk) = steppar_load( refile ; keys, ext=pidstr );
    if( length(lsp) != 0 ){
      rsm_sp = lsp[0];
      rsm_k = lk[0];
      
      stephistory = [ stephistory, &rsm_sp ];
      % rerun test, keys should be equal!
      foreach param(["extname","num_variable_params","num_bins","pname","pidx"]){
	ifnot( _eqs( get_struct_field(keys,param), get_struct_field(rsm_k,param) ) ){
	  vmessage("ERRO: <%s>: Key '%s' of file-to-rerun/resume ('%s') does not match to Parameterset!",
		   _function_name, param, save );
	  return NULL;
	}
      }
    }
  }
  else if( refile != NULL ){
    vmessage("WARNING: <%s> File('%s') to rerun does not exist!",
	     _function_name, refile );
  }

  % steppar stepping variables
  variable stepping = qualifier("stepping", [range[0]:range[1]:#nsteps]);
  % set the stepped parameter values
  set_struct_field(info, escapedParameterName(parinfo.name), stepping );

  
  variable iorder, ileft, iright, imax;
  variable stat, val;
  variable pdiff, pind, pdiffmin;
  variable useparams,params,newparams,qualis;
  variable checkfiles;
  
  variable nrestarts = 0, i, p;
  % LOOP over restarts. If check>0 after each step a check for new best parameters
  % is performed and the stepping is restarted.
  % NOTE THAT the check for new best params does not wait for the other steppar
  % processes, i.e., if the current stepping is finished earlier than others it will
  % finish and possible best params found afterwards are not taken into account!
  while( nrestarts <= check ){

    % ATTENTION! Some already set values change due to new best parameter set
    params = get_params;
    
    keys.pval = get_par(par);
    ()=eval_counts(&stat);
    keys.statistic = stat.statistic;

    %%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Define stepping order
    % order in which stepping is stepped (altering right/left with respect to pval)
    if( qualifier_exists("resume") ){
      % only take steps into account, which are not calculated yet
      ileft  = reverse(where( parinfo.value >  stepping and rsm_sp.chi2 == 0 ));
      iright =         where( parinfo.value <= stepping and rsm_sp.chi2 == 0 );
    }
    else{
      ileft  = reverse(where( parinfo.value >  stepping ));
      iright =         where( parinfo.value <= stepping );
    }
    % apply the altering order
    imax = min([length(iright),length(ileft)]) - 1;
    iorder = Integer_Type[0];
    _for i ( 0, imax, 1 ){
      iorder = [ iorder, iright[i], ileft[i] ];
    }
    iorder = [ iorder, iright[[imax+1:]] ];
    iorder = [ iorder, ileft[[imax+1:]] ];

    
    qualis = struct{
      minchi2 = stat.statistic*( 1. - dchi2),
    };


    % get files in which new best parameters are searched (only runs if 'save' is given)
    checkfiles = NULL;
    if( check > 0 and qualifier_exists("save") ){
      checkfiles = string_matches (save,"PID[0-9]+"R);
      if( checkfiles !=NULL ){
	checkfiles = strreplace( save, checkfiles[0], "PID?????" );
	checkfiles = glob(checkfiles);
	checkfiles = checkfiles[array_sort(checkfiles)];
	checkfiles = checkfiles[where(checkfiles != save)];
      }
    }

    % start the stepping
    foreach i ( iorder ){
      % check other parameter files for a better parameter set and restart the stepping
      if( nrestarts < check and checkfiles!=NULL ){
	newparams = steppar_get_bestparams(checkfiles;; struct_combine(__qualifiers,qualis) );
	if( length(newparams) > 0 ){
	  set_params(newparams);
	  nrestarts++;
	  break;
	}
      }
      
      val = stepping[i];
      
      % SEARCH best parameter set in means of smallest difference to the stepped par value
      useparams = params;
      if( reset==0 ){
	pdiffmin = abs( val - parinfo.value );
	foreach p ( stephistory ){
	  pdiff = abs( val - get_struct_field(@p,escapedParameterName(parinfo.name)));
	  pind = where( (@p).chi2 != 0 );
	  if( length(pind)>0 && min(pdiff) < pdiffmin ){
	    useparams = _steppar_get_params( @p, pind[where_min( pdiff[pind] )] );
	    pdiffmin = min(pdiff);
	  }
	}
      }
      set_params( useparams );
      
      % SET & STEP
      set_par( par, val, 1, range[0], range[1] );
      () = (@fit)(__push_list(fitargs) ;; __qualifiers );
      
      % WRITE info
      stat = eval_stat_counts;
      foreach param (get_params){
	if(param.freeze==0 || param.name==par){
	  get_struct_field(info, escapedParameterName(param.name))[i] = param.value;
	}
      }
      info.chi2[i] = stat.statistic;
      info.chi2red[i] = stat.statistic/(stat.num_bins-stat.num_variable_params);
      
      if( chatty ){
	%print_struct(info; i=i);
	vmessage("INFO <%s>: Stepping %s (%d); restarts %3d/%3d: step %3d/%3d",
		 _function_name, parinfo.name, parinfo.index,
		 nrestarts, check, i+1, length(iorder)
		);
      }
      if( qualifier_exists("save") ){
	fits_write_binary_table( save, pidstr, info , keys );
      }
    }
    % In case no new best params are found during stepping make sure while loop
    % will be left
    if( length(iorder)==0 || i == iorder[-1] ){
      nrestarts = 2*(abs(check)+1);
    }
  }
  % Restore parameters
  set_params(originalparams);
  ()=eval_counts;
  Fit_Verbose=fitverbosity;
  
  if(qualifier_exists("keys"))
  {
    return info, keys;
  }
  else
    return info;
}
%}}}


%%%%%%%%%%%%%%%%%%%%%
define steppar_plot() %{{{
%%%%%%%%%%%%%%
%!%+
%\function{steppar_plot}
%\synopsis{xfig plot of the chi2 landscape of (a) stepped parameter(s)}
%\usage{steppar_plot( Struct_Type steppar, key );}
%\altusage{steppar_plot( String_Type stepparfile );}
%\qualifiers{
%\qualifier{norender}{If given xfig plots are returned instead of rendered}
%\qualifier{pdfunite}{If given the rendered plots are united into a single one}
%\qualifier{ignorez}{Ignores Chi2 values equal to Zero}
%\qualifier{size}{=[15,11] Size of the plot}
%\qualifier{path}{="steppar.pdf": Path for the rendered file}
%\qualifier{ext}{=".pdf": File Type, e.g., "png"}
%\qualifier{yoff}{Constant offset for the y-axis. Set to the initial statistic
%                   by default}
%\qualifier{yrange}{Range of the y-axis. Either Double_Type[1] or [2].
%                     If only one value is given it is taken as ymax! }
%\qualifier{dchi2}{=2.71: Delta Chisqr}
%}
%!%-
{
  variable sp, keys;
  switch(_NARGS)
  { case 1: sp = (); }
  { case 2: (sp, keys) = (); }
  { help(_function_name); return; }
  
  if( _typeof( sp ) == String_Type )
    ( sp, keys ) = steppar_load( sp ; keys );
  else ifnot( _typeof(sp)==Struct_Type ){
    vmessage("ERROR: <%s>: Argument has to be String or Struct_Type!",
	     _function_name); return;
  }

  variable norender = qualifier_exists("norender") ? 1 : 0;
  variable pdfunite = qualifier_exists("pdfunite") ? 1 : 0;
  variable ignorez  = qualifier_exists("ignorez") ? 1 : 0;
  variable size = qualifier("size",[15,11]);
  variable path = qualifier("path","steppar.pdf");
  variable ext  = qualifier("ext",path_extname(path));
  ext = ext == "" ? ".pdf" : ext;
  path = path_sans_extname(path);

  variable yoff = qualifier("yoff");
  variable yrange = [qualifier("yrange")];
  variable ymin = NULL, ymax = NULL;
  if( qualifier_exists("yrange") ){
    ymax = yrange[-1];
    if( length(yrange) > 1 ){
      ymin = yrange[0];
    }
  }

  variable dchi2 = qualifier("dchi2",2.71);
  
  variable N = length(sp);
  variable xf = Struct_Type[N];

  variable spconf = steppar_get_conf( sp; dchi2=dchi2 );
  
  variable x, y, chimin, xmin, xmax, dx, dy;
  variable wz;
  variable i, fn, I;
  _for i ( 0, N-1, 1 ){
    fn = escapedParameterName(keys[i].pname);
    x  = get_struct_field( sp[i], fn );
    y  = sp[i].chi2;

    wz = where( y < DOUBLE_MAX);
    if(ignorez){
      wz = where( 0 < y < DOUBLE_MAX );
    }

    x = x[wz];
    y = y[wz];

    
    xmin = min(x);
    xmax = max(x);
    dx = 0.0*(xmax-xmin);
    xmin -= dx;
    xmax += dx;

    if( ymin == NULL ){
      ymin = min(y);
    }
    if( ymax == NULL ){
      ymax = max(y);
    }
    
    dy = 0.05*(ymax-ymin);
    ymin -= dy;
    ymax += dy;
    
    chimin = min(y);
    
    ifnot(qualifier_exists("yoff")){
      yoff = keys[i].statistic;
    }
    
    xf[i] = xfig_plot_new( size[0], size[1] );
    xf[i].world( xmin,xmax , ymin-yoff,ymax-yoff ; padx=0, pady=0 );
    xf[i].ylabel(sprintf("$\\chi^2 - %.3f$",yoff));
    xf[i].xlabel( strreplace(keys[i].pname,"_","\\\_")+sprintf(" [%s]",keys[i].extname) );

    % Chi2
    xf[i].plot( x, y-yoff
		; depth=30, color="black", width=4 );
    % initial stat
    xf[i].plot( [xmin, xmax] , keys[i].statistic*[1,1]-yoff
		; depth=25, color="red");
    % initial par value
    xf[i].plot( keys[i].pval*[1,1], [ymin, ymax]-yoff
		; depth=25, color="red", width=2 );
    xf[i].xylabel( keys[i].pval, ymax-dy-yoff, 
		   sprintf("$p_\\mathrm{init}=%.3g$",keys[i].pval),
		   nint((xmax-keys[i].pval)/(xmax-xmin))==0 ? .5 : -.5,
		   .5
		   ; color="red",rotate=90
		 );
    
    % fill dchi2 area
    xf[i].plot( [xmin,xmax], chimin-yoff+[dchi2,dchi2]
		; depth=27, color="black" , width=2 );
    xf[i].xylabel( xmin+dx, chimin+dchi2-yoff
		   , sprintf("$\\Delta\\chi^2 = %.2f$",dchi2)
		   , -.5, -.5
		 ); 
    if( __is_initialized(&spconf) ){
      if( spconf[i].conf_min != NULL and spconf[i].conf_max != NULL ){
	xf[i].plot( spconf[i].conf_min*[1,1], [xmin,chimin+dchi2]-yoff
		    ; depth=27, color="black" );
	xf[i].plot( spconf[i].conf_max*[1,1], [xmin,chimin+dchi2]-yoff
		    ; depth=27, color="black" );
	I = where( y-chimin <= dchi2 );
	xf[i].shade_region( [spconf[i].conf_min, x[I], spconf[i].conf_max],
			    [chimin+dchi2, y[I], chimin+dchi2]-yoff
			    ; fillcolor="black");
      }
    }
    ifnot( norender ){
      %xf[i].render(path+sprintf("_%03d",keys[i].pidx)+ext);
      xf[i].render(path+sprintf("_%s",keys[i].extname)+ext);
    }
  }
  
  if(norender){
    return xf;
  }
  if(pdfunite and N>1 ){
    ()=system("pdfunite "+path+"_PID?????"+ext+" "+path+ext);
    ()=system("rm "+path+"_PID?????"+ext);
  }
}
%}}}


