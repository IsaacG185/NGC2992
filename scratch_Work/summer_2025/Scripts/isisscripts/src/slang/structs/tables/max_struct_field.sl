%%%%%%%%%%%%%%%%%%%%%%%
define max_struct_field()
%%%%%%%%%%%%%%%%%%%%%%%
%!+
%\function{max_struct_field}
%\synopsis{returns the maximal field value of an array of structures}
%\usage{Double_Type mx = max_struct_field(Struct_Type structs[], String_Type fieldname);}
%\description
%    \code{structs} is an array of structures containing the field called \code{fieldname}.
%    \code{mx} is computed in the following way:\n
%    \code{mx = max( array_map(Double_Type, &max, array_map(Array_Type, &get_struct_field, [structs], fieldname)) );}
%\seealso{min_struct_field, min_time, max_time}
%!%-
{
  variable structs, fieldname;
  switch(_NARGS)
  { case 2: (structs, fieldname) = (); }
  { help(_function_name()); return; }

  return max( array_map(Double_Type, &max, array_map(Array_Type, &get_struct_field, [structs], fieldname)) );
}
