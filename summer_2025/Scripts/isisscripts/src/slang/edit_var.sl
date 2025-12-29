%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define assoc_has_default_value(hash, defaultvalref)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable min_char =  32;  % ' '
  variable max_char = 126;  % '~'

  % find a string that is no key of hash
  variable N = 0;
  variable key = "";
  while(assoc_key_exists(hash, key))
  {
    N++;
    variable a = UChar_Type[N];
    a[*] = min_char;
    key = "";
    loop(N)  key += char(min_char);
    while(assoc_key_exists(hash, key))
    { variable i = -1;
      do i++, a[i] = min_char+((a[i]-min_char+1) mod (max_char-min_char+1));
      while(a[i]==min_char && i<N-1);
      if(a[i]==min_char && i==N-1)
	break;
      key = "";
      _for i (N-1, 0, -1)
        key += char(a[i]);
    }
  }

  try @defaultvalref = hash[key];
  catch AnyError: return 0;
  return 1;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define datatype_to_string();
private define datatype_to_string(val)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable i, last, type = typeof(val);
  variable indent = qualifier("indent", 0);
  variable sp = "";  loop(indent)  sp += "  ";
  variable fold = (indent>0);  % qualifier_exists("fold");

  indent++;
  if(type == String_Type || type == BString_Type)
      sprintf(`"%S"%s`, val, (type==BString_Type ? "B" : ""));  % left on stack
  else if(type == Array_Type || type == List_Type)
  {
      (type==Array_Type ? "[" : "{") + sprintf(" %% %S", val) + (fold ? " %{{{" : "") + "\n";  % left on stack
      last = length(val)-1;
      _for i (0, last, 1)
        () + sp+"  "
           + datatype_to_string(val[i]; indent=indent)
	   + (i<last ? "," : "") + "\n";  % left on stack
      () + (fold ? "%}}}\n" : "") + sp+ (type==Array_Type ? "]" : "}");  % left on stack
  }
  else if(is_struct_type(val))  % also works with typedef'ed struct's
  {
      sprintf("struct { %% %S", val) + (fold ? " %{{{" : "") + "\n";  % left on stack
      variable field = get_struct_field_names(val);
      last = length(field)-1;
      _for i (0, last, 1)
        () + sp+"  " + field[i] + " = "
           + datatype_to_string(get_struct_field(val, field[i]); indent=indent)
	   + (i<last ? "," : "") + "\n";  % left on stack
      () + (fold ? "%}}}\n" : "") + sp + "}";  % left on stack
  }
  else if(type == Assoc_Type)
  {
      variable defval;
      "($0=Assoc_Type[" + string(_typeof(assoc_get_values(val)))
                        + (assoc_has_default_value(val, &defval) ? ", "+datatype_to_string(defval; indent=indent) : "")
	                + "]," + (fold ? " %{{{" : "") + "\n";  % left on stack
      variable key = assoc_get_keys(val);
      last = length(key)-1;
      _for i (0, last, 1)
        () + sp+`  $0["`+key[i]+`"] = `
           + datatype_to_string(val[key[i]]; indent=indent)
           + ",\n";  % left on stack
      () + (fold ? "%}}}\n" : "") + sp + "$0)";  % left on stack
  }
  else if(type == Char_Type)
      sprintf("typecast(%d,Char_Type)", val);  % left on stack
  else if(type == UChar_Type)
      sprintf(`'\x%02X'`, val);  % left on stack
  else if(type == Short_Type)  % == Int16_Type
      sprintf("%dH", val);  % left on stack
  else if(type == UShort_Type)  % == UInt16_Type
      sprintf("%dUH", val);  % left on stack
  else if(type == Long_Type)  % == Int32_Type
      sprintf("%dL", val);  % left on stack
  else if(type == ULong_Type)  % == UInt32_Type
      sprintf("%ldUL", val);  % left on stack
  else if(type == LLong_Type)  % == Int64_Type
      sprintf("%lldLL", val);  % left on stack
  else if(type == ULLong_Type)  % == UInt64_Type
      sprintf("%lldULL", val);  % left on stack
  else if(type == Float_Type)
      sprintf("%ff", val);  % left on stack
  else % (Void_Type, Null_Type, Double_Type, Complex_Type, DataType_Type)
      sprintf("%S", val);  % left on stack
}


%%%%%%%%%%%%%%%
define edit_var()
%%%%%%%%%%%%%%%
%!%+
%\function{edit_var}
%\synopsis{allows to edit S-Lang variables in an editor}
%\usage{edit_var(&x);
%\altusage{Any_Type y = edit_var(Any_Type x);}
%}
%\qualifiers{
%\qualifier{tmpfile}{temporary file [default: /tmp/edit_var_$UID_$PID]}
%}
%\description
%    edit_var supports the following data types:
%    - Undefined_Type (=Void_Type), Null_Type,
%    - Integer_Type, Double_Type, Complex_Type
%    - String_Type, BString_Type
%    as well as
%    - Array_Type
%    - Assoc_Type
%    - Struct_Type
%    - List_Type
%    in a recursive way. (Circular linked list
%    are currently not supported.)
%
%    S-Lang code defining the variable x is shown
%    in the editor specified by the EDITOR environ-
%    ment variable or jed, if EDITOR is undefined.
%    edit_var uses jed's folding mode (one should
%    run 'Buffers' => 'Folding' => 'Enable Folding')
%    for nested data structures, which can hence be
%    very easily investigated.
%
%    The S-Lang code for x can be modified. After
%    saving the temporary file and closing the editor,
%    the file is evaluated, which should return an
%    S-Lang object that is either stored in x
%    (if passed by reference) or returned.
%\example
%    \code{i = edit_var(struct { uc='A', s=1H, us=1UH, l=1L, ul=1UL, ll=1LL, ull=1ULL });}
%!%-
{
  variable x;
  switch(_NARGS)
  { case 1: x = (); }
  { help(_function_name()); return; }

  variable is_ref = (typeof(x)==Ref_Type);
  variable xx = ( is_ref ? @x : x );
  variable t = typeof(xx);

  variable tmpfile = qualifier("tmpfile", sprintf("/tmp/edit_var_%d_%d", getuid(), getpid()));
  variable fp = fopen(tmpfile, "w");
  ()=fputs("% -*- mode: SLang; mode: fold -*-\n\n"
	   +(t==List_Type ? "($0=" : "")
	   +datatype_to_string(xx)
	   +(t==List_Type ? ", $0)" : ""),
	   fp);
  ()=fclose(fp);

  variable e = getenv("EDITOR");  if(e==NULL)  e = "jed";
  if(system(e+" "+tmpfile))
    if(is_ref)  return;  else  return x;

  try(e)  ()=evalfile(tmpfile);  % S-Lang code produces return value that is left on stack
  catch AnyError:
  {
    vmessage(`"%s" exception:
%s
%s:%d`, e.descr, e.message, e.file, e.line);
    if(is_ref)  return;  else  return NULL;
  }
  finally ()=remove(tmpfile);

  if(is_ref)  @x = ();
}
