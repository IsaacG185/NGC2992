define RXTE_PCA_modes()
%!%+
%\function{RXTE_PCA_modes}
%\usage{RXTE_PCA_modes(String_Type obsids);}
%\qualifiers{
%\qualifier{compact}{only one row per ObsID, omit TSTART, TSTOP and duration}
%\qualifier{get_struct}{return information on PCA modes in a structure, too}
%\qualifier{quiet}{do not show information, implies \code{get_struct}}
%}
%\description
%    Reads RXTE-PCA data modes from the PCA FITS-index (FIPC) file.
%    The location of the RXTE data archive is determined from the
%    \code{local_paths.RXTE_data} variable (defined within the isisscripts).
%!%-
{
  variable path_to_data = NULL;
  try {
    foreach path_to_data ([local_paths.RXTE_data])
      if(stat_file(path_to_data)!=NULL)
        break;
  } catch NotImplementedError: { vmessage("warning (%s): local_paths.RXTE_PCA_modes not defined",_function_name()); };
  if(path_to_data == NULL)
  { vmessage("error (%s): no path to RXTE data found", _function_name());
    return;
  }

  variable dir=NULL, obsid;
  switch(_NARGS)
  { case 0: dir = getcwd(); }
  { case 1: obsid = (); }

  variable quiet = qualifier_exists("quiet");
  variable get_struct = qualifier_exists("get_struct") or quiet;

  variable PCAmodes;
  if(typeof(obsid)==Array_Type)
  {
    variable i, n = length(obsid);
    PCAmodes = Struct_Type[n];
    _for i (0, n-1, 1)
      PCAmodes[i] = RXTE_PCA_modes(obsid[i];; struct_combine(__qualifiers(), "quiet", "get_struct"));
    PCAmodes = merge_struct_arrays(PCAmodes);
    ifnot(quiet)  print_struct(PCAmodes);
    if(get_struct)
      return PCAmodes;
    else
      return;
  }

  if(dir==NULL)
  { variable AO = obsid[[0]];
    variable prop = string_matches(obsid, `\([0-9]*\)-`, 1)[1];
    if(AO=="9")  AO = string( 9 + integer(obsid[[1]]) );
    dir = path_to_data + "/AO" + AO + "/P" + prop + "/" + obsid;
  }

  variable FIPCfiles = glob(dir+"/FIPC_*");
  PCAmodes = struct { ObsID, TSTART, TSTOP, duration, EA1mode, EA2mode, EA3mode, EA5mode, EA6mode, EA7mode };
  if(length(FIPCfiles)==0)
  { message("warning ("+_function_name()+"): no FIPC file in "+dir);
    set_struct_fields(PCAmodes, String_Type[0], Integer_Type[0], dup(), dup(), String_Type[0], dup(), dup(), dup(), dup(), dup());
  }
  else
  {
    variable PCAindex = fits_read_table(FIPCfiles[0]);
    set_struct_fields(PCAmodes, PCAindex.obsid, PCAindex.beginmet, PCAindex.endmet,
                                PCAindex.endmet-PCAindex.beginmet,
		                PCAindex.ea1modenm, PCAindex.ea2modenm, PCAindex.ea3modenm, PCAindex.ea5modenm, PCAindex.ea6modenm, PCAindex.ea7modenm);
    if(qualifier_exists("compact"))
    {
      variable i1 = wherefirst(PCAmodes.EA1mode!=" ");  i1 = (i1 ? i1 : 0);   % if wherefirst == NULL (== 0 in a boolean context), set i to 0
      variable i2 = wherefirst(PCAmodes.EA2mode!=" ");  i2 = (i2 ? i2 : 0);
      variable i3 = wherefirst(PCAmodes.EA3mode!=" ");  i3 = (i3 ? i3 : 0);
      variable i5 = wherefirst(PCAmodes.EA5mode!=" ");  i5 = (i5 ? i5 : 0);
      variable i6 = wherefirst(PCAmodes.EA6mode!=" ");  i6 = (i6 ? i6 : 0);
      variable i7 = wherefirst(PCAmodes.EA7mode!=" ");  i7 = (i7 ? i7 : 0);
      PCAmodes = struct {
        ObsID   = [PCAmodes.ObsID[0]],
        EA1mode = [PCAmodes.EA1mode[i1]],
        EA2mode = [PCAmodes.EA2mode[i2]],
        EA3mode = [PCAmodes.EA3mode[i3]],
        EA5mode = [PCAmodes.EA5mode[i5]],
        EA6mode = [PCAmodes.EA6mode[i6]],
        EA7mode = [PCAmodes.EA7mode[i7]],
      };
    }
    ifnot(quiet)  print_struct(PCAmodes);
  }

  if(get_struct)
    return PCAmodes;
}
