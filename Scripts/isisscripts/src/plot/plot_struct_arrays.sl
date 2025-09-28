define plot_struct_arrays()
%!%+
%\function{plot_struct_arrays}
%\synopsis{plots the fields of a structure agains each other}
%\usage{plot_struct_arrays(Struct_Type s, String_Type fieldnameX, String_Type fieldnameY);}
%\qualifiers{
%\qualifier{xoffset}{}
%\qualifier{yoffset}{}
%}
%\description
%    \code{plot(s.fieldnameX - xoffset,  s.fieldnameY - yoffset);}
%!%-
{
  variable s, fieldnameX, fieldnameY;
  switch(_NARGS)
  { case 3: (s, fieldnameX, fieldnameY)= (); }
  { help(_function_name()); return; }

  plot(get_struct_field(s, fieldnameX)-qualifier("xoffset", 0),
       get_struct_field(s, fieldnameY)-qualifier("yoffset", 0));
}
