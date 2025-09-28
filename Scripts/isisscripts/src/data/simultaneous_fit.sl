% -*- mode: slang; mode: fold; -*-

define data_map_function()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{data_map_function}
%\synopsis{executes a function on specific datasets}
%\usage{data_map_function(String_Type filter, Ref_Type function, arguments...; qualifiers);}
%\description
%    Loops over all defined datasets and matches each data
%    information against the given filter. In the simplest
%    way, this filter is a string respresenting the wanted
%    instrument as specified in the field of 'get_data_info'.
%    If the 'fi' qualifier is provided, the given filter is
%    interpreted as if-statement, which has to be fullfiled.
%    Thereby, the associated data information can be accessed
%    via the 'info' variable. The given function is applied
%    to each matching dataset in the form
%      function(dataset, arguments...; qualifiers);
%\example
%    % set the energy ranges for all RXTE-PCA sepctra
%    data_map_function("PCA", &xnotice_en, 3.5, 50);
%
%    % apply grouping to all Suzaku-PIN spectra
%    data_map_function(`is_substr(info.file, "hxd_pin")`,
%      &group; min_sn = 40, fi);
%\seealso{get_data_info, eval, array_map}
%!%-
{
  if (_NARGS < 2) { help(_function_name); return; }
  variable dtctr, funref, args = __pop_args(_NARGS - 2);
  variable ifstat = qualifier_exists("fi");
  (dtctr, funref) = ();

  % loop over all data
  variable d;
  _for d (0, length(all_data)-1, 1) {
    variable info = get_data_info(all_data[d]);
    if (ifstat) eval(sprintf("variable info = get_data_info(all_data[%d]);", d));
    if (info.instrument == dtctr || (ifstat && eval(dtctr))) (@funref)(all_data[d], __push_args(args) ;; __qualifiers);
  }
} %}}}

%%%%%%%%%%%%%%%%%%%%%
define simfit_namespace()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{simfit_namespace}
%\synopsis{implements all SimFit-functions into a namespace}
%\usage{simfit_namespace(Struct_Type SimFit);}
%\qualifiers{
%    \qualifier{name}{name of the new namespace (default: simfit)}
%    \qualifier{chatty}{chattiness of this function (default: 1)}
%}
%\description
%    Takes a simultaneous fit structure as input and
%    implements all available functions defined in there
%    into a new namespace. In this way the user no longer
%    has to type the structure's name in front of the
%    functions, but use the functions directly.
%
%    Note that in this namespace the ISIS intrinsic
%    functions, such as 'fit_fun', 'set_par', etc. are
%    being overwritten by the SimFit-versions.
%
%    Furthermore, 'eval_counts' is defined as a combination
%    of 'eval_groups' and 'eval_global', and 'fit_counts'
%    now points to 'fit_smart'.
%
%    To access the original ISIS functions just switch the
%    namespace back to 'isis' using 'use_namespace' or
%    access the functions via isis->function_name
%
%    WARNING: there is no check implemented yet that the
%    given structure actually is a SimFit-structure, so
%    every structure containing reference to functions may
%    be passed, which might HARM your ISIS-session or
%    machine!
%
%    FINALLY, if there will be any error the namespace is
%    most likely set to 'isis' afterwards (we tried to
%    catch errors in the SimFit-functions but this does
%    not work for, e.g., syntax errors within the shell).
%\seealso{simultaneous_fit, use_namespace}
%!%-
{
  if (_NARGS != 1) { help(_function_name); return; }
  variable s = ();
  variable space   = qualifier("name", "simfit");
  variable current = "Global";
  variable chatty = qualifier("chatty", 1);
  
  % check on existence of the namespace
  if (any(_get_namespaces == space)) {
    vmessage("error (%s): namespace '%s' already exists", _function_name, space);
    return;
  }

  % define a new variable holding the simfit structure
  % into the current namespace
  variable simfit = sprintf("SimFit_Structure_%s", space);
  if (chatty) { vmessage("copying structure to variable %s->%s", current, simfit); }
  eval(sprintf("variable %s", simfit), current);
  use_namespace(current);
  @(__get_reference(simfit)) = s;

  % define new namespace
  if (chatty) { vmessage("implementing namespace '%s'", space); }
  implements(space);
  % implement functions
  if (chatty) { vmessage("defining functions in namespace '%s'", space); }
  variable fun, code;
  foreach fun (get_struct_field_names(s)) {
    variable ref = get_struct_field(s, fun);
    if (typeof(ref) == Ref_Type) {
      code  = sprintf("define %s() {\n", fun);
      code += sprintf("  variable args = __pop_args(_NARGS);\n");
      code += sprintf("  use_namespace(\"%s\");\n", current);
      code += sprintf("  variable e = NULL;\n");
      code += sprintf("  try(e) { %s.%s(__push_args(args);; __qualifiers); }\n", simfit, fun);
      code += sprintf("  catch AnyError: { message(e.message); };\n");
      code += sprintf("  use_namespace(\"%s\");\n", space);
      code += sprintf("}\n");
      eval(code, space);
    }
  }
  % implement eval_counts
  code  = sprintf("define eval_counts() {\n");
  code += sprintf("  variable args = __pop_args(_NARGS);\n");
  code += sprintf("  use_namespace(\"%s\");\n", current);
  code += sprintf("  variable e = NULL;\n");
  code += sprintf("  try(e) { variable a = %s.eval_groups(__push_args(args);; struct_combine(struct { skipfinaloutput }, __qualifiers));\n", simfit);
  code += sprintf("  variable b = %s.eval_global(;; __qualifiers); }\n", simfit);
  code += sprintf("  catch AnyError: { message(e.message); };\n");
  code += sprintf("  use_namespace(\"%s\");\n", space);
  code += sprintf("  return (a && b);\n");
  code += sprintf("}\n");
  eval(code, space);
  % implement fit_counts
  code  = sprintf("define fit_counts() {\n");
  code += sprintf("  variable args = __pop_args(_NARGS);\n");
  code += sprintf("  use_namespace(\"%s\");\n", current);
  code += sprintf("  variable e = NULL;\n");
  code += sprintf("  try(e) { %s.fit_smart(__push_args(args);; __qualifiers); }\n", simfit);
  code += sprintf("  catch AnyError: { message(e.message); };\n");
  code += sprintf("  use_namespace(\"%s\");\n", space);
  code += sprintf("}\n");
  eval(code, space);
} %}}}

%%% TODO %%%
% list_par (what was this about?)
% [a-b] place holder
% hack substructure (see below in main function simultaneous_fit)
% group_stats -> list or return d.o.f. for all groups (mu-factor!)

variable SimFit_Verbose = -1; % verbosity during [eval/fit]_counts;
variable SimFit_Verbose_Histogram = 0; % show (0) or hide (-1) histogram after [eval/fit]_*

private define _simultaneous_fit_help(nargs, fname) %{{{
{ % display help to a specific function (adopted from xfgi module)
  if (nargs == 0 && qualifier_exists("help") == 0) return 0;
  _pop_n(nargs);
  help(strreplace(fname, "eous_fit_", "eous_fit."));
  if (qualifier_exists("help")) return 1;
} %}}}

private define _simultaneous_fit_parname(parname, dataid);
private define _simultaneous_fit_parname(parname, dataid) %{{{
{ % evaluates a parameter name with placeholders
  % check if placeholder exists
  if (is_substr(parname, "%")) {
    % matches on parameters WITHOUT %
    variable nparname = string_matches(parname, "\(.*\)(\([^%]*\))\.\(.*\).*"R);
    % if no parameter was found, try to evaluate the placeholder
    if (nparname == NULL) {
      nparname = string_matches(parname, "\(.*\)(\(.*\))\.\(.*\).*"R);
      if (nparname == NULL) return parname;
      else return sprintf("%s(%d).%s", _simultaneous_fit_parname(nparname[1], dataid),
			               eval(strreplace(nparname[2], "%", sprintf("%d", dataid))),
			               _simultaneous_fit_parname(nparname[3], dataid));
    }
    % otherwise, repeat with strings before and after the found non-% parameter
    else return sprintf("%s(%s).%s", _simultaneous_fit_parname(nparname[1], dataid),
			             nparname[2],
			             _simultaneous_fit_parname(nparname[3], dataid));
  }
  % return input without changing anything
  else return parname;
} %}}}

private define _simultaneous_fit_get_instances(ff, comp) %{{{
{ % extracts all instances of the given component from the fit-function
  variable rules = String_Type[0];
  variable z = 1;
  while (z < strlen(ff)) {
    variable s = is_substr(substr(ff, z, -1), sprintf("%s(", comp)) - 1;
    if (s >= 0) {
      variable p = 1, l = strlen(comp), e = 1;
      while(p > 0) {
        switch(substr(ff, z+s+l+e, 1))
          { case "(": p++; }
          { case ")": p--; }
          { case ",": if (p == 1) p = 0; }
          { e++; }
      }
      rules = [rules, substr(ff, z+s+l+1, e-1)];
      z += s+l+e+1;
    } else z = strlen(ff);
  }
  return rules;
} %}}}

private define simultaneous_fit_setrestore() %{{{
%!%+    
%\function{simultaneous_fit.setrestore}
%\synopsis{To be written}
%\usage{simultaneous_fit.setrestore();}
%\description
%    To be written...
%\seealso{simultaneous_fit.restore}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  s.model.exclude = all_data[where(array_struct_field(array_map(Struct_Type, &get_data_info, all_data), "exclude") == 1)];
  s.model.params = get_params();
} %}}}

private define simultaneous_fit_restore() %{{{
%!%+    
%\function{simultaneous_fit.restore}
%\synopsis{To be written}
%\usage{simultaneous_fit.restore();}
%\description
%    To be written...
%\seealso{simultaneous_fit.setrestore}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  include(array_flatten(list_to_array(s.data, Array_Type)));
  exclude(s.model.exclude);
  if (qualifier_exists("params")) {
    set_params(s.model.params);
  } else {
    variable fstate = array_struct_field(s.model.params, "freeze");
    freeze(freeParameters);
    thaw(array_struct_field(s.model.params, "name")[where(fstate == 0)]);
  }
} %}}}

private define simultaneous_fit_apply_logic() %{{{
%!%+    
%\function{simultaneous_fit.apply_logic}
%\synopsis{ties parameters of simultaneous data to each other}
%\usage{simultaneous_fit.apply_logic();}
%\qualifiers{
%    \qualifier{keepparfun}{do not reset all parameter functions}
%    \qualifier{chatty}{chattiness of this function (default: 1)}
%}
%
%\description
%    For each defined data an individual set of parameters
%    exist. If some of the data were taken simultaneously
%    the parameters should be the same. This function applies
%    this logic by tieing the parameters of these data to
%    each other by setting the corresponding parameter
%    functions via set_par_fun. To do so the functions for
%    all parameters are set to NULL first (this can be
%    inhibited using the keepparfun-qualifier).
%\seealso{simultaneous_fit.add_data, simultaneous_fit.fit_fun,
%    set_par_fun}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  variable chatty = qualifier("chatty", 1);

  if (s.model.fit_fun == NULL) return;
  % the updategroup-qualifier is used internally and, thus,
  % not listed in the help
  variable update = qualifier("updategroup", NULL);
  % delete all parameter functions (can be reset eventually
  % with .set_par_fun_history if the user has used
  % .set_par_fun only)
  if (update == NULL) {
    ifnot (qualifier_exists("keepparfun")) {
      if (chatty) { message("setting all parameter functions to NULL"); }
      array_map(Void_Type, &set_par_fun,
	array_struct_field(get_params, "name"), NULL);
      s.sort_params(; updategroup = 0, chatty = 0);
    }
  }

  % loop over all parameters of a data group
  % and tie parameters to each other
  variable g, check = 0;
  if (chatty) { message("tieing group parameters together"); }
  _for g (update == NULL ? 0 : update, update == NULL ? length(s.model.group)-1 : update, 1) {
    variable p;
    _for p (0, length(s.model.group[g])-1, 1) {
      if (s.model.tieto[g][p] != NULL)
        set_par_fun(s.model.group[g][p], s.model.tieto[g][p]);
      else if (update != NULL && get_par_info(s.model.group[g][p]).fun != NULL) {
	set_par_fun(s.model.group[g][p], NULL);
	check = 1;
      }
    }
  }

  if (check) {
    vmessage("warning (%s): parameter logic of group %d changed, please check parameter functions:\n", _function_name, update+1);
    s.list_groups(update+1; tied);
  }
} %}}}

private define simultaneous_fit_sort_params() %{{{
%!%+    
%\function{simultaneous_fit.sort_params}
%\synopsis{sort all fit parameters into global and group ones}
%\usage{simultaneous_fit.sort_params();}
%\qualifiers{
%    \qualifier{chatty}{chattyness of this function (default: 1)}
%}
%\description
%    The defined data may contain both, simultaneous and non-
%    simultaneous data. Thus, there are parameters which apply
%    to individual data on one hand (called group parameters),
%    and on the other hand parameters which act on all defined
%    data (called global parameters). This function determines
%    the relationship between the defined data in order to sort
%    the existing parameters into global and group parameters.
%\seealso{simultaneous_fit.add_data, simultaneous_fit.apply_logic}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  if (s.model.fit_fun == NULL) { return; }
  if (length(s.data) == 0) { return; }
  variable chatty = qualifier("chatty", 1);
  variable update = qualifier("updategroup", NULL);

  % remember excluded datasets
  s.setrestore();
  
  % idea: include the data groups one after another and
  %       extract the names of any new parameters
  if (chatty) { message("analyzing parameters"); }
  variable g, ids = array_flatten(list_to_array(s.data, Array_Type));
  exclude(ids);
  exclude(ids); % needed to update list of parameters properly (Isis_Active_Dataset -> 0)
  % get global parameters
  variable globalpars = get_params;
  if (length(globalpars) > 0) { s.model.global = array_struct_field(globalpars, "name"); }
  % remove parameters, which don't exist after including all data (e.g. component(0).parameter)
  include(ids);
  variable n = Integer_Type[0];
  _for g (0, length(s.model.global)-1, 1) if (_get_index(s.model.global[g]) > -1) n = [n, g];
  s.model.global = s.model.global[n];
  if (chatty) { vmessage("  -> %d global parameters", length(s.model.global)); }

  if (update == 0) { return; }
  % get parameteres assigned to specific data groups
  if (update == NULL) { % forget the known logic
    s.model.instances = Assoc_Type[Array_Type];
    s.model.group = Array_Type[length(s.data)];
    s.model.tieto = Array_Type[length(s.data)];
    s.model.stat = struct_array(length(s.data)+1, struct {
      statistic = 0,
      num_variable_params = 0,
      num_bins = 0
    }); % +1 for globals (index 0)
  }
  _for g (update == NULL ? 0 : update, update == NULL ? length(s.data)-1 : update, 1) {
    variable d, thispars = String_Type[0], tiesto = String_Type[0];
    _for d (0, length(s.data[g])-1, 1) {
      exclude(ids);
      include(s.data[g][d]);
      variable actpars = get_params;
      if (length(actpars) > 0) {
        actpars = array_struct_field(actpars, "name");
        % remove global parameters
        n = Integer_Type[0];
	variable t;
        _for t (0, length(actpars)-1, 1) if (wherefirst(s.model.global == actpars[t]) == NULL) n = [n, t];
        thispars = [thispars, actpars[n]];
	% check if parameter can/may be tied to first dataset of this group
	_for t (0, length(n)-1, 1) {
	  variable comp;
          if (d == 0) { % if first dataset of this group, extract all instances of the fit components
	    tiesto = [tiesto, NULL];
	    comp = substr(actpars[n[t]], 1, is_substr(actpars[n[t]], "(")-1);
	    ifnot (assoc_key_exists(s.model.instances, comp)) s.model.instances[comp] = _simultaneous_fit_get_instances(s.model.fit_fun, comp);
	  }
	  else {
	    % find parameter name of first data within this group
            comp = string_matches(actpars[n[t]], "\(.*\)(\(\d*\))\.\(.*\).*"R);
	    variable tieparname = NULL;
	    if (assoc_key_exists(s.model.instances, comp[1])) {
	      % find instance string, which results into the current parameter instance
	      variable inst = s.model.instances[comp[1]];
              variable i = wherefirst(array_map(Integer_Type, &eval, array_map(String_Type, &strreplace, inst, "%", sprintf("%d", s.data[g][d]))) == atoi(comp[2]));
	      if (i != NULL) tieparname = sprintf("%s(%d).%s", comp[1], eval(strreplace(inst[i], "%", sprintf("%d", s.data[g][0]))), comp[3]);
	    }
	    tiesto = [tiesto, tieparname];
	  }
	}
      }
    }
    s.model.group[g] = @thispars;
    s.model.tieto[g] = @tiesto;
  }
  if (chatty) {
    n = int(sum(array_map(Integer_Type, &length, s.model.group)));
    t = 1. * n / length(s.model.group);
    vmessage("  -> %d group parameters, %.0f per group", n, t);
    if (t - int(t) > 0) {
      message("  warning: number of parameters per group is no integer!");
    }
  }
  
  s.restore();
} %}}}

