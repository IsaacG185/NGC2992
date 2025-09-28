%<DEPRECATED>
%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_params_from_file()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_params_from_file}
%\synopsis{retrieves fit-parameter information from a file}
%\usage{Struct_Type params[] = get_params_from_file(String_Type params);}
%\seealso{load_par, get_params}
%!%-
{
  vmessage("*** Warning: Deprecated function, use 'read_par' instead");
  read_par();
#iffalse
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable fit_fun_before = get_fit_fun();
  variable params_before = get_params();

  load_par(filename);
  variable params = get_params();

  if(fit_fun_before != NULL)
  { fit_fun(fit_fun_before);
    set_params(params_before);
  }

  return params;
#endif
}
%</DEPRECATED>

% This must be in sync with the isis source, otherwise we can not
% read par files.

%%%%%%%%%%%%%%%
define read_par ()
%%%%%%%%%%%%%%%
%!%+
%\function{read_par}
%\synopsis{Read function parameter from file}
%\usage{Struct_Type[] params = read_par(filename[, funp]);}
%\description
%  This function process a parameter file according to the ISIS
%  file convention (safed, e.g., with save_par) and returns the
%  paramter settings as an array of structs. This array is
%  compatible to the array retireved by get_params and can
%  therefore be used with set_params.
%
%  If an additional parameter is given, it is expected to be a
%  pointer to a variable in which the function string gets stored.
%
%\seealso{get_params, set_params, save_par}
%!%-
{
  variable file, funp;
  switch (_NARGS)
  { case 1: file = (); funp = NULL; }
  { case 2: (file, funp) = (); }
  { help(_function_name()); return; }

  variable fp = fopen(file, "r");
  variable line, status, nvalues, line_num = 0;
  variable pars = {}, par;
  variable par_default = struct {
    name,
    index,
    value,
    min,
    max,
    freeze,
    tie,
    fun = NULL, % defaults to null
  };

  % skip first lines if they are comments (staring with '#')
  do {
    status = fgets(&line, fp);
    line_num++;
  } while ((status > 0) && (line[0] == '#'));

  if (status < 0)
    throw IOError, sprintf("Invalid parameter file: '%s'", file);

  % copy function string
  if (NULL != funp)
    @funp = strtrim(line);

  while (fgets(&line, fp) > 0) {
    line_num++;

    if (line[0] == '#') {
      if (line[[0:2]] == "#=>")
	par.fun = strtrim(line[[3:]]);
    } else {
      % everything else must be a parameter
      par = @(par_default);
      % this match is easier compared to isis internals
      nvalues = sscanf(line, "%u %s %d %d %le %le %le",
		       &(par.index),
		       &(par.name),
		       &(par.tie),
		       &(par.freeze),
		       &(par.value),
		       &(par.min),
		       &(par.max));
      if (nvalues == 0)
	continue;
      if (nvalues != 7)
	throw IOError, sprintf("Unable to parse %s:%d", file, line_num);
      list_append(pars, par);
    }
  }

  variable i;
  foreach par (pars) {
    if (par.tie != 0) {
      % not elegant, but do we expect to have thousands of parameters?
      _for i (0, length(pars)-1) {
	if (typeof(par.tie) != String_Type && pars[i].index == par.tie)
	  par.tie = pars[i].name;
      }

      if (String_Type != typeof(par.tie))
	par.tie = NULL;
    }
  }

  return list_to_array(pars);
}
