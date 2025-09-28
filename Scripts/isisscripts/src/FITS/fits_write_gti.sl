%%%%%%%%%%%%%%%%%%%%%
define fits_write_gti()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_write_gti}
%\synopsis{creates a FITS file with good time intervals}
%\usage{fits_write_gti(String_Type filename, Struct_Type gti, Double_Type MJDref);
%\altusage{fits_write_gti(String_Type filename, Double_Type start[], stop[], MJDref);}
%}
%\qualifiers{
%\qualifier{creator}{[\code{="isisscripts:fits_write_gti"}] (XMM SAS needs an arbitrary value)}
%\qualifier{date}{[\code{="1998-JAN-01"}] (XMM SAS needs an arbitrary value)}
%\qualifier{combineGTIs}{[\code{=1}]: combine intervals that adjoin each other}
%\qualifier{verbose}{[\code{=1}]: tell when intervals are combined}
%}
%\description
%     Good time intervals are organized as \code{gti} structures
%     containing arrays \code{START} and \code{STOP} of the corresponding times,
%     usually measured in s since the reference date \code{MJDref}.
%     (If \code{MJDref} is a string, the date is read from this file.)
%     Intervals that adjoin each other are combined.
%
%     The header keywords \code{creator} and \code{date} (according to the qualifiers)
%     are written to the primary header of the created FITS file.
%\seealso{fits_write_binary_table}
%!%-
{
  variable filename, gti, start, stop, MJDref;
  switch(_NARGS)
  { case 3: (filename, gti, MJDref) = (); }
  { case 4: (filename, start, stop, MJDref) = ();
            gti = struct { START=[start], STOP=[stop] };
  }
  { help(_function_name()); return; }

  variable fields = get_struct_field_names(gti);
  if(fields[0]=="start" && fields[1]=="stop")
    gti = struct { START=gti.start, STOP=gti.stop };  % for XMM SAS
  if(typeof(MJDref)==String_Type)
    MJDref = fits_read_key_int_frac(MJDref, "MJDREF");

  % sort GTIs by time
  struct_filter(gti, array_sort(gti.START));

  variable n = length(gti.START);
  if(qualifier("combineGTIs", 1) && n>0)
  { % combine intervals that adjoin each other
    start = { gti.START[0] };  % start with
    stop  = { gti.STOP[0] };   % first interval
    variable i;
    _for i (1, length(gti.START)-1, 1)
      if(gti.STOP[i-1] == gti.START[i])
        stop[-1] = gti.STOP[i];  % enlarge last interval
      else
        list_append(start, gti.START[i]),  % add new
        list_append(stop, gti.STOP[i]);    % interval
    if(qualifier("verbose", 1))
      vmessage("%% %s: %d intervals could be combined to %d intervals", _function_name(), n, length(start));
    gti = struct { START=list_to_array(start), STOP=list_to_array(stop) };
  }

  fits_write_binary_table(filename, "STDGTI", gti, struct { MJDref = MJDref });
  fits_update_key(filename+"[0]", "CREATOR", qualifier("creator", "isisscripts:fits_write_gti"));  % for XMM SAS
  fits_update_key(filename+"[0]", "DATE", qualifier("date", "1998-JAN-01"));  % dummy date to make XMM-arfgen happy
}
