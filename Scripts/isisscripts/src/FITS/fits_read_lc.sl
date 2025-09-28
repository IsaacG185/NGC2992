%%%%%%%%%%%%%%%%%%%
define fits_read_lc()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_read_lc}
%\synopsis{reads a light curve file in FITS format}
%\usage{Struct_Type lc = fits_read_lc(String_Type filename[]);}
%\description
%     Reads light curves from \code{filename}, which can be
%     a globbing expression, an array of filenames or both.
%     If there are several light curves, they will be merged
%     into one data structure with ascending times.
%
%     The function assures that the returned structure contains
%     the fields \code{time}, \code{rate} and \code{error}.
%     The time field is always converted into Modified Julian Date
%     according to the MJDREF[{I,F}], TIMEUNIT and TIMEZERO keywords.
%\qualifiers{
%\qualifier{verbose}{show the filename of the light curves when reading more than one}
%\qualifier{cut}{cut all fields but time, rate, error}
%\qualifier{rate_per_PCU}{divide count rate for RXTE-PCA light curves
%                     by number of PCUs determined from the given filterfile
%                     (*.xfl, see 'RXTE_nr_PCUs_from_filterfile').}
%\qualifier{time}{[=\code{"time"}]: name of the time field, e.g., \code{"barytime"};
%                      if \code{!= "time"}, this field is renamed \code{"time"},
%                      overwriting any previously existing \code{time} field}
%\qualifier{time_in_s}{add structure fields for time in sec, MJDref
%                     and T0 to the output structure}
%\qualifier{filename}{add filename structure field}
%\qualifier{extension}{add number of extension to be read}
%}
%\seealso{fits_read_table, fits_read_key, fits_read_key_int_frac, RXTE_nr_PCUs_from_filename}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable lc;
  variable verbose = qualifier_exists("verbose");

  variable filenames = glob(filename);
  if(length(filenames)>1)
  { variable lcs = Struct_Type[0];
    foreach filename (filenames)
      lcs = [lcs, fits_read_lc(filename;; __qualifiers())];
    lc = merge_struct_arrays(lcs);
    struct_filter(lc, array_sort(lc.time));
    return lc;
  }

  if(length(filenames)==0)
  {
    vmessage("warning (%s): file(s) %s not found", _function_name(), filename);
    return struct { time=Double_Type[0], rate=Double_Type[0], error=Double_Type[0] };
  }
  else
    filename = filenames[0];

  % if qualifier for extension set, use it
  if(qualifier_exists("extension")) filename = filename+"+"+string(qualifier("extension"));

  % reading light curve
  if(verbose)  vmessage("reading %s", filename);
  lc = fits_read_table(filename);
  variable fieldnames = get_struct_field_names(lc);

  % maybe use another field for the times
  variable time_field_name = qualifier("time", "time");
  if(time_field_name!="time")
    if(all(fieldnames!=time_field_name))
      vmessage(`warning (%s): field name "%s" does not exist`, _function_name(), time_field_name);
    else {
      variable otime = all(fieldnames != "time") ? NULL : @lc.time; % keep original time array for #PCU determination
      lc = struct_combine(reduce_struct(lc, time_field_name),  % remove the old name of the time field we actually want to use
			  struct { time = get_struct_field(lc, time_field_name) }  % overwrite the field called 'time'
			 );
    }
  
  variable MJDref = fits_read_key_int_frac(filename, "MJDREF");
  if(MJDref==NULL)
  { MJDref = 0;
    if(verbose)
      vmessage("warning (%s): %s does not contain MJDREF[I,F] keyword[s].", _function_name(), filename);
  }

  variable T0 = fits_read_key_int_frac(filename, "TIMEZERO");
  if(T0==NULL)  T0 = 0;
  if(qualifier_exists("time_in_s"))
    % create extra structure fields if qualifier time_in_sec is set
    lc = struct_combine(lc, struct {
      time_in_s = lc.time,
      MJDref    = [MJDref:MJDref:#length(lc.time)],
      T0        = [  T0  :  T0  :#length(lc.time)]
    });

  if(qualifier_exists("filename"))
    lc = struct_combine(lc, struct {
      filename = [filename][Integer_Type[length(lc.time)]]  % Integer_Type[n] = [0, 0, ..., 0]  is here used as index-array
    });

  variable TIMEUNIT = fits_read_key(filename, "TIMEUNIT");
  if(TIMEUNIT==NULL && any(fieldnames=="time"))
    TIMEUNIT = fits_read_key(filename, "TUNIT"+string(wherefirst(fieldnames=="time")+1));
  if(TIMEUNIT!=NULL)
    TIMEUNIT = strlow(TIMEUNIT);
  switch( TIMEUNIT )
  { case "s": lc.time = MJDref + (T0+lc.time)/86400.; }
  { case "d":
      lc.time = MJDref +  T0+lc.time;
      if(qualifier_exists("time_in_s"))  lc.time_in_s *= 86400.;
  }
  { % else:
      vmessage(`warning (%s): %s contains unknown TIMEUNIT="%S", not converting time`, _function_name(), filename, TIMEUNIT);
  }

  variable TELESCOP = "???";
  if(fits_key_exists(filename, "TELESCOP")) TELESCOP = fits_read_key(filename, "TELESCOP");
  if(fits_key_exists(filename, "TELSCOP"))  TELESCOP = fits_read_key(filename, "TELSCOP");
  switch( strup(TELESCOP) )
  { case "XTE":  % lc = struct { time, rate, error, fracexp, deadc }
      if(qualifier_exists("rate_per_PCU"))
      {
	if (access(qualifier("rate_per_PCU"), F_OK) == 0) {
  	  lc = struct_combine(lc, struct { nr_PCUs = RXTE_nr_PCUs_from_filterfile(qualifier("rate_per_PCU"), otime) });
	  if(verbose)  vmessage(" -> %d-%d PCUs", min(lc.nr_PCUs), max(lc.nr_PCUs));
	  lc.rate  /= lc.nr_PCUs;
	  lc.error /= lc.nr_PCUs;
	} else { vmessage("warning (%s): given filterfile does not exist, number of PCUs not determined", _function_name); }
      }
  }
  { case "CHANDRA":  % lc = struct { time_bin, time_min, time, time_max, counts, stat_err, count_rate, count_rate_err, exposure }
      fieldnames[where(fieldnames=="count_rate")] = "rate";
      fieldnames[where(fieldnames=="count_rate_err")] = "error";
      lc = struct_combine(rename_struct_fields(lc, fieldnames), struct { fracexp = lc.exposure/(lc.time_max-lc.time_min) });
  }
  { case "SWIFT":  % lc = struct { time, rate, error, (fracexp) }
      ;
  }
  { case "INTEGRAL":  % lc = struct { time, tot_counts, backv, backe, rate, error, fracexp, barytime }
      ;
  }
  { case "XMM":
      if(all(fieldnames!="rate") && any(fieldnames=="counts"))
      { variable inv_dt = 1./(86400*(make_hi_grid(lc.time)-lc.time));
        lc = struct { time = lc.time,
  	              rate = lc.counts * inv_dt,
	              error = sqrt(lc.counts) * inv_dt
                    };
      }
  }
  { % else:
      if( not (any(fieldnames=="time") && any(fieldnames=="rate") && any(fieldnames=="error")) )
      { vmessage("error (%s): file %s (TELESCOP=%S) does not contain the columns time, rate and error", _function_name(), filename, TELESCOP);
        return NULL;
      }
  }
  if(qualifier_exists("cut"))
     return struct { time=lc.time, rate=lc.rate, error=lc.error };
  else
     return lc;
}
