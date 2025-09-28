%%%%%%%%%%%%%%%%%%%%%%%%%%%
define rename_struct_fields()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{rename_struct_fields}
%\usage{Struct_Type new_s = rename_struct_fields(Struct_Type s, String_Type fieldnames[]);}
%!%-
{
  variable s, fieldnames;
  switch(_NARGS)
  { case 2: (s, fieldnames) = (); }
  { help(_function_name()); return; }

  if(length(get_struct_field_names(s)) != length(fieldnames))
  { message("error ("+_function_name()+"): The number of field names is not the same.");
    return;
  }

  variable new_s = @Struct_Type(fieldnames);
  set_struct_fields(new_s, get_struct_fields(s, __push_array(get_struct_field_names(s))));
  return new_s;
}
