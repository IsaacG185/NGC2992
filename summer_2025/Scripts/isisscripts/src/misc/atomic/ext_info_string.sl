define ext_info_string()
%!%+
%\function{ext_info_string}
%\synopsis{converts the ext_line_info into a string}
%\usage{String_Type ext_info_string(Struct_Type info[, Integer_Type format])}
%\description
%    format=0 => string [default] \n
%    format=1 => PGPLOT \n
%    format=2 => TeX
%\seealso{ext_line_info, ext_info_string}
%!%-
{
  variable info, format=0;
  switch(_NARGS)
  { case 1:  info = (); }
  { case 2:  (info, format) = (); }
  { print("usage: ext_info_string(info[, format]); format = 0->string, 1->PGPLOT, 2->TeX"); return; }

  if(info != NULL)
  {
    variable type = ext_line_type(info.nr, format);
    if(type != NULL)
    {
      if(info.ion>0)
      { return atom_name(info.Z) + " " + Roman(info.ion) + " " + type; }
      else
      { return atom_name(info.Z) + type; }
    }
  }
  return NULL;
}
