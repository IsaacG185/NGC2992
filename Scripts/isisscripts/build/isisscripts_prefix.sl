%
% Initialization routines for the isisscripts
% Executed BEFORE the functions are defined
%

% give the isisscripts a verbose option
#ifeval __get_reference("_Isisscripts_Verbose")==NULL
variable _Isisscripts_Verbose=Isis_Verbose;
#endif

if (_Isisscripts_Verbose>0) {
    vmessage("loading %s", __FILE__);
}

$1 = path_sans_extname(__FILE__)+".txt";
ifnot(path_is_absolute($1))  $1 = path_concat(getcwd(), $1);
if(stat_file($1)!=NULL)
  set_doc_files([$1, get_doc_files()]);
else if (_Isisscripts_Verbose>0)
  vmessage("*** warning: Unable to locate help file '%s'", $1);

if (_Isisscripts_Verbose>0) {
message(`
If you use results obtained with the ISISscripts in a paper please cite as:
"This research has made use of ISIS functions (ISISscripts) provided by
ECAP/Remeis observatory and MIT (http://www.sternwarte.uni-erlangen.de/isis/)."
`);
}

provide("isisscripts");

%
% define local paths
%   Let users define where the local models are found!

%   We default to nothing, let user either set environment
%   variables, the local_paths variable, or use the
%   set_local_paths function

#ifeval __get_reference("local_paths")==NULL
variable local_paths = struct { @NULL };
#endif

private define __report_local_paths()
{
  if (_Isisscripts_Verbose>1) {
    variable path_name, path;
    variable path_names = get_struct_field_names(local_paths);
    if (length(path_names)) {
      message("   Setting local paths:");
      foreach path_name (path_names) {
	path = get_struct_field(local_paths, path_name);
	if (Array_Type == typeof(path))
	  path = strjoin(path, char(path_get_delimiter()));
	vmessage("     %s = %s", path_name, path);
      }
    } else {
      message("   No local model paths set");
    }
    message("");
  }
}

define set_local_paths ()
% This function sets the local paths to find instrument related data and local models
% It can either be done via qualifiers or environment variables
% The following settings exit:
% Data                  Qualifier            Environment
% localmodels           localmodels          XSPEC_LOCAL_MODELS,XSPEC_TABLE_MODELS     % semi-colon seperated list of paths
% RXTE data             rxte_data            RXTE_DATA_PATH                            % path to RXTE/FD
% RXTE ASM data         rxte_asm_data        RXTE_ASM_PATH                             % path to RXTE/ASM
% RXTE obscat           rxte_obscat          RXTE_OBSCAT_PATH                          % path to RXTE obscat
% MAXI lightcurves      maxi_lightcurves     MAXI_LIGHTCURVES_PATH                     % path to MAXI lightcurves
% FERMI catalog         fermi_catalog        FERMI_CATALOG_PATH                        % path to FERMI catalog
% FERMI catalog 3fgl    fermi_catalog_3fgl   FERMI_CATALOG_3FGL_PATH                   % path to FERMI catalog 3fgl
{
  % we combine model libraries and table models here for now. But keep the
  % two environment variables in case we need to change it
  variable local_tab_models = getenv("XSPEC_TABLE_MODELS"); % ';' separated list of paths to table models
  variable local_xsp_models = getenv("XSPEC_LOCAL_MODELS"); % ';' separated list of paths to compiled models
  variable localmodels = NULL;
  
  if (local_tab_models != NULL)
    localmodels = local_tab_models;
  if (local_xsp_models != NULL)
    localmodels = (localmodels != NULL) ? sprintf("%s%c%s", localmodels, path_get_delimiter(), local_xsp_models)
      : local_xsp_models;

  % overwrite with qualifiers
           localmodels        = qualifier("localmodels",        localmodels);
  variable rxte_data          = qualifier("rxte_data",          getenv("RXTE_DATA_PATH"));
  variable rxte_asm_data      = qualifier("rxte_asm_data",      getenv("RXTE_ASM_PATH"));
  variable rxte_obscat        = qualifier("rxte_obscat",        getenv("RXTE_OBSCAT"));
  variable maxi_lightcurves   = qualifier("maxi_lightcurves",   getenv("MAXI_LIGHTCURVES_PATH"));
  variable fermi_catalog      = qualifier("fermi_catalog",      getenv("FERMI_CATALOG_PATH"));
  variable fermi_catalog_3fgl = qualifier("fermi_catalog_3fgl", getenv("FERMI_CATALOG_3FGL_PATH"));

  % use HOME for backwards comp.
  if (localmodels != NULL)
    localmodels += char(path_get_delimiter()) + path_concat(getenv("HOME"),"share/software/localmodels");
  else
    localmodels = path_concat(getenv("HOME"),"share/software/localmodels");

  % split localmodels path

  variable loc = struct { localmodels = strchop(localmodels, ':', 0) };
  if (rxte_data != NULL)
    loc = struct { @loc, RXTE_data = [rxte_data] };
  if (rxte_asm_data != NULL)
    loc = struct { @loc, RXTE_ASM_data = [rxte_asm_data] };
  if (rxte_obscat != NULL)
    loc = struct { @loc, RXTE_obscat = [rxte_obscat] };
  if (maxi_lightcurves != NULL)
    loc = struct { @loc, MAXI_lightcurves = [maxi_lightcurves] };
  if (fermi_catalog != NULL)
    loc = struct { @loc, fermi_catalog = [fermi_catalog] };
  if (fermi_catalog_3fgl != NULL)
    loc = struct { @loc, fermi_catalog_3fgl = [fermi_catalog_3fgl] };

  local_paths = struct { @loc, @local_paths };
  __report_local_paths(); % show settings
}

