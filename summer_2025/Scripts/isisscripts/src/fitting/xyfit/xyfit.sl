% -*- mode: slang; mode: fold -*-

% Defining a xyfit function should now be much closer to the 'fit_fun'
% to define a fit function for a binned dataset. The general idea is
% to define one fit function which operate on the metadata of the dataset
% instead of the actual data. To increase the features the so defined function
% works on a stack that is builed up during the function call. Each stack
% element is therefore the result of a subfunction in the xyfit function.
% after all stack elements are calculated the complete function gets called
% but with the sub functions replaced by the individual stack elements.
% This has the benefit, that here we do not have to implement the slang
% interpreter again, but can just use it. The tradeoff is that we use
% memory to store the sub function results. Overall this should not be to bad
% as long as the number of sub functions times number of gridpoints is small.
%
% Be aware that this implementation may break older uses of the xyfit_fun.
% Simple function calls should not be affected, but the workaround with
%
% > xyfit_fun("foo(1)");
% > xyfit_fun("bar(2)");
% > fit_fun("foo(1) + bar(2)");
%
% does not work anymore. But now
%
% > xyfit_fun ("foo(1)+bar(2)");
%
% works as expected.

% input class definition
private variable NUMBER = 0x4;
private variable NUMBER_EXP = 0x1;
private variable NUMBER_DEC = 0x2;

private variable OPERAND = 0x8;
private variable FUNCTION = 0x2;
private variable FUNCTION_XY = 0x4;
private variable FUNCTION_OPEN = 0x1;

private variable _STK = Assoc_Type[List_Type];
private variable _PAR = Assoc_Type[Int_Type];
private variable _FCT = NULL;

private variable Fmt_Colheads, Fmt_Params;
Fmt_Colheads = " idx%-*stie-to  freeze         value         min         max";
Fmt_Params   = "%3u  %-*s  %2d    %2d   %14.7g  %10.7g  %10.7g  %s%s";

%%% helper functions %{{{
define __xy () {
  variable key, el;
  switch(_NARGS)
  { case 0: _STK = Assoc_Type[List_Type];}
  { case 1: key = ();
    if (typeof(key) != String_Type) {
      variable k = assoc_get_keys(_STK);
      if (length(k) != 0)
	return _STK[k[0]];
      else
	return NULL;
    }
    %if (assoc_key_exists(_STK, key))
    %  return _STK[key];
    return 0;
  }
  { case 2: (key, el) = ();
    if (typeof(el) == String_Type) {
      % string(eval()) because number might be a variable
      variable f = sprintf("%s(%s)", key, string(eval(el)));
      if (assoc_key_exists(_STK, f))
	return _STK[f];
      return 0;
    }
    _STK[key] = el;
    return 0;
  }
  { return 0;}
}

private define __f_access (s) {
  variable global_funs = _apropos("Global", s, 3);
  variable current_funs = _apropos(current_namespace, s, 3);
  return (length(global_funs)+length(current_funs)) ? 1 : 0;
}
%}}}

private define define_xyfun (fname, fnumb) { %{{{
  variable ffname = sprintf("%s_xy_fit", fname);
  if (__get_reference(ffname)==NULL) {
    eval(`
define ${ffname}(bin_lo, bin_hi, par)
{
  variable md = get_dataset_metadata(Isis_Active_Dataset);
  ifnot(_is_struct_type(md))
    throw UsageError, "No metadata associated with dataset #$data_id. (Was it defined via define_xydata?)"$;
  variable model = md.xy_model;
  variable quali = @md.xyfit_qualifier;
  variable key = sprintf("${fname}(%d)", Isis_Active_Function_Id);
  variable x = @(model.x);
  variable y = @(model.y)*0;
  ${fname}_xyfit(&x, &y, par;; md.xyfit_qualifier);
  () = __xy(key, {x, y});
  return 0.;
}
`$, current_namespace);
    variable xyname = sprintf("%s_xyfit", fname);
    variable parnames = @(__get_reference(xyname))();
    variable normpars = Integer_Type[0];
    if (typeof(parnames) == Struct_Type) {
      normpars = parnames.norm;
      parnames = parnames.pars;
      if (_typeof(normpars) == String_Type) {
	variable newnormpars = Integer_Type[length(normpars)];
	variable i;
	_for i (0, length(normpars)-1, 1) {
	  newnormpars[i] = wherefirst(parnames == normpars[i]);
	}
	normpars = newnormpars;
      }
    }
    try {
      add_slang_function(
        fname, __get_reference(ffname), parnames, normpars
      );
    }
    catch AnyError: {
      vmessage("%s error: %s(); does not provide parameter description?", _function_name(), xyname);
      return;
    };
    set_param_default_hook(fname, __get_reference(sprintf("%s_default", xyname)));
  }
  return sprintf("+%s%s", fname, fnumb);
} %}}}

private define message_param_structs (pars) { %{{{
  % this is unfortunately a copy of the isis intrinsic function, which
  % is not accessible.
  variable len = 0;
  foreach (pars) {
    variable p = ();
    len = max([len, strlen(p.name)]);
    if (p.tie != NULL) {
      p.tie = _get_index(p.tie);
    }
    else p.tie = 0;
    
    if (p.fun != NULL) {
      p.fun = sprintf ("\n#=>  %s", strtrim(p.fun));
    }
    else p.fun = "";
    
    if (andelse
      {p.min == -_isis->DBL_MAX}
	{p.max ==  _isis->DBL_MAX})
    {
      p.min = 0;
      p.max = 0;
    }
  }
  return len;
}%}}}

private define define_generic (call) { %{{{
  eval(`
define F_fit (bin_lo, bin_hi, par) {
  variable e;
  variable md = get_dataset_metadata(Isis_Active_Dataset);
  ifnot (_is_struct_type(md))
    throw UsageError, "No metadata associated with dataset #$data_id. (Was it defined via define_xydata?)"$;
  variable model = md.xy_model;
  variable x_part = __xy(1)[0];
  model.y = ${call};
  model.x = (x_part != NULL) ? x_part : model.x;
  if (length(model.y) == 1) {
    model.y = @Double_Type[length(model.x)]+1*model.y;
  }
  __xy;
  try (e) {
    return xyfit_residuals(Isis_Active_Dataset);
  } catch AnyError:
  {
    return 0;
  }
}`$, current_namespace);
  add_slang_function("F", assoc_get_keys(_PAR)[assoc_get_values(_PAR)]);
  return "+F(1)";
} %}}}

