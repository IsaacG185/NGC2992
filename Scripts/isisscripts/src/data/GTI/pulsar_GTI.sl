% -*- mode:slang; mode:fold -*-

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define phasebin_to_gti(tstart, tstop, tref, p, pdot, pddot, phase_lo, phase_hi, satellite){ %{{{
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  variable d2s = 86400.;
  variable eph = struct{t0, p0 = p, pdot = pdot, p2dot = pddot, p3dot =0.}; % orbit structure required by pulse_time

  if (qualifier_exists("MJD")){
    eph.t0 = double(tref); 
    tref = (tref-MJDref_satellite(satellite))*d2s; % Converting the reference time in the  staellite's time format
    tstart = (tstart-MJDref_satellite(satellite))*d2s; % Start and stop time are converted to seconds, because
    tstop = (tstop-MJDref_satellite(satellite))*d2s;   % the pulse period will always be in seconds!
    
  }else{
    eph.t0 = tref/d2s + MJDref_satellite(satellite); % The reference time in the ephemeris structure must always be in MJD
  }
  variable nxp = [ int((tstart-tref)/p)-2 : int((tstop-tref)/p) +2] ; %index array of pulses during observation
  
  variable gti = struct {
    start = Double_Type[length(nxp)] ,
    stop = Double_Type[length(nxp)]
  };
  
  %calculate pulse arrival times
  gti.start = pulse_time (nxp + phase_lo; eph = eph); % pulse_time returns arrival times in MJD
  gti.stop =  pulse_time (nxp + phase_hi; eph = eph); % Make sure the MJD qualifier is NOT passed to pulse time!!!
  
  %convert to satellite's time system
  gti.start = (gti.start - MJDref_satellite(satellite))*d2s; % convert back to seconds
  gti.stop = (gti.stop - MJDref_satellite(satellite))*d2s;
  
  return gti;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define convert_GTI(nobarevt, barevt, gti){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Do linear interpolation to calculate the GTIs in the satellite's time format
  variable nobargti = struct{
    start = interpol (gti.start, barevt.time, nobarevt.time),
    stop = interpol (gti.stop, barevt.time, nobarevt.time)};    

  return nobargti;
};
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define pulsar_GTI(){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsar_GTI}
%\synopsis{Calculates GTIs for pulse phase resolved spectroscopy}
%\usage{pulsar_GTI(Double_Type tstart, tstop, String_Type satellite, basefilename, Double_Type t0, p, phase_lo, phase_hi);}
%\qualifiers{
%\qualifier{pdot}{first derivative of the pulse period in s/s (default: 0) }
%\qualifier{pddot}{second derivative of the pulse period in s/s^2 (default: 0) }
%\qualifier{MJD}{If set, tstart, tstop and t0 are assumed to in MJD}
%\qualifier{local}{create GTIs in satellite's local time system. Requires qualifiers 'nobarevt' and 'barevt' to be set.}
%\qualifier{barevt}{event file in barycentered time frame}
%\qualifier{nobarevt}{event file in local time frame}
%\qualifier{}{all other qualifiers are passed to BinaryPos}
%}
%\description
%   This function calculates the GTIs for pulse phase resolved spectroscopy. Input arguments are\n
%   
%      tstart - start time of the time interval to be covered (typically the start of the observation)
%      tstart - end time of the time interval to be covered (typically the end of the observation) 
%      satellite - the name of the satellite (needed for setting the reference MJD correctly)
%      basefilename - the file created will be named 'basefilename.gti'
%      t0 - the reference time (time of phase zero)
%      p - the pulse period
%      phase_lo - the lower phase boundary
%      phase_hi - the upper phase boundary
%   \n
%   Upon qualifier request, tstart, tstop, and t0 can be given in MJD instead of seconds. The pulse
%   period is always in seconds.\n
%   \n
%   If the pulse period and the reference time are corrected for the binary
%   motion, the orbital parameters should be provided by qualifiers such that
%   the GTIs can be transformed into the observers time system. The
%   qualifiers are passed and equal to the \code{BinaryPos} function.
%   \n
%   If GTIs in the satellite's local reference time system are needed (e.g., for Suzaku-XIS),
%   an event file in both local and barycenterd time can be passed via qualifiers and the GTIs
%   are interpolated to the local time system. Header keywords are set accordingly.
%\example
%   pulsar_GTI (2.7082e8, 2.7097e8, "nustar", "phase_0.25-0.35", 2.708242e8, 443.07, 0.25, 0.35);
%   \n
%   creates a GTI file named 'phase_0.25-0.35.gti', ranging from 2.7082e8--2.7097e8 seconds
%   in NuSTAR's mission specific time system for the pulsar 4U 1907+09 with pulse period 443.07 seconds
%   for the pulse phase interval 0.25--0.35 where phase 0.0 is set to be at 2.708242e8 seconds.
%
%\seealso{MJDref_satellite, BinaryPos, pulse_time}
%!%-
  
  variable nobarevt, barevt, name, t0, p, phase_lo, phase_hi, tstart, tstop, satellite;
  switch(_NARGS)
  {case 8: (tstart, tstop, satellite, name, t0, p, phase_lo, phase_hi) = (); }
  {help(_function_name()); return; }
  
  variable fn_local = qualifier("nobarevt", NULL);
  variable local = qualifier_exists("local");
  variable fn_bary = qualifier("barevt", NULL);
  variable pdot = qualifier("pdot", 0.);
  variable pddot = qualifier("pddot", 0.);
  variable d2s = 86400.; % days to seconds
  
  if (local){
    if ( fn_local == NULL or fn_bary == NULL){
      fprintf(stderr, "%s: ERROR: Conversion to LOCAL time system requires qualifiers 'nobarevt' and 'barevt' to be set!\n", _function_name);
      return;
    }
    %Check the arguments   
    if(typeof(fn_local) ==  String_Type){
      if(fits_read_key(fn_local, "TIMEREF") != "LOCAL"){
	()= printf("ERROR: Event file has wrong reference time! \n");
	return -1;
      };
      nobarevt = fits_read_table(fn_local);
    };
    if(typeof(fn_bary) == String_Type){
      if(fits_read_key(fn_bary, "TIMEREF") != "SOLARSYSTEM"){
	()=printf("ERROR: Event file has wrong reference time! \n");
	return -1;
      };
      barevt = fits_read_table(fn_bary);
    };
    %Check the arguments
    if (length(nobarevt.time) != length(barevt.time)){
      () = printf("ERROR: Event files do not contain an equal number of events! \n");
      return -1;
    };
    
    
    struct_filter(nobarevt, array_sort(barevt.time));
    struct_filter(barevt, array_sort(barevt.time));   
  }
  
  variable bargti =  phasebin_to_gti(tstart, tstop, t0, p, pdot, pddot, phase_lo, phase_hi, satellite;;__qualifiers);  
  
  % binary correction
  if (qualifier_exists("asini") and qualifier_exists("porb")) {
    variable qual = reduce_struct(__qualifiers, "satellite");
    % Do the binary correction in MJD 
    bargti.start = bargti.start/d2s + MJDref_satellite(satellite);
    bargti.stop = bargti.stop/d2s + MJDref_satellite(satellite);   
    
    bargti.start += BinaryPos(bargti.start;; qual)/d2s;
    bargti.stop  += BinaryPos(bargti.stop ;; qual)/d2s;
    
    bargti.start = (bargti.start - MJDref_satellite(satellite))*d2s;
    bargti.stop =  (bargti.stop - MJDref_satellite(satellite))*d2s;
  }
  
  if (local){
    variable nobargti =  convert_GTI(nobarevt, barevt, bargti);
  }
  
  % Write the FITS file and update some keywords  
  fits_write_gti(name +".gti", local ? nobargti : bargti, MJDref_satellite(satellite); date = time() );
  fits_update_key(name +".gti", "TELESCOP", satellite, "Mission name");
  fits_update_key(name +".gti", "TIMEREF", local ? "LOCAL" : "SOLARSYSTEM");
  fits_update_key(name +".gti[1]", "TIMEREF", local ? "LOCAL" : "SOLARSYSTEM");
  fits_update_key(name +".gti", "MJDREFI", int(MJDref_satellite(satellite)), "MJD reference day");
  fits_update_key(name +".gti", "MJDREFF", MJDref_satellite(satellite) - int(MJDref_satellite(satellite)), "fractional part of the MJD reference");  
  fits_update_key(name +".gti[1]", "MJDREFI", int(MJDref_satellite(satellite)), "MJD reference day");
  fits_update_key(name +".gti[1]", "MJDREFF", MJDref_satellite(satellite) - int(MJDref_satellite(satellite)), "fractional part of the MJD reference");
  fits_write_comment (name +".gti", "Phase_lo = " + string(phase_lo));
  fits_write_comment (name +".gti", "Phase_hi = " + string(phase_hi));
}
%}}}