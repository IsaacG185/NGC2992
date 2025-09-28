% *** IMPORTANT NOTE ***
% We need to have this script been copied into the isiscripts.sl
% before most of all remaining scripts! That is due to calls to
% fitfun_init_cache in these others scripts, which requires this
% function to be *fully* defined already (and not just its existence)!
% That's why this script is named starting with and underscore.

%!%+
%\function{fitfun_cache}
%\usage{see below}
%\description
%    The so-called caching extension is part of the ISISscripts and not
%    an ISIS internal feature.
%    
%    The caching extension provides an easy way to manage additional data for
%    the internal usage of user-defined fit-functions. The cache consists of
%    an slang structure for each defined dataset and fit-function using this
%    extension. This concept is similar to the metadata associated to each
%    dataset (see, e.g., 'get_dataset_metadata').
%
%    Inside of a user-defined fit-function, e.g., 'myfun' the cache for this
%    function and the current dataset (Isis_Active_Dataset) can be retrieved
%    by 'fitfun_get_cache':
%#v+
%    define myfun_fit(lo, hi, pars) {
%      ...
%      variable cache = fitfun_get_cache();
%      ...
%    }
%#v-
%    Here, the variable 'cache' would hold the corresponding slang structure.
%    Since slang structures are internally passed and returned via references,
%    any changes of the fields of 'cache' are permanent.
%
%    In order to define and/or initialize the fields of the structure, one
%    has to call 'fitfun_init_cache' and providing the slang structure.
%    For the example above this could look like
%#v+
%    fitfun_init_cache("myfun", &myfun_fit, struct { tempresult, lastpars });
%#v-
%    The caching extension can be used to, e.g., save temporary results from
%    calculations, which can then be retrieved once the model is evaluated
%    again. For this purpose it might be useful to also save the parameters
%    in a field like 'lastpars' into the cache, which can then be checked
%    against changes:
%#v+
%    define myfun_fit(lo, hi, pars) {
%      ...
%      variable cache = fitfun_get_cache();
%      if (any(cache.lastpars != pars)) {
%        ...
%      }  
%      cache.lastpars = pars;
%      ...
%    }
%#v-
%    Please read the documentation of 'fitfun_get_cache' and
%    'fitfun_init_cache' fot details and further examples.
%\seealso{fitfun_get_cache, fitfun_init_cache, fitfun_cache_enabled}
%
%!%-

private variable _fitfun_cache_enabled = 1;
private variable _fitfun_cache = Struct_Type[0];
private variable _fitfun_internal_cache = Assoc_Type[Struct_Type];
private variable _fitfun_name = Assoc_Type[String_Type];

%%%%%%%%%%%%%%%%%%%%%
define fitfun_cache_enabled()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fitfun_cache_enabled}
%\synopsis{returns whether the ISISscripts caching extension
%    for fit-functions is enabled (1) or disabled (0).}
%\usage{Integer_Type fitfun_cache_enabled();}
%\seealso{fitfun_cache, fitfun_enable_cache, fitfun_disable_cache}
%!%-
{
  return _fitfun_cache_enabled;
}

%%%%%%%%%%%%%%%%%%%%%
define fitfun_enable_cache()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fitfun_enable_cache}
%\synopsis{enables the ISISscripts caching extension}
%\usage{fitfun_enable_cache();}
%\seealso{fitfun_cache, fitfun_disable_cache, fitfun_cache_enabled}
%!%-
{
  _fitfun_cache_enabled = 1;
}

%%%%%%%%%%%%%%%%%%%%%
define fitfun_disable_cache()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fitfun_disable_cache}
%\synopsis{disables the ISISscripts caching extension}
%\usage{fitfun_disable_cache();}
%\seealso{fitfun_cache, fitfun_enable_cache, fitfun_cache_enabled}
%!%-
{
  _fitfun_cache_enabled = 0;
}

