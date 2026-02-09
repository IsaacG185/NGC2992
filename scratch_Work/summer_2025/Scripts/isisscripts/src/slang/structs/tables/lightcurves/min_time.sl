define min_time()
%!%+
%\function{min_time}
%\synopsis{finds the earliest time in an array of structures with a time field}
%\usage{Double_Type tmin = min_time(Struct_Type structs[]);}
%\description
%    \code{structs} is an array of structures containing the field \code{time}.
%    \code{tmin} is computed in the following way:\n
%    \code{tmin = min( array_map(Double_Type, &min, array_map(Array_Type, &get_struct_field, [structs], "time")) );}
%\seealso{max_time, min_struct_field, max_struct_field}
%!%-
{
  variable structs;
  switch(_NARGS)
  { case 1: structs = (); }
  { help(_function_name()); return; }

  return min( array_map(Double_Type, &min, array_map(Array_Type, &get_struct_field, [structs], "time")) );
}