% execute once on startup
set_local_paths();

%
% preload XSPEC local models
%

try {require("xspec");} catch AnyError: {;};

% only activate if module xspec could be loaded
#ifeval __get_reference("load_xspec_local_models")!=NULL

private define __load_localmodel (model, verbose)
{
  variable base,path,searchpath;
  if (path_is_absolute(model))
    searchpath = [model];
  else
    searchpath = [local_paths.localmodels, model];

  foreach base (searchpath) {
    if (model == base) % first try specified path
      path = base;
    else if (any(strchop(base, '/', 0)==model)) % then try if path contains this exact name
      path = base;
    else % else search for subfolders
      path = path_concat(base, model);

    variable e;
    variable gLmod = glob(path_concat(path, "lmodel.dat"), path_concat(path, "model.dat"));
    variable f;
    if (verbose>3) vmessage("%% Searching in '%s'", path);

    foreach f (gLmod) { % compiled models
      if (verbose) vmessage("%% loading xspec model from '%s'", path);
      try (e) {
	load_xspec_local_models(path);
      } catch AnyError, sprintf("%s: an error was caught: %s\n%s", _function_name(), e.descr, e.message);
      return;
    }

    variable gTmod = glob(path_concat(path, "*.fits"),
			  path_concat(path, "*.FITS"),
			  path_concat(path, "*.Fits"),
			  path_concat(path, "*.mod")
			 );

    variable t, tname, ttype, isModel=0;
    foreach t (gTmod) { % table model
      % get model name and type from primary extension
      tname = fits_read_key(t+"[0]", "MODLNAME");
      ttype = fits_read_key(t+"[0]", "ADDMODEL");
      if (NULL != tname && NULL != ttype) {
	try (e) {
	  if (ttype) add_atable_model(t, tname);
	  else add_mtable_model(t, tname);
	} catch AnyError, sprintf("%s: an error was caught: %s\n%s", _function_name(), e.descr, e.message);
	isModel |= 1;
      }
    }

    if (isModel) {
      if (verbose) vmessage("%% loading table model from '%s'", path);
      return;
    }
  }

  if (verbose>-1)
    vmessage("*** Warning: Unable to find a candidate for '%s'", model);
}

%%%%%%%%%%%%%%%%%%%%%
define use_localmodel()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{use_localmodel}
%\synopsis{load (an) xspec local (table) model[s] from local paths}
%\usage{use_localmodel(String_Type model[, model2, ...]);}
%\qualifiers{
%\qualifier{verbose}{: show the isis command[s] to load the xspec local model}
%}
%\description
%  This functions searches the defined search paths for local models
%  and tries to load the best matching model from a folder named
%  'model'. It is assumed that all models are installed with a default
%  lmodel.dat description file (compiled models) or follow the OGIP
%  table model specifications (table models).
%
%  An attempt is made to load table models correctly as additive or
%  multiplicative. Exponential models are also loaded as multiplicative
%  models.
%!%-
{
  if(_NARGS==0) { help(_function_name()); return; }

  variable model, models = ();
  loop(_NARGS-1)
  { model = ();
    models = [models, model];
  }
  variable verbose = qualifier("verbose", _Isisscripts_Verbose);

  foreach model ([models]) {
    if(verbose>2) vmessage("%% searching for %s", model);
    __load_localmodel(model, verbose);
  }
}
 
%
% use local models
%   use ISISCRIPTS_USE_MODELS to load set of default models
$1 = getenv("ISISSCRIPTS_USE_MODELS");
if (NULL != $1)
  foreach $2 (strchop($1, path_get_delimiter(), 0)) use_localmodel($2);

#endif
