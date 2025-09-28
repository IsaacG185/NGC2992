%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define ext_info_string_PGPLOT()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ext_info_string_PGPLOT}
%\synopsis{converts the ext_line_info into a PGPLOT string}
%\usage{String_Type ext_info_string_PGPLOT(Struct_Type info)}
%\seealso{ext_line_info, ext_info_string}
%!%-
{
  variable info;
  switch(_NARGS)
  { case 1:  info = (); }
  { help(_function_name()); return; }

  return ext_info_string(info, 1);
}