private define tokenize (call) { %{{{
  % TODO: needs cleanup
  call = strreplace(call, " ", ""); % remove all whitespace
  variable mode = 0; % mode flag
  variable ops = ['-', '+', '*', '/', '^', '(', ')', ',']; % operator charactes
  variable tokens = {}; % buffer for found tokens
  variable c1 = 0, c2 = 0; % starting and stoping token character position
  variable callen = strlen(call);
  variable bracematch = 0; % counter for matching braces (only within xyfit fun)
  while (c2<callen) {
%{{{ loop over all characters    
    while ((callen > c2) && all(ops!=call[c2]) ) {
%{{{ loop over all non-operator characters in a row
      if (mode & OPERAND) {
%{{{ if after operand
	ifnot ((('0' <= call[c2]) && (call[c2] <= '9')) || (('a' <= call[c2]) &&
	       (call[c2] <= 'z')) || (('A' <= call[c2]) && (call[c2] <= 'Z')) ||
	       (call[c2] == '_')) { % if not symbol expression
	  ifnot ((mode & FUNCTION_XY) && ((call[c2] == '(') || (call[c2] == ')'))) { % this seems not really usefull as c2 never is an operator here change to test for expression in xyfun
	    throw UsageError, sprintf("Unsupported character in expression: '%c'", call[c2]);
	  }
	}
%}}}
      } else if (mode & NUMBER) {
%{{{ if in number expression
	if (not(mode & NUMBER_EXP) && ((call[c2] == 'e') || (call[c2] == 'E'))) { % if exponential number expression
	  mode |= NUMBER_DEC | NUMBER_EXP;
	} else if (not(mode & NUMBER_EXP) && call[c2] == '.') { % if decimal number expression
	  mode |= NUMBER_DEC;
	} else if (('0' <= call[c2]) && (call[c2] <= '9')) { % if a number
	  
	} else { % if not a number
	  throw UsageError, sprintf("Not a number: found '%c'", call[c2]);
	}
%}}}
      } else if (mode == 0) {
%{{{ if in no mode
	if (('0'<=call[c2] && call[c2]<='9')) { % if a number
	  mode = NUMBER;
	} else if (call[c2] == '.') { % if a decimal number
	  mode = NUMBER | NUMBER_DEC;
	} else { % else is a function
	  mode = OPERAND;
	}
      }
%}}}
      c2++;
    }
%}}}
    if (callen <= c2) {
%{{{ if reached end of expression
      if (mode & OPERAND) {
%{{{ if in operand
	if (__f_access(sprintf("%s_xyfit", call[[c1:c2-1]]))) {
	  list_append(tokens, sprintf("%s(1)", call[[c1:c2-1]]));
	} else if (mode & FUNCTION_XY) {
	  if ((call[c2-1] == ')') && (mode & FUNCTION_OPEN)) {
	    list_append(tokens, call[[c1:c2]]);
	  } else if (not (mode & FUNCTION_OPEN)) {
	    list_append(tokens, sprintf("%s(1)", call[[c1:c2-1]]));
	  } else {
	    throw UsageError, sprintf("Unrecognized character in xy-function: '%c'", call[c2-1]);
	  }
	} else {
	  list_append(tokens, call[[c1:c2-1]]);
	}
%}}}
      } else if (mode & NUMBER) {
%{{{ if in number
	if (mode & NUMBER_DEC) {
	  list_append(tokens, atof(call[[c1:c2-1]]));
	} else {
	  list_append(tokens, atoi(call[[c1:c2-1]]));
	}
%}}}
      } else {
%{{{ else append part as string
	list_append(tokens, call[[c1:c2-1]]);
      }
%}}}
      return tokens;
%}}}
    } else if (mode & OPERAND) {
%{{{ if in operand
      if (__f_access(sprintf("%s_xyfit", call[[c1:c2-1]]))) {
%{{{ if xyfun
	mode |= FUNCTION_XY;
	if ((call[c2] == '(')) {
	  mode |= FUNCTION_OPEN;
	  bracematch++;
	} else if ( any(ops == call[c2]) ) {
	  list_append(tokens, sprintf("%s(1)", call[[c1:c2]]));
	  c1 = c2+1;
	  mode = 0;
	} else {
	  throw UsageError, sprintf("Unrecognized character after xy-function: '%c'", call[c2]);
	}
%}}}
      } else if (mode & FUNCTION_XY) {
%{{{ if in xyfun
	if ((call[c2] == '(') && (mode & FUNCTION_OPEN)) {
	  bracematch++;
	} else if ((call[c2] == ')') && (mode & FUNCTION_OPEN)) {
	  bracematch--;
	  ifnot (bracematch) {
	    list_append(tokens, call[[c1:c2]]);
	    c1 = c2+1;
	    mode = 0;
	  }
	} else {
	  %throw UsageError, sprintf("Unrecognized character in xy-function: '%c'", call[c2]);
	}
%}}}
      } else if (not(mode & FUNCTION_XY) && __f_access(call[[c1:c2-1]])) {
%{{{ if in slang fun
	list_append(tokens, __get_reference(call[[c1:c2-1]]));
	list_append(tokens, call[c2]);
	c1 = c2+1;
	mode = 0;
%}}}
      } else {
%{{{ else append magic variables
	list_append(tokens, call[[c1:c2-1]]);
	list_append(tokens, call[c2]);
	c1 = c2+1;
	mode = 0;
%}}}
      }
%}}}
    } else if (mode & NUMBER) {
%{{{ if in number
      if ((mode & NUMBER_EXP) && ((call[c2] == '+') || (call[c2] == '-'))) {
	
      } else if (mode & NUMBER_DEC) {
	list_append(tokens, atof(call[[c1:c2-1]]));
	list_append(tokens, call[c2]);
	c1 = c2+1;
	mode = 0;
      } else {
	list_append(tokens, atoi(call[[c1:c2-1]]));
	list_append(tokens, call[c2]);
	c1 = c2+1;
	mode = 0;
      }
%}}}
    } else if (mode == 0) {
%{{{ if none append operator (?)
      list_append(tokens, call[c2]);
      c1 = c2+1;
    }
%}}}
    c2++;
  }
%}}}
  if (callen <= c2) {
%{{{ if at end of expression
% (seems useless to do it again, but meanwhile eoe might be reached) change if
%  possible
    if (mode & OPERAND) { % if in operand
      if (mode & FUNCTION_XY) {
	if ((call[c2-1] == ')') && (mode & FUNCTION_OPEN)) {
	  list_append(tokens, call[[c1:c2-1]]);
	} else if (not (mode & FUNCTION_OPEN)) {
	  list_append(tokens, sprintf("%s(1)", call[[c1:c2-1]]));
	} else {
	  throw UsageError, sprintf("Unrecognized character in xy-function: '%c'", call[c2-1]);
	}
      }
    } else if (mode & NUMBER) { % if in number
      if (mode & NUMBER_DEC) {
	list_append(tokens, atof(call[[c1:c2-1]]));
      } else {
	list_append(tokens, atoi(call[[c1:c2-1]]));
      }
    } else if (c1 == c2) { % if empty string (what to return here?)
      
    } else { % else append token
      list_append(tokens, call[[c1:c2-1]]);
    }
  }
%}}}
  return tokens;
}
%}}}

