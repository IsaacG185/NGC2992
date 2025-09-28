define struct_fields_list_to_array()
%!%+
%\function{struct_fields_list_to_array}
%\synopsis{convert all fields of a structure from lists to arrays}
%\usage{struct_fields_list_to_array(Struct_Type s[, DataType_Type t]);}
%\seealso{list_to_array}
%!%-
{
  variable s, t=NULL;
  switch(_NARGS)
  { case 1: s = (); }
  { case 2: (s, t) = (); }
  { return help(_function_name()); }

  if(typeof(s)!=Struct_Type)
    return vmessage("error (%s): expecting Struct_Type, found %S", _function_name(), typeof(s));

  variable n;
  foreach n (get_struct_field_names(s))
  {
    variable v = get_struct_field(s, n);
    if(typeof(v)==List_Type)
      set_struct_field(s, n, list_to_array(t==NULL ? v : (v, t)));
  }
}
