define sort_struct_arrays()
%!%+
%\function{sort_struct_arrays}
%\usage{Struct_Type sort_struct_arrays(Struct_Type s, String_Type fieldname);}
%!%-
{
  variable s, fieldname;
  switch(_NARGS)
  { case 2: (s, fieldname)= (); }
  { help(_function_name()); return; }

  return struct_filter(s, array_sort(get_struct_field(s, fieldname)); copy);

%  variable i = array_sort(get_struct_field(s, fieldname));
%  variable sorted_s = @s;
%  foreach fieldname (get_struct_field_names(s))
%  { set_struct_field(sorted_s, fieldname, get_struct_field(s, fieldname)[i]); }
%  return sorted_s;
}
