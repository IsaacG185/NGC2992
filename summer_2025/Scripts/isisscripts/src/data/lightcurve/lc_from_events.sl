private define _lc_from_event_single(ff,b_lo,b_hi,band_max)
{
   variable s_filt;
   % if the upper boundary is equal to the maximal value: include it! 
   % (otherwise bins are lost)
   if (b_hi == band_max)
   {	 
      s_filt = struct_filter (ff, where(ff.pi >= b_lo and ff.pi <= b_hi ); copy);
   }
   else
   {
      s_filt = struct_filter (ff, where(ff.pi >= b_lo and ff.pi < b_hi ); copy);
   }
   return s_filt;
}

%%%%%%%%%%%%%%%%%%%%%%%
define lc_from_events()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{lc_from_events}
%\synopsis{extracts light curves from an event list}
%\usage{Struct_Type dat = lc_from_events(Struct_Type evts [, Array_Type bands]);}
%\qualifiers{
%\qualifier{dt}{time resolution in sec [default: 100]}
%\qualifier{back}{Struct_Type b_evts : subtract background events}
%\qualifier{gti}{struct { Double_Type start, stop } : GTIs for events}
%\qualifier{minfracexp}{minimum allowed fractional exposure of a time bin, requires GTIs to be set}
%}
%\description
%    This function extracts light curves from an event list given as the
%    following structure:
%      Double_Type[] time - the event arrival times (in seconds)
%      Double_Type[] pi   - the associated event energies (in eV) 
%    If \code{bands}
%    is given, an array of structures containing light curves of each band
%    is returned. The energy bands have to be given in eV. To receive
%    two lightcurves with energies between 1-2keV and 2-3keV, e.g., 
%
%    If GTIs are provided, the fractional exposure 'fracexp' will be added
%    to the output structure.
%    
%    \code{dat = lc_from_events(evts, [1000,2000,3000]);}
%\seealso{color_color_data, histogram}
%!%-
{

   variable ff, bands;
   switch (_NARGS)
   {case 1: ff = ();}
   {case 2: (ff, bands) = ();}
   { help(_function_name()); return;}

%   print(typeof(ff));
   if (typeof(ff) == String_Type) { ff = fits_read_table(ff);}
   
   variable band_min = min(ff.pi); variable band_max = max(ff.pi);
   
   ifnot (__is_initialized(&bands))
   {
      bands = [band_min, band_max];
   }

   variable i, band_lo, band_hi;
   variable n_bands = length(bands)-1;
   variable lc_bands = Struct_Type[n_bands];
   variable s_filt, b_filt;


   % establish the time-grid 
   variable dt = qualifier("dt",100);
   variable tmin = min(ff.time); variable tmax = max(ff.time);
   
   variable t_lo = [tmin:tmax:dt];
   variable t_hi = [t_lo[[1:]],tmax];
   
   % GTI filtering
   variable fracexp = NULL;
   if (qualifier_exists("gti")) {
     variable qual = struct { fracexp = &fracexp };
     if (qualifier_exists("minfracexp")) {
       qual = struct_combine(qual, struct { minfracexp = qualifier("minfracexp") });
     }
     i = filter_gti(t_lo, t_hi, qualifier("gti");; qual);
     t_lo = t_lo[i];
     t_hi = t_hi[i];
   }

   _for i(0,n_bands-1,1)
   {
      band_lo = bands[i];
      band_hi = bands[i+1];

      % make the light curve
      s_filt = _lc_from_event_single(ff,band_lo,band_hi,band_max);
      variable cts = histogram(s_filt.time, t_lo, t_hi);

      % exculde the back ground?
      variable bg = 0; variable q = qualifier("back");
      if (q != NULL)
      {
	 b_filt = _lc_from_event_single(q,band_lo,band_hi,band_max);
	 bg = histogram(b_filt.time, t_lo, t_hi);
      }
      
      variable dt_bins = t_hi-t_lo;
      
      lc_bands[i] = struct {
	 time = 0.5*(t_lo+t_hi),
	 rate = (cts-bg)/dt_bins,
	 err = sqrt(cts+bg)/dt_bins
      };
      if (fracexp != NULL) {
	lc_bands[i] = struct_combine(lc_bands[i], struct { fracexp = fracexp });
      }
   }

   
   return (length(lc_bands) > 1) ? lc_bands : lc_bands[0] ;
}

