require("xspec"); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define switch_tbnew_rel_abund()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{switch_tbnew_rel_abund}
%\usage{switch_tbnew_rel_abund([String_Type parnames]);}
%\description
%    Unless one or more \code{parnames} are given, all elements are switched.
%\qualifiers{
%\qualifier{inst}{[=1] instance of tbnew}
%\qualifier{verbose}{}
%}
%!%-
{
  variable parnames;
  switch(_NARGS)
  { case 0: parnames = "tbnew(" + string(qualifier("inst", 1)) + ")."
                       + ["He", "C", "N", "O", "Ne", "Na", "Mg", "Al", "Si", "S", "Cl", "Ar", "Ca", "Cr", "Fe", "Co", "Ni"]; }
  { case 1: parnames = (); }
  { help(_function_name()); return; }

  parnames = [parnames];
  variable parname_parts = strtok(parnames[0], ".");
  variable NH = get_par(parname_parts[0] + ".nH");
  if(NH>0)  NH *= -1e22;

  if(qualifier_exists("verbose"))
  {
    message("% before switching:");
    list_Par(parnames);
  }
  variable parname;
  foreach parname (parnames)
  { variable parinfo = get_par_info(parname);
    $1 = NH*xspec_elabund(strtok(parname, ".")[1]);
    if(parinfo.value<0)  $1 = 1./$1;
    set_par(parname, parinfo.value*$1, parinfo.freeze, parinfo.max*$1, parinfo.min*$1);
  }
  if(qualifier_exists("verbose"))
  {
    message("\n% after switching:");
    list_Par(parnames);
  }
}

