define RXTE_nr_PCUs_from_filename()
%!%+
%\function{RXTE_nr_PCUs_from_filename}
%\synopsis{counts how many PCUs were off from an *_xyoff_excl_* filename}
%\usage{Integer_Type RXTE_nr_PCUs_from_filename(String_Type filename)}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable part = strtok(filename, "_\.");
  return min([5, 6-string_match(part[wherefirst(part=="excl")-1], "off", 1)]);
  % string_match("<p1><p2>...<pn>off", "off", 1) == n+1
}
