define append_struct_arrays()
%!%+
%\function{append_struct_arrays}
%\synopsis{appends a structure's fields to another structures's fields}
%\usage{append_struct_arrays(Struct_Type &s, Struct_Type additional_s[]);}
%\description
%    \code{s} and \code{additional_s} have to be structures with the same fields.
%    \code{s}, which is changed by this function, has to be passed by reference.
%    For every \code{field},\n
%       \code{s.field = [s.field, additional_s.field];}\n
%    The following two statements are equivalent:\n
%       \code{append_struct_arrays(&s, additional_s);}\n
%       \code{s = merge_struct_arrays( [s, additional_s] );}
%\seealso{merge_struct_arrays}
%!%-
{
  variable s, additional_s;
  switch(_NARGS)
  { case 2: (s, additional_s) = (); }
  { help(_function_name()); return; }

  if(@s==NULL) { @s = additional_s; return; }
  @s = merge_struct_arrays( [@s, additional_s] );
}
