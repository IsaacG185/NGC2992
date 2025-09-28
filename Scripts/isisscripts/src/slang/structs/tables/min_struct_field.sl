%%%%%%%%%%%%%%%%%%%%%%%
define min_struct_field()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{min_struct_field}
%\synopsis{returns the minimal field value of an array of structures}
%\usage{Double_Type mn = min_struct_field(Struct_Type structs[], String_Type fieldname);}
%\description
%    \code{structs} is an array of structures containing the field called \code{fieldname}.
%    \code{mn} can be computed in the following way:\n
%    \code{mn = min( array_map(Double_Type, &min, array_map(Array_Type, &get_struct_field, [structs], fieldname)) );}
%\seealso{max_struct_field, min_time, max_time}
%!%-
{
  variable structs, fieldname;
  switch(_NARGS)
  { case 2: (structs, fieldname) = (); }
  { help(_function_name()); return; }

  return min( array_map(Double_Type, &min, array_map(Array_Type, &get_struct_field, [structs], fieldname)) );
}
