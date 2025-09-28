%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define RXTE_nr_PCUs_from_filterfile()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{RXTE_nr_PCUs_from_filterfile}
%\synopsis{returns the number of PCUs switched on over time}
%\usage{Integer_Type[] RXTE_nr_PCUs_from_filterfile(String_Type filterfile[, Double_Type[] time])}
%\description
%     The number of PCUs switched on during an observation
%     may vary, which results in jumps in the lightcurve.
%     The filter file (your_extraction/filter/*.xfl) provides
%     time resolved information about the operating PCUs,
%     which is read out and returned.
%
%     ATTENTION:
%     If no time array is given the number of PCUs is returned
%     for the full length of the observation (no GTIs applied!).
%     In the other case the given time array HAS TO be in the
%     SATELLITE TIME SYSTEM and in SECONDS since RXTE started
%     operating (see 'MJDref_satellite').
%\seealso{MJDref_satellite, RXTE_nr_PCUs_from_filename}
%!%-
{
  variable filt, t;
  switch(_NARGS)
  { case 1: % return full list
    filt = ();
    return fits_read_table(filt).num_pcu_on;
  } { case 2: % return time matched list
    (filt,t) = ();
    filt = fits_read_table(filt);
    variable i, num = Integer_Type[length(t)];
    _for i (0, length(num)-1, 1) % match times
      num[i] = filt.num_pcu_on[where_min(abs(filt.time - t[i]))];
    return num;
  } {
    help(_function_name()); return;
  }
}
