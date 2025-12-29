% -*- mode: slang; mode: fold -*-

% known data-types, which code can be written using a simple format code %{{{
private define _slang_primitive_datatype_format_string(t)
{
  return t == Int16_Type    ? "%dH"
      :  t == UInt16_Type   ? "%dUH"
      :  t == Int32_Type    ? "%dL"
      :  t == UInt32_Type   ? "%ldUL"
      :  t == Int64_Type    ? "%lldLL"
      :  t == UInt64_Type   ? "%lldULL"
      :  t == Double_Type   ? "%S"
      :  t == Float_Type    ? "%Sf"
      :  t == Complex_Type  ? "%S"
      :  t == Char_Type     ? "typecast(%d,Char_Type)"
      :  t == UChar_Type    ? "'%c'"
      :  t == String_Type   ? `"%s"`
      :  t == BString_Type  ? `"%s"B`
      :  t == Null_Type     ? "%S"
      :  t == Void_Type     ? "%S"
      :  t == DataType_Type ? "%S"
      : NULL;
}

private define _is_primitive_datatype(t)
{
  return _slang_primitive_datatype_format_string(t) != NULL;
}
%}}}

% recursive function for converting the given S-lang
% variable into a string and writing into a file
private define _slang_variable_to_file();
private define _slang_variable_to_file(varname, var, fp)
{
  variable fmt = _slang_primitive_datatype_format_string(typeof(var));
  if (fmt != NULL) { % primitive datatype %{{{
    % print out variable declaration
    if (varname != NULL) { ()=fprintf(fp, "variable %s = ", varname); }
    % check on infinity or NaN
    if (__is_numeric(var) && isinf(var)) {
      ()=fprintf(fp, "%s_Inf", sign(var) == -1 ? "-" : "");
    } else if (__is_numeric(var) && isnan(var)) {
      ()=fprintf(fp, "%s_NaN", substr(string(var),1,1) == "-" ? "" : "-");
    } else {
      ()=fprintf(fp, fmt, var);
    }
    % ending
    if (varname != NULL) { ()=fprintf(fp, ";\n"); }
    return;
  }
%}}}
  variable type = typeof(var);
  % objects
  variable i, n, elementvarname, keys, values, ind;
  if(type == Ref_Type)  % references (as values of struct fields) %{{{
  {
    % convert reference to executable string
    ind = string(var);
    % check on private function/variable
    if (__get_reference(substr(ind, 2, -1)) == NULL) {
      % FIXME: ps has not been assigned!
      % if (ps == NULL) { vmessage("error: '%s' is a private function/variable", ind); return; }
    }
    ()=fprintf(fp, "variable %s = %s;\n", varname, ind);
  }
%}}}
  else if(type == Array_Type)  % arrays %{{{
  {
    variable len = length(var);
    variable dims, ndims, datatype; (dims, ndims, datatype) = array_info(var);
    % initialize empty array
    ()=fprintf(fp, "variable %s = %S[%d];\n", varname, datatype, len);
    if(ndims > 1)  { reshape(var, len); }  % flatten array
    if (_is_primitive_datatype(datatype)) {
      % print elements in packages
      variable ps = qualifier("packagesize", datatype == String_Type ? 5 : 10);
      _for n (0, len/ps, 1) {
	ind = [n*ps:(n+1)*ps < len ? ((n+1)*ps)-1 : len-1];
	if (length(ind) > 0) {
	  ()=fprintf(fp, "%s[[%d:%d]] = [\n  ", varname, ind[0], ind[-1]);
	  _for i (0, length(ind)-1, 1) {
	    _slang_variable_to_file(NULL, var[ind[i]], fp);
	    if (i < length(ind)-1) { ()=fprintf(fp, ","); }
	  }
	  ()=fprintf(fp, "\n];\n");
	}
      }
    }
    else { % array contains objects -> every element will be a variable
      _for n (0, len-1, 1) {
	% variable name for current element
	elementvarname = sprintf("%s_i%d", varname, n);
	% define variable for element and build it recursively
	()=fprintf(fp, "%% array element %d %%{{{\n", n);
	_slang_variable_to_file(elementvarname, var[n], fp;; __qualifiers);
	()=fprintf(fp, "%%}}}\n");
	()=fprintf(fp, "%s[%d] = __tmp(%s);\n", varname, n, elementvarname);
      }
    }
    if(ndims > 1)
    { % reshape finally
      ()=fprintf(fp, "%% reshape to array's dimensions\nreshape(%s, [%s]);\n",
		 varname, strjoin(array_map(String_Type, &string, dims), ","));
      reshape(var, dims);
    }
  }
%}}}
  else if(type == Assoc_Type)  % associative arrays %{{{
  {
    % get keys and values
    keys = assoc_get_keys(var);
    values = assoc_get_values(var);
    len = length(keys);
    % init associative array
    ()=fprintf(fp, "variable %s = Assoc_Type[%s];\n", varname, string(_typeof(values)));
    % fill array and take value's data type into account
    if (_is_primitive_datatype(_typeof(values))) {
      _for n (0, len-1, 1) {
        ()=fprintf(fp, `%s["%s"] = `, varname, keys[n]);
	_slang_variable_to_file(NULL, values[n], fp);
	()=fprintf(fp, ";\n");
      }
    }
    else { % objects
      _for n (0, len-1, 1) {
	% variable name for current element
	elementvarname = sprintf("%s_i%d", varname, n);
	% define element variable and call yourself recursively
	()=fprintf(fp, "%% associative array's element %d %%{{{\n", n);
	_slang_variable_to_file(elementvarname, values[n], fp;; __qualifiers);
	()=fprintf(fp, "%%}}}\n");
	()=fprintf(fp, "%s[\"%s\"] = __tmp(%s);\n", varname, keys[n], elementvarname);
      }
    }
  }
%}}}
#ifeval __get_reference("vector") != NULL
  else if(type == Vector_Type) %{{{
  {
    variable vector_constructor = "vector("B;
    % each component is a variable
    _for n ('x', 'z', 1) {
      elementvarname = sprintf("%s_v%c", varname, n);
      ()=fprintf(fp, "%% %c component%%{{{\n", n);
      _slang_variable_to_file(elementvarname, get_struct_field(var, char(n)), fp;; __qualifiers);
      ()=fprintf(fp, "%%}}}\n");
      vector_constructor += sprintf("\n  __tmp(%s)%s", elementvarname, (n!='z' ? "," : ""));
    }
    % create the vector
    ()=fprintf(fp, "%% create vector\n");
    ()=fprintf(fp, "variable %s = %s\n);\n", varname, vector_constructor);
  }
%}}}
#endif
  else if(is_struct_type(var))  % also works with typedef'ed struct's %{{{
  {
    % get struct field names and define them
    keys = get_struct_field_names(var);
    variable fieldsvarname = sprintf("%s_flds", varname);
    ()=fprintf(fp, "%% field names %%{{{\n");
    _slang_variable_to_file(fieldsvarname, keys, fp;; __qualifiers);
    ()=fprintf(fp, "variable %s = @Struct_Type(__tmp(%s));\n", varname, fieldsvarname);
    ()=fprintf(fp, "%%}}}\n");
    % loop over fields
    _for n (0, length(keys)-1, 1) {
      variable value = get_struct_field(var, keys[n]);
      if (_is_primitive_datatype(typeof(value))) {
	% assign primitive value directly
	()=fprintf(fp, "set_struct_field(%s, \"%s\", ", varname, keys[n]);
        _slang_variable_to_file(NULL, value, fp);
	()=fprintf(fp, ");\n");
      }
      else { % objects get their own variables
	elementvarname = sprintf("%s_f%d", varname, n);
	()=fprintf(fp, "%% field value %d %%{{{\n", n);
	_slang_variable_to_file(elementvarname, value, fp;; __qualifiers);
	()=fprintf(fp, "%%}}}\n");
	()=fprintf(fp, "set_struct_field(%s, \"%s\", __tmp(%s));\n", varname, keys[n], elementvarname);
      }
    }
  }
%}}}
  else if(type == List_Type) %{{{
  {
    % init empty list
    ()=fprintf(fp, "variable %s = list_new();\n", varname);
    _for n (0, length(var)-1, 1) {
      if (_is_primitive_datatype(typeof(var[n]))) {
	% append primitive value directly
	()=fprintf(fp, "list_append(%s, ", varname);
        _slang_variable_to_file(NULL, var[n], fp);
	()=fprintf(fp, ");\n");
      }
      else { % objects get their own variables
	elementvarname = sprintf("%s_l%d", varname, n);
	()=fprintf(fp, "%% list element %d %%{{{\n", n);
	_slang_variable_to_file(elementvarname, var[n], fp;; __qualifiers);
	()=fprintf(fp, "%%}}}\n");
	()=fprintf(fp, "list_append(%s, __tmp(%s));\n", varname, elementvarname);
      }
    }
  }
%}}}
  else
  {
    vmessage("error: data-type %S not supported", typeof(var));
    return;
  }
}


