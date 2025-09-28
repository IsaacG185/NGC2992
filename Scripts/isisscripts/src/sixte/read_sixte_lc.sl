%%%%%%%%%%%%%%%%%%%%%%%
define read_sixte_lc(fname){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{read_sixte_lc}
%\synopsis{Reads a LC created by the SIXTE makelc tool}
%\description
%       makelc writes the lightcurve file according to the first OGIP
%       standard, i.e. only a COUNTS column is written and the timing
%       information is stored in the TSTART, TSTOP, TIMEDEL, and
%       TIMEPIXR keywords. SIXTE uses the convention TIMEPIXR=0, which
%       means that the time field of the lightcurve returned by
%       read_sixte_lc equals the beginning of the bin (time_lo).
%\usage{read_sixte_lc(filename);}
%!%-
  variable lc = struct{time, rate, error};
  variable raw = fits_read_table(fname);
  
  variable dt = fits_read_key(fname, "TIMEDEL");
  variable timepixr = fits_read_key(fname, "TIMEPIXR");
  
  variable n = length(raw.counts);
  variable time_lo = dt*[0:n-1];
  % variable time_hi = dt*[1:n];
  
  if (timepixr != 0.){
    vmessage("WARNING: TIMEPIXR equals %g! Assuming TIMEPIXR=0 (start of time bin)", timepixr);
  }
  
  lc.time = time_lo;
  lc.rate = raw.counts/dt;
  lc.error = sqrt(raw.counts)/dt;
  
  return lc;
}
