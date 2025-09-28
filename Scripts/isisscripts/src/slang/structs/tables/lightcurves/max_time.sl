define max_time()
%!%+
%\function{max_time}
%\synopsis{finds the latest time in an array of structures with a time field}
%\usage{Double_Type tmax = max_time(Struct_Type structs[]);}
%\description
%    \code{structs} is an array of structures containing the field \code{time}.
%    \code{tmax} is computed in the following way:\n
%    \code{tmax = max( array_map(Double_Type, &max, array_map(Array_Type, &get_struct_field, [structs], "time")) );}
%\seealso{min_time, min_struct_field, max_struct_field}
%!%-
{
  variable structs;
  switch(_NARGS)
  { case 1: structs = (); }
  { help(_function_name()); return; }

  return max( array_map(Double_Type, &max, array_map(Array_Type, &get_struct_field, [structs], "time")) );
}
