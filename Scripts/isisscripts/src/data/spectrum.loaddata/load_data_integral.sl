define load_data_integral()
%!%+
%\function{load_data_integral}
%\synopsis{reads an INTEGRAL spectrum from a PHA file and performs the necessary tweaks}
%\usage{Integer_Type id = load_data_integral(String_Type pha_filename);}
%\description
%    ISIS's load_data often does not work with INTEGRAL spectra for the following reasons:\n
%    - The extension of the PHA file is not called 'SPECTRUM'.\n
%    - The extensions of the RMF file are not called 'MATRIX' and 'EBOUNDS'.\n
%    - The extension of the ARF file is not called 'SPECRESP'.\n
%    - The columns ENERG_LO and ENERG_HI of the ARF file contain only zeros.\n
%    The function load_data_integral tries to make the appropriate changes
%    (modify the extension names, write a new ARF file) and finally uses load_data.
%\qualifiers{
%\qualifier{verbose}{[=1] show changes}
%}
%\seealso{load_data}
%!%-
{
  variable phafile;
  switch(_NARGS)
  { case 1: phafile = (); }
  { help(_function_name()); }

  variable verbose = qualifier("verbose", 1);

  % correct name of the PHA-file's SPECTRUM extension
  variable EXTNAME, newEXTNAME, F = fits_open_file(phafile, "w");
  ()=_fits_movabs_hdu(F, 1);
  do
  { EXTNAME = fits_read_key(F, "EXTNAME");
    if(any(["ISGR-PHA1-SPE", "JMX1-PHA1-SPE", "JMX2-PHA1-SPE", "SPI.-PHA1-SPE"] == EXTNAME))
    { newEXTNAME = "SPECTRUM";
      ()=_fits_update_key(F, "EXTNAME", newEXTNAME, "name of the binary extension [updated]");
      ()=_fits_write_history(F, "EXTNAME "+EXTNAME+" was updated by ISIS:"+_function_name());
      if(verbose)
	vmessage("%s: changing extension name of %s from '%s' to '%s'", _function_name(), phafile, EXTNAME, newEXTNAME);
    }
  } while(_fits_movrel_hdu(F, 1)==0);
  fits_close_file(F);

  %%vg: if data loaded not from directory with data, but by giving an
  %%(absolute) path to the data, take care of the path to be used for
  %%RESPONDE and ARF
  %%BUT: don't have to do it, if absolute pathes are already given
  variable path;
  variable pathparts = strchop(phafile,'/',0);
  if (length(pathparts) == 1) {
    path = "";
  }
  else {    
    path = strjoin(pathparts[[0:length(pathparts)-2]],"/")+"/";
  }

  variable ok;
  variable RESPFILE = fits_read_key(phafile+"[SPECTRUM]", "RESPFILE");
  ifnot (strncmp(RESPFILE,"/",1)==0) {RESPFILE = path+RESPFILE;};
  if(RESPFILE!=NULL && RESPFILE!="NONE")
  { % correct name of the RMF-file's MATRIX/EBOUNDS extensions
    ok = 1;
    try { F = fits_open_file(RESPFILE, "w"); }
    catch FitsError: { ok = 0; vmessage("warning (%s): FITS error while opening %s in 'w' mode (Do you have write permission?)", _function_name(), RESPFILE); }
    if(ok)
    {
      ()=_fits_movabs_hdu(F, 1);
      do
      { EXTNAME = fits_read_key(F, "EXTNAME");
        if(any(["ISGR-RMF.-RSP",
		"JMX1-RMF.-RSP", "JMX2-RMF.-RSP",
		"SPI.-RMF.-RSP",
		"COMP-SRMF-RSP"] == EXTNAME))
        { newEXTNAME = "MATRIX";  % "SPECRESP MATRIX" ?
  	  ()=_fits_update_key(F, "EXTNAME", newEXTNAME, "name of the binary extension [updated]");
          ()=_fits_write_history(F, "EXTNAME "+EXTNAME+" was updated by ISIS:"+_function_name());
          if(verbose)
  	    vmessage("%s: changing extension name of %s from '%s' to '%s'", _function_name(), RESPFILE, EXTNAME, newEXTNAME);
        }
        if(any(["ISGR-EBDS-MOD",
		"JMX1-FBDS-MOD", "JMX2-FBDS-MOD",
		"SPI.-EBDS-SET",
		"COMP-SEBD-MOD"] == EXTNAME))
        { newEXTNAME = "EBOUNDS";
  	  ()=_fits_update_key(F, "EXTNAME", newEXTNAME, "name of the binary extension [updated]");
          ()=_fits_write_history(F, "EXTNAME "+EXTNAME+" was updated by ISIS:"+_function_name());
          if(verbose)
	    vmessage("%s: changing extension name of %s from '%s' to '%s'", _function_name(), RESPFILE, EXTNAME, newEXTNAME);
        }
      } while(_fits_movrel_hdu(F, 1)==0);
      fits_close_file(F);
    }
  }

  variable ANCRFILE = path+fits_read_key(phafile, "ANCRFILE");
  ifnot (strncmp(ANCRFILE,"/",1)==0) {ANCRFILE = path+ANCRFILE;};
  if(ANCRFILE!=NULL && ANCRFILE!="NONE")
  { % correct name of the ARF-file's EBOUNDS extensions
    ok = 1;
    try { F = fits_open_file(ANCRFILE, "w"); }
    catch FitsError: { ok = 0; vmessage("warning (%s): FITS error while opening %s in 'w' mode (Do you have write permission?)", _function_name(), ANCRFILE); }
    if(ok)
    {
      ()=_fits_movabs_hdu(F, 1);
      do
      { EXTNAME = fits_read_key(F, "EXTNAME");
        if(any(["ISGR-ARF.-RSP",
		"JMX1-AXIS-ARF", "JMX2-AXIS-ARF",
		"COMP-SARF-RSP"] == EXTNAME))
        { newEXTNAME = "SPECRESP";
  	  ()=_fits_update_key(F, "EXTNAME", newEXTNAME, "name of the binary extension [updated]");
          ()=_fits_write_history(F, "EXTNAME "+EXTNAME+" was updated by ISIS:"+_function_name());
          if(verbose)
  	    vmessage("%s: changing extension name of %s from '%s' to '%s'", _function_name(), ANCRFILE, EXTNAME, newEXTNAME);
        }
      } while(_fits_movrel_hdu(F, 1)==0);
      fits_close_file(F);

      variable arf = fits_read_table(ANCRFILE);
      if(max(arf.energ_lo)==0)
      { if(verbose)
          vmessage("%s: changing %s due to zero-columns ENERG_LO and ENERG_HI", _function_name(), ANCRFILE);
        (arf.energ_lo, arf.energ_hi) = fits_read_col(RESPFILE+"[MATRIX]", "energ_lo", "energ_hi");
        variable oldANCRFILE = ANCRFILE+".old";
        ()=rename(ANCRFILE, oldANCRFILE);
        F = fits_open_file(ANCRFILE, "c");
        variable Fold = fits_open_file(oldANCRFILE, "r");
        ()=_fits_movabs_hdu(Fold, 1);
        ()=_fits_copy_header(Fold, F);
        ()=_fits_movabs_hdu(Fold, 2);
        variable records = fits_read_records(Fold);
        fits_write_binary_table(F, newEXTNAME, arf);
        ()=_fits_movabs_hdu(F, 2);
        fits_write_records(F, records);
        fits_close_file(F);
       fits_close_file(Fold);
      }
    }
  }

  variable OGIPcomp = Rmf_OGIP_Compliance;
  Rmf_OGIP_Compliance = 0;
  variable id = load_data(phafile);
  Rmf_OGIP_Compliance = OGIPcomp;

  set_rebin_error_hook(id, "rebin_error_hook");

  return id;
}