%%%%%%%%%%%%%%%%%%%%%
define fitfun_get_cache()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fitfun_get_cache}
%\synopsis{return the cache for the current dataset and the given fit-function}
%\usage{Struct_Type fitfun_get_cache([String_Type fit-function_name]);}
%\description
%    The cached slang structure for the currently evaluated
%    fit-function and the current dataset (Isis_Active_Dataset) is
%    returned. In case caching is disabled (by 'fitfun_disable_cache')
%    a new structure as defined using 'fitfun_init_cache' is returned.
%
%    The optional and only parameter specifies the name of a
%    fit-function, which stack is to be returned. This allows to share
%    and access the cache between different fit-functions. If this
%    particular fit-function has not been evaluated yet (or is not
%    used in the current model) NULL is returned.
%
%    Note: if the number of bins of the data grid of the current
%          dataset changes, the cache is initialized again with the
%          structure defined by 'fitfun_init_cache'. This might be
%          necessary as soon as, e.g., the fit-function is
%          'eval_fun'ed on a user-grid.
%\example
%    % use the cache inside a fit-function in order to save a temporary
%    % result, which depends on a subset of the input parameters only
%    define myfun_fit(lo, hi, pars) {
%      ...
%      variable cache = fitfun_get_cache();
%      if (any(cache.lastpars[[:1]] != pars[[:1]])) {
%        % assuming that 'expensive_calculation' depends on the first
%        two fit-parameters  
%        cache.tempresult = expensive_calculation(pars[0], pars[1]);
%      }  
%      cache.lastpars = pars;
%      ...
%      return cache.tempresult ...;
%    }
%
%    % retrieve the cache from another fit-function inside a fit-function
%    define mybetter_fit(lo, hi, pars) {
%      ...
%      variable ocache = fitfun_get_cache("myfun");
%      if (ocache != NULL) {
%        ocache.tempresult ...
%        ...
%      }
%      ...  
%    }
%
%    % investigate the temporary results after a fit from the command line
%    isis> Isis_Active_Dataset = 2; % get the cache for this dataset
%    isis> cache = fitfun_get_cache("myfun");
%    isis> print(cache.tempresult);
%\seealso{fitfun_cache, fitfun_init_cache}
%!%-
{
  % determine the cache's name from the frame stack
  variable fitfun, remote = 0, num_bins = NULL;
  if (_NARGS == 0) {
    variable call = _get_frame_info(_get_frame_depth()-1);
    % function was called from the known fit-function
    if (assoc_key_exists(_fitfun_name, call.function)) {
      fitfun = _fitfun_name[call.function];
      % get the number of bins of the grid the function was called with
      num_bins = length(_get_frame_variable(_get_frame_depth()-1, call.locals[0]));
    }
    % function was probably called from another function
    else {
      throw RunTimeError, sprintf("fitfun_get_cache called without an argument or from the unknown function '%s'", call.function);
    }
  }
  % the name is given as an argument -> remote access
  else {
    remote = 1;
    fitfun = ();
  }
  
  if (Isis_Active_Dataset < 1) {
    throw RunTimeError, "no cache for dataset 0 defined"$;
  }
  
  % return fresh structure if caching is disabled
  ifnot (fitfun_cache_enabled) {
    return remote ? NULL : struct_copy(_fitfun_internal_cache[fitfun].init);
  }

  % check the length of the cache-struct-array
  if (length(_fitfun_cache) < Isis_Active_Dataset) {
    % increase the array length
    loop (Isis_Active_Dataset-length(_fitfun_cache)) {
      _fitfun_cache = [_fitfun_cache, @Struct_Type(String_Type[0])];
    }
  }
  
  % check the struct-field on existence 
  ifnot (struct_field_exists(_fitfun_cache[Isis_Active_Dataset-1], fitfun)) {
    if (remote) { return NULL; }
    ifnot (assoc_key_exists(_fitfun_internal_cache, fitfun)) {
      throw RunTimeError, sprintf("no initializing struct for fit-function '%s' found"$, fitfun);
    }
    _fitfun_cache[Isis_Active_Dataset-1] = struct_combine(
      _fitfun_cache[Isis_Active_Dataset-1], @Struct_Type(fitfun)
    );
    set_struct_field(
      _fitfun_cache[Isis_Active_Dataset-1], fitfun,
      struct_copy(_fitfun_internal_cache[fitfun].init)
    );
  }

  % check the length of the internal number of bins
  if (length(_fitfun_internal_cache[fitfun].num_bins) < Isis_Active_Dataset) {
    % increase the array length
    loop (Isis_Active_Dataset-length(_fitfun_internal_cache[fitfun].num_bins)) {
      _fitfun_internal_cache[fitfun].num_bins = [_fitfun_internal_cache[fitfun].num_bins, num_bins];
    }
  }

  % reset cache in case the number of bins of the current grid changed (eval_fun!!!)
  if (num_bins != NULL && num_bins != _fitfun_internal_cache[fitfun].num_bins[Isis_Active_Dataset-1]) {
    set_struct_field(
      _fitfun_cache[Isis_Active_Dataset-1], fitfun,
      struct_copy(_fitfun_internal_cache[fitfun]).init
    );
    _fitfun_internal_cache[fitfun].num_bins[Isis_Active_Dataset-1] = num_bins;
  }
  
  % return the cache for the fit-function
  return get_struct_field(_fitfun_cache[Isis_Active_Dataset-1], fitfun);
}

%%%%%%%%%%%%%%%%%%%%%
public define fitfun_init_cache()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fitfun_init_cache}
%\synopsis{}
%\usage{fitfun_init_cache(String_Type fit-function_name, Ref_Type fit-function_handle, Struct_Type init_struct);}
%\description
%    Defines the structure, which is used to initialize the cache of the
%    the given fit-function. This should be called after a user-defined
%    fit-function, which uses caching, has been added to the list of
%    available models.
%
%    The first parameter 'fit-function_name' specifies the name of the
%    fit-function, 'fit-function_handle' is the reference to the actual
%    function calculating the model, and 'init_struct' is the structure
%    the cache will be initialized with for each dataset.
%\example
%    % Define a new fit-function, add it to the list of available
%    % models, and initialize its cache with a structure with empty
%    % fields. Inside the fit-function 'myfun' the value of lastpars
%    % can be checked on NULL or changed parameters in order to
%    % trigger an expensive calculation.
%
%    define myfun_fit(lo, hi, par) {
%      ...
%    }
%  
%    add_slang_function("myfun", ["par1", "par2", ...]);
%
%    fitfun_init_cache(
%      "myfun", &myfun_fit, struct { tempresult, lastpars = NULL }
%    );
%\seealso{fitfun_cache, fitfun_get_cache}
%!%-
{
  variable fitfun, handle, s;;
  switch (_NARGS)
    { case 3: (fitfun, handle, s) = (); }
    { help(_function_name); }

  if (typeof(handle) != Ref_Type) {
    vmessage("error (%s): handle has to be of Ref_Type", _function_name);
    return;
  }
  _fitfun_name[substr(string(handle), 2, -1)] = fitfun;

  % set the initializing structure
  _fitfun_internal_cache[fitfun] = struct {
    init = s,
    num_bins = Integer_Type[0]
  };
}