private define setup_xyfun (flist) { %{{{
  _PAR = Assoc_Type[Int_Type];
  variable i, newcall = "";
  variable ffcall = "";
  variable npar = -1;
  _for i (0, length(flist)-1, 1) {
    if (typeof(flist[i]) == String_Type) {
      if (string_match(flist[i], "[a-zA-Z_0-9]+\\(([-+*/()a-zA-Z_0-9]+)\\)")) {
	variable pos, len;
	(pos, len) = string_match_nth(1);
	ffcall += define_xyfun(flist[i][[:pos-1]], flist[i][[pos:pos+len-1]]);
	newcall += sprintf("__xy(\"%s\", \"%s\")[1]", flist[i][[:pos-1]], flist[i][[pos+1:pos+len-2]]);
      } else if (flist[i][0] == '#') { % currently only recognized as x-axis
	newcall += "model.x";
      } else {
	if (assoc_key_exists(_PAR, flist[i])) {
	  newcall += sprintf("par[%d]", _PAR[flist[i]]);
	} else {
	  npar++;
	  newcall += sprintf("par[%d]", npar);
	  _PAR[flist[i]] = npar;
	}
      }      
    } else if (typeof(flist[i]) == Ref_Type) {
      newcall += sprintf("(@(%s))", string(flist[i]));
    } else if (typeof(flist[i]) == UChar_Type) {
      newcall += sprintf("%c", flist[i]);
    } else {
      if ((typeof(flist[i]) == Double_Type) || (typeof(flist[i]) == Float_Type)) {
	newcall += sprintf("%f", flist[i]);
      } else if (typeof(flist[i]) == Int_Type) {
	newcall += sprintf("%d", flist[i]);
      }
    }
  }
  ffcall += define_generic(newcall);
  fit_fun(ffcall);
} %}}}

private define param_string (p, len) { %{{{
  return sprintf (Fmt_Params, p.index, len, p.name,
		  p.tie, p.freeze, p.value, p.min, p.max, p.units, p.fun);
}%}}}

%%%%%%%%%%%%%%%%%%%%
public define get_xyfit_fun()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_xyfit_function}
%\synopsis{returns xy-fit-function}
%#c%{{{
%\usage{String_Type get_xyfit_fun();}
%\seealso{xyfit_fun, list_xypar}
%!%-
{
  if ((_FCT == "") || (_FCT == "null") || (_FCT == NULL))
    _FCT = NULL;
  return _FCT;
}
%}}}

private define list_xypar_string () { %{{{
  variable s = get_xyfit_fun();
  s = (s == NULL) ? String_Type[0] : [strtrim(s)];
  variable ps = String_Type[0];  
  variable pars = get_params();
  if (pars != NULL) {
    variable len = message_param_structs (pars);
    variable colheads;
    colheads = sprintf (Fmt_Colheads, len, "  param");
    ps = array_map (String_Type, &param_string, pars, len);
    s = strjoin ([s, colheads, ps], "\n");
  }
  if (length(s) == 0)
    return NULL;
  else if (length(s) == 1 && typeof(s) == Array_Type)
    s = s[0];
  return s;
}%}}}

%%%%%%%%%%%%%%%%%
define list_xypar()
%%%%%%%%%%%%%%%%%
%!%+
%\function{list_xypar}
%\synopsis{list current xy-parameter and xy-function}
%#c%{{{
%\usage{list_xypar();}
%\seealso{get_xyfit_fun, save_xypar, xyfit_fun}
%!%-
{
  variable dest = NULL;
  if (_NARGS) dest = ();
  _isis->put_string (dest, _function_name, list_xypar_string());
}
%}}}

%%%%%%%%%%%%%%%%%
define xyfit_fun()
%%%%%%%%%%%%%%%%%
%!%+
%\function{xyfit_fun}
%\synopsis{define xy-function to fit data defined via \code{define_xydata}}
%#c%{{{
%\usage{xyfit_fun(String_Type function_expression);}
%\description
%    Setting up an xy-fit-function with \code{fitfun} with \code{xyfit_fun("fitfun");}
%    is done by interpreting the string "fitfun" and creates a fit function that can
%    be understood by the isis routines. The string is searched for known functions
%    and special symbols. Every thing else is interpreted as a new fit parameter belonging
%    to a generic function \code{F}.
%
%    The known functions can either be a registered isis function with name \code{fun_xyfit}
%    or an slang intrinsic (see examples). If a symbol starts with '#' it is replaced
%    with the x-axis of the current data set.
%
%    If the xy-fit-function describes the graph a function,
%    it usually computes \code{@yref} in terms of \code{@xref} and the \code{par}-array.
%    This is the only option for xy-data without \code{xerr}, see \code{define_xydata}.
%
%    If the xy-fit-function describes a parameterized curve,
%    it usually computes \code{(@xref, @yref)} in terms of \code{par}
%    and probably further (constant) parameters passed to \code{fitfun_xyfit}
%    as qualifiers, which have been defined by \code{set_xyfit_qualifier}
%
%    If a function of the form \code{fitfun_xyfit} is loaded and a function
%    \code{fitfun_xyfit_default} exists, this will be passed to
%    \code{set_param_default_hook}.
%
%    Importand Notes:
%    The routine will first search for functions with the appendix _xyfit
%    and afterwards for intrinsic functions. This means if a function \code{fun} exists
%    and there is also a function \code{fun_xyfit} registered the routine will use the
%    latter.
%    
%    Calling a parameterized function together with functions of the form f(x) = y or
%    two parameterized functions redults in undefined behavior. Calling a parameterized
%    alone behaves as expected.
%
%    The internal structure of the routine requires it that a call to \code{list_par},
%    \code{save_par} or \code{load_par} do not work as expected. Equivalent _xypar functions
%    exist.
%\examples
%    xyfit_fun("linear"); % or
%    xyfit_fun("linear(1)"); % sets up xyfit-function linear_xyfit
%                             % in this form it is the xy-equivalent to fit_fun
%
%    % example for defining a proper _xyfit function:
%    % (example for y = x*a+b; as available already with: xyfit_fun("linear");)
%    define another_linear_regression_xyfit ()
%    {
%        variable xref, yref, par;
%        switch(_NARGS)
%        { case 0: return ["a [unit_a]", "b [unit_b]"];}
%        { case 3: (xref, yref, par) = (); }
%
%        @yref = par[0] * @xref + par[1];
%    }
%    define another_linear_regression_xyfit_default(i)
%    {
%    switch(i)
%        { case 0: return (1, 0, -10, 10); }
%        { case 1: return (0, 0,  -5, 10); }
%    }
%    xyfit_fun("another_linear_regression");
%    list_xypar;
%
%    % example for specifying normalization parameters
%    % (see 'norm_indexes' parameter of 'add_slang_function')
%    define fun_with_norm_xyfit ()
%    {
%        variable xref, yref, par;
%        switch(_NARGS)
%        { case 0: return struct { pars = ["a [unit_a]", "b [unit_b]"], norm = [0] }; }
%        { case 3: (xref, yref, par) = (); }
%
%        @yref = par[0] * (@xref ^ par[1]);
%    }
%    xyfit_fun("fun_with_norm");
%    
%    % example for a simple function call
%    xyfit_fun("Norm*sin(#x)/exp(#x-xoff)"); % results in fit-function of the form
%                                             % Norm*sin(x)/exp(x-xoff)
%                                             % with two parameters: Norm, xoff
%
%    % example of a combination of the previous cases
%    xyfit_fun("linear(1)+tan(#x^2-xoff)/linear(2)");
%    list_xypar; % output:
%                %   linear(1)+tan(#x^2-xoff)/linear(2)
%                %   idx  param    tie-to  freeze         value         min         max
%                %   1  linear(1).a   0     0                1     -100000      100000  coefficient of x
%                %   2  linear(1).b   0     0                0     -100000      100000  additive constant
%                %   3  linear(2).a   0     0                1     -100000      100000  coefficient of x
%                %   4  linear(2).b   0     0                0     -100000      100000  additive constant
%                %   5  F(1).xoff     0     0                0           0           0
%\seealso{define_xydata, set_xyfit_qualifier, list_xypar, save_xypar, load_xypar, plot_xyfit}
%!%-
{
  variable f;
  switch (_NARGS)
  { case 1: f = () ; }
  { return help(_function_name()); }
  if ((f == NULL) || (f == "")) {
    _FCT = NULL;
    fit_fun("");
    return;
  }
  variable tok = tokenize(f);
  setup_xyfun(tok);
  _FCT = f;
}
%}}}

