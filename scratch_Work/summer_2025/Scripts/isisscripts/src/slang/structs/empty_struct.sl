define empty_struct()
%!%+
%\function{empty_struct}
%\synopsis{Returns a struct with 0 fields}
%\usage{ Struct_Type = empty_struct();}
%\description
%  This function returns a struct with 0 fields,
%  which is usable with other funtions, e.g.,
%  struct_field_exists.
%!%-
{
  return @Struct_Type(String_Type[0]);
}
