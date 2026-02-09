%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_write_pha_file()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_write_pha_file}
%\synopsis{writes a spectrum to an OGIP PHA file inserting the required header keywords}
%\usage{fits_write_pha_file(String_Type filename, Integer_Type data)}
%\altusage{fits_write_pha_file(String_Type filename, Array_Type data[, Array_Type stat_err])
%}
%
%\description
%    The 'filename' argument is the name of the output FITS file.
%
%    The 'data' argument can be either the index of a data set, in 
%    which case the isis data set is written to a file, 
%    an array containing the spectrum. 
%      If the array is of IntegerType, the spectrum contains total counts,
%      If the array is of FloatType/DoubleType, the spectrum is given in counts/s.
%    (DoubleType arrays will be type-casted to FloatType.) 
%
%    If 'data' is an array, then the statistical uncertainty is assumed
%    to be Poisson, unless the errors are given in the 3rd (optional) 
%    argument of the function, 'stat_err'. Note that this argument is
%    mandatory for the case of count rate spectra.
%    If 'data' is an index to a data set, then the errors are taken 
%    directly from the data set.
%
%\qualifiers{
%\qualifier{TELESCOP}{the "telescope" (mission/satellite name) ["unknown"]}
%\qualifier{INSTRUME}{the instrument/detector ["unknown"]}
%\qualifier{FILTER}{the instrument filter in use (if any) ["none"]}
%\qualifier{EXPOSURE}{the integration time (in seconds) for the PHA data
%                 (assumed to be corrected for deadtime, data drop-outs etc. ) [1.0]}
%\qualifier{AREASCAL}{nominal effective area [1.0]}
%\qualifier{BACKFILE}{the name of the corresponding background file (if any) ["none"]}
%\qualifier{BACKSCAL}{background scale factor [1.0]}
%\qualifier{CORRFILE}{the name of the corresponding correction file (if any) ["none"]}
%\qualifier{CORRSCAL}{the correction scaling factor [1.0]}
%\qualifier{RESPFILE}{the name of the corresponding (default) redistribution matrix file ["none"]}
%\qualifier{ANCRFILE}{the name of the corresponding (default) ancillary response file ["none"]}
%\qualifier{HDUCLASS}{should contain the string "OGIP" to indicate that this is an OGIP style file ["OGIP"]}
%\qualifier{HDUCLAS1}{should contain the string "SPECTRUM" to indicate this is a spectrum ["SPECTRUM"]}
%\qualifier{HDUCLAS2}{indicating the type of data stored: "TOTAL", "NET", "BKG" ["TOTAL"]}
%\qualifier{HDUVERS1}{the version number of the format ["1.2.1"]}
%\qualifier{CHANTYPE}{whether the channels used in the file have been corrected in anyway,
%                 values: "PHA" or "PI" (see also CAL/GEN/92-002, George et al. 1992, Section 7)
%                 ["PHA"]}
%\qualifier{start_channel}{start value of 'channel' column [1]}
%}
%
%   \seealso{Definition of PHA FITS format: OGIP/92-007 and OGIP/92-007a}
%!%-
{
    % Get the start value for the channel column. 
    % If this qualifier is not set the channel start at unity.
    variable start_channel = qualifier("START_CHANNEL", 1);
    
    % Set the required header keywords getting the values from the function qualifiers.
    variable keys = struct {
	% mandatory:
	TELESCOP = qualifier("TELESCOP"  , "unknown"),
	INSTRUME = qualifier("INSTRUME"  , "unknown"),
	FILTER   = qualifier("FILTER"    , "none"),
	EXPOSURE = qualifier("EXPOSURE"  , 1.0),
	AREASCAL = qualifier("AREASCAL"  , 1.0),
	BACKFILE = qualifier("BACKFILE"  , "none"),
	BACKSCAL = qualifier("BACKSCAL"  , 1.0),
	CORRFILE = qualifier("CORRFILE"  , "none"),
	CORRSCAL = qualifier("CORRSCAL"  , 1.0),
	RESPFILE = qualifier("RESPFILE"  , "none"),
	ANCRFILE = qualifier("ANCRFILE"  , "none"),
	HDUCLASS = qualifier("HDUCLASS"  , "OGIP"),
	HDUCLAS1 = qualifier("HDUCLAS1"  , "SPECTRUM"),
	HDUVERS  = qualifier("HDUVERS"   , "1.2.1"),
	CHANTYPE = qualifier("CHANTYPE"  , "PHA"),
	DETCHANS,
	% optional:
	CREATOR  = "{fits_write_pha_file} v{1.0.0}",
	HDUCLAS2 = qualifier("HDUCLAS2"  , "TOTAL"),
	HDUCLAS3 = "COUNTS",
	GROUPING = 0,
	% self-defined, leave only in for backwards compatibility
	AREAFILE = qualifier("AREAFILE"  , "none")
    };

    % Get the values of the function parameters:
    variable filename, data, stat_err,poisserr,staterr;
    switch(_NARGS) { 
       case 3:  % 'stat_err' is specified
	  (filename, data, stat_err) = ();
	  if (typeof(data)==Integer_Type) {
	      ()=fprintf(stderr,"stat_err argument is only allowed if data is an array.\n");
	      throw SyntaxError;
	  }
	  poisserr=0;  % false
	  staterr = 1;  % true
      }
      { 
	  case 2:  % 'stat_err' is not specified.
	  (filename, data) = ();
	  if (typeof(data)==Array_Type) {
	      poisserr=1; % true
	      staterr = 0;
	  }
      }

      % Wrong number of parameters: show help information
      { help(_function_name()); return; }

    % TODO: insert optional PHA header keywords


    % Define the data structure for the output to the FITS table:
    variable SPECTRUM = struct {CHANNEL, COUNTS};

    % If 'data' is just an integer number, obtain spectral
    % data from the loaded spectrum
    if (typeof(data) == Integer_Type)  {
	poisserr = 0;  % false
	staterr = 1;  % true

	variable indx=data;
	data = get_data_counts(indx);
	      
	if(qualifier_exists("Angstrom"))  {
	    keys = struct_combine(keys, struct { TUNIT3 = "Angstrom", TUNIT4 = "Angstrom" });
	} else {
	    data = _A(data);
	    keys = struct_combine(keys, struct { TUNIT3 = "keV", TUNIT4 = "keV" });
	}

	stat_err=data.err;
	
	SPECTRUM = struct_combine(SPECTRUM, struct { BIN_LO = data.bin_lo, BIN_HI = data.bin_hi });
	data = data.value;
	if(max(data mod 1)==0) data = typecast(data, Integer_Type);

	keys.EXPOSURE=qualifier("EXPOSURE",get_data_exposure(indx));
	keys.BACKSCAL=qualifier("BACKSCAL",get_data_backscale(indx));

	variable info=get_data_info(indx);

	% get instrument from arf since it is not set after a fakeit
	if (info.arfs[0]>0) {
	    keys.ANCRFILE=qualifier("ANCRFILE",get_arf_info(info.arfs[0]).file);
	    keys.INSTRUME=qualifier("INSTRUME",get_arf_info(info.arfs[0]).instrument);
	}
	if (info.rmfs[0]>0) {
	    keys.RESPFILE=qualifier("RESPFILE",get_rmf_info(info.rmfs[0]).arg_string);
	}
	% as an improvement we should add a qualifier that allows us to
	% also write the background assigned to a data set in the same step
	keys.BACKFILE=qualifier("BACKFILE",info.bgd_file);

    } else if (typeof(data) == Array_Type) {

	% If data is a floating point array, then we have
	% a rate spectrum and a spectral error column is
	% mandatory
	if ((typeof(data[0]) == Float_Type) || (typeof(data[0]) == Double_Type))  {
	    data = typecast(data, Float_Type);
	    keys = struct_combine(keys, struct {TTYPE2 = "RATE"});  
	    keys.HDUCLAS3 = "RATE";
	    if(poisserr) {
		()=fprintf(stderr,"Error: rate spectra cannot have Poisson errors\n");
		throw SyntaxError;
	    }
	} else if (typeof(data[0]) != Integer_Type) {
	    ()=fprintf(stderr, "Error: 'data' has unsupported data type (must be an array of either Float, Double, or Integer)!\n");
	    throw SyntaxError;
	}
    } else {
	()=fprintf(stderr, "Error:' data' must be either an array or an integer type!\n");
	throw SyntaxError;
    }
    SPECTRUM.COUNTS = data;

    if (staterr == 1) {
	if ((typeof(stat_err[0]) == Float_Type) || (typeof(stat_err[0]) == Double_Type)) {
	    stat_err = typecast(stat_err, Float_Type);
	    SPECTRUM=struct_combine(SPECTRUM,struct{STAT_ERR=stat_err});
	} else {
	    ()=fprintf(stderr, "Error: 'stat_err' has unsupported data type (must be an array of either Float, Double)!\n");
	    throw SyntaxError;
	}
    }

    % Set the first column of the spectrum table (PHA channels):
    keys.DETCHANS = length(data);   % number of channels
    SPECTRUM.CHANNEL = start_channel + [0:keys.DETCHANS-1];
    % Append TLMINnnn and TLMAXnnn keywords if channel does NOT start with unity:
    if (start_channel != 1) {
	keys = struct_combine(keys, 
	struct { TLMIN001 = start_channel, 
	TLMAX001 = start_channel+keys.DETCHANS-1 }
	);
    }

    % Write the spectrum to the FITS file:
    fits_write_binary_table(filename, "SPECTRUM", SPECTRUM, keys);

    % update logicals (I do not know an easier way)
    variable fd=fits_open_file(filename,"w");
    fits_movabs_hdu(fd,2); % 1st extension is the spectrum
    fits_update_logical(fd,"POISSERR",poisserr,"Poisson errors appropriate?");
    fits_update_logical(fd,"STAT_ERR",staterr,"Assume statistical errors?");
    fits_update_key(fd,"SYS_ERR",0.0,"no global systematic error");
    fits_close_file(fd);
}