%%%%%%%%%%%%%%%%%
define save_xypar()
%%%%%%%%%%%%%%%%%
%!%+
%\function{save_xypar}
%\synopsis{save current xy-fit-parameter in file}
%#c%{{{
%\usage{save_xypar(String_Type file);}
%\description
%    Save current xy-parameter and xy-function in file.
%\seealso{load_xypar, get_xyfit_fun, list_xypar}
%!%-
{
  if (_NARGS == 0) {
    usage ("%s (filename)", _function_name);
  }
  variable s, file = ();
  variable fp = fopen (file, "w");
  if (fp == NULL)
    throw IsisError, "Failed opening $file for writing"$;
  _isis->put_string (fp, _function_name, list_xypar_string());
  if (2 == is_defined ("isis_save_par_hook")) {
    eval ("isis_save_par_hook (\"$file\")"$);
    s = ();
    () = fputs (s, fp);
  }
  if (-1 == fclose (fp)) {
    variable err = "Failed closing $file"$;
    if (errno) err += sprintf (" (%s)", errno_string(errno));
    throw IsisError, err;
  }
}
%}}}

%%%%%%%%%%%%%%%%%
define load_xypar()
%%%%%%%%%%%%%%%%%
%!%+
%\function{load_xypar}
%\synopsis{load xy-parameter and xy-function from parameter file}
%#c%{{{
%\usage{load_xypar(String_Type file);}
%\description
%    Load parameter file saved with \code{save_xypar("file.par")}. To display
%    the load parameters one should use \code{list_xypar} instead of
%    \code{list_par}.
%\seealso{save_xypar, load_par}
%!%-
{
  _isis->error_if_fit_in_progress (_function_name);
  variable msg = "load_xypar (\"filename\")";
  if (_isis->chk_num_args (_NARGS, 1, msg))
    return;
  variable fname = ();
  variable fp = fopen(fname, "r");
  if (fp == NULL)
    throw IOError, "Failed opening file '${fname}'"$;
  variable xypar = fgetslines(fp);
  ()=fclose(fp);
  variable line = 0;
  while (xypar[line][0] == '#') line++;
  if (xypar[line][-1] != '\n')
    throw InternalError, "String expression of function to long.";
  variable fcall = xypar[line][[:-2]];
  xyfit_fun(fcall);
  xypar[line] = get_fit_fun+"\n";
  variable tmp = popen("mktemp", "r");
  if (tmp == NULL)
    tmp = popen("mktemp -p /home/"+getenv("USER"), "r");
  if (tmp == NULL)
    throw InternalError, "Could not process parameter file";
  variable tmpname;
  () = fgets(&tmpname, tmp); tmpname = tmpname[[:-2]];
  if (pclose(tmp) != 0)
    throw IOError, "Failed to load file '${fname}'"$;
  variable tfp = fopen(tmpname, "w");
  ()=fputslines(xypar, tfp);
  () = fclose(tfp);
  variable status,e;
  try (e) {
    status = _isis->_load_par (tmpname);
  } catch AnyError: {}
  () = remove(tmpname);
}
%}}}

