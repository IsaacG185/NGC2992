define create_struct_field()
%!%+    
%\function{create_struct_field}
%\synopsis{create and set the value associated with a structure field}
%\usage{Struct_Type create_struct_field(s, field_name, field_value);}
%\qualifiers{
%    \qualifier{skip}{do not update an existing field}
%}
%\description
%    Does the same as the `set_struct_field' function except
%    that the given field is created first if it does not
%    exist.
%\seealso{set_struct_field, struct_combine}
%!%-
{
  variable s, field, value;
  switch (_NARGS)
  { case 3: (s, field, value) = (); }
  { help(_function_name); }

  if (qualifier_exists("skip") and struct_field_exists(s, field)) { return s; }
  s = struct_combine(s, field);
  set_struct_field(s, field, value);
  return s;
}