%%%%%%%%%%%%%%%%%%%%%%%%
define save_slang_variable()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{save_slang_variable}
%\synopsis{allows to save S-Lang variables into a file}
%\usage{save_slang_variable(file, &var1, &var2, ...);}
%\qualifiers{
%    \qualifier{edit}{open an editor to modify the variables;
%             in that case all variables have to be passed
%             as references and will be set to their new
%             values after the editor is closed}
%    \qualifier{delete}{delete the file after editing (requires the
%             'edit' qualifier to be set); note that the
%             given variables are still modified!}
%}
%\description
%    The S-Lang code defining the given variables is saved
%    into a file, specified by either the filename or an
%    already opened file-pointer. In order to handle arrays
%    with a large number (>1000) of items as well as
%    complex structures, the S-Lang code uses temporary
%    variable names. Their values are assigned step by step
%    to avoid a stack overflow. The file can be evaluated
%    later to push the saved variables onto the stack (see
%    the example).
%
%    This function allows to modify the given variables as
%    well. In that case the 'edit'-qualifier has to be set
%    and all passed variables have to be given as references.
%    The file the variables are saved into is shown in the
%    editor specified by the EDITOR environment variable
%    or jed, if EDITOR is undefined. After saving the file
%    and closing the editor, the file is evaluated, which
%    should push the (modified) S-Lang objects onto the
%    stack. These objects are finally assigned to the given
%    variables.
%
%    NOTE: the latter feature is based on the function
%          'edit_var', which does the same except that the
%          main purpose is to edit the variables using a
%          temporary file. Here, the S-lang code is human
%          readable as well, since no temporary variables
%          are used to assign the values stepwise. In that
%          case, however, stack overflow errors may occure.
%          But who wants to edit such large variables...?
%    
%    The function supports the following data-types:
%      Integer_Type, Double_Type, Complex_Type,
%      Char_Type, String_Type, BString_Type,
%      Null_Tpye, Void_Type (=Undefined_Type),
%    as well as
%      Array_Type, Assoc_Type, Struct_Type, List_Type
%      Vector_Type, Ref_Type (as structure fields)
%\example
%    % define a structure 
%    variable a = struct { example = "foo" };
%    
%    % save the structure into a file
%    save_slang_variable("mystruct.sl", a);
%
%    % restore the variable into a new one
%    variable b;
%    (b,) = evalfile("mystruct.sl");
%    
%    % edit the original variable
%    % using a temporary filename
%    save_slang_variable("/tmp/myedit", &a; edit, delete);
%
%    % this operation can be performed using
%    % 'edit_var' as well (but better readable)
%    edit_var(&a);
%\seealso{evalfile, edit_var}
%!%-
{
  if (_NARGS < 2) { help(_function_name()); return; }

  % get filename and given variables
  variable args = __pop_list(_NARGS-1);
  variable fname = ();

  % given variables should be edited
  variable n, edit = qualifier_exists("edit");
  % check which given variables are references
  variable varref = Ref_Type[length(args)];
  _for n (0, length(args)-1, 1) {
    if (typeof(args[n]) == Ref_Type) { varref[n] = args[n]; }
  }
  % if in edit mode every variable has to be given as reference
  % however, if none references are given at all, ignore edit mode
  if (edit and any(_isnull(varref))) {
    message("error: editing requires references exclusively");
    return;
  }
  % dereference
  _for n (0, length(args)-1, 1) {
    if (varref[n] != NULL) { args[n] = @(args[n]); }
  }

  % pick temporary variable names for each given variable
  variable varname = String_Type[length(args)];
  _for n (0, length(varname)-1, 1) {
    (,varname[n]) = varref[n] != NULL ? get_variable_name(varref[n]) : (0,sprintf("v%02d", n+1));
    varname[n] = sprintf("_%s_%02d", varname[n], n+1);
  }

  % recursively write variables and their values into the file
  variable fp = (typeof(fname) == File_Type ? fname : fopen(fname, "w+"));
  ()=fprintf(fp, "%% -*- mode: slang; mode: fold -*-\n\n");
  _for n (0, length(varname)-1, 1) {
    ()=fprintf(fp, "%% %d%s variable %%{{{\n", n+1, n == 10 ? "th" : n == 11 ? "th" : n mod 10 == 0 ? "st" : n mod 10 == 1 ? "nd" : n mod 10 == 2 ? "rd" : "th", varname[n]);
    _slang_variable_to_file(varname[n], args[n], fp;; __qualifiers);
    ()=fprintf(fp, "%%}}}\n\n");
  }

  % finally, push variables onto the stack and uninitialize them
  ()=array_map(Integer_Type, &fprintf, fp, "__tmp(%s);  %% left on stack\n", varname);

  if (typeof(fname) == String_Type) { ()=fclose(fp); }

  % eventually open editor
  if (edit) {
    variable e = getenv("EDITOR");
    if (e == NULL) { e = "jed"; }
    if (system(sprintf("%s %s", e, fname))) {
      message("warning: running $EDITOR raised an error");
      return;
    }

    try(e) { ()=evalfile(fname); } % will push all variables onto the stack
    catch AnyError:
    {
      message("error: unable to evaluate the file");
      vmessage(`"%s" exception:
%s
%s:%d`, e.descr, e.message, e.file, e.line);
    }

    % assign the new values to the given variables
    args = __pop_list(length(varref));
    _for n (0, length(args)-1, 1) {
      @(varref[n]) = args[n];
    }

    % eventually remove the file
    if (qualifier_exists("delete")) {
      if (typeof(fname) == File_Type) { vmessage("warning: 'file' has to be given as filename to be deleted"); }
      else { ()=remove(fname); }
    }
  }
}


%%%%%%%%%%%%%%%%%%%%%%%%
define storevar()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{storevar}
%\synopsis{use `save_slang_variable' instead}
%!%-
{
  message("\nuse save_slang_variable instead\n");
  return "use save_slang_variable instead";
}