%%%%%%%%%%%%%%%%%%%%
define define_xydata()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{define_xydata}
%\synopsis{defines an xy-dataset to be modeled with xyfit_fun}
%#c%{{{
%   \usage{Integer_Type data_id = define_xydata ( x[], y[] [, yerr[]] ); }
%\altusage{Integer_Type data_id = define_xydata ( x[], xerr[], y[], yerr[] ); }
%\qualifiers{
%\qualifier{N[=1000]}{: number of curve points, when xerr is considered}
%\qualifier{x_mdl [default: array covering \code{x} with \code{N} steps]}{:
%            (initial) x-values of the model, when \code{xerr} is considered}
%\qualifier{y_mdl [default: array covering \code{y} with \code{N} steps]}{:
%            (initial) y-values of the model, when \code{xerr} is considered}
%}
%\description
%    This function creates a dummy spectral dataset for ISIS and stores
%    the xy-dataset in its metadata, which are only considered when
%    fitting with a dedicated xy-fit-function defined by \code{xyfit_fun}.
%    Fitting via \code{fit_counts} will minimize the sum of squared residuals,
%    see \code{xyfit_residuals}.
%    
%    If no \code{xerr} is specified, the xy-fit-function will only be evaluated
%    at the x-values of the data. (yerr defaults to 1, if not specified.)
%    
%    If \code{xerr} is given as well, a curve is constructed in order to compute
%    the residuals of the data points. The xy-fit-function may produce a
%    (reasonably smooth!) graph (x, y(x)) or parameterized curve (x(t), y(t)).
%    It operates on the model points and possibly (constant) parameters
%    defined by \code{set_xy_qualifier}. Model points for an xy-dataset
%    are initially defined by the \code{N} or \code{x_mdl} and \code{y_mdl} qualifiers.
%
%    If xerr, yerr are lists with two array entries, than the first is
%    interpreted as lower and second as upper uncertainty
%
%\example
%    N = 150; (x, y) = ellipse(8, 5, 0.2*PI, grand(N)*1.5);
%    x += grand(N)+4; y += grand(N)+1;
%    id = define_xydata (x, ones(N), y, ones(N));
%    xyfit_fun("ellipse_xy");
%    set_xyfit_qualifier(id; curve_parameter=[0:2*PI:#3000]);
%    ()=fit_counts;
%    set_par("ellipse_xy(1).pos_angle", 30); ()=fit_counts; % help with angles...
%    plot_xyfit(id);
%    % fit_interactive(&plot_xyfit);
%\seealso{xyfit_fun, set_xyfit_qualifier, xyfit_residuals, plot_xyfit}
%!%-
{
  variable d = struct { x, xerr, y, yerr, n, xsyserr = 0, ysyserr = 0 };

  switch (_NARGS)
  { case 2: (d.x,         d.y        ) = (); }
  { case 3: (d.x,         d.y, d.yerr) = (); }
  { case 4: (d.x, d.xerr, d.y, d.yerr) = (); }
  { return help(_function_name()); }

  if(d.yerr == NULL) { d.yerr = 0 * d.y + 1; }
  if(typeof(d.xerr) == List_Type) { % put upper and lower uncertainties in 2d array
    d.xerr = _reshape([abs(d.xerr[0]), d.xerr[1]], [2, length(d.xerr[0])]);
  }
  if(typeof(d.yerr) == List_Type) {
    d.yerr = _reshape([abs(d.yerr[0]), d.yerr[1]], [2, length(d.yerr[0])]);
  }
  
  if(length(d.x) == length(d.y) && (length(d.yerr) == length(d.y) || length(d.yerr) == 2*length(d.y))
     && (d.xerr == NULL || (length(d.xerr) == length(d.x) || length(d.xerr) == 2*length(d.x)))) {
    d.n = length(d.x);
  } else {
    vmessage("error (%s): input data have inconsistent array lengths", _function_name);
    return;
  }

  variable data_id = define_counts([1:d.n], dup+1, dup*0, dup+1);  % dummy dataset for ISIS

  variable N = qualifier("N", 1000); % some default number of steps for modelgrid
  variable model = struct {
    x = d.xerr == NULL ? d.x : qualifier("x_mdl", [min(d.x-5*(length(d.xerr) == d.n ? d.xerr : d.xerr[0,*])) : max(d.x+5*(length(d.xerr) == d.n ? d.xerr : d.xerr[1,*])) : #N]),
    y = d.xerr == NULL ? d.y : qualifier("y_mdl", [min(d.y-5*(length(d.yerr) == d.n ? d.yerr : d.yerr[0,*])) : max(d.y+5*(length(d.yerr) == d.n ? d.yerr : d.yerr[1,*])) : #N]),
  };
  set_dataset_metadata (data_id, struct { xy_data=d, xy_model=model, xyfit_qualifier });

  return data_id;
}
%}}}

%%%%%%%%%%%%%%%%
define ignore_xy ()
%%%%%%%%%%%%%%%%
%!%+
%\function{ignore_xy}
%\synopsis{ignore points from xy-dataset}
%c#%{{{
%\usage{ignore_xy (index [, low, high]);}
%\description
%    Wraper function of the ignore function for datasets defined with
%    define_xydata. Ignores data points of dataset \code{index}
%    (in the range low to high) for fitting.
%\seealso{notice_xy, ignore, ignore_en, define_xydata}
%!%-
{
  variable id, lo=NULL, hi;
  switch (_NARGS)
  { case 1: id = ();               }
  { case 3: (id, lo, hi) = ();     }
  { return help(_function_name()); }

  variable i,n,nlist, md;
  _for i (0, length(id)-1, 1) {
    if (_isnull(lo)) {
      ignore(id[i]);
    } else {
      md = get_dataset_metadata(id[i]);
      if (typeof(md) != Struct_Type) {
	vmessage("No metadata associated with dataset %d, have you defined it via 'define_xydata'?", id[i]);
	return;
      }
      variable xn = get_data_info(id[i]).notice;
      n = (md.xy_data.x>=lo and md.xy_data.x<=hi);
      _isis->_set_notice_using_mask(int((xn-n)>0), id[i]);
    }
  }
}
%}}}

%%%%%%%%%%%%%%%%
define notice_xy ()
%%%%%%%%%%%%%%%%
%!%+
%\function{notice_xy}
%\synopsis{notice points from xy-dataset}
%#c%{{{
%\usage{notice_xy (index [, low, high]);}
%\description
%    Wraper function of the notice function for datasets defined with
%    define_xydata. Include data points of dataset \code{index}
%    (in the range low to high) for fitting.
%\seealso{ignore_xy, notice, notice_en, define_xydata}
%!%-
{
  variable id, lo=NULL, hi;
  switch (_NARGS)
  { case 1: id = ();               }
  { case 3: (id, lo, hi) = ();     }
  { return help(_function_name()); }

  variable i,n,nlist, md;
  _for i (0, length(id)-1, 1) {
    if (_isnull(lo)) {
      notice(id[i]);
    } else {
      md = get_dataset_metadata(id[i]);
      if (typeof(md) != Struct_Type) {
	vmessage("No metadata associated with dataset %d, have you defined it via 'define_xydata'?", id[i]);
	return;
      }
      variable xn = get_data_info(id[i]).notice;
      n = (md.xy_data.x>=lo and md.xy_data.x<=hi);
      _isis->_set_notice_using_mask(int((n+xn)>0), id[i]);
    }
  }
}
%}}}

