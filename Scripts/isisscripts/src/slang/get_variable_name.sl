%%%%%%%%%%%%%%%
define get_variable_name()
%%%%%%%%%%%%%%%
%!%+
%\function{get_variable_name}
%\synopsis{returns the namespace and name of a given reference}
%\usage{(namespace, name) = get_variable_name(&var);}
%\description
%    The name of the variable or function the given
%    reference points to will be returned as a string.
%    The namespace where it is defined is returned as
%    well. In case of a private namespace, however,
%    NULL will be returned instead.
%\seealso{current_namespace}
%!%-
{
  variable ref;
  switch (_NARGS)
    { case 1: ref = (); }
    { help(_function_name); return; }

  if (typeof(ref) != Ref_Type) { vmessage("error: given argument has to be a reference"); return; }

  % convert reference to variable name (eventually including the namespace)
  variable name = string_matches(string(ref), "^&\(.*\)$"R);
  if (name == NULL) { return (NULL, NULL); }
  else { name = name[1]; }
  % extract the namespace (may be undefined -> private)
  variable match = string_matches(name, "^\(.*\)->\(.*\)$"R);
  
  if (match == NULL) { return (NULL, name); }
  else { return (match[1], match[2]); } 
}
