%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define set_par_from_confmap_table()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_par_from_confmap_table}
%\synopsis{set parameters from a table obtained by get_confmap}
%\usage{set_par_from_confmap_results(Struct_Type table, Integer_Type i);}
%\description
%    The function sets the parameters of \code{table}'s row \code{i}.
%    As parameter names are infered from column names, the FITS
%    table may have to be read with the \code{casesen} qualifier.
%\seealso{get_confmap}
%!%-
{
  variable table, i;
  switch(_NARGS)
  { case 2: (table, i) = (); }
  { return help(_function_name()); }

  variable field;
  foreach field (get_struct_field_names(table)[[:-2]])
  {
    variable part = strtok(field, "_");
    variable par = "";
    while(not('0' <= part[0][-1] <= '9'))
    {
      par += part[0]+"_";
      part = part[[1:]];
    }
    variable m = string_matches(part[0], `\(.*\)\(\d+\)`);
    par = sprintf("%s%s(%s).%s", par, m[1], m[2], part[1]);
    variable val = get_struct_field(table, field)[i];
    vmessage(`set_par("%s", %S);`, par, val);
    try { set_par(par, val); }
    catch AnyError: ;
  }
}