private define get_xyfit_metadata(data_id) %{{{
{
  variable md = get_dataset_metadata(data_id);
  ifnot(_is_struct_type(md))
    throw UsageError, "No metadata associated with dataset #$data_id. (Was it defined via define_xydata?)"$;
  ifnot(   struct_field_exists(md, "xy_data")
	&& struct_field_exists(md, "xy_model")
	&& struct_field_exists(md, "xyfit_qualifier"))
    throw UsageError, "Metadata assosicated with dataset #$data_id were not defined via define_xydata."$;
  return md;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%
define set_xyfit_qualifier(data_id)
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_xyfit_qualifier}
%\synopsis{modify the meta data of an xy-dataset defined by \code{define_xydata} and used for an xy-fit}
%#c%{{{
%\usage{set_xyfit_qualifier(data_id; qualifiers); }
%\description
%    This function can be used to modify the information for the xy-data.
%    The used qualifiers are combined with the data structure. Normally
%    the qualifiers to be set should be \code{x_mdl} or \code{curve_parameter}.
%\example
%    set_xyfit_qualifier(id; curve_parameter=[0:2*PI:#3000]);
%\seealso{define_xydata, xyfit_fun, plot_xyfit}
%!%-
{
  % TODO: The xyfit_qualifiers should be specific to the xy-fit-function
  %       and not to the xy-dataset.
  variable md = get_xyfit_metadata(data_id);
  md.xyfit_qualifier = struct_combine(md.xyfit_qualifier, __qualifiers);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%
define set_xyfit_sys_err_frac()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_xyfit_sys_err_frac}
%\synopsis{adds systematic uncertainties to an xy-dataset defined by \code{define_xydata}}
%#c%{{{
%\usage{set_xyfit_sys_err_frac(data_id, [xsyserr,] ysyserr);}
%\description
%    A systematic uncertainty is added in quadrature to either
%    the x- and y-data or to the latter only. The combined
%    uncertainty considered by \code{xyfit_residuals} then is
%
%      err_new = sqrt( err^2 + (data * syserr)^2 )
%
%    where \code{data} is the x- or y-data as defined using
%    \code{define_xydata} and \code{err} is the corresponding
%    defined uncertainty.
%
%    By default, no systematics uncertainties are considered.
%\example
%    % adds 0.5% systematics to the y-data only
%    set_xyfit_sys_err_frac(1, .005);
%    
%    % adds systematics to both, x- (0.5%) and y-data (1%)
%    set_xyfit_sys_err_frac(1, .005, 0.01);
%\seealso{xyfit_residuals, define_xydata, set_sys_err_frac}
%!%-
{
  variable data_id, xsyserr = 0, ysyserr;
  switch (_NARGS)
    { case 2: (data_id, ysyserr) = (); }
    { case 3: (data_id, xsyserr, ysyserr) = (); }
    { help(_function_name); }
  
  variable md = get_xyfit_metadata(data_id);
  md.xy_data.xsyserr = xsyserr;
  md.xy_data.ysyserr = ysyserr;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%
define xyfit_residuals(data_id)
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{xyfit_residuals}
%\synopsis{calculates the difference between xy-data and xy-model}
%#c%{{{
%\usage{Double_Type res[] = xyfit_residuals(Integer_Type data_id);}
%\description
%    The residuals \code{res[i]} are determined differently for xy-data with
%    uncertainties in y only or in both dimensions.
%    
%    If the xy-data have no x-uncertainties \code{xerr}:\n
%       \code{res[i] = (data.y[i] - model.y[i]) / data.yerr[i];}
%       
%    If the xy-data have uncertainties \code{xerr} as well:\n
%       \code{res[i] = min( relative_distance_from_curve[i] );}\n
%    where \code{relative_distance_from_curve[i]} is composed of 
%       \code{(model.x - data.x[i]) / data.xerr[i]} and
%       \code{(model.y - data.y[i]) / data.yerr[i]}.
%\seealso{define_xydata, xyfit_fun}
%!%-
{
  variable md = get_xyfit_metadata(data_id);
  variable data = md.xy_data;
  variable model = md.xy_model;

  % filter notice list
  variable noti = get_data_info(data_id).notice;

  % add systematics to y-data (if set)
  variable yerr = @(data.yerr);
  if (typeof(data.ysyserr) == Array_Type or data.ysyserr > 0) {
    yerr = length(yerr) == data.n % symmetric error bars?
         ? sqrt(yerr*yerr + data.ysyserr*data.ysyserr*data.y*data.y)
	 : sqrt(yerr*yerr + outer_product([1,1], data.ysyserr*data.ysyserr*data.y*data.y));
  }

  % no x-errors given
  variable residuals;
  if (data.xerr == NULL) {
    residuals = data.y - model.y;
    residuals /= length(yerr) == data.n % symmetric error bars?
      ? yerr : yerr[[0:data.n-1] + data.n*(sign(-residuals)+1)/2];
    return residuals[where(noti)];
  }
  
  % else: fitting data points with uncertainties in both dimensions

  % add systematics to x-data (if set)
  variable xerr = @(data.xerr);
  if (typeof(data.xsyserr) != Double_Type or data.xsyserr > 0) {
    xerr = length(xerr) == data.n % symmetric error bars?
         ? sqrt(xerr*xerr + data.xsyserr*data.xsyserr*data.x*data.x)
	 : sqrt(xerr*xerr + outer_product([1,1], data.xsyserr*data.xsyserr*data.x*data.x));
  }

  variable i, resx, resy;
  residuals = Double_Type[data.n];
  _for i (0, data.n-1, 1)
  {
    %MB: currently we assume a 2D-Gaussian profile of uncertainties, but use an ellipse with
    %    the semi-axes xerr and yerr
    %    take care of effective_error=0? fix problems with strong excentricities?
    %    better solution? the calculations above might be computationally expensive for
    %    fine models with many points

    % variable distance_to_curve = hypot ( model.x - data.x[i], model.y - data.y[i] );
    % variable angle_to_curve    = atan2 ( model.y - data.y[i], model.x - data.x[i] );
    % variable effective_error   = hypot( data.xerr*cos(angle_to_curve), data.yerr*sin(angle_to_curve) );
    % residuals[i] = min ( distance_to_curve / effective_error );
    % MB: the residuals above are only valid in certain cases, better use the Mh version
    resx = model.x - data.x[i];
    resx /= length(xerr) == data.n ? xerr[i] : xerr[(sign(resx)+1)/2,i];
    resy = model.y - data.y[i];
    resy /= length(yerr) == data.n ? yerr[i] : yerr[(sign(resy)+1)/2,i];
    residuals[i] = min( hypot( resx, resy ) );
  }
  return residuals[where(noti)];
}
%}}}

%%%%%%%%%%%%%%%%%
define get_xydata(data_id)
%%%%%%%%%%%%%%%%%
%!%+
%\function{get_xydata}
%\synopsis{provides the xy-data, which has been defined with \code{define_xydata}}
%#c%{{{
%   \usage{(x[],         y[], yerr[]) = get_xydata(Integer_Type data_id);}
%\altusage{(x[], xerr[], y[], yerr[]) = get_xydata(Integer_Type data_id);}
%\description
%    This function returns the xy-data of dataset # \code{data_id}
%    previously defined with \code{define_xydata}.
%    If no x-uncertainty was defined, no \code{xerr} is returned.
%\seealso{define_xydata, get_xymodel}
%!%-
{
  variable data = get_xyfit_metadata(data_id).xy_data;
  variable n = qualifier_exists("noticed") ? where(get_data_info(data_id).notice) : [0:data.n-1];
  return (data.xerr == NULL)
    ? (@data.x[n], @data.y[n], length(data.yerr) == data.n ? @data.yerr[n] : {data.yerr[0,n], data.yerr[1,n]})
    : (@data.x[n], length(data.xerr) == data.n ? @data.xerr[n] : {data.xerr[0,n], data.xerr[1,n]}, @data.y[n], length(data.yerr) == data.n ? @data.yerr[n] : {data.yerr[0,n], data.yerr[1,n]});
}
%}}}

%%%%%%%%%%%%%%%%%%
define get_xymodel(data_id)
%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_xymodel}
%\synopsis{provides the xy-model \code{(x_mdl[], y_mdl[])} given by an xy-fit}
%#c%{{{
%\usage{(x_mdl[], y_mdl[]) = get_xymodel(Integer_Type data_id);}
%\description
%    This function returns the xy-model (\code{(x_mdl[],y_mdl[])})
%    provided by the last evaluation (by \code{fit_counts} / \code{eval_counts})
%    of the xy-fit-function specified with \code{xyfit_fun}.
%\seealso{xyfit_fun, get_xydata, define_xydata}
%!%-
{
  variable model = get_xyfit_metadata(data_id).xy_model;
  return (@model.x, @model.y);
}
%}}}

