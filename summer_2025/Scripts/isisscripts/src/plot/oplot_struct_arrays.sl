define oplot_struct_arrays()
%!%+
%\function{oplot_struct_arrays}
%\synopsis{overplots the fields of a structure agains each other}
%\usage{oplot_struct_arrays(Struct_Type s, String_Type fieldnameX, String_Type fieldnameY);}
%\qualifiers{
%\qualifier{xoffset}{}
%\qualifier{yoffset}{}
%}
%\description
%    \code{oplot(s.fieldnameX - xoffset,  s.fieldnameY - yoffset);}
%!%-
{
  variable s, fieldnameX, fieldnameY;
  switch(_NARGS)
  { case 3: (s, fieldnameX, fieldnameY)= (); }
  { help(_function_name()); return; }

  oplot(get_struct_field(s, fieldnameX)-qualifier("xoffset", 0),
        get_struct_field(s, fieldnameY)-qualifier("yoffset", 0));
}
