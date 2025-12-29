%%%%%%%%%%%%%%%%%%%
define RXTE_obscat_info()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{RXTE_obscat_info}
%\synopsis{reads an RXTE human-readable obs(ervation)cat(alogue)}
%\usage{Struct_Type RXTE_obscat_info(Integer_Type obscat_days[]);}
%\seealso{aitlib/rxte/readobscat.pro}
%!%-
{
  variable days;
  switch(_NARGS)
  { case 1: days = (); }
  { help(_function_name()); return; }

  variable verbose = qualifier_exists("verbose");

  % find local path
  variable path = NULL;
  try {
    foreach path ([local_paths.RXTE_obscat])
      if(stat_file(path)!=NULL)  break;
  } catch NotImplementedError: { vmessage("error (%s): local_paths.RXTE_obscat not defined",_function_name()); return NULL; };

  % return structure
  variable info = struct {
%   start_slew = Double_Type[0],
%     end_slew = Double_Type[0],
     in_occult = Double_Type[0],
    out_occult = Double_Type[0],
        in_saa = Double_Type[0],
       out_saa = Double_Type[0],
    start_good = Double_Type[0],
      end_good = Double_Type[0],
  };

  variable MJDREF = 49353.000696574074;
  variable mode = -1;
  variable day;
  foreach day ([days])
  { variable file = sprintf("%s/OCday%04d", path, day);
    if(stat_file(file)==NULL)
      vmessage("warning (%s): %s does not exist", _function_name(), file);
    else
    { if(verbose)  vmessage("reading %s", file);
      variable unit = fopen(file, "r");
      variable line;
      if(unit!=NULL)
      { while(not feof(unit) && fgets(&line, unit)>0)
	{ variable modstr = line[[0:8]];
	  if(modstr != "         ")  mode = modstr;
	  switch( mode )
          { case "  EVENTS:":
	      variable when = MJDREF + atof(line[[34:43]])/86400.;
  	      switch( line[[10:19]] )
%	      { case "start_slew":
%		  if(length(info.start_slew) > length(info.end_slew))
%		    info.start_slew[-1] = when;
%		  else
%		    info.start_slew = [info.start_slew, when];
%	      }
%	      { case "end_slew  ":
%		  info.end_slew = [info.end_slew, when];
%	      }
	      { case "in_occult ":
		  if(length(info.in_occult) > length(info.out_occult))
		    info.in_occult[-1] = when;
		  else
		    info.in_occult = [info.in_occult, when];
	      }
	      { case "out_occult":
		  info.out_occult = [info.out_occult, when];
	      }
	      { case "in_saa    ":
		  if(length(info.in_saa) > length(info.in_saa))
		    info.in_saa[-1] = when;
		  else
		    info.in_saa = [info.in_saa, when];
	      }
	      { case "out_saa   ":
		  info.out_saa = [info.out_saa, when];
		  % hack for missing 'in_saa'-tag in some obscats
		  if(length(info.in_saa)<length(info.out_saa))
		    info.out_saa = [info.out_saa, when];
	      }
	  }
	  { case "GOODTIME:":
	      info.start_good = [info.start_good, MJDREF + atof(line[[20:29]])/86400.];
	      info.end_good   = [info.end_good,   MJDREF + atof(line[[45:54]])/86400.];
	  }
	}
	()=fclose(unit);
      }
    }
  }

% info.start_slew = info.start_slew[[:length(info.end_slew)-1]];
  info.in_occult = info.in_occult[[:length(info.out_occult)-1]];
  info.in_saa = info.in_saa[[:length(info.out_saa)-1]];
  return info;
}