%%%%%%%%%%%%%%%%%
define eval_xyfun ()
%%%%%%%%%%%%%%%%%
%!%+
%\function{eval_xyfun}
%\synopsis{evaluate current xy-function for points x [y]}
%#c%{{{
%\usage{(Double_Type[] x, Double_Type[] y) = eval_xyfun(Double_Type[] x [, Double_Type[] y]);}
%\qualifiers{
%\qualifier{id[=Isis_Active_Dataset]:}{ uses parameter and model for dataset #id}
%}
%\description
%Evaluate the current xy-model on the points (x,y)
%\seealso{define_xydata, xyfit_fun}
%!%-
{
  variable x,y=NULL;
  switch (_NARGS)
  { case 1: x = ();              }
  { case 2: (x,y) = ();          }
  { help(_function_name); return;}

  variable id = qualifier("id", Isis_Active_Dataset);

  if (y!=NULL) {
    if (length(x) != length(y)) {
      message("x- and y-arrays must have the same size");
      return;
    }
  } else {
    y = @x;
  }

  variable md = get_dataset_metadata(id);
  if (typeof(md) != Struct_Type) {
    vmessage("No metadata associated with dataset %d, have you defined it via 'define_xydata'?", id);
    return;
  }

  variable x_save, y_save;
  (x_save, y_save) = get_xymodel(id);
  md.xy_model.x = @x;
  md.xy_model.y = @y;
  set_dataset_metadata(id, md);
  variable grid = get_data_counts(id);
  variable reset_active = Isis_Active_Dataset;
  Isis_Active_Dataset = id;
  ()=eval_fun(grid.bin_lo, grid.bin_hi);
  Isis_Active_Dataset = reset_active;

  variable xr, yr;
  (xr,yr) = get_xymodel(id);
  md.xy_model.x = x_save;
  md.xy_model.y = y_save;
  set_dataset_metadata(id, md);
  return xr, yr;
}%}}}

%%%%%%%%%%%%%%%%%%
define eval_xyfun2 ()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{eval_xyfun2}
%\synopsis{evaluate valid xyfit_fun string with parameters}
%#c%{{{
%\usage{(Double_Type[] x, Double_Type[] y) = eval_xyfun2 (handle, x[ , y, par])}
%\qualifiers{
%\qualifier{qualifier:}{ pass qualifier structure to function}
%}
%\description
%Evaluates function \code{handle} (either the name of a xy-function or reference)
%on the points x (and y) with parameters \code{par}.
%\seealso{eval_xyfun, define_xydata, xyfit_fun}
%!%-
{
  variable expr,x,y,par;
  variable q = qualifier("qualifier");
  switch (_NARGS)
  { case 3: (expr,x,par) = (); y=@Int_Type[length(x)]*0.; }
  { case 4: (expr,x,y,par) = ();                          }
  { help(_function_name); return;                         }
  if (length(x) != length(y)) {
    message("x- and y-array must have the same length");
    return;
  }

  variable f = (typeof(expr)==Ref_Type) ? expr : __get_reference(expr+"_xyfit");
  variable xr = @x, yr = @y;
  if (_isnull(f)) {
    vmessage("function %s not found", expr);
    return;
  }
  @f(&xr, &yr, par;; q);
  return (xr, yr);
}%}}}

private define plot_xyresiduals(data_id) %{{{
{
  if (get_xyfit_fun == NULL) {
    message("No model defined");
    return;
  }
  variable dcol = qualifier("dcol", 4);
  variable res = qualifier("res", 1); % residual mode
  variable rcol = qualifier("rcol", dcol);
  variable recol = qualifier("recol", rcol);
  variable dsym = qualifier("dsym", 4);
  variable rsym = qualifier("rsym", dsym);
  variable ovrplt = qualifier("ovrplt");
  variable xlbl = qualifier("xlabel", "x");

  variable popt = get_plot_options;

  variable cdcol, crcol, crecol, crsym;
  variable rsign, xyres,noti,my,md,data;

  xlabel(xlbl);
  if (res == 1) {
    ylabel("\\gx");
  } else if (res == 2) {
    ylabel("\\gx\\u2");
  } else {
    ylabel("Ratio");
  }

  variable i;
  % yplot range
  variable yminr, ymaxr;
  _for i (0, length(data_id)-1, 1) {
    md = get_dataset_metadata(data_id[i]);
    data = md.xy_data;
    (,my) = eval_xyfun(data.x, data.y; id=data_id[i]);
    noti = get_data_info(data_id[i]).notice_list;
    rsign = sign(data.y[noti] - my[noti]);
    xyres = xyfit_residuals(data_id[i]);
    xyres = sign(xyres)*xyres;
    if (i) {
      if (res == 1) {
	yminr = min([yminr, rsign*xyres - ones(length(noti)) ] );
	ymaxr = max([ymaxr, rsign*xyres + ones(length(noti)) ] );
      } else if (res == 2) {
	yminr = min([rsign*sqr(xyres),yminr]);
	ymaxr = max([rsign*sqr(xyres),ymaxr]);
      } else {
	yminr = min( [ yminr, (data.y[noti]-((data.n==length(data.yerr))?data.yerr[noti] : data.yerr[0,*][noti]))/my[noti] ] );
	ymaxr = max( [ ymaxr, (data.y[noti]+((data.n==length(data.yerr))?data.yerr[noti] : data.yerr[1,*][noti]))/my[noti] ] );
      }
    } else {
      if (res == 1) {
	yminr = min(rsign*xyres - ones(length(noti)) );
	ymaxr = max(rsign*xyres + ones(length(noti)) );
      } else if (res == 2) {
	yminr = min(rsign*sqr(xyres));
	ymaxr = max(rsign*sqr(xyres));
      } else {
	yminr = min( (data.y[noti]-((data.n==length(data.yerr))?data.yerr[noti] : data.yerr[0,*][noti]))/my[noti] );
	ymaxr = max( (data.y[noti]+((data.n==length(data.yerr))?data.yerr[noti] : data.yerr[1,*][noti]))/my[noti] );
      }
    }
  }
  yrange(yminr-(ymaxr-yminr)*.1, ymaxr+(ymaxr-yminr)*.1);
  
  _for i (0, length(data_id)-1, 1) {
    variable id = data_id[i];
    cdcol = length(dcol)>i ? dcol[i] : 4;
    crcol = length(rcol)>i ? rcol[i] : cdcol;
    crecol = length(recol)>i ? recol[i] : crcol;
    crsym = length(rsym)>i ? rsym[i] : 4;
    
    md = get_dataset_metadata(id);
    variable model = md.xy_model;
    data = md.xy_data;
    noti = get_data_info(id).notice_list;
      
    (,my) = eval_xyfun(data.x, data.y; id=id);
    rsign = sign(data.y[noti] - my[noti]);
    
    variable qstruct = struct{error_color=crecol};
    if (ovrplt || i) {
      qstruct = struct {@qstruct, overplot=NULL};
    }
    
    % plot residuals with errors
    xyres = xyfit_residuals(id);
    xyres = sign(xyres)*xyres;
    
    color(crcol);
    pointstyle(rsym);
    if (res == 1) {
      if (data.xerr == NULL) {
	plot_with_err (data.x[noti], rsign*xyres, ones(length(noti));; qstruct);
      } else {
	plot_with_err (data.x[noti], data.xerr[noti], rsign*xyres, ones(length(noti));; qstruct);
      }
    } else if (res == 2) {
      connect_points(0);
      if (ovrplt || i) {
	oplot (data.x[noti], rsign*sqr(xyres));
      } else {
	plot (data.x[noti], rsign*sqr(xyres));
      }
    } else {
      if (data.xerr == NULL) {
	plot_with_err (data.x[noti], data.y[noti]/my[noti],
		       data.n == length(data.yerr) ? data.yerr[noti]/my[noti] :
		     {data.yerr[0,*][noti]/my[noti], data.yerr[1,*][noti]/my[noti]};; qstruct);
      } else {
	plot_with_err (data.x[noti], data.n == length(data.xerr) ? data.xerr[noti] :
		     {data.xerr[0,*][noti], data.xerr[1,*][noti]},
		       data.y[noti]/my[noti], data.n == length(data.yerr) ? data.yerr[noti]/my[noti] :
		     {data.yerr[0,*][noti]/my[noti], data.yerr[1,*][noti]/my[noti]};; qstruct);
      }
    }
  }
  
  % plot ideal line
  variable cpo = get_plot_options;
  color(-1);
  connect_points(-1);
  linestyle(2);
  if (res == 3) {
    oplot([cpo.xmin, cpo.xmax], [1, 1]);
  } else {
    oplot([cpo.xmin, cpo.xmax], [0, 0]);
  }

  popt.color = popt.color+1;
  set_plot_options(popt); % reset options
}
%}}}