private define simultaneous_fit_add_data_old() %{{{
%!%+    
%\function{simultaneous_fit.add_data_old}
%\synopsis{adds the given data to the simultaneous/combined fit (old version)}
%\usage{simultaneous_fit.add_data(String_Type[] phafiles);
% or simultaneous_fit.add_data(Struct_Type[] { bin_lo, bin_hi, value, error });
% or simultaneous_fit.add_data(List_Type datagroups);}
%\qualifiers{
%    \qualifier{loadfun}{function reference to load the given filename
%              (default &load_data), further arguments are passed}
%    \qualifier{loadfunlist}{indicates that 'loadfun' already returns an
%              array of datagroups, i.e. a list with integer
%              arrays representing the datasets in each group}
%    \qualifier{nosort}{do not sort the parameters (implies 'nologic')}
%    \qualifier{nologic}{do not apply parameter logic}
%    \qualifier{ROC}{value for Rmf_OGIP_Compliance for each data,
%              has to be given in the same structure as the
%              input data, i.e., as integer array or list of
%              integer arrays}
%}
%\description
%    This function is deprecated and is superseded by the default
%    one in the simultaneous-fit-structure.
%
%    The given data will be loaded or defined and added to the
%    simultaneous/combined fit. This data can be given as either
%    a file name to the spectrum as accepted by 'load_data' or a
%    structure as accepted by 'define_counts'.
%
%    If an array of data is given, this data will be treated
%    as simultaneously recorded data (called a data group).
%    That means, if any parameter logic is applied afterwards,
%    the parameters of all datasets are tied to each other.
%    This logic will be applied automatically unless the
%    'nologic' qualifier is given. To apply it later,
%    'simultaneous_fit.apply_logic' may be called. This logic,
%    however, has to be known first, which is done by
%    'simultaneous_fit.sort_params' automatically. Again,
%    this may be skipped by the 'nosort' qualifier.
%
%    Further on, a list of several data groups can be given.
%    This list may contain both, filenames to spectra and
%    structures and arrays of these as well.
%\example
%    % define a simultaneous fit first
%    variable simfit = simultaneous_fit();
%    
%    % add a single RXTE observation (consisting of a PCA-
%    % and a HEXTE-spectrum, both taken simultaenously, of
%    % course)
%    simfit.add_data(["pca.pha", "hexte.pha"]);
%
%    % add an RXTE (PCA and HEXTE) and a Swift-XRT
%    % observation (both observations were NOT taken
%    % simultaneously -> List_Type)
%    simfit.add_data({["pha.pha", "hexte.pha"], "xrt.pha"});
%\seealso{load_data, define_counts, simultaneous_fit.sort_params,
%    simultaneous_fit.apply_logic}
%!%-
{
  variable s, data, addargs = Struct_Type[0];
  if (_NARGS == 2) (s,data) = ();
  else if (_NARGS > 2) {
    addargs = __pop_args(_NARGS-2);
    (s,data) = ();
  }
  else { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  variable loadfun = qualifier("loadfun", &load_data);
  % loadfun given and that returns a list of data groups
  variable loadfunlist = qualifier_exists("loadfun") && qualifier_exists("loadfunlist");
  
  % convert input string(s), struct(s), or integer(s) into a list
  if (any(_typeof(data) == [String_Type, Struct_Type, Integer_Type]))
    { data = { data }; }
  else if (_typeof(data) != List_Type)
    { vmessage("error (%s): wrong type of 'data'", _function_name); return; }

  % same for Rmf_OGIP_Compliance
  variable roc = qualifier("ROC", NULL);
  variable defroc = Rmf_OGIP_Compliance;
  if (roc != NULL) {
    if (_typeof(roc) == Integer_Type) roc = { roc };
    else if (_typeof(roc) != List_Type) { vmessage("error (%s): wrong type of 'roc' qualifier", _function_name); return; }
    if (length(roc) != length(data) || length(array_flatten(list_to_array(roc))) != length(array_flatten(list_to_array(data))))
      { vmessage("error (%s): 'roc' qualifier has to have the same structure and number of elements as the input data", _function_name); return; }
  }
    
  % loop over data groups
  variable g, nid = list_new;
  _for g (0, length(data)-1, 1) {
    % convert input into array (will not affect an already given array)
    if (typeof(data[g]) != Array_Type) data[g] = [data[g]];
    % load the data or define the counts
    variable d, ids = loadfunlist ? List_Type[0] : Integer_Type[0];
    _for d (0, length(data[g])-1, 1) {
      if (roc != NULL) Rmf_OGIP_Compliance = roc[g][d];
      ids = [ids, typeof(data[g][d]) == String_Type ? (@loadfun)(data[g][d], __push_args(addargs);; __qualifiers) : define_counts(data[g][d] ;; __qualifiers)];
      if ((loadfunlist ? ids[-1][0] : ids[-1]) == -1) { vmessage("error (%s): something went wrong during loading or defining data", _function_name); return; }
    }
    % eventually set data info
    if (qualifier_exists("datainfo")) {
      foreach d (ids)
	set_data_info(d, struct_combine(get_data_info(d), qualifier("datainfo")));
    }
    % remember data indices
    if (loadfunlist) {
      _for d (0, length(ids)-1, 1) {
	while (length(ids[d]) > 0) {
          list_append(s.data, [list_pop(ids[d])]);
          list_append(nid, s.data[-1]);
	}
      }
    }
    else {
      list_append(s.data, ids);
      list_append(nid, s.data[-1]);
    }
  }

  % parameter stuff
  ifnot (qualifier_exists("nosort")) {
    s.sort_params();
    ifnot (qualifier_exists("nologic")) s.apply_logic();
  }

  Rmf_OGIP_Compliance = defroc;
  return nid;
} %}}}

private define simultaneous_fit_add_data() %{{{
%!%+    
%\function{simultaneous_fit.add_data}
%\synopsis{adds the given data to the simultaneous/combined fit}
%\usage{simultaneous_fit.add_data(List_Type data_for_one_group);
% or simultaneous_fit.add_data(List_Type[] multiple_groups);}
%\qualifiers{
%    \qualifier{nosort}{do not sort the parameters (implies 'nologic')}
%    \qualifier{nologic}{do not apply parameter logic}
%}
%\description
%    NOTE: compared to the previous version of this function the data
%          has to be provided as a list or array of lists!
%
%    The given data will be loaded or defined and added to the
%    simultaneous/combined fit. The data can be provided in different
%    formats inside a surrounding list. All data within this list is
%    treated as a single data group. Further groups can be defined by
%    either calling add_data again or by providing an array of lists,
%    where each item corresponds to a group. The data inside the
%    list(s) can be given as
%    - String_Type filename: the given filename is loaded by a call
%      to 'load_data'.
%    - Integer_Type dataset: the ID of an already existing ISIS
%      dataset.
%    - Struct_Type, the field layouts allowed are
%      - { Double_Type[] bin_lo, bin_hi, value, error }: is passed
%        to 'define_counts' by default.
%      - { String_Type filename }: is passed to 'load_data' by
%        default.
%      Further fields allow additional features:
%        - { ..., Integer_Type roc }: Rmf_OGIP_Compliance is set to
%           'roc' before the data is defined or loaded.
%        - { ..., Ref_Type loadfun }: reference to a function which
%          should be used instead of 'load_data' or 'define_counts'.
%          This function has to return the new ISIS dataset ID.
%        - { ..., Struct_Type qualifiers } - the structure is passed
%          as qualifiers to the function for loading or defining
%          the data.
%     
%    After the data and corresponding data groups have been defined
%    the resulting parameter logic is analyzed by
%    'simultaneous_fit.sort_params'. As this step might take a long
%    time and is only needed once (during the last call to 'add_data'
%    or manually), you can skip this step using the 'nosort'
%    qualifier.
%    Finally, the analyzed parameter logic is applied to the defined
%    model and parameters using 'simultaneous_fit.apply_logic' unless
%    the 'nologic' qualifier is set.
%\example
%    % define a simultaneous fit structure first
%    variable simfit = simultaneous_fit();
%    
%    % add a single RXTE observation (consisting of a PCA-
%    % and a HEXTE-spectrum, both taken simultaenously, of
%    % course)
%    simfit.add_data({"pca.pha", "hexte.pha"});
%
%    % add two data groups consisting of an RXTE (PCA and HEXTE) and
%    % a Swift-XRT observation
%    simfit.add_data([ % note the array
%      {"pha.pha", "hexte.pha"}, % first data group
%      {struct { filename = "xrt.pha", roc = 0 }} % second data group
%    ]);
%
%    % add one already existing ISIS datasets and load an PHA-file
%    % both defining a single data group
%    % fit grouped into two data groups
%    simfit.add_data({1, "file.pha"});
%\seealso{load_data, define_counts, simultaneous_fit.sort_params,
%    simultaneous_fit.apply_logic}
%!%-
{
  variable s, data;
  if (_NARGS == 2) { (s,data) = (); }
  else { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) { return; }

  % sanity checks
  if (typeof(data) == List_Type) { data = [data]; }
  else if (typeof(data) != Array_Type || _typeof(data) != List_Type) {
    vmessage("error (%s): 'data' have to be given as list or array of lists", _function_name);
    return;
  }

  variable troc = Rmf_OGIP_Compliance;

  % loop over array times (= data groups)
  variable g, d, ids = List_Type[length(data)];
  _for g (0, length(data)-1, 1) {
    % loop over list itmes (= datasets wihtin the group)
    ids[g] = list_new;
    _for d (0, length(data[g])-1, 1) {
      switch (typeof(data[g][d]))
      % load file
      { case String_Type:
	list_append(ids[g], load_data(data[g][d]));
      }
      % add existing dataset
      { case Integer_Type:
	list_append(ids[g], data[g][d]);
      }
      { case Struct_Type:
	variable fields = get_struct_field_names(data[g][d]);
	
	% determine struct type
	variable type;
	if (any(fields == "filename")) { type = 1; }
	else if (any(fields == "bin_lo") && any(fields == "bin_hi") &&
		 any(fields == "value") && any(fields == "err")) { type = 2; }
	else {
	  vmessage(
            "error (%s): given structure layout is not allowed", _function_name
	  ); return;
	}
	
	% define load function
	variable funref = any(fields == "loadfun") ? data[g][d].loadfun
                        : type == 1 ? &load_data : type == 2 ? &define_counts : NULL;
	if (funref == NULL) {
	  vmessage(
            "error (%s): function to load/define the data is NULL", _function_name
	  ); return;
	}
	% additional qualifiers
	variable qual = any(fields == "qualifiers") ? data[g][d].qualifiers : NULL;
	% custom Rmf_OGIP_Compliance
	if (any(fields == "roc")) { Rmf_OGIP_Compliance = data[g][d].roc; }

	% now load or define the data
	list_append(ids[g], (@funref)(
	  type == 1 ? data[g][d].filename : data[g][d]
	;; qual));

	% restore Rmf_OGIP_Compliance
	if (any(fields == "roc")) { Rmf_OGIP_Compliance = troc; }
      }
    }
    
    % add IDs to internal simfit structure
    list_append(s.data, list_to_array(ids[g], Integer_Type));
  }
  
  ifnot (qualifier_exists("nosort")) {
    % analyze parameter logic
    s.sort_params();
    % apply logic
    ifnot (qualifier_exists("nologic")) { s.apply_logic(); }
  }

  return ids;
} %}}}

private define simultaneous_fit_delete_data() %{{{
%!%+    
%\function{simultaneous_fit.delete_data}
%\synopsis{deletes the given data from the simultaneous/combined fit}
%\usage{simultaneous_fit.delete_data(Integer_Type[] group[, Integer_Type[] data]);}
%\qualifiers{
%    \qualifier{keep}{the associated data are not deleted by
%           'delete_data', thus only the logic of the
%           simultaneous fit is modified}
%}
%\description
%    The given data 'group' is removed from the simultaneous
%    fit and the associated data is deleted (using the ISIS
%    internal function 'delete_data'. The second, optional
%    argument can be used to delete specific data from a
%    group specified by its number within the group (starting
%    at one).
%
%    If the first group is deleted, the global parameters
%    might change. In that case a warning message will be
%    raised and you should check the parameter dependencies!
%
%    Further on, if the first dataset of a group is deleted,
%    the parameter logic will change and paramaters will be
%    tied again according to that logic (but of that group
%    only). Please check the resulting parameter dependencies
%    (in particular the value-functions of global parameters)
%    as suggested by the warning message!
%\example
%    % delete data group 3 and 5
%    simultaneous_fit.delete_data([3,5]);
%
%    % delete data group 1
%    % this might cause that a global parameter gets deleted
%    simultaneous_fit.delete_data(1);
%    
%    % delete the first spectrum from group 4 only
%    % this will probably change the group parameter dependencies
%    simultaneous_fit.delete_data(4, 1);
%\seealso{delete_data, simultaneous_fit.add_data}
%!%-
{
  variable s, grp, data = NULL;
  switch (_NARGS)
    { case 2: (s,grp) = (); }
    { case 3: (s,grp,data) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  if (typeof(grp) == Array_Type && typeof(data) == Array_Type)
    { vmessage("error (%s): either 'group' or 'data' may be an array, not both", _function_name, length(s.data)); return; }
  if (typeof(grp) != Array_Type) grp = [grp];
  if (min(grp) < 1 || max(grp) > length(s.data))
    { vmessage("error (%s): allowed data groups range from 1 to %d", _function_name, length(s.data)); return; }
  if (data != NULL) {
    if (typeof(data) != Array_Type) data = [data];
    if (min(data) < 1 || max(data) > length(s.data[grp[0]-1]))
      { vmessage("error (%s): allowed data in group %d range from 1 to %d", _function_name, grp[0], length(s.data[grp[0]-1])); return; }
  }
      
  % loop over given groups
  variable g, ng = 0;
  variable keep = qualifier_exists("keep");
  foreach g (grp-1) {
    % remember global parameters
    variable global = @(s.model.global);
    % remove data
    if (data == NULL) {
      ifnot (keep) { delete_data(s.data[g-ng]); }
      list_delete(s.data, g-ng);
      if (s.model.fit_fun != NULL) {
        s.model.group = array_remove(s.model.group, g-ng);
        s.model.tieto = array_remove(s.model.tieto, g-ng);
        s.sort_params(; updategroup = 0); % update global parameters (if necessary)
      }
      ng++;
    } else {
      ifnot (keep) { delete_data(s.data[g-ng][data-1]); }
      data = data[array_sort(data)];
      variable d;
      _for d (0, length(data)-1, 1)
	s.data[g-ng] = array_remove(s.data[g-ng], data[d]-d-1);
      % whole group was deleted
      if (length(s.data[g-ng]) == 0) {
        list_delete(s.data, g-ng);
        if (s.model.fit_fun != NULL) {
          s.model.group = array_remove(s.model.group, g-ng);
          s.model.tieto = array_remove(s.model.tieto, g-ng);
          s.sort_params(; updategroup = 0); % update global parameters (if necessary)
	}
	ng++;
      } else {
        if (s.model.fit_fun != NULL) {
          s.sort_params(; updategroup = g-ng); % update global and group parameters
          s.apply_logic(; updategroup = g-ng);
	}
      }
    }
    % check on changed global parameters
    variable p;
    foreach p (global)
      if (wherefirst(s.model.global == p) == NULL)
        vmessage("warning (%s): global parameter %s has been deleted and removed from the list!", _function_name, p);
  }
} %}}}

private define simultaneous_fit_fit_fun() %{{{
%!%+    
%\function{simultaneous_fit.fit_fun}
%\synopsis{defines the model applied within the simultaneous fit}
%\usage{simultaneous_fit.fit_fun(String_Type fit_fun);}
%\qualifiers{
%    \qualifier{nosort}{do not sort the parameters
%                (implies 'nologic' and 'nohistory')}
%    \qualifier{nologic}{do not apply parameter logic}
%    \qualifier{nohistory}{do not apply the set_par_fun-history}
%    \qualifier{ask}{see set_par_fun_history}
%    \qualifier{chatty}{chattiness of this function (default: 1)}
%}
%\description
%    The given string is used to define the fit function.
%    Usually, a lot of data is added to the simultaneous
%    fit, which might lead to more complicated fit functions.
%    In order to simplify its definition, some place holders
%    can be used within the fit function:
%      % - will be replaced by Isis_Active_Dataset
%    More placeholders will be implemented in the future.
%
%    Afterwards, the parameters are sorted into global and
%    group ones and the parameter logic is applied to the
%    model (see simultaneous_fit.sort_params and
%    simultaneous_fit.apply_logic).
%
%    Finally, any parameter functions previously define
%    with simultaneous_fit.set_par_fun are restored by
%    calling simultaneous_fit.set_par_fun_history(; apply).
%\example
%    % the model shall be an absorbed powerlaw, where there
%    % are independent parameters of the powerlaw for each
%    % data group, but a single absorber, which is applied
%    % to all data
%    simultaneous_fit.fit_fun("tbnew(1)*powerlaw(%)");
%\seealso{fit_fun, simultaneous_fit.sort_params,
%    simultaneous_fit.apply_logic, simultaneous_fit.set_par_fun_history}
%!%-
{
  variable s, ff;
  switch (_NARGS)
    { case 2: (s,ff) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  variable chatty = qualifier("chatty", 1);
  
  % modify and set fit function
  if (chatty) { message("setting fit-function"); }
  s.model.fit_fun = ff;
  ff = strreplace(ff, "%", "Isis_Active_Dataset");
  fit_fun(ff);

  % parameter stuff
  ifnot (qualifier_exists("nosort")) {
    s.sort_params(; chatty = chatty);
    if (qualifier_exists("nohistory")) {
      ifnot (qualifier_exists("nologic")) { s.apply_logic(; chatty = chatty); }
    } else {
      s.set_par_fun_history(;; struct_combine(
	struct { apply, chatty = chatty }, [
          qualifier_exists("ask") ? "ask" : String_Type[0],
          qualifier_exists("nologic") ? "nologic" : String_Type[0],
        ])
      );
    }
  }
} %}}}

private define simultaneous_fit_get_par() %{{{
%!%+    
%\function{simultaneous_fit.get_par}
%\synopsis{get the value of a/many fit parameter/parameters}
%\usage{Double_Type[] simultaneous_fit.get_par(String_Type parameter);}
%\description
%    Does the same as 'get_par' with the modification that
%    the following place holders are allowed:
%      % - set the value for all defined data
%    Note, that here the parameter name has to be provided,
%    not the parameter id!
%
%    All qualifiers are passed to get_par.
%\example
%    % get the normalization of all powerlaws
%    norms = simultaneous_fit.get_par("powerlaw(%).norm");
%\seealso{get_par}
%!%-
{
  variable s, parname;
  switch (_NARGS)
    { case 2: (s,parname) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % loop over all data groups
  variable g, values = Double_Type[0];
  _for g (0, length(s.data)-1, 1) {
    % loop over datasets within the group
    variable d;
    _for d (0, length(s.data[g])-1, 1) {
      % current parameter name
      variable nparname = _simultaneous_fit_parname(parname, s.data[g][d]);
      % check if this parameter exists
      if (_get_index(nparname) > -1) {
        variable pinfo = get_par_info(nparname);
        % get this parameter
        if (pinfo.fun == NULL) values = [values, get_par(nparname)];
      }
    }
  }

  return values;
} %}}}

private define simultaneous_fit_set_par() %{{{
%!%+    
%\function{simultaneous_fit.set_par}
%\synopsis{set the value of a/many fit parameter/parameters}
%\usage{simultaneous_fit.set_par(String_Type parameter[, Double_Type value[, Integer_Type freeze[, Double_Type min, max]]]);}
%\description
%    Does the same as 'set_par' with the modification that
%    the following place holders are allowed:
%      % - set the value for all defined data
%    Note, that here the parameter name has to be provided,
%    not the parameter id!
%
%    All qualifiers are passed to set_par.
%\example
%    % set the normalization of all powerlaws
%    simultaneous_fit.set_par("powerlaw(%).norm", 1, 0, 0, 10);
%\seealso{set_par}
%!%-
{
  variable s, parname, value, freeze, min, max;
  switch (_NARGS)
    { case 2: (s,parname) = (); value = NULL; }
    { case 3: (s,parname,value) = (); }
    { case 4: (s,parname,value,freeze) = (); }
    { case 6: (s,parname,value,freeze,min,max) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % loop over all data groups
  variable nparname = String_Type[0];
  variable g,d;
  _for g (0, length(s.data)-1, 1) {
    % loop over datasets within the group
    _for d (0, length(s.data[g])-1, 1) {
      % current parameter name
      nparname = [ nparname, _simultaneous_fit_parname(parname, s.data[g][d]) ];
      % check if this parameter exists
    }
  }
  
  value = (value == NULL ? get_par(nparname) : value);
  % set this parameter
  switch (_NARGS)
  { case 2: set_par(nparname ;; __qualifiers); }
  { case 3: set_par(nparname, value ;; __qualifiers); }
  { case 4: set_par(nparname, value, freeze ;; __qualifiers); }
  { case 6: set_par(nparname, value, freeze, min, max ;; __qualifiers); }
  
} %}}}

private define simultaneous_fit_copy_par() %{{{
%!%+    
%\function{simultaneous_fit.copy_par}
%\synopsis{copy the parameters of one group to another}
%\usage{simultaneous_fit.copy_par(Integer_Type from_group, to_group);}
%\qualifiers{
%    \qualifier{limits}{copy parameter limits as well}
%}
%\description
%    The values of the group parameters of the first given
%    datagroup are copied to the second datagroup. Parameter
%    limits are not copied unless the limits-qualifier is
%    set.
%
%    Instead of a single target data group, 'to_group', an
%    array of groups, Integer_Type[], may be given.
% \example
%    % copy the parameter values of group 5 to group 6
%    simultaneous_fit.copy_par(5, 6);
%\seealso{simultaneous_fit.list_groups}
%!%-
{
  variable s, g1, g2;
  switch (_NARGS)
    { case 3: (s,g1,g2) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  variable pars = merge_struct_arrays(get_params(s.model.group[g1-1]));
  if (typeof(g2) != Array_Type) { g2 = [g2]; }
  variable g;
  foreach g (g2) {
    if (qualifier_exists("limits")) {
      variable frz = array_struct_field(get_params(s.model.group[g-1]), "freeze");
      array_map(Void_Type, &set_par, s.model.group[g-1], pars.value, frz, pars.min, pars.max);
    } else {
      array_map(Void_Type, &set_par, s.model.group[g-1], pars.value);
    }
  }
} %}}}

private define simultaneous_fit_set_par_fun() %{{{
%!%+    
%\function{simultaneous_fit.set_par_fun}
%\synopsis{Define the value of a/many fit parameter.parameters using a function}
%\usage{simultaneous_fit.set_par_fun(String_Type parameter, String_Type valuefunction);}
%\description
%    In princible, this function does the same as 'set_par_fun'
%    with the modifcation that place holders are allowed:
%      % - set the function for all defined data
%    Note, that here the parameter name has to be provided,
%    not the parameter id!
%
%    This function tries to recognize, if the value function
%    is a parameter itself, which should be applied to a set
%    of the same parameters (e.g. the photon indices are set
%    to a single one). In that case the parameter given in
%    the value function will be treated as a global one from
%    now on.
%
%    On the other side, if the value functions of a set of
%    parameters are deleted (valuefunction=NULL), which were
%    tied to a global parameter before, this parameter is
%    treated as a group one.
%
%    In both cases, a warning message will be shown in order
%    to inform the user which parameter has been treated as
%    global or group parameter.
%
%    In an upcoming version, the place holders are allowed
%    in the value function as well.
%
%    Any call to this function is remembered in an internal
%    history for applying the calls later again (see
%    simultaneous_fit.set_par_fun_history).
%\example
%    % use a single photon index for all data, while
%    % keeping individual normalizations
%    simultaneous_fit.fit_fun("powerlaw(%)");
%    simultaneous_fit.set_par_fun("powerlaw(%).PhoIndex",
%      "powerlaw(1).PhoIndex");
%
%    % allow individual photon indices again
%    simultaneous_fit.set_par_fun("powerlaw(%).PhoIndex",
%      NULL);
%
%    % more fascinating, tie the photon index to a function
%    % of the powerlaw normalization
%    simultaneous_fit.set_par_fun("powerlaw(%).PhoIndex",
%      "constant(1).factor + powerlaw(%).norm * constant(2).factor");
%\seealso{set_par_fun, simultaneous_fit.set_par_fun_history}
%!%-
{
  variable s, parname, parfun;
  switch (_NARGS)
    { case 3: (s,parname,parfun) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % add call to history
  list_append(s.model.tieto_history, {parname, parfun});
  
  % check if parfun is a parameter and it should be applied to a set
  % of parameters -> it is likely that parfun might become a global parameter
  variable global = 0;
  if (parfun != NULL && strlen(parfun) < 32 && _get_index(parfun) > -1 && is_substr(parname, "%") && qualifier_exists("ignoreglobal") == 0) {
    vmessage("warning (%s): interprete %s as global parameter", _function_name, parfun);
    global = 1;
    % move parameter to global list (if not already there)
    if (wherefirst(s.model.global == parfun) == NULL) s.model.global = [s.model.global, parfun];
    else vmessage("warning (%s): %s is already a global parameter", _function_name, parfun);
    % corresponding parameter within each group is tied below
  }
  % if parfun is NULL, than a global parameter might become
  % a group parameter (all corresponding ones)
  if (parfun == NULL) global = Integer_Type[0];

  % loop over all data groups
  variable g;
  _for g (0, length(s.data)-1, 1) {
    % loop over datasets within the group
    variable d;
    _for d (0, length(s.data[g])-1, 1) {
      % current parameter name
      variable nparname = _simultaneous_fit_parname(parname, s.data[g][d]);
      % check if this parameter exists
      if (_get_index(nparname) > -1) {
        variable pinfo = get_par_info(nparname), n;
	% set parameter function
	if (nparname != parfun || qualifier_exists("all"))
	  set_par_fun(nparname, parfun == NULL ? NULL : _simultaneous_fit_parname(parfun, s.data[g][d]));
        % if parfun is a global parameter tie corresponding group parameter
	if (typeof(global) == Integer_Type && global == 1) {
	  n = wherefirst(s.model.group[g] == nparname);
	  if (n != NULL) s.model.tieto[g][n] = parfun;
	}
	% if parfun is NULL check if *all* parameters are tied to the same
	% global parameter (which will become a group parameter afterwards)
	if (typeof(global) == Array_Type) {
	  n = wherefirst(s.model.group[g] == nparname);
	  if (n != NULL && ((length(global) == 0 && s.model.tieto[g][n] != NULL) || (length(global > 0) && s.model.tieto[g][n] == s.model.tieto[0][global[0]])))
	    global = [global, n];
	  else global = 0;
	}
      }
    }
  }
  % change a global parameter to a group one
  if (typeof(global) == Array_Type) {
    vmessage("warning (%s): interprete that %s is no longer a global parameter", _function_name, s.model.tieto[0][global[0]]);
    s.model.global = array_remove(s.model.global, wherefirst(s.model.global == s.model.tieto[0][global[0]]));
    n = 0;
    _for g (0, length(s.data)-1, 1)
      _for d (0, length(s.data[g])-1, 1) {
	if (d == 0) s.model.tieto[g][global[n]] = NULL;
	else {
	  % parameters of remaining data within this group should be
	  % tied to first dataset (according to the logic)
	  s.model.tieto[g][global[n]] = s.model.group[g][global[n-d]];
	  set_par_fun(s.model.group[g][global[n]], s.model.tieto[g][global[n]]);
	}
	n++;
      }
  }
} %}}}

private define simultaneous_fit_set_par_fun_history() %{{{
%!%+    
%\function{simultaneous_fit.set_par_fun_history}
%\synopsis{applies or clears the history of set_par_fun}
%\usage{simultaneous_fit.set_par_fun_history(; qualifiers);}
%\qualifiers{
%    \qualifier{get}{returns the history of calls to set_par_fun}
%    \qualifier{print}{print the history}
%    \qualifier{apply}{applies all calls of the history again}
%    \qualifier{ask}{prompts the user before applying each call
%              of the history (apply-qualifier required)}
%    \qualifier{clear}{clears the history}
%    \qualifier{chatty}{chattiness of this function (default: 1)}
%    \qualifier{nologic}{do not call apply_logic during the history
%              is applied (apply-qualifier)}
%}
%\description
%    Whenever simultaneous_fit.set_par_fun is called the
%    arguments passed are remembered in an internal
%    history. This functions allows to apply each call of
%    the history again, retrieve the history, or clear it.
%
%    This is particularly useful once the parameter logic
%    is set by simultaneous_fit.apply_logic. Note that
%    simultaneous_fit.fit_fun applies the history auto-
%    matically.
%    Note that applying the history first resets the
%    parameter logic with simultaneous_fit.apply_logic.
%
%    In case the history should be returned a list is
%    returned, where each item is a call to set_par_fun
%    with the two strings which have been passed.
%\seealso{simultaneous_fit.set_par_fun,simultaneous_fit.apply_logic}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: s = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  variable chatty = qualifier("chatty", 1);
  
  % return history
  if (qualifier_exists("get")) {
    return s.model.tieto_history;
  }

  % clear history
  if (qualifier_exists("clear")) {
    s.model.tieto_history = list_new;
    if (chatty) { message("cleaned the set_par_fun-history"); }
    return;
  }

  variable i;
  % print history
  if (qualifier_exists("print")) {
    if (chatty) { message("history of set_par_fun:"); }			 
    _for i (0, length(s.model.tieto_history)-1, 1) {
      vmessage("  set_par_fun(\"%s\", \"%s\");",
	       s.model.tieto_history[i][0],
	       s.model.tieto_history[i][1]);
    }
    return;
  }

  % apply history
  if (qualifier_exists("apply")) {
    ifnot (qualifier_exists("nologic")) { s.apply_logic(; chatty = chatty); }
    variable hist = s.model.tieto_history;
    s.model.tieto_history = list_new;
    variable ask = qualifier_exists("ask"), str;
    if (chatty and length(hist) > 0) { message("applying the set_par_fun-history"); }
    _for i (0, length(hist)-1, 1) {
      str = sprintf("  set_par_fun(\"%s\", \"%s\");"R, hist[i][0], hist[i][1]);
      if (ask) {
	switch (keyinput(; nchr = 1, prompt = str + " % y/n? "))
          { case "y": message(""); }
          { message(""); continue; }
      } else { message(str); }
      s.set_par_fun(hist[i][0], hist[i][1]);
    }
    return;
  }

  ()=_simultaneous_fit_help(0, _function_name; help);
} %}}}

private define simultaneous_fit_set_global() %{{{
%!%+    
%\function{simultaneous_fit.set_global}
%\synopsis{Sets a specific group parameter to be fitted globally}
%\usage{simultaneous_fit.set_global(String_Type grouppar);}
%\description
%    A wrapper around simultaneous_fit.set_par_fun, which
%    simply ties the given group parameter name (using the
%    %-placeholder instead of the dataset index) to a single,
%    global parameter.
%    If successful, a warning message will be shown.
%\example
%    % use a single photon index for all data
%    simultaneous_fit.fit_fun("powerlaw(%)");
%    simultaneous_fit.set_global("powerlaw(%).PhoIndex");
%\seealso{simultaneous_fit.unset_global,simultaneous_fit.set_par_fun}
%!%-
{
  variable s, parname;
  switch (_NARGS)
    { case 2: (s,parname) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  s.set_par_fun(parname, _simultaneous_fit_parname(parname, 1));
} %}}}

private define simultaneous_fit_unset_global() %{{{
%!%+    
%\function{simultaneous_fit.unset_global}
%\synopsis{A specific group parameter is fitted individually again}
%\usage{simultaneous_fit.unset_global(String_Type grouppar);}
%\description
%    A wrapper around simultaneous_fit.set_par_fun, which
%    simply unties the given group parameter name (using the
%    %-placeholder instead of the dataset index), which was
%    tied to a single global parameter before.
%    If successful, a warning message will be shown.
%\example
%    % use a photon index for each data group
%    simultaneous_fit.unset_global("powerlaw(%).PhoIndex");
%\seealso{simultaneous_fit.set_global,simultaneous_fit.set_par_fun}
%!%-
{
  variable s, parname;
  switch (_NARGS)
    { case 2: (s,parname) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  s.set_par_fun(parname, NULL);
} %}}}

private define simultaneous_fit_freeze() %{{{
%!%+    
%\function{simultaneous_fit.freeze}
%\synopsis{freezes a/many parameter/parameters}
%\usage{simultaneous_fit.freeze(String_Type parameter);}
%\description
%    In princible, this function does the same as 'freeze'
%    with the modifcation that place holders are allowed:
%      % - set the function for all defined data
%    Note, that here the parameter name has to be provided,
%    not the parameter id!
%\seealso{freeze}
%!%-
{
  variable s, parname;
  switch (_NARGS)
    { case 2: (s, parname) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  s.set_par(parname, NULL, 1);
} %}}}

private define simultaneous_fit_thaw() %{{{
%!%+    
%\function{simultaneous_fit.thaw}
%\synopsis{thawes a/many parameter/parameters}
%\usage{simultaneous_fit.thaw(String_Type parameter);}
%\description
%    In princible, this function does the same as 'thaw'
%    with the modifcation that place holders are allowed:
%      % - set the function for all defined data
%    Note, that here the parameter name has to be provided,
%    not the parameter id!
%\seealso{thaw}
%!%-
{
  variable s, parname;
  switch (_NARGS)
    { case 2: (s, parname) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  s.set_par(parname, NULL, 0);
} %}}}

private define simultaneous_fit_list_data() %{{{
%!%+    
%\function{simultaneous_fit.list_data}
%\synopsis{lists the data groups and their associated dataset IDs}
%\usage{simultaneous_fit.list_data([&variable]);}
%\description
%    Lists the data groups and their associated dataset IDs and
%    number of group parameters. If the optional reference to a
%    variable is provided, then the IDs as an array of lists
%    is put into this variable, where each item corresponds to
%    a data group.
%!%-
{
  variable s, ids = NULL;
  switch (_NARGS)
    { case 1: (s) = (); }
    { case 2: (s,ids) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  
  % list all parameters
  variable list;
  list_par(&list);
  if (list == "null") { message(list); return; }
  list = strchop(list, '\n', 0);

  % loop over data groups
  variable g;
  if (typeof(ids) == Ref_Type) { (@ids) = List_Type[length(s.data)]; }
  _for g (0, length(s.data)-1, 1) {
    if (typeof(ids) == Ref_Type) { (@ids)[g] = { __push_array(s.data[g]) }; }
    vmessage("grp %s: IDs=[%s], #pars=%d",
      sprintf(sprintf("%%0%ds", int(ceil(log10(length(s.data))))), sprintf("%d", g+1)),
      strjoin(array_map(String_Type, &sprintf, "%d", s.data[g]), ","),
      length(wherenot(_isnull(s.model.group[g])))
    );
  }
} %}}}

private define simultaneous_fit_list_global() %{{{
%!%+    
%\function{simultaneous_fit.list_global}
%\synopsis{lists all global parameters}
%\usage{simultaneous_fit.list_global();}
%\description
%    Like 'list_par' this function lists all global parameters.
%\seealso{list_par}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % this might be done in a more elegant way...
  
  % list all parameters
  variable list;
  list_par(&list);
  if (list == "null") { message(list); return; }
  list = strchop(list, '\n', 0);

  % selective output
  variable l;
  message(list[0]); message(list[1]);
  _for l (2, length(list)-1, 1)
    if (substr(list[l], 1, 3) != "#=>")
      if (wherefirst(array_map(Integer_Type, &is_substr, list[l], " "+s.model.global+" ")) != NULL)
        message(list[l]);
} %}}}

private define simultaneous_fit_list_groups() %{{{
%!%+    
%\function{simultaneous_fit.list_groups}
%\synopsis{lists all parameters of specific data groups}
%\usage{simultaneous_fit.list_groups([Integer_Type[] groups]);}
%\qualifiers{
%    \qualifier{tied}{list parameters, which are determined by a
%           value function, also}
%}
%\description
%    Like 'list_par' this function lists all parameters of
%    one or more specific data groups. Note, that unlike
%    arrays the index of the first data group is 1. If no
%    data groups are given the parameters of all groups
%    are listed. By default, parameters without a value
%    function are listed only.
%\seealso{list_par}
%!%-
{
  variable s, groups;
  switch (_NARGS)
    { case 1: (s) = ();
      groups = s.model.current_groups[0] == -1
             ? [[1:length(s.data)]]
             : s.model.current_groups; }
    { case 2: (s,groups) = (); if (typeof(groups) != Array_Type) groups = [groups]; }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % this might be done in a more elegant way...
  
  % list all parameters
  variable list;
  list_par(&list);
  if (list == "null") { message(list); return; }
  list = strchop(list, '\n', 0);

  % get all group parameters
  variable g, grouppar = String_Type[0];
  _for g (0, length(groups)-1, 1) grouppar = [grouppar, s.model.group[groups[g]-1][where(_isnull(s.model.tieto[groups[g]-1]))]];

  % selective output
  variable l;
  message(list[0]); message(list[1]);
  _for l (2, length(list)-1, 1)
    if (substr(list[l], 1, 3) != "#=>")
      if (wherefirst(array_map(Integer_Type, &is_substr, list[l], grouppar)) != NULL) {
	variable tie = (l < length(list)-2 && substr(list[l+1], 1, 3) == "#=>" ? qualifier_exists("tied") ? 1 : 2 : 0);
	if (tie < 2) { message(list[l]);
	  if (tie) message(list[l+1]);
	}
      }
} %}}}

private define simultaneous_fit_plot_group() %{{{
%!%+    
%\function{simultaneous_fit.plot_group}
%\synopsis{plots data and model of a specific data group}
%\usage{simultaneous_fit.plot_group([Integer_Type group]);}
%\description
%    This function plots the data and model of the given
%    data group using the 'plot_data' function.
%
%    If no group number is given the currently selected
%    group is plotted (if it is the only one selected).
%    A specific group can be selected using .select_groups
%
%    All qualifiers are passed to plot_data
%
%\seealso{plot_data, simultaneous_fit.select_groups}
%!%-
{
  variable s, grp;
  switch (_NARGS)
    { case 1: (s) = ();
      if (length(s.model.current_groups) == 1 && s.model.current_groups != -1) {
	grp = s.model.current_groups;
      } else {
        vmessage("error (%s): only a single selected group can be plotted", _function_name); return;
      }
    }
    { case 2: (s,grp) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  if (grp < 1 || grp > length(s.data))
    { vmessage("error (%s): allowed data group range from 1 to %d", _function_name, length(s.data)); return; }

  variable l = list_new();
  array_map(&list_append, l, s.data[grp-1]);
  plot_data(l ;; __qualifiers);
} %}}}

private define _simultaneous_fit_comb_chi_sqr() %{{{
{ % calculates and prints the combined chi-square statistic
  % after Kuehnel et al, 2015b, Acta. Pol., subm.
  variable s = ();

  % get and merge all statistics
  variable chi = s.model.stat;
  chi = merge_struct_arrays(array_map(Struct_Type, &reduce_struct, chi, "covariance_matrix"));
  if (any(chi.num_bins == 0)) {
    vmessage("error(%s): the global parameters or some groups have not been evaluated or fitted", _function_name);
    return;
  }

  s.model.cstat.statistic = chi.statistic[[1:]];
  s.model.cstat.num_group_params = chi.num_variable_params[[1:]];
  s.model.cstat.num_global_params = chi.num_variable_params[0];
  s.model.cstat.num_bins = int(chi.num_bins[[1:]]);
  variable N = length(chi.statistic)-1; % number of groups
  variable mu = s.model.cstat.weight_fun == NULL % weightening of global parameters
    ? (s.model.cstat.num_bins - s.model.cstat.num_group_params)
      / sum(s.model.cstat.num_bins - s.model.cstat.num_group_params)
    : @(s.model.cstat.weight_fun)(
	s.model.cstat.statistic, s.model.cstat.num_bins,
	s.model.cstat.num_group_params, s.model.cstat.num_global_params
      );
  s.model.cstat.combredchi = 1./N * sum(
    s.model.cstat.statistic / (s.model.cstat.num_bins
      - s.model.cstat.num_group_params - mu * s.model.cstat.num_global_params
  ));

  if (SimFit_Verbose > -2 && qualifier_exists("recalc") == 0) {
    vmessage(" Var. global/group pars. = %d/%d", s.model.cstat.num_global_params, int(sum(s.model.cstat.num_group_params)));
    vmessage("               Data bins = %d", int(sum(s.model.cstat.num_bins)));
    vmessage("              Chi-square = %s", substr(sprintf("%.7f", sum(s.model.cstat.statistic)), 1, 9));
    vmessage("    Comb.red. chi-square = %s", substr(sprintf("%.7f", s.model.cstat.combredchi), 1, 9));
  }
} %}}}

private define _simultaneous_fit_map_groups() %{{{
{ % loops over all groups and calls the given function reference
  variable s, groups, dtype, fun, params = Struct_Type[0];
  if (_NARGS > 4) { params = __pop_args(_NARGS-4); }
  (s, groups, dtype, fun) = ();

  % remember free parameters and exclude state
  s.setrestore(); 
  variable freep = freeParameters;
  variable ids = array_flatten(list_to_array(s.data)); 

  try {
    % loop over all given groups
    variable g, ret = (dtype)[length(groups)];
    _for g (0, length(groups)-1, 1) {
      variable p;
      % print group number
      if (SimFit_Verbose > -2) {
	()=system(sprintf("echo -n %d..", groups[g]));
      }
      % freeze all parameters except those associated to this data group (and are not tied)
      variable grouppar = array_map(Integer_Type, &_get_index, s.model.group[groups[g]-1][where(_isnull(s.model.tieto[groups[g]-1]))]);
      foreach p (freep) if (wherefirst(grouppar == p) == NULL) freeze(p);
      % exclude all datasets except those associated with the given group
      exclude(ids);
      _for p (0, length(s.data[groups[g]-1])-1) { ifnot (any(s.model.exclude == s.data[groups[g]-1][p])) { include(s.data[groups[g]-1][p]); } }
      % call the function
      variable tparams = COPY(params);
      _for p (0, length(tparams)-1) { if (length(tparams[p].value) == length(groups)) { tparams[p].value = tparams[p].value[g]; } }
      (@fun)(__push_args(tparams) ;; __qualifiers);
       % get the returned values from that function
      if (dtype != Void_Type) { ret[g] = (); }
      % restore free parameters and exclude state
      s.restore();
    }

    ifnot (qualifier_exists("skipfinaloutput")) {
      if (SimFit_Verbose > -2) { message(""); }
      % print combined statistic
      _simultaneous_fit_comb_chi_sqr(s);
       % print histogram
      if (SimFit_Verbose_Histogram == 0) { ()=s.group_stats(); }
    }
    if (dtype != Void_Type) { return ret; }
    return;
  }
  catch UserBreakError: {
    if (SimFit_Verbose > -2) { message(""); }
    vmessage("\nuser break during group %d: restoring simfit status", g+1);
    s.restore(; params);
    if (dtype != Void_Type) { return dtype[1]; }
  }
} %}}}

private define _simultaneous_fit_map_global() %{{{
{ % calls the given function reference for the global parameters only
  variable s, dtype, fun, params = Struct_Type[0];
  if (_NARGS > 3) { params = __pop_args(_NARGS-3); }
  (s, dtype, fun) = ();

  % remember free parameters
  variable freep = freeParameters;
  s.setrestore();

  try {
    % print global indicator
    if (SimFit_Verbose > -2) {
      ()=system("echo -n global..");
    }
    % freeze all parameters except the global ones
    variable p, global = array_map(Integer_Type, &_get_index, s.model.global);
    foreach p (freep) if (wherefirst(p == global) == NULL) freeze(p);
    % call the function
    variable ret;
    (@fun)(__push_args(params) ;; __qualifiers);
    if (dtype != Void_Type) { ret = (); }
    % restore free parameters
    thaw(freep);

    % update fit-statistic of all groups
    ifnot (qualifier_exists("skipupdatestat")) {
      variable i, fv = Fit_Verbose;;
      exclude(all_data); Fit_Verbose = -1;
      _for i (0, length(s.data)-1, 1) {
	include(s.data[i]);
	s.model.stat[i+1].statistic = eval_stat_counts().statistic;
	exclude(s.data[i]);
      }
      include(all_data); Fit_Verbose = fv;
    }

    ifnot (qualifier_exists("skipfinaloutput")) {
      if (SimFit_Verbose > -2) { message(""); }
      % print combined statistic
      _simultaneous_fit_comb_chi_sqr(s);
       % print histogram
      if (SimFit_Verbose_Histogram == 0) { ()=s.group_stats(); }
    }
    if (dtype != Void_Type) { return ret; }
    return;
  }
  catch UserBreakError: {
    if (SimFit_Verbose > -2) { message(""); }
    message("\nuser break: restoring simfit status");
    s.restore(; params);
  }
} %}}}

private define simultaneous_fit_group_stats() %{{{
%!%+    
%\function{simultaneous_fit.group_stats}
%\synopsis{prints a summary about the groups current fit-statistics}
%\usage{Integer_Type[] simultaneous_fit.group_stats();}
%\description
%    A histogram of the current red. chi-squares of all
%    groups is printed into the terminal. The histogram
%    ranges from the smallest to the largest found
%    red. chi-square. This range is shown as two ticmarks
%    below the x-Axis. The detailed statistics of each
%    group can be found in the .model.stat-field.
%    The returned array holds the numbers of groups
%    sorted by their red. chi-square, starting at the
%    worst.
%\seealso{printhplot}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % get and merge the red. chi-squares of all groups
  variable chis = merge_struct_arrays(s.model.stat[[1:]]);
  if (any(chis.num_bins == 0)) {
    vmessage("error(%s): some groups have not been evaluated or fitted", _function_name);
    return;
  }
  chis = chis.statistic / (chis.num_bins - chis.num_variable_params);
  % create a histrogram
  variable lo, hi;
  (lo,hi) = linear_grid(min(chis), max(chis), 30);
  variable hist = histogram(chis, lo, hi);
  % printplot it
  printhplot(lo, hi, hist; W = length(lo), H = 5, yformat = "%d", ystrlen = 2);

  return array_sort(chis; dir = -1) + 1;
} %}}}

private define simultaneous_fit_filter_groups() %{{{
%!%+    
%\function{simultaneous_fit.filter_groups}
%\synopsis{return the group numbers matching a filter}
%\usage{simultaneous_fit.filter_groups([Integer_Type or String_Type filter]);}
%\description
%    Returns the group numbers which reduced chi-square
%    matches the given filter. The filter can be one of
%    the following three options:
%    1) no filter given - the group with the worst fit
%       statistic is returned
%    2) integer (n) given - sorts the groups after their
%       fit statistic (beginning at the worst) and returns
%       the first n groups
%    3) string given - has to be given in the format
%       "[operator][number]". Those group number are
%       returned which reduced chi-squares (chi) matches
%         chi [operator] [number]
%       The operators >, >=, <, <=, and == are possible.
%       Multiple of those rules can be specified if
%       separated with ','.
%
%    This function can be very useful if combined with
%    .select_groups
%\example
%    % initialize the simultaneous fit
%    simpi = simulteneous_fit();
%    ...
%    
%    % return the three worst fitted groups
%    grps = simpi.filter_groups(3);
%
%    % return those which have 1.7 <= chi^2_red <= 3
%    grps = simpi.filter_groups(">=1.7,<=3");
%
%    % directly select the worst group for fitting,
%    % plotting, etc.
%    simpi.select_groups(simpi.filter_groups());
%\seealso{simultaneous_fit.select_groups}
%!%-
{
  variable s, filter = NULL;
  switch (_NARGS)
    { case 1: (s) = (); }
    { case 2: (s, filter) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % get and merge the red. chi-squares of all groups
  variable chis = merge_struct_arrays(s.model.stat[[1:]]);
  if (any(chis.num_bins == 0)) {
    vmessage("error(%s): some groups have not been evaluated or fitted", _function_name);
    return;
  }
  chis = chis.statistic / (chis.num_bins - chis.num_variable_params);

  % return the worst group
  if (filter == NULL) {
    return where_max(chis) + 1;
  }
  % return the n worst groups
  if (typeof(filter) == Integer_Type) {
    return array_sort(chis; dir = -1)[[0:filter-1]] + 1;
  }
  % return matching user-defined filter
  filter = strchop(filter, ',', 0);
  variable i = [0:length(s.data)-1], n;
  _for n (0, length(filter)-1, 1) {
    variable rule = string_matches(filter[n], "\([^0-9]*\)\([0-9\.]*\)"R);
    if (length(rule) != 3 || rule[2] == "") {
      vmessage("error(%s): could not parse the filter %s", _function_name, filter[n]);
      return;
    }
    switch (rule[1])
      { case ">": i = i[where(chis[i] > atof(rule[2]))]; }
      { case ">=": i = i[where(chis[i] >= atof(rule[2]))]; }
      { case "<": i = i[where(chis[i] < atof(rule[2]))]; }
      { case "<=": i = i[where(chis[i] <= atof(rule[2]))]; }
      { case "==": i = i[where(chis[i] == atof(rule[2]))]; }
      { vmessage("error(%s): unkown operater '%s'", _function_name, rule[1]); return; }
  }
  return i+1;
} %}}}

private define simultaneous_fit_select_groups() %{{{
%!%+    
%\function{simultaneous_fit.select_groups}
%\synopsis{select the default groups to be worked on}
%\usage{simultaneous_fit.select_groups([Integer_Type[] groups]);}
%\description
%    Some functions within in the simultaneous structure
%    accept an optional array of group numbers, on which
%    they perform their taks. For instance, .fit_groups
%    either performs a fit for the given groups only. If
%    none are given, the default is to fit all groups.
%    This function, however, changes this default such
%    that the here given group(s) are used by default.
%    If no groups are given the default is set back to
%    all groups. To get the current set default you may
%    check the .model.current_groups variable (-1 means
%    all groups are used).
%!%-
{
  variable s, g;
  switch (_NARGS)
    { case 1: (s) = (); s.model.current_groups = -1; }
    { case 2: (s, g) = (); s.model.current_groups = g; }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;  
} %}}}

private define simultaneous_fit_eval_groups() %{{{
%!%+    
%\function{simultaneous_fit.eval_groups}
%\synopsis{evaluates the model for each (given) data group}
%\usage{Integer_Type simultaneous_fit.eval_groups([Integer_Type[] groups]);}
%\description
%    Loops over each (given) data group and evaulates the
%    model using only those parameters assigned to that
%    group. All other groups and parameters are excluded.
%    If no group is given, every group is evaluated.
%    Note, that the number of the first data group is 1
%    (not 0 as for arrays).
%    The displayed fit statistics are those of the
%    individual group only. The statistics are available
%    afterwards in the model.stat struct-array.
%
% All qualifiers are passed to eval_counts
%\seealso{simultaneous_fit.eval_global, eval_counts}
%!%-
{
  variable s, groups;
  switch (_NARGS)
    { case 1: (s) = ();
      groups = s.model.current_groups[0] == -1
             ? [1:length(s.data)]
             : s.model.current_groups; }
    { case 2: (s,groups) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % check given groups
  if (min(groups) < 1 || max(groups) > length(s.data)) { vmessage("error (%s): allowed data groups range from 1 to %d", _function_name, length(s.data)); return NULL; }

  %    if (fit_counts(&(s.model.stat[g]);; struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers)) == -1);
  variable ref = Ref_Type[length(groups)], fc;
  _for fc (0, length(groups)-1) { ref[fc] = &(s.model.stat[groups[fc]]); }
  fc = _simultaneous_fit_map_groups(s, groups, Integer_Type, &eval_counts, ref;;
                                    struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers));
 
  return min(fc); % <0 if any fit failed
} %}}}

private define simultaneous_fit_fit_groups() %{{{
%!%+    
%\function{simultaneous_fit.fit_groups}
%\synopsis{performs a fit of each (given) data group}
%\usage{Integer_Type simultaneous_fit.fit_groups([Integer_Type[] groups]);}
%\description
%    Loops over each (given) data group and performs a fit
%    of only those parameters assigned to that group. All
%    other groups and parameters are excluded from the fit.
%    In particular, all global parameters are fixed! If no
%    group is given, a fit for every group is performed.
%    Note, that the number of the first data group is 1
%    (not 0 as for arrays).
%    The displayed fit statistics are those of the
%    individual group only. The statistics are available
%    afterwards in the model.stat struct-array.
%
%    All qualifiers are passed to fit_counts.
%
%\seealso{simultaneous_fit.fit_global, fit_counts}
%!%-
{
  variable s, groups;
  switch (_NARGS)
    { case 1: (s) = ();
      groups = s.model.current_groups[0] == -1
             ? [1:length(s.data)]
             : s.model.current_groups; }
    { case 2: (s,groups) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % check given groups
  if (min(groups) < 1 || max(groups) > length(s.data)) { vmessage("error (%s): allowed data groups range from 1 to %d", _function_name, length(s.data)); return NULL; }

  %    if (fit_counts(&(s.model.stat[g]);; struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers)) == -1);
  variable ref = Ref_Type[length(groups)], fc;
  _for fc (0, length(groups)-1) { ref[fc] = &(s.model.stat[groups[fc]]); }
  fc = _simultaneous_fit_map_groups(s, groups, Integer_Type, &fit_counts, ref;;
                                    struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers));

  return min(fc); % <0 if any fit failed
} %}}}

private define simultaneous_fit_eval_global() %{{{
%!%+    
%\function{simultaneous_fit.eval_global}
%\synopsis{evaluates the model for all global parameters}
%\usage{Integer_Type simultaneous_fit.eval_global();}
%\description
%    All data groups are included within the evaulation
%    of the model, but the only free parameters are the
%    global parameters.
%    The displayed fit statistic includes all data, but
%    the global parameters only. The statistics are
%    available afterwards in the model.stat struct-array.
%
%    All qualifiers are passed to eval_counts.
%
%\seealso{simultaneous_fit.eval_groups, eval_counts}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  return _simultaneous_fit_map_global(s, Integer_Type, &eval_counts, &(s.model.stat[0]);;
				      struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers));
} %}}}

private define simultaneous_fit_fit_global() %{{{
%!%+    
%\function{simultaneous_fit.fit_global}
%\synopsis{performs a fit of all global parameters}
%\usage{Integer_Type simultaneous_fit.fit_global();}
%\description
%    All data groups are included within the fit, but the
%    only free parameters are the global parameters. In
%    particular, all group parameters are fixed!
%    The displayed fit statistic includes all data, but
%    the global parameters only. The statistics are
%    available afterwards in the model.stat struct-array.
%
%    All qualifiers are passed to fit_counts.
%
%\seealso{simultaneous_fit.fit_group, fit_counts}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  return _simultaneous_fit_map_global(s, Integer_Type, &fit_counts, &(s.model.stat[0]);;
				      struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers));
} %}}}

private define simultaneous_fit_fit_smart() %{{{
%!%+    
%\function{simultaneous_fit.fit_smart}
%\synopsis{combines group- and global-fits to achieve the best-fit}
%\usage{Integer_Type simultaneous_fit.fit_smart();}
%\qualifiers{
%    \qualifier{maxiter}{maximum number of iterations (default: 10)}
%    \qualifier{tol}{favored difference in chi square (default: 0.1)}
%    \qualifier{chatty}{output statistics for each iteration (default: 1)}
%}
%\description
%    By alternating between fitting the group parameters
%    and then the global parameters only, a best-fit is
%    tried to achieve. The fit is successful, if the
%    difference in delta chi square compared to the
%    previous iteration is less than the given tolerance.
%    The loop interrupts, if a maximum number of allowed
%    iterations is reached (the default number is low on
%    purpose).
%
%    Some tests showed that the final best-fit here is worse
%    than that achieved by 'fit_counts' (in the order of 10%
%    in reduced chi square). If a lot of data is fitted,
%    this method is, however, much faster than a simple
%    'fit_counts' (which might take days...).
%
%    All qualifiers not listed above are passed to fit_counts
%\seealso{simultaneous_fit.fit_global, simultaneous_fit.fit_groups}
%!%-
{
  variable s;
  switch (_NARGS)
    { case 1: (s) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % default values
  variable maxiter = qualifier("maxiter", 10);
  variable tol = qualifier("tol", .1);
  variable chatty = qualifier("chatty", 1);

  % initialize fit
  if (s.model.stat[0].num_bins == 0) {
    vmessage("error(%s): the global parameters have not been evaluated or fitted", _function_name);
    return;
  }
  variable last = s.model.stat[0].statistic;
  variable i = 0;

  % iterative loop
  do {
    % perform the fits
    ()=s.fit_groups(;; struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers));
    ()=s.fit_global(;; struct_combine(struct { fit_verbose = SimFit_Verbose }, __qualifiers));
    % compute statistics
    variable this = s.model.stat[0].statistic;
    variable change = last - this;
    last = this; i++;
    if (chatty) {
      vmessage(sprintf("iteration %%d: chi^2 = %%.%df, change = %%.%df", abs(int(log10(tol)))+1, abs(int(log10(tol)))+1), i, this, change);
    }
  } while (change >= tol && i < maxiter);
  return -(i == maxiter);
} %}}}

private define simultaneous_fit_fit_pars() %{{{
%!%+    
%\function{simultaneous_fit.fit_pars}
%\synopsis{runs fit_pars for the given data group}
%\usage{Struct_Type simultaneous_fit.fit_pars( Integer_Type group );}
%\altusage{Struct_Type simultaneous_fit.fit_pars( String_Type parname );}
%\qualifiers{
%\qualifier{frozen}{[=0] Perform fit_pars also for frozen Parameters.
%                   NOTE: just works if 'parname' is given!}
%\qualifier{force}{If group=0 (globals) force to perform fit_pars for all
%                  globals. Without this qualifier the parname of ONE global
%                  parameter is required!}
%}
%\description
%    Calculates the confidence level(s) of the parameter(s)
%    associated to the given data 'group' or 'parname'.
%    The function uses 'fit_pars' and returns its result.
%
%    Instead of the number of a data group, the name of
%    a parameter may be given instead. In that
%    case the confidence level of this parameter is
%    calculated only.
%
%    Note that for a global parameter the 'parname' has
%    to be given!
%
%    Also note that normally frozen parameters are ignored.
%    If this function is called with 'parname' and the
%    'frozen' qualifier is given, the confidence level
%    is calculated nevertheless.
%
%    It is important to keep in mind, that a 'fit_pars'
%    can lead to a new best fit. If the confidence levels
%    of a group as a whole are calculated a new best fit
%    of one of the group parameter is automatically taken
%    into account, but not if the confidence level of a
%    single parameter (e.g., using 'parname') is looked
%    at. This is a problem especially for the global
%    parameters. Use 'mpi_fit_pars' for your advantage!
%    
%    Note, that a usual 'fit_pars' will take a tremendous
%    amount of time (like 'fit_counts'). Thus, this
%    function accepts one data group only and it is
%    recommended to use only one parameter in addition.
%    It might be helpful to reduce the accuracy with which
%    fitting methods try to calculate chi square values
%    and/or parameters (see set_fit_method).
%
%    Further on, this approach is ideal to be used with
%    Torque (see 'simultaneous_fit.fit_pars_jobfile').
%
%    All qualifiers are also passed to fit_pars.
%
%\seealso{fit_pars, simultaneous_fit.list_groups,
%    simultaneous_fit.list_global, simultaneous_fit.fit_pars_jobfile}
%!%-
{
  variable frozen = qualifier("frozen",0);  if( qualifier_exists("frozen") ) frozen = 1;

  variable freep = freeParameters;
  variable paridx = Integer_Type[0];
  variable OUT = NULL, p;
  
  variable s, grp = NULL, parname = NULL;
  switch (_NARGS)
  { case 2: (s,grp) = ();
    if( typeof(grp) == String_Type ){
      % find according group:
      parname = grp;
      grp == NULL;
      ifnot( wherefirst( parname == s.model.global ) == NULL )
	grp = 0;
      else{
	_for p ( 1, length(s.model.group), 1 )
	  ifnot( wherefirst( parname == s.model.group[p-1] ) == NULL )
	    grp = p;
      }
      if( grp == NULL )
      { vmessage("error (%s): %s is no parameter!", _function_name, parname); return OUT; }
    }
  }
  %  { case 3: (s,grp,parname) = (); }
  { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  s.setrestore();

  try {
  % global parameter
  if (grp == 0) {
    if (parname == NULL ){
      ifnot( qualifier_exists("force") ){
	vmessage("error (%s): global parameter name required (or use qualifier 'force')", _function_name);
        return OUT;
      }
    }
    else if( wherefirst(_get_index(parname)==freeParameters) == NULL and frozen==0 ){
      vmessage("error (%s): %s is frozen! Set qualifier 'frozen' to perform confidence calculations!",
	       _function_name, parname);
      return OUT;
    }
    
    variable globalpar = array_map(Integer_Type, &_get_index, s.model.global);

    % freeze groups
    foreach p (freep) if (wherefirst(p == globalpar) == NULL) freeze(p);
    if (parname == NULL)
      paridx = freeParameters;
    else if( wherefirst(_get_index(parname)==freeParameters) != NULL or frozen==1 )
      paridx = _get_index(parname);
    % perform confidence calculation
    OUT = fit_pars( paridx ;; __qualifiers);
    s.model.stat[grp] = reduce_struct( eval_stat_counts(), "covariance_matrix");
    % restore free parameters
    thaw(freep);
  }
  % group parameter(s)
  else if( grp <= length(s.model.group) ) {
    variable grouppar  = array_map(Integer_Type, &_get_index, s.model.group[grp-1][where(_isnull(s.model.tieto[grp-1]))]);
    variable ids = array_flatten(list_to_array(s.data));
    variable excl = array_struct_field(get_data_info(ids), "exclude");

    % freeze all parameters except those associated to this data group (and are not tied)
    foreach p (freep) if (wherefirst(p == grouppar) == NULL) freeze(p);
    % only use given data group during fit
    exclude(ids);
    _for p (0, length(s.data[grp-1])-1, 1) ifnot (excl[wherefirst(all_data == s.data[grp-1][p])]) include(s.data[grp-1][p]);
    % perform confidence calculation
    if (parname == NULL)
      paridx = freeParameters;
    else if( wherefirst(_get_index(parname)==freeParameters) != NULL or frozen==1 )
      paridx = _get_index(parname);
    OUT = fit_pars( paridx ;; __qualifiers);
    s.model.stat[grp] = reduce_struct( eval_stat_counts(), "covariance_matrix");
    % restore free parameters and exclude state
    _for p (0, length(ids)-1, 1) if (excl[p] == 0) include(ids[p]);
    thaw(freep);
  }
  else
  { vmessage("error (%s): There is no group with idx %d!", _function_name, grp); return OUT; }  

  return OUT;
  }
  catch UserBreakError: {
    message("\nuser break: restoring simfit status");
    s.restore(; params);
  }
  catch AnyError: {
    message("\nsome error occured: consider calling .restore");
  }
} %}}}

private define _simultaneous_fit_steppar_fit() %{{{
{
  % Fit function for steppar replacing fit_counts
  variable s, grp;
  switch (_NARGS)
  { case 2: (s, grp) = (); }
  { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;
  
  if(grp==0){
    ()=s.fit_global();
  }
  else{
    ()=s.fit_groups(grp);
  }
  return s.fit_smart(;;__qualifiers);
}
%}}}

private define simultaneous_fit_steppar() %{{{
%!%+    
%\function{simultaneous_fit.steppar}
%\synopsis{runs steppar based on the simultanous fit logic}
%\usage{Struct_Type simultaneous_fit.steppar( String_Type parname );}
%\altusage{Struct_Type simultaneous_fit.steppar( Integer_Type idx );}
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
%\qualifier{check}{[=0] Before each step saved steppar informations of other stepped
%                        parameters are gathered and checked for a parameter set with a
%                        better chi2 (using steppar_get_bestparams). In case a better
%                        parameter set was found the stepping will be restarted.
%                        * ATTENTION: 'save' qualifier is required !!!
%                        * Gathered are steppar-files, which match the pattern
%                          given with 'save',e.g., if save is "steppar_PID001.fits"
%                          all files "steppar_PID???.fits" are globed!
%                          Note that the affix "_PID???" is automaticcaly appended to
%                          the save string if it does not exist (see 'save' qualifier!)
%                        * The Integer 'check' is set to is the maximal number of
%                          restarts.
%                        * A parameter set is considered better if
%                          chi2_new < chi2_init * ( 1 - dchi2 )
%                        * NOTE: Parameter grouping is possible (see steppar_get_bestparams)
%                        }
%\qualifier{dchi2}{[=0.1] Fractional limit for the chi2 of a new parameter set to be
%                  considered as a better parameter set (see 'check'):
%                  chi2_new < chi2_init * ( 1 - dchi2 ).}
%\qualifier{save}{After each stepping the result is saved in the file given
%                   (as String_Type) with this qualifier. The chi2 of undone steps
%                   are set to 0.! Also note that the filename is appended with
%                   the parameterindex: 'steppar.fits' -> 'steppar_PID001.fits'}
%\qualifier{force}{Forces to overwrite an existing file given with 'save'.}
%\qualifier{chatty}{Prints fitting information.}
%}
%\description
%      This function is calling 'steppar' with an adjusted fitting function:
%      fit = &_simultaneous_fit_steppar_fit which first calls either %.fit_groups
%      or %.fit_global depending on the affiliation of the given parameter.
%      Afterwards %.fit_smart is called (with the passed qualifiers).
%      For more detailed information see the help of 'steppar'!
%
%      Qualifiers are also passed to 'steppar' & '%.fit_smart'!
%
%\seealso{%.fit_smart, steppar}
%!%-
{
  variable s, parname;
  switch (_NARGS)
  { case 2: (s, parname) = (); }
  { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;
  
  try {
    
    %%% Parameter check:
    % check for parameter existence (if multiple, chosing first)
    variable parinfo = get_par_info(parname)[0];
    if( parinfo == NULL ){
      vmessage("ERROR <%s>: No parameter to given parname=%s found!",
	       _function_name,parname );
      return NULL;
    }
    parname = parinfo.name;

    % find group of parameter
    variable i = 0, j;
    variable grp = NULL;
    while( grp == NULL ){
      j = where( s.model.group[i] == parname );
      i++;
      ifnot( length(j) == 0 ){
	grp = i;
	j = j[0];
      }
    }
    % check if global parameter
    if( any( s.model.tieto[grp-1][j] == s.model.global ) ){
      vmessage("WARNING <%s>: '%s' is tied to global parameter '%s' (now used)!",
	       _function_name, parname, s.model.tieto[grp-1][j] );
      grp = 0;
      parname == s.model.tieto[grp-1][j];
      parinfo = get_par_info(parname);
    }

    variable params = get_params;
    variable fitargs = { s, grp };
    variable qualis = struct{
      fit=&_simultaneous_fit_steppar_fit,
      fitargs=fitargs
    };
    if( grp != 0 ){
      qualis = struct_combine( qualis, struct{ groups = s.model.group[grp-1] } );
    }
    
    return steppar( parname ;; struct_combine( qualis, __qualifiers ));
  }
  catch UserBreakError: {
    message("\nuser break: restoring simfit status");
    set_params(params);
    return;
  }
  catch AnyError: {
    message("\nsome error occured: consider calling .restore");
    return;
  }
} %}}}

private define simultaneous_fit_fit_pars_jobfile() %{{{
%!%+    
%\function{simultaneous_fit.fit_pars_jobfile}
%\synopsis{writes a Torque-jobfile to calculate confidence levels}
%\usage{simultaneous_fit.fit_pars_jobfile(String_Type jobfile, scriptfile);}
%\qualifiers{
%    \qualifier{force}{overwrites an existing jobfile or script
%                  (default: don't overwrite)}
%    \qualifier{writescript}{writes a template for the script into
%                  the given filename (file will be overwritten)}
%}
%\description
%    Writes a Torque 'jobfile' to calculate the confidence
%    levels of all (free) parameters. Therefore, the filename
%    of the script for loading the data, defining the model
%    and running simultaneous_fit.fit_pars is mandatory.
%    This script will be called by each job with a
%    command line argument, which is either
%      - the data group index, for which the confidence levels
%        should be calculated for or
%      - the parameter name to compute the level
%        for a single parameter in the global group.
%        This means that the parameters of a data group are
%        treated in parallel by multiple jobs.
%    In case of a global parameter, the data group argument
%    is omitted and the name of the global parameter is
%    given instead. The command lines arguments can be
%    accessed using '__argv' and '__argc'.
%    
%    If the qualifier 'writescript' exists, a template for
%    the script described above will be written into the
%    given 'scriptfile'name. This has to be modified
%    afterwards to ensure compatibility and should be
%    treated as a support!
%    Warning: in case of an already existing filename this
%             file will be overwritten!
%\seealso{simultaneous_fit.fit_pars}
%!%-
{
  variable s, jobfile, scriptfile;
  switch (_NARGS)
    { case 3: (s,jobfile,scriptfile) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;


  % QUALIFIER JOBFILES
  variable walltime = qualifier("walltime","00:01:00");
  variable jobname  = qualifier("jobname","sim_fitpars");
  variable logpath  = qualifier("logpath",jobname);
  
  % Check TYPE
  if (typeof(jobfile) != String_Type){ vmessage("error (%s): given jobfile has to be a string", _function_name); return; }
  if (typeof(scriptfile) != String_Type){ vmessage("error (%s): given scriptfile has to be a string", _function_name); return; }
  
  % Scriptfiles with arguments
  variable script = strtok(scriptfile)[0];
  variable nargs  = length(strtok(scriptfile)[[1:]]);
  
  % Check files
  if (access(jobfile, F_OK) == 0 && qualifier_exists("force") == 0)
    { vmessage("error (%s): jobfile '%s' already exists", _function_name, jobfile); return; }
  if ( not(qualifier_exists("writescript")) && access(script, F_OK) == -1 )
  { vmessage("error (%s): scriptfile '%s' does not exists", _function_name, script); return; }
  if (qualifier_exists("writescript") && access(script, F_OK) == 0 && qualifier_exists("force") == 0)
  { vmessage("error (%s): scriptfile '%s' already exists", _function_name, script); return; }

  
  % get current user
  variable user, pp = popen("whoami", "r");
  ()=fgets(&user, pp);
  ()=pclose(pp);
  user = strreplace(user, "\n", "");

  % get current directory
  variable pwd;
  pp = popen("pwd", "r");
  ()=fgets(&pwd, pp);
  ()=pclose(pp);
  pwd = strreplace(pwd, "\n", "");
  
  % CHECK LOGPATH
  if( is_substr( logpath,pwd ) == 0 )
    logpath = pwd+"/"+logpath;
  if( logpath[-1] == '/' )
    logpath = logpath[[:-2]];
  mkdir(logpath);

 
  % build jobfile
  variable job = "#!/bin/bash\n#\n";
  job += "#PBS -S /bin/bash -V\n";
  job += "#PBS -t 0-%d%%10000\n";
  job += "#PBS -l nodes=1\n";
  job += "#PBS -l arch=x86_64\n";
  job += sprintf("#PBS -l walltime=%s\n", walltime);
  job += sprintf("#PBS -N %s\n",jobname);
  job += sprintf("#PBS -o %s/%s_groups.out\n", logpath, jobname);
  job += sprintf("#PBS -e %s/%s_groups.err\n", logpath, jobname);
  job += sprintf("\ncd %s\n", pwd);

  variable n = 0, g;
  % loop over each data group
  _for g (1, length(s.data), 1) {
    % a fit_pars for all parameters of the group
    job += sprintf("COMMAND[%d]=\"isis-script %s %d\"\n", n, scriptfile, g);
    n++;
  }
  % add global parameters to jobfile
  _for g (0, length(s.model.global)-1, 1) {
    job += sprintf("COMMAND[%d]=\"isis-script %s %s\"\n", n, scriptfile, s.model.global[g]);
    n++;
  }
  job += "/usr/bin/nice -n +15 ${COMMAND[$PBS_ARRAYID]}";
  job = sprintf(job, n-1);

  % write jobfile
  variable fp = fopen(jobfile, "w+");
  ()=fputs(job, fp);
  ()=fclose(fp);


  % QUALIFIER SCRIPTFILE
  variable parpath = qualifier("parpath",logpath);
  % CHECK PARPATH
  if( is_substr( parpath,pwd ) == 0 )
    parpath = pwd+"/"+parpath;
  if( parpath[-1] == '/' )
    parpath = parpath[[:-2]];
  mkdir(parpath);
  
  % eventually, write script template
  variable wscrpt;
  if (qualifier_exists("writescript")) {
    wscrpt  = "require(\"isisscripts\");\n";
    wscrpt += "% TIME LOG\n";
    wscrpt += "tic;vmessage(\"%s : Calling: '%s'\",time,strjoin(__argv,\" \"));\n\n";
    
    wscrpt += "%%% initialize the simultaneous fit, adding the %%%\n";
    wscrpt += "%%% data and defining/loading the model here    %%%\n\n";
    
    wscrpt += "% get command line arguments (last argument has to be the group index or parname!)\n";
    wscrpt += "variable grp = __argv[-1];\n";
    wscrpt += "if( atoi(grp) != 0 ) grp = atoi(grp);\n";

    wscrpt += "\n%%% set the directory for the output fits-files here %%%\n";
    wscrpt += "%%% make sure that this directory exists!            %%%\n";
    wscrpt += sprintf("variable parpath = %s;\n",parpath);
    wscrpt += "% check on existence of parpath\n";
    wscrpt += "if (access(parpath, F_OK) != 0) {\n";
    wscrpt += "  vmessage(\"error: directory %s does not exist, aborting...\", parpath);\nexit;\n}\n";

    wscrpt += "\n% calculate uncertainties\n";
    wscrpt += "%%% replace 'simfit' by the name of your simultaneous-fit-structure %%%\n";
    wscrpt += "variable fpars = simfit.fit_pars( grp ; basefilename = sprintf(\"%s/"+jobname+"_%04d.fits\", parpath, grp));\n";

    wscrpt += "\n% TIME LOG\n";
    wscrpt += "variable elaptime = toc;\n";
    wscrpt += "vmessage(\"%s : Finished '%s' after %d s < %d %s\",\n";
    wscrpt += "time,strjoin(__argv,\" \"),nint(elaptime),time_array(elaptime)[-1]+1,\n";
    wscrpt += "[\"sec\",\"min\",\"h\",\"d\",\"y\"][length(time_array(elaptime))-1]  );";
    
    
    % write scriptfile
    fp = fopen(script, "w+");
    ()=fputs(wscrpt, fp);
    ()=fclose(fp);
  }
} %}}}

#ifeval __get_reference("mpi_fit_pars")!=NULL
private define simultaneous_fit_mpi_fit_pars() %{{{
%!%+    
%\function{simultaneous_fit.mpi_fit_pars}
%\synopsis{runs mpi_fit_pars for the given data group}
%\usage{Struct_Type simultaneous_fit.mpi_fit_pars( Integer_Type group );}
%\description
%    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%    ATTENTION: This function does not work in an open
%               isis session, as it links to 'mpi_fit_pars'!
%               It is supposed to be used in a script file
%               submitted as a torque job only!
%    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%
%    Calculates the confidence levels of the FREE parameters
%    associated to the given data group.
%    This function uses the function 'mpi_fit_pars' and its
%    result is returned.
%
%    The argument <group> represents the index  of the
%    data GROUP, of which the confidence levels are supposed
%    to be calculated.
%    group = 0 corresponds to the 'group' of the GLOBAL
%    parameters!
%    
%    Note, that a usual 'fit_pars' will take a tremendous
%    amount of time (like 'fit_counts'). Thus, this
%    function accepts one data group only and it is
%    recommended to use only one parameter in addition.
%    It might be helpful to reduce the accuracy with which
%    fitting methods try to calculate chi square values
%    and/or parameters (see set_fit_method).
%
%    Further on, this approach is ideal to be used with
%    Torque (see 'simultaneous_fit.mpi_fit_pars_jobfiles').
%
%    All qualifiers are also passed to mpi_fit_pars
%
%\seealso{fit_pars, mpi_fit_pars, simultaneous_fit.list_groups,
%    simultaneous_fit.list_global, simultaneous_fit.mpi_fit_pars_jobfiles}
%!%-
{
  variable s, grp;
  switch (_NARGS)
  { case 2: (s,grp) = ();}
  { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;
  
  variable err1 = sprintf("<%s> ERROR: #freeParameters does not match %%.model.stat.num_variable_params, i.e.,\n"
			  +"since the last fit parameters have been frozen/thawed!\n"
			  +"Please perform a fit_counts or %%.fit_smart/groups/global!",_function_name);
  
  variable freep = freeParameters;
  variable OUT = NULL, p;
  % global parameter (grp==0)
  if (grp == 0) {
    variable global = array_map(Integer_Type, &_get_index, s.model.global);
    % freeze groups
    foreach p (freep) if (wherefirst(p == global) == NULL) freeze(p);
    % perform confidence calculation ON FREE PARAMETERS
    if( s.model.stat[grp].num_variable_params != length(freeParameters) )
    { vmessage(err1); }
    else{
      OUT = mpi_fit_pars( freeParameters ;; __qualifiers);
      s.model.stat[grp] = reduce_struct( eval_stat_counts(), "covariance_matrix");
    }
    % restore free parameters
    thaw(freep);
  }
  % group parameter(s)
  else {
    variable ids = array_flatten(list_to_array(s.data)); 
    variable excl = array_struct_field(get_data_info(ids), "exclude");
    % freeze all parameters except those associated to this data group (and are not tied)
    variable grouppar = array_map(Integer_Type, &_get_index, s.model.group[grp-1][where(_isnull(s.model.tieto[grp-1]))]);
    foreach p (freep) { if (wherefirst(grouppar == p) == NULL) { freeze(p); } }
    % only use given data group during fit
    exclude(ids);
    _for p (0, length(s.data[grp-1])-1, 1) { ifnot (excl[wherefirst(all_data == s.data[grp-1][p])]) { include(s.data[grp-1][p]); } }
    % perform confidence calculation
    if( s.model.stat[grp].num_variable_params != length(freeParameters) )
    { message(err1); }
    else{
      OUT = mpi_fit_pars( freeParameters ;; __qualifiers);
      s.model.stat[grp] = reduce_struct( eval_stat_counts(), "covariance_matrix");
    }
    % restore free parameters and exclude state
    _for p (0, length(ids)-1, 1) if (excl[p] == 0) include(ids[p]);
    thaw(freep);
  }
  return OUT;
} %}}}

private define simultaneous_fit_mpi_fit_pars_jobfiles() %{{{
%!%+    
%\function{simultaneous_fit.mpi_fit_pars_jobfiles}
%\synopsis{writes a Torque-jobfile to calculate confidence levels}
%\usage{simultaneous_fit.mpi_fit_pars_jobfiles(String_Type jobfile, scriptfile);}
%\qualifiers{
%\qualifier{walltime: }{[="00:01:00"] Torque walltime for global & group
%                     jobfile}
%\qualifier{wt_global: }{[=walltime] Torque walltime for global jobfile}
%\qualifier{wt_groups: }{[=walltime] Torque walltime for groups jobfile}
%\qualifier{jobname: }{[="simpi_fitpars"] Name of Torque job (& files!)}
%\qualifier{logpath: }{[=pwd+jobname] Directory for log files}
%\qualifier{force: }{overwrites an existing jobfile or script
%                  (default: don't overwrite)}
%\qualifier{writescript: }{ writes a template for the script into
%                  the given filename (file will be overwritten)}
%}
%\description
%    Writes a Torque 'jobfile' to calculate the confidence
%    levels of all parameters. Therefore, the filename of
%    the script for loading the data, defining the model
%    and running simultaneous_fit.fit_pars is mandatory.
%    This script will be called by each job with a
%    command line arguments, which represents the data
%    group, for which the confidence levels should be
%    calculated for. The command line arguments can be
%    accessed using '__argv' and '__argc'.
%
%    In case the 'scriptfile' requires additional command
%    line arguments add them to the 'scriptfile'-string,e.g.,
%    like "scriptfile.sl arg1 arg2", and make sure these
%    are asigned correctly!
%    
%    If the qualifier 'writescript' exists, a template for
%    the script described above will be written into the
%    given 'scriptfile'name. This has to be modified
%    afterwards to ensure compatibility and should be
%    treated as a support!
%    Warning: in case of an already existing filename this
%             file will be overwritten!
%\seealso{simultaneous_fit.fit_pars}
%!%-
{
  variable s, jobfile, scriptfile;
  switch (_NARGS)
  { case 3: (s,jobfile,scriptfile) = (); }
  { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;
  
  % QUALIFIER JOBFILES
  variable walltime = qualifier("walltime","00:01:00");
  variable wt_global= qualifier("wt_global",walltime);
  variable wt_groups= qualifier("wt_groups",walltime);
  variable jobname  = qualifier("jobname","simpi_fitpars");
  variable logpath  = qualifier("logpath",jobname);
  
  % Check TYPE
  if (typeof(jobfile) != String_Type){ vmessage("error (%s): given jobfile has to be a string", _function_name); return; }
  if (typeof(scriptfile) != String_Type){ vmessage("error (%s): given scriptfile has to be a string", _function_name); return; }

  variable N = length(s.model.group), g;
  variable iformat = "_%04d";
  
  % Jobfiles
  variable jobfile_ext   = path_extname(jobfile);
  if( jobfile_ext == "" ) { jobfile_ext = ".job"; }
  variable jobfiles = array_map(String_Type,&sprintf,path_sans_extname(jobfile)+iformat+jobfile_ext,[0:N]);

  % Scriptfiles with arguments
  variable script = strtok(scriptfile)[0];
  variable nargs  = length(strtok(scriptfile)[[1:]]);
  
  % Check files
  _for g ( 0, N, 1 ){
    if (access(jobfiles[g], F_OK) == 0 && qualifier_exists("force") == 0)
    { vmessage("error (%s): jobfile '%s' already exists", _function_name, jobfiles[g]); return; }

  }
  if ( not(qualifier_exists("writescript")) && access(script, F_OK) == -1 )
  { vmessage("error (%s): scriptfile '%s' does not exists", _function_name, script); return; }
  if (qualifier_exists("writescript") && access(script, F_OK) == 0 && qualifier_exists("force") == 0)
  { vmessage("error (%s): scriptfile '%s' already exists", _function_name, script); return; }
  
  % get current user
  variable user, pp = popen("whoami", "r");
  ()=fgets(&user, pp);
  ()=pclose(pp);
  user = strreplace(user, "\n", "");

  % get current directory
  variable pwd = getcwd[[:-2]];
  
  % CHECK LOGPATH
  if( is_substr( logpath,pwd ) == 0 )
    logpath = pwd+"/"+logpath;
  if( logpath[-1] == '/' )
    logpath = logpath[[:-2]];
  ()=mkdir(logpath);
  
  % build jobfiles
  variable job;
  variable nodes,index;

  % loop over each data group
  _for g (0, N, 1) {
    
    % finde & test number of nodes[=#freeParameters in each group] (MUST be the same)
    nodes = s.model.stat[g].num_variable_params;

    index = sprintf(iformat,g);
    
    job = "#!/bin/bash\n#\n";
    job += "#PBS -S /bin/bash -V\n";
    job += sprintf("#PBS -l nodes=%d\n",nodes);
    %job += "#PBS -l arch=x86_64\n";
    job += sprintf("#PBS -l walltime=%s\n", g==0? wt_global : wt_groups );
    job += sprintf("#PBS -N %s%s\n",jobname,index);
    job += sprintf("#PBS -o %s/%s%s.out\n", logpath, jobname, index);
    job += sprintf("#PBS -e %s/%s%s.err\n", logpath, jobname, index);
    job += sprintf("\ncd %s\n", pwd);

    % add group parameter to job file
    job += sprintf("COMMAND=\"mpiexec isis-script %s --grp=%d\"\n", scriptfile, g);
    job += "/usr/bin/nice -n +15 ${COMMAND}";
    
    % write GROUP jobfile
    variable fp = fopen( sprintf("%s",jobfiles[g]), "w+");
    ()=fputs(job, fp);
    ()=fclose(fp);
  }

  % QUALIFIER SCRIPTFILE
  variable parpath = qualifier("parpath",logpath);
  % CHECK PARPATH
  if( is_substr( parpath,pwd ) == 0 )
    parpath = pwd+"/"+parpath;
  if( parpath[-1] == '/' )
    parpath = parpath[[:-2]];
  ()=mkdir(parpath);
  
  % eventually, write script template
  variable wscrpt;
  if (qualifier_exists("writescript")) {
    wscrpt  = "require(\"isisscripts\");\n";
    wscrpt += "% TIME LOG\n";
    wscrpt += "tic;vmessage(\"%s : Calling: '%s'\",time,strjoin(__argv,\" \"));\n\n";
    
    wscrpt += "%%% initialize the simultaneous fit, adding the %%%\n";
    wscrpt += "%%% data and defining/loading the model here    %%%\n\n";
    
    wscrpt += "% get command line arguments (last argument has to be the group index!)\n";
    wscrpt += "variable grp = atoi(get_arg_struct().grp);\n";

    wscrpt += "\n%%% set the directory for the output fits-files here %%%\n";
    wscrpt += "%%% make sure that this directory exists!            %%%\n";
    wscrpt += sprintf("variable parpath = \"%s\";\n",parpath);
    wscrpt += "% check on existence of parpath\n";
    wscrpt += "if (access(parpath, F_OK) != 0) {\n";
    wscrpt += "  vmessage(\"error: directory %s does not exist, aborting...\", parpath);\nexit;\n}\n";

    wscrpt += "\n% calculate uncertainties\n";
    wscrpt += "%%% replace 'simfit' by the name of your simultaneous-fit-structure %%%\n";
    wscrpt += "variable fpars = simfit.mpi_fit_pars( grp ; dir=parpath,";
    wscrpt += "basefilename = sprintf(\""+jobname+iformat+".fits\", grp));\n";

    wscrpt += "\n% TIME LOG\n";
    wscrpt += "variable elaptime = toc;\n";
    wscrpt += "vmessage(\"%s : Finished '%s' after %d s < %d %s\",\n";
    wscrpt += "time,strjoin(__argv,\" \"),nint(elaptime),time_array(elaptime)[-1]+1,\n";
    wscrpt += "[\"sec\",\"min\",\"h\",\"d\",\"y\"][length(time_array(elaptime))-1]  );";
    
    
    % write scriptfile
    fp = fopen(script, "w+");
    ()=fputs(wscrpt, fp);
    ()=fclose(fp);
  }
} %}}}
#endif

private define simultaneous_fit_fit_pars_collect() %{{{
%!%+    
%\function{simultaneous_fit.fit_pars_collect}
%\synopsis{reads the results of a former fit_pars or mpi_fit_pars
%    and checks for a new best-fit}
%\usage{Struct_Type simultaneous_fit.fit_pars_collect(String_Type FITSpattern);}
%\qualifiers{
%    \qualifier{chitol}{how much a delta chi-square  has to be
%                     to actually consider this fit as a new
%                     best-fit or a worse-fit (default: 1e-10)}
%    \qualifier{setnewbestpars}{sets the parameters to those of a
%                     possible new best-fit (see below)}
%    \qualifier{bestpars}{reference to a variable where all found
%                     parameter values and other helpful
%                     information is returned}
%    \qualifier{parspriority}{in case parameters of a new best-fit
%                     are set, this qualifiers decides
%                     whether the changed "global"- or
%                     "group"-parameters are set (both are
%                     not possible!) (default: "global")}
%    \qualifier{PARpattern}{the string which replaces "_conf.fits"
%                     to match the parameter file
%                     (default: "_best.par")}
%    \qualifier{silent}{suppress warning messages (BIT wise)
%                     1: "fit ... is worse"
%                     2: "new best-fit ... found"
%                     4: "no uncertainties ... found"
%                     8: "setting new ... re-fit ..."}
%}
%\description
%    If the uncertainties of a simultaneous fit have been
%    calculated using Torque-jobfiles (e.g., by using the
%    mpi_fit_pars_jobfile function), the results will be
%    saved in several FITS-files.
%    This function reads all FITS-files matching the given
%    'FITSpattern' and returns a single structure containing
%    all results (similar to a single fit_pars structure).
%    Furthermore, if a new best-fit was found during one
%    of the calculations, a warning message will be shown.
%    In case of a crashed calculation (resulting in missing
%    uncertainties) a warning message will be shown as well.
%
%    If the qualifier "setnewbestpars" is set, the parameters
%    of a new best-fit will be set automatically. However,
%    new global parameters causes the group parameters to be
%    fitted again and vise versa. For this reason, new group
%    parameters are discarded in favor for new global ones
%    (to change this priority use the 'parspriority'
%    qualifier).
%
%    Note, that the par-files saved by fit_pars are needed to
%    set the remaining parameters in case of a new best-fit!
%\seealso{simultaneous_fit.mpi_fit_pars_jobfile, simultaneous_fit.fit_pars_jobfile}
%!%-
{
  variable s, pattern;
  switch (_NARGS)
    { case 2: (s,pattern) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  variable silent = qualifier("silent", 0);
  variable chitol = qualifier("chitol", 1e-10);
  % find all FITS-files
  variable files = glob(pattern);
  files = files[ array_sort(files) ];
  if (length(files) == 0) { vmessage("error (%s): did not find any FITS-file", _function_name); return NULL; }

  % loop over all files
  variable file, result = NULL;
  variable newbest = struct { group = Integer_Type[0], file = String_Type[0], params = Struct_Type[0], deltachi = Double_Type[0], missing = Struct_Type[0], statistic = Double_Type[0], isbetter = Integer_Type[0] };
  foreach file (files) {
    % load FITS-file
    variable fits = fits_read_table(file);
    % merge with results
    result = result == NULL ? fits : merge_struct_arrays([result, fits]);
    % check if FITS-file contains global parameters
    variable par, grp = 1;
    foreach par (fits.name) { if (grp && sum(array_map(Integer_Type, &is_substr, s.model.global, par)) > 0) { grp = 0; } }
    % if no global parameters are found, find the corresponding data group
    if (grp) {
      grp = Integer_Type[length(fits.name)];
      % loop over each parameter in FITS-file and find the corresponding group (black one-line magic)
      _for par (0, length(fits.name)-1) {
	grp[par] = wherefirst(array_map(Double_Type, &sum, array_map(Array_Type, &is_substr, s.model.group, fits.name[par])) == 1) + 1;
      }
      grp = int(array_unique(grp));
      % something weird happened if parameter is found in multiple groups...
      if (length(grp) != 1) {
        vmessage("error (%s): FITS-file %s contains parameters of several: groups %s", _function_name, file, strjoin(array_map(String_Type, &sprintf, "%d", grp), ","));
        return NULL;
      }
      grp = grp[0];
    }
    % compare chi-square values of that group (0 = global paramater)
    variable deltachi = fits_read_key(file, "chi2") - s.model.stat[grp].statistic;
    if (deltachi > chitol) {
      ifnot (silent & 1) {
	vmessage("warning (%s): fit during fit_pars of group %d is worse (delta chisqr = %.2f)", _function_name, grp, deltachi);
      }
    }
    else if (deltachi < -chitol) { % new best-fit found
      ifnot (silent & 2) {
	vmessage("warning (%s): new best-fit of %s found (delta chisqr = %.2f)", _function_name, grp == 0 ? "a global parameter" : sprintf("datagroup %d", grp), deltachi);
      }
    }
    % load parameters of the fit
    variable parfile = strreplace(file, "_conf.fits", qualifier("PARpattern", "_best.par"));
    if (access(parfile, F_OK) == 0) {
      variable newpars = NULL;
      try { 
        newpars = ascii_read_table(parfile, [{"%d","idx"},{"%s","name"},{"%d","tieto"},{"%d", "freeze"},{"%f","value"}]; startline = 3);
      }
      catch AnyError: {
        vmessage("warning (%s): could not parse parameter file %s, cannot set new best-fit parameters!", _function_name, parfile);
      }
      if (newpars != NULL) {
        % remember best-fit
        newbest = merge_struct_arrays([newbest, struct {
          group = grp, file = file, params = newpars, deltachi = deltachi, missing = NULL, statistic = 0, isbetter = int(deltachi < -chitol)
        }]);
        % load statistics of best-fit
        variable txtfile = strreplace(file, "_conf.fits", qualifier("TXTpattern", "_conf.txt"));
        % remember new statistics
        newbest.statistic[-1] = fits_read_key(file, "chi2");
      }
    } else { vmessage("warning (%s): parameter file %s not found, cannot set new best-fit parameters!", _function_name, parfile); }
  }

  % check on missing parameters
  foreach par ([array_flatten(s.model.group), s.model.global]) {
    newbest.missing = String_Type[0];
    if (get_par_info(par).freeze == 0 and wherefirst(result.name == par) == NULL) {
      ifnot (silent & 4) { vmessage("warning (%s): no uncertainties of parameter %s found!", _function_name, par); }
      newbest.missing = [newbest.missing, par];
    }
  }
  % eventually return info structure
  if (qualifier_exists("bestpars")) {
    @(qualifier("bestpars")) = newbest;
  }

  % eventually set new best parameters
  variable newbesti = where(newbest.isbetter); % better groups
  if (qualifier_exists("setnewbestpars") && length(newbesti) > 0) {
    variable isgl = wherefirst(newbest.group[newbesti] == 0); % better globals found?
    variable prio = qualifier("parspriority", "global") == "global";
    % set global parameters or...
    if (isgl != NULL && prio == 1) {
      isgl = newbesti[isgl];
      ifnot (silent & 8) { message("setting new GLOBAL parameters, please re-fit the groups"); }
      _for par (0, length(newbest.params[isgl].idx)-1) {
	if (newbest.params[isgl].freeze[par] == 0) {
	  set_par(newbest.params[isgl].name[par], newbest.params[isgl].value[par]);
	}
      }
      if (newbest.statistic[isgl] > 0) {
        s.model.stat[0].statistic = newbest.statistic[isgl];
      }
    }
    % ..set group parameters instead
    else {
      ifnot (silent & 8) { message("setting new GROUP parameters, you might re-fit the globals"); }
      foreach grp (newbesti) {
	if (newbest.group[grp] != 0) {
          _for par (0, length(newbest.params[grp].idx)-1) {
            if (newbest.params[grp].freeze[par] == 0) {
              set_par(newbest.params[grp].name[par], newbest.params[grp].value[par]);
	    }
          }
          if (newbest.statistic[grp] > 0) {
            s.model.stat[newbest.group[grp]].statistic = newbest.statistic[grp];
	  }
	}
      }
    }
  }
  
  return result;
} %}}}

private define simultaneous_fit_fit_pars_run_job() %{{{
%!%+    
%\function{simultaneous_fit.fit_pars_run_job}
%\synopsis{submits the (MPI-)fit_pars-jobfiles until no better fit is found}
%\usage{Struct_Type simultaneous_fit.fit_pars_run_job(
%                  String_Type or String_Type[] globaljobs, groupjobs,
%                  String_Type FITSpattern, String_Type or Ref_Type save
%                );}
%\qualifiers{
%    \qualifier{first}{submits either the jobs for the global- (=0)
%              or the group-parameters (=1, default) first}
%    \qualifier{maxiter}{maximum number of iterations (default: 3)}
%    \qualifier{wait}{seconds to wait before it is checked if the
%              Torque-jobs have completed (default: 10)}
%}
%\description
%    Usually, the uncertainties of the group- and global-
%    parameters should be calculated using Torque-jobs.
%    However, if one job finds a new best-fit of a, e.g.,
%    group parameter, the uncertainties of the global
%    parameters have to be re-calculated (and vise versa).
%    Note, that the calculations of remaining groups in
%    that case, which might still be running, don't have
%    to be canceled, because the global parameters might
%    stay the same even a better group parameter is found!
%
%    This function submits the Torque-jobs for different
%    kinds of parmeters (given as filename-patterns or the
%    filename(s) for the 'globaljobs' and 'groupjobs')
%    until no further best-fit has been found. By default,
%    the group jobs are submitted first. If a new best-fit
%    was found, the internal .save function is called with
%    the given 'save'-filenam to ensure that the current
%    (better) parameters can be loaded by the  re-submitted
%    jobs. If the 'save'-parameter is a reference to a
%    function, this one will be called instead of saving
%    the fit automatically. This function does not get any
%    parameters and should save parameter AND the model
%    field of the simultaneous fit.
%    Once no better fit is found a structure similar to
%    that of fit_pars is returned.
%
%    As a protection for an (infinite) loop, the above
%    procedure is repeated only a few times (adjustable
%    using the 'maxiter' qualifier).
%
%    IMPORTANT:
%    This function is only a control function! It has to
%    know the current parameters and dataset logic, but
%    does not require any CPU power! Thus, to free memory,
%    the complete loaded DATA, ARFs, and RMFs are DELETED!
%    So you CANNOT work with your data afterwards! If you
%    agree with that procedure please set the 'agree'-
%    qualifier. Otherwise, the function will exit.
%\seealso{simultaneous_fit.fit_pars_jobfile}
%!%-
{
  variable s, glbjob, grpjob, pattern, savefun;
  switch (_NARGS)
  { case 5: (s,glbjob,grpjob,pattern,savefun) = (); }
  { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % user has to agree on deleting all data
  ifnot (qualifier_exists("agree")) { vmessage("error (%s): read the help first", _function_name); return; }
  ifnot (typeof(savefun) == String_Type || typeof(savefun) == Ref_Type) {
    vmessage("error (%s): 'save' has to be a filename or a reference to a function", _function_name); return;
  }
  % replace all data by dummies to save memory, since this ISIS
  % instance should just be a control job, so no resources needed
  variable adata = @all_data, ad;
  delete_data(all_data);
  foreach ad ([1:max(adata)]) { ()=define_counts(1, 2, 3, 4); }
  delete_data(complement(all_data, adata)+1);
  delete_arf(all_arfs);
  delete_rmf(all_rmfs);

  variable maxiter = qualifier("maxiter", 3);
  
  % find all job-files
  variable jobs = {
    typeof(glbjob) != Array_Type ? glob(glbjob) : glbjob,
    typeof(grpjob) != Array_Type ? glob(grpjob) : grpjob
  };
  if (length(jobs[0]) == 0) { vmessage("error (%s): no global jobfiles found!", _function_name); return; }
  if (length(jobs[1]) == 0) { vmessage("error (%s): no group jobfiles found!", _function_name); return; }
  vmessage("found %d global- and %d group-jobfiles", length(jobs[0]), length(jobs[1]));

  % check on empty working directory
  variable workdir = path_dirname(pattern);
  if (length(glob(workdir + "/*")) > 0) { vmessage("error (%s): working directory not empty!", _function_name); return; }

  % run-order (0 = globals, 1 = groups)
  variable runord = qualifier("first", 1);
  
  % run-loop
  variable best = 1, jobids, pp, i, j, tmp, nloop = 0;
  do {
    jobids = Array_Type[2];
    % submit the jobs
    _for i (0,1) { % handle globals and groups the same way
      jobids[i] = Integer_Type[0];
      % submit the jobs?
      if (runord == i) {
	% loop over jobfiles of that kind
	_for j (0, length(jobs[i])-1) {
	  % submit the job and get its ID
          pp = popen(sprintf("qsub %s", jobs[i][j]), "r");
	  tmp = strjoin(fgetslines(pp));
	  ()=pclose(pp);
	  tmp = string_matches(tmp, "^\([0-9]*\)\[?\]?\."R);
	  % submit successful?
	  if (length(tmp) != 2) { vmessage("error (%s): got no job-ID after submitting %s\nis Torque running?", _function_name, jobs[i][j]); return; }
	  jobids[i] = [jobids[i], atoi(tmp[1])];
        }
	vmessage("submitted %d %s-jobs (IDs: %s)", length(jobids[i]), i == 0 ? "global" : "group", strjoin(array_map(String_Type, &sprintf, "%d", jobids[i]), ","));
      }
    }
    jobids = array_flatten(jobids);
    j = ones(length(jobids));

    % wait for the jobs to finish
    do {
      sleep(qualifier("wait", 10));
      pp = popen("qstat", "r");
      tmp = fgetslines(pp);
      ()=pclose(pp);
      % (too?) simple checks if command was successful
      if (length(tmp) < 3) { vmessage("error (%s): list of Torque jobs is empty (even completed ones)!", _function_name); return; }
      if (is_substr(tmp[0], "Job id") == 0) { vmessage("error (%s): couldn't get Torque status! Is Torque running?", _function_name); return; }
      % check output of qstat on substrings containing the job IDs     
      _for i (0,length(jobids)-1) {
	if (j[i]) { % only check if job is believed to be still running
	  % find output line where the current job is listed and check if it status isn't "R"
	  pp = [array_map(Void_Type, &string_matches, tmp, sprintf("^%d\[?\]?\."R, jobids[i]))];
	  pp = wherefirst(strlen(pp) > 0); % index where the job is listed
	  if (pp == NULL) { vmessage("error (%s): could not get status of job %d", _function_name, jobids[i]); return; }
          if (is_substr(tmp[pp], " C ")) {
	    j[i] = 0;
	    vmessage("job %d completed, %d of %d jobs left", jobids[i], int(sum(j)), length(jobids));
	  }
	}
      }
    } while(sum(j) > 0);
    
    % all jobs completed, collect results now
    vmessage("collecting results");
    variable results, info;
    results = s.fit_pars_collect(pattern;; struct_combine(struct { bestpars = &info, setnewbestpars, silent = 1+4+8 }, __qualifiers));
	    if (results == NULL) { vmessage("error (%s): collecting results failed", _function_name); return; }
    % check on new best-fit
    if (wherefirst(info.isbetter) == NULL) {
      best = 0;
      % save parameters of new best-fit
      vmessage("saving fit-parameters");
      switch (typeof(savefun))
        { case String_Type: s.save(savefun); }
        { case Ref_Type: (@savefun)(); }
    } else { best = 1; }
    % move all files created by fit_pars 
    vmessage(sprintf("moving files into loop%03d subfolder", nloop/2));
    if (access(sprintf("%s/loop%03d", workdir, nloop/2), F_OK) != 0) {
      ()=system(sprintf("mkdir %s/loop%03d", workdir, nloop/2));
    }
    ()=system(sprintf("mv %s/*.* %s/loop%03d/", workdir, workdir, nloop/2));
    % fit the other parameter type next time
    runord = not runord;
    nloop++;
  } while ((best == 0 || nloop mod 2 == 1) && nloop < maxiter*2); % nloop == 1: make sure that groups- and global are fit_parsed
  if (best == 1) { vmessage("no new best-fit found"); }
  else { vmessage("maximum number of iterations reached"); }
  % collect results of last loop
  % but for that we need to copy the files of a previous loop in order to
  % get missing parameter types (imagine loop0: best-fit in groups, best-fit
  % in globals, loop1: no best-fit in groups -> results of the globals are
  % missing in loop1 subfolder)
  nloop--;
  if (nloop > 1) { % copy result from last loop here (don't overwrite existing files!)
    ()=system(sprintf("cp -n %s/loop%03d/*.* %s/loop%03d/", workdir, nloop/2-1, workdir, nloop/2));
  }
  % collect the (merged) results
  results = s.fit_pars_collect(sprintf("%s/loop%03d/%s", workdir, nloop/2, path_basename(pattern)); silent = 1);
  if (length(info.missing) > 0) {
    vmessage("warning: uncertainties of some parameters are missing!");
     message("         please collect manually and check the results!");
  }
  if (length(info.group) > 0 && best == 1) {
    vmessage("warning: last loop still results in a better fit!");
     message("         please collect manually and check the results!");
     message("         something strange happened...");
  }
  return results;
}
%}}}

private define simultaneous_fit_load() %{{{
%!%+    
%\function{simultaneous_fit.load}
%\synopsis{loads a simultaneous fit from a FITS-table}
%\usage{simultaneous_fit.load(String_Type filename);}
%\description
%    Uses 'fits_load_fit' to first restore the fit and then
%    to load the model-field of the simultaneous fit from
%    the FITS-table. Because the data associations don't
%    have to be analyzed, any additional use of
%    'simultaenous_fit.add_data' before loading the fit (if
%    the data is defined by, e.g, 'define_counts') should
%    be called with the 'nosort' qualifier to save the time
%    needed to create the model-field.
%
%    The function recognizes if the simfit was saved with
%    the 'alt'-qualifier of  simultaneous_fit.save. In this
%    case 'fits_load_fit' is not used.
%
%    All qualifiers are passed to fits_load_fit.
%
%\example
%    % initialize a new simultaneous_fit
%    simfit = simultaneous_fit();
%    % define the data
%    simfit.add_data({
%      [define_counts(...), ...],
%      ...
%    }; nosort);
%    % restore the fit (parameters and model-field)
%    % from a file previously created by simfit.save
%    simfit.load("best-fit.fits"; nodata);
%\seealso{simultaneous_fit.save, simultaneous_fit, fits_load_fit}
%!%-
{
  variable s, filename;
  switch (_NARGS)
    { case 2: (s,filename) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  % load the fit first
  variable fit, tmp;
  if (fits_read_key(filename + "[0]", "alt") == NULL) {
    ()=fits_load_fit(filename;; struct_combine(__qualifiers, struct { strct = &fit }));
  } else { % simfit was saved in an alternative way
    fit = fits_load_fit_struct(filename);
    fit_fun(fits_read_key(filename + "[save_par]", "fit_fun"));
    variable j, i = where(fit.tie != " ", &j);
    array_map(Void_Type, &tie, fit.tie[i], fit.name[i]);
    array_map(Void_Type, &untie, fit.name[j]);
    i = where(fit.fun != " ", &j);
    array_map(Void_Type, &set_par_fun, fit.name[i], fit.fun[i]);
    array_map(Void_Type, &set_par_fun, fit.name[j], NULL);
    array_map(Void_Type, &set_par, get_struct_fields(fit,
      "name", "value", "freeze", "min", "max"
    ));
  }
  if (qualifier_exists("strct")) {
    tmp = qualifier("strct");
    @tmp = fit;
  }

  %%% restore simultaneous fit informations
  % data indices and fit-function
  s.data = list_new;
  array_map(Void_Type, &list_append, s.data, array_map(
    Array_Type, &atoi, array_map(Array_Type, &strchop, strchop(fit.simfit_data[0], ';', 0), ',', 0)
  ));
  s.model.fit_fun = fit.simfit_fit_fun[0];
  % global and group parameters and to what they are tied
  s.model.global = String_Type[0];
  s.model.group = Array_Type[length(s.data)];
  s.model.tieto = Array_Type[length(s.data)];
  _for tmp (0, length(s.data)-1, 1) {
    s.model.group[tmp] = String_Type[0];
    s.model.tieto[tmp] = String_Type[0];
  }
  variable par, grp;
  foreach par (get_params) {
    tmp = "simfit_" + fits_conv_to_legal_char(par.name) + "_group";
    if (struct_field_exists(fit, tmp)) {
      grp = get_struct_field(fit, tmp)[0];
      % global parameter (grp == 0 AND grp < 0, i.e. associated, but global)
      if (grp <= 0) {
	s.model.global = [s.model.global, par.name];
      }
      % group parameter (also applicable to a global one)
      grp = abs(grp);
      if (grp > 0) {
	grp--;
        s.model.group[grp] = [s.model.group[grp], par.name];
        tmp = "simfit_" + fits_conv_to_legal_char(par.name) + "_tieto";
  	if (struct_field_exists(fit, tmp)) {
	  tmp = get_struct_field(fit, tmp)[0];
	  s.model.tieto[grp] = [s.model.tieto[grp], tmp == " " ? NULL : tmp];
	} else {
          vmessage("warning (%s): did not find tie-to field of parameter %s", _function_name, par.name);
	}
      }
    } else {
      vmessage("warning (%s): did not find a group association of parameter %s", _function_name, par.name);
    }
  }
  % statistic
  s.model.stat = Struct_Type[length(s.data)+1];
  tmp = fit.simfit_statistic;
  _for grp (0, length(s.model.stat)-1, 1) {
    s.model.stat[grp] = struct {
      statistic = fit.simfit_statistic[0,grp],
      num_variable_params = fit.simfit_num_variable_params[0,grp],
      num_bins = fit.simfit_num_bins[0,grp]
    };
  }
  _simultaneous_fit_comb_chi_sqr(s; recalc);
  % instances
  s.model.instances = Assoc_Type[Array_Type];
  foreach tmp (strchop(fit.simfit_instances[0], ';', 0)) {
    grp = strchop(tmp, '=', 0);
    s.model.instances[grp[0]] = strchop(grp[1], ',', 0);
  }

  % tieto-history
  s.model.tieto_history = list_new;
  if (struct_field_exists(fit, "simfit_tieto_history")) {
    if (fit.simfit_tieto_history[0] != " ") {
      foreach grp (array_map(Array_Type, &strchop, strchop(fit.simfit_tieto_history[0], ';', 0), ',', 0)) {
	if (length(grp) == 2) {
          list_append(s.model.tieto_history, { grp[0], grp[1] });
	} else {
	  % there seems to be a bug in saveing the history
	  message("warning: error in saved set_par_fun-history, could not restore history completely");
	}
      }
    }
  } else { message("warning: could not find a set_par_fun-history"); }
} %}}}

private define simultaneous_fit_load_model() %{{{
%!%+
%\function{simultaneous_fit.load_model}
%\description
%    DEPRECATED, use simultaneous_fit.load
%\seealso{simultaneous_fit.load}
%!%-
{
  variable s, filename;
  switch (_NARGS)
    { case 2: (s,filename) = (); }
    { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  message("*** DEPRECATED, use simultaneous_fit.load ***");
  ifnot (qualifier_exists("go")) { throw RunTimeError, "***  to continue set the 'go' qualifier   ***"; }

  (s.model,) = evalfile(filename,current_namespace);
  % check on Null_Type of 'stat' field
  ifnot (struct_field_exists(s.model, "stat")) { s.model = struct_combine(s.model, struct { stat = NULL }); }
  if (_typeof(s.model.stat) == Null_Type) { s.model.stat = Struct_Type[length(s.model.group)+1]; }
} %}}}

private define simultaneous_fit_save() %{{{
%!%+    
%\function{simultaneous_fit.save}
%\synopsis{saves the simultaneous fit to a FITS-table}
%\usage{simultaneous_fit.save_model(String_Type filename[, Struct/String_Type conf]);}
%\qualifiers{
%    \qualifier{alt}{use an alternative to 'fits_save_fit', see text;
%  all other qualifiers are passed to 'fits_save_fit'}
% }
%\description
%    Uses 'fits_save_fit' to save the simultaneous fit and,
%    most importantly, its model-field. The creation of this
%    field may take some time due to the fact that the fit-
%    function as well as the data associations have to be
%    analyzed. Thus, saving it to a FITS-table speeds up
%    the loading process if 'simultaneous_fit.load' is used.
%
%    However, the large number of parameters of a simfit
%    can lead to "out of memory" exception when using
%    'fits_save_fit'. In this case, the 'alt'-qualifier
%    uses an alternative FITS-structure for saving, i.e.,
%    'fits_save_fit' is not used. Note that in this case
%    only the parameters (like in 'save_par') are saved,
%    but _not_ the loaded data, noticed energy bins, etc.
%\seealso{simultaneous_fit.load, fits_save_fit}
%!%-
{
  variable s, args;
  if (2<= _NARGS <=3) {
    args = __pop_args(_NARGS-1);
    s = ();
  } else { _simultaneous_fit_help(_NARGS, _function_name); return; }
  if (_simultaneous_fit_help(0, _function_name ;; __qualifiers)) return;

  %%% build model structure to be appended to the FITS-table
  variable info = struct {
    simfit_fit_fun = [s.model.fit_fun],
    % convert the .data list of integer-arrays as a string like "1,2;3,4,5;..."
    simfit_data = [strjoin(array_map( % loop over groups
      String_Type, &strjoin, array_map(  % loop over dataset within group
        Array_Type, &array_map,
	  String_Type, &sprintf, "%d", list_to_array(s.data)
      ), ","),
    ";")]
  };
  % global parameters
  variable par;
  foreach par (s.model.global) {
    info = create_struct_field(info, "simfit_" + fits_conv_to_legal_char(par) + "_group", [0]);
  }
  % group parameters and to what they are tied
  variable grp;
  _for grp (0, length(s.model.group)-1, 1) {
    _for par (0, length(s.model.group[grp])-1, 1) {
      variable tmp = "simfit_" + fits_conv_to_legal_char(s.model.group[grp][par]) + "_group";
      % if field does not exist yet -> group parameter
      % else -> global parameter, save group association, but with a negative sign
      ifnot (struct_field_exists(info, tmp)) {
        info = create_struct_field(info, tmp, [grp+1]);
      } else {
	set_struct_field(info, tmp, -[grp+1]);
      }
      info = create_struct_field(info, "simfit_" + fits_conv_to_legal_char(s.model.group[grp][par]) + "_tieto", [s.model.tieto[grp][par] == NULL ? "" : s.model.tieto[grp][par]]);
    }
  }
  % statistic
  par = merge_struct_arrays(s.model.stat);
  info = struct_combine(info, ["simfit_statistic", "simfit_num_variable_params", "simfit_num_bins"]);
  grp = length(par.statistic);
  info.simfit_statistic = _reshape(par.statistic, [1,grp]);
  info.simfit_num_variable_params = _reshape(par.num_variable_params, [1,grp]);
  info.simfit_num_bins = _reshape(par.num_bins, [1,grp]);
  % instances
  grp = String_Type[0];
  foreach par (assoc_get_keys(s.model.instances)) {
    grp = [grp, sprintf("%s=%s", par, strjoin(s.model.instances[par], ","))];
  }
  info = create_struct_field(info, "simfit_instances", [strjoin(grp, ";")]);
  % tieto-history
  % There seems to be a bug here where the first array_map returns
  % a string array with one element only (no "tie-to"-parameter seems
  % to be present), i.e. the string contains "...;global;..." instead
  % of "...;global,tieto;..." -> workaround in the load-function
  info = create_struct_field(info, "simfit_tieto_history",
    length(s.model.tieto_history) == 0 ? [""] : [strjoin(
      array_map(String_Type, &strjoin, array_map(
        Array_Type, &list_to_array, list_to_array(s.model.tieto_history)
      ), ","), ";"
    )]
  );
  
  % eventually add a given info structure
  if (qualifier_exists("info")) {
    info = struct_combine(qualifier("info"), info);
  }

  % save the fit
  ifnot (qualifier_exists("alt")) {
    fits_save_fit(__push_args(args);; struct_combine(__qualifiers, struct { info = info }));
  } else {
    fits_save_fit_write(args[0].value, info);
    % save all parameters into the same file
    % merge_struct_arrays will not work here because NULL field-values
    % are skipped, which is the case for .tie and .fun in many cases
    variable pars = get_params();
    pars = struct {
      name = array_map(String_Type, &get_struct_field, pars, "name"),
      index = array_map(Integer_Type, &get_struct_field, pars, "index"),
      value = array_map(Double_Type, &get_struct_field, pars, "value"),
      min = array_map(Double_Type, &get_struct_field, pars, "min"),
      max = array_map(Double_Type, &get_struct_field, pars, "max"),
      freeze = array_map(Integer_Type, &get_struct_field, pars, "freeze"),
      tie = array_map(String_Type, &get_struct_field, pars, "tie"),
      fun = array_map(String_Type, &get_struct_field, pars, "fun")
    };
    pars.tie[where(_isnull(pars.tie))] = "";
    pars.fun[where(_isnull(pars.fun))] = "";
    variable fp = fits_open_file(args[0].value, "w");
    fits_update_key(fp, "alt", 1, "alternative format");
    fits_write_binary_table(fp, "save_par", pars, struct { fit_fun = get_fit_fun });
    if (length(args) > 1) { fits_write_binary_table(fp, "fit_pars", args[1].value); }
    fits_close_file(fp);
  }
} %}}}

%%%%%%%%%%%%%%%%%%%%%
define simultaneous_fit()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+    
%\function{simultaneous_fit}
%\synopsis{initializes a structure to handle simultaneous/combined
%    fits of a lot of data}
%\usage{Struct_Type simultaneous_fit();}
%\description
%    The advantage of fitting a lot of data at the same is
%    that fit parameters, which seem to be the same for all
%    data, can be fitted properly. That results in a reduced
%    number of free parameters for individual observations
%    or data groups, and thus constrains parameters even
%    better at low data quality.
%
%    The disadvantages are, that a) a lot of painful work
%    has to be done on tieing and freezing parameters and
%    b) a fit using 'fit_counts' will take hours to days.
%    There are several functions implemented within the
%    returned structure, which can help to solve that issues.
%
%    To access the help of a function, simply call it with
%    the 'help' qualifier (like for the xfig functions).
%
%    References for simultaneous fits in ISIS are
%      Kuehnel et al. 2015, Acta Polytechnica 55(2), 123­127
%      Kuehnel et al. 2016, Acta Polytechnica 56(1), 41­46
%    
%    NOTE: The simultaneous fits are still in development.
%!%-
{
  if (_NARGS > 0) { help(_function_name); return; }

  message("NOTE: a new version of the add_data-function has been implemented.");
  message("      You may set the \"old\"-qualifier to fall back to the old");
  message("      function for compatibility reasons.");
  
  return struct {
    add_data = qualifier_exists("old") ? &simultaneous_fit_add_data_old : &simultaneous_fit_add_data,
    delete_data = &simultaneous_fit_delete_data,
    sort_params = &simultaneous_fit_sort_params,
    apply_logic = &simultaneous_fit_apply_logic,
    fit_fun = &simultaneous_fit_fit_fun,
    get_par = &simultaneous_fit_get_par,
    set_par = &simultaneous_fit_set_par,
    freeze = &simultaneous_fit_freeze,
    thaw = &simultaneous_fit_thaw,
    copy_par = &simultaneous_fit_copy_par,
    set_par_fun = &simultaneous_fit_set_par_fun,
    set_par_fun_history = &simultaneous_fit_set_par_fun_history,
    set_global = &simultaneous_fit_set_global,
    unset_global = &simultaneous_fit_unset_global,
    list_data = &simultaneous_fit_list_data,
    list_global = &simultaneous_fit_list_global,
    list_groups = &simultaneous_fit_list_groups,
    plot_group = &simultaneous_fit_plot_group,
    group_stats = &simultaneous_fit_group_stats,
    filter_groups = &simultaneous_fit_filter_groups,
    select_groups = &simultaneous_fit_select_groups,
    eval_groups = &simultaneous_fit_eval_groups,
    eval_global = &simultaneous_fit_eval_global,
    fit_groups = &simultaneous_fit_fit_groups,
    fit_global = &simultaneous_fit_fit_global,
    fit_smart = &simultaneous_fit_fit_smart,
    fit_pars = &simultaneous_fit_fit_pars,
    steppar = &simultaneous_fit_steppar, 
#ifeval __get_reference("mpi_fit_pars")!=NULL
    mpi_fit_pars = &simultaneous_fit_mpi_fit_pars,
    mpi_fit_pars_jobfiles = &simultaneous_fit_mpi_fit_pars_jobfiles,
#endif
    fit_pars_collect = &simultaneous_fit_fit_pars_collect,
    fit_pars_run_job = &simultaneous_fit_fit_pars_run_job,
    load_model = &simultaneous_fit_load_model,
    load = &simultaneous_fit_load,
    save = &simultaneous_fit_save,
    setrestore = &simultaneous_fit_setrestore,
    restore = &simultaneous_fit_restore,
    model = struct {
      fit_fun = NULL,
      global = String_Type[0],
      group = Array_Type[0],
      stat = Struct_Type[0],
      cstat = struct {
	statistic = 0, num_group_params = 0, num_global_params = 0,
	num_bins = 0, combredchi = 0, weight_fun = NULL
      },
      tieto = Array_Type[0],
      tieto_history = list_new,
      instances = Assoc_Type[Array_Type], % key = component, value = instance string
      exclude = Integer_Type[0],
      params = Struct_Type[0],
      current_groups = -1
    },
    data = list_new
    % hack = struct {
    %   % move "internal" functions into this structure, like
    %   sort_params, apply_logic,
    %   set_weights % function to modify the weightening "mu" of the globals
    %   % functions for editing the group parameters?
    % }
  };
} %}}}