%%%%%%%%%%%%%%%%%
define plot_xyfit(data_id)
%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_xyfit}
%\synopsis{plot xy-data and its current xy-model}
%#c%{{{
%\usage{plot_xyfit(Integer_Type data_id);}
%\description
%    A simple plot function of the xy-data (given by \code{define_xydata})
%    and -model (last evaluation of the xy-fit-function, see \code{xyfit_fun}).
%
%    This functions basically calls:\n
%        \code{plot_with_err( get_xydata(data_id) );}\n
%        \code{oplot( get_xymodel(data_id) );}
%\seealso{get_xydata, get_xymodel, define_xydata, xyfit_fun, plot_with_err}
%!%-
{
  variable dcol=qualifier("dcol", 4);
  variable decol=qualifier("decol", dcol);
  variable mcol=qualifier("mcol", 2);
  variable rcol=qualifier("rcol", dcol);
  variable recol=qualifier("recol", dcol);
  variable dsym=qualifier("dsym", 4);
  variable rsym=qualifier("rsym", dsym);
  variable res=qualifier("res", 0);
  variable xlbl=qualifier("xlabel", "x"), ylbl=qualifier("ylabel", "y");

  variable cdcol,cdecol,cmcol,cdsym;
  variable hasmodel = (get_xyfit_fun!=NULL)?1:0;

  variable popt = get_plot_options;

  if (res && hasmodel) {
    multiplot([3,1]);
  }
  ylabel(ylbl); xlabel(xlbl);
  variable i, id, md, noticed, xasym, yasym;
  % set plot range if not set already
  % this requires the full data to be in one array
  variable all_x = Double_Type[0];
  variable all_y = Double_Type[0];
  variable all_xloerr = Double_Type[0];
  variable all_xhierr = Double_Type[0];
  variable all_yloerr = Double_Type[0];
  variable all_yhierr = Double_Type[0];
  _for i (0, length(data_id)-1, 1) {
    md = get_dataset_metadata(data_id[i]);
    noticed = get_data_info(data_id[i]).notice_list;
    xasym = length(md.xy_data.xerr) != md.xy_data.n ? _isnull(md.xy_data.xerr) ? -1 : 1 : 0;
    yasym = length(md.xy_data.yerr) != md.xy_data.n ? _isnull(md.xy_data.yerr) ? -1 : 1 : 0;
    all_x = [all_x, md.xy_data.x[noticed]];
    all_y = [all_y, md.xy_data.y[noticed]];
    if (xasym < 0) {
      all_xloerr = [all_xloerr, Double_Type[md.xy_data.n][noticed]];
      all_xhierr = [all_xhierr, Double_Type[md.xy_data.n][noticed]];
    } else if (xasym > 0) {
      all_xloerr = [all_xloerr, md.xy_data.xerr[0,*][noticed]];
      all_xhierr = [all_xhierr, md.xy_data.xerr[1,*][noticed]];
    } else {
      all_xloerr = [all_xloerr, -md.xy_data.xerr[noticed]];
      all_xhierr = [all_xhierr, md.xy_data.xerr[noticed]];
    }
    if (yasym < 0) {
      all_yloerr = [all_yloerr, Double_Type[md.xy_data.n][noticed]];
      all_yhierr = [all_yhierr, Double_Type[md.xy_data.n][noticed]];
    } else if (yasym > 0) {
      all_yloerr = [all_yloerr, md.xy_data.yerr[0,*][noticed]];
      all_yhierr = [all_yhierr, md.xy_data.yerr[1,*][noticed]];
    } else {
      all_yloerr = [all_yloerr, -md.xy_data.yerr[noticed]];
      all_yhierr = [all_yhierr, md.xy_data.yerr[noticed]];
    }
  }
  % Mikes private function
  variable cp = get_plot_options.connect_points;
  oplt = 0; % is undefined when none of Mikes plotting functions is called
  () = start_plot(all_x+all_xloerr,
		  all_x+all_xhierr,
		  all_y+all_yloerr,
		  all_y+all_yhierr);
  set_plot_options(popt);

  _for i (0, length(data_id)-1, 1) {
    cdcol = length(dcol)>i ? dcol[i] : 4;
    cdecol = length(decol)>i ? decol[i] : cdcol;
    cmcol = length(mcol)>i ? mcol[i] : 2;
    cdsym = length(dsym)>i ? dsym[i] : 4;

    id = data_id[i];
    color(cdcol);
    pointstyle(cdsym);
    %if (i)
      oplot_with_err( get_xydata(id; noticed); error_color=cdecol );
    %else
    %  plot_with_err( get_xydata(id; noticed); error_color=cdecol );
    connect_points(-1);
    color(cmcol);
    if (hasmodel) {
      oplot( get_xymodel(id) );
    }
    connect_points(cp);
  }
  if (res && hasmodel) {
    plot_xyresiduals(data_id;; __qualifiers);
  }
  set_plot_options(popt);
}
%}}}
