
%%%%%%%%%%%%%%%%%%%%%%%%
define pulse2pulse_flux_lc()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulse2pulse_flux_lc}
%\synopsis{averages the given lightcurve over the pulsar's period}
%\usage{Struct_Type = pulse2pulse_flux_lc(
%      Struct_Type lightcurve,
%      Double_Type or Struct_Type period,
%      [, Struct_Type orbit]
%    );}
%\qualifiers{
%    \qualifier{remap}{interpolate the resulting flux lightcurve
%               on the input time grid (default: no)}
%    \qualifier{interpol}{function reference to perform the time
%               interpolation (default: &interpol_points)}
%    \qualifier{dphitol}{minimum phase coverage (dphi) a pulse in
%               the lc has to have at least (default: .95)}
%    \qualifier{gaptol}{minimum time difference between bins which
%               defines a gap (default: 2*min(diff(lc.time)))}
%    \qualifier{t0}{time of pulse phase zero (can be provided
%               using the ephemeris structure as well;
%               default: first time bin of the lightcurve)}
%    \qualifier{phase}{array of the pulse phases corresponding to
%               the lightcurve time array (default: its
%               calculated using 'pulseperiod2phase'). If
%               the qualifier is set to a reference the
%               calculated phases are assigned to the
%               given variable.}
%}
%\description
%    The underlying slope in a lightcurve of a pulsar
%    might affect any timing analysis of its pulsations
%    due to pulse to pulse variations of the luminosity.
%    This functions averages the count rates over each
%    pulse to get this luminosity dependance, which is
%    afterwards interpolated to the binning of the input
%    lightcurve.
%
%    The input lightcurve must be of struct {
%      Double_Type[] time, rate, error
%    }
% 
%    The input pulse period may be either a single number
%    implying a constant pulse period or a structure
%    containing the pulse ephemeris as defined in
%    'check_pulseperiod_orbit_struct'. In addition, the
%    orbital parameters might be also given as a
%    structure to take also the Doppler shift of the
%    pulse period into account. This is necessary only
%    in case of a non binary corrected lightcurve.
%
%    The output lightcurve is a struct {
%      Double_Type[] time (center of pulse), rate, error,
%      dphi (phase coverage of each pulse, <1 for a gap)
%    }
%
%    By default, bad sampled pulses are ignored in the
%    final lightcurve, which would lead to wrong mean
%    count rates otherwise.
%
%    Note, that all parameters must have the same time
%    unit, if applicable.
%
%    Note further, that the lightcurve's time grid has
%    to be evenly spaced!
%\seealso{pulseperiod2phase, interpol_points}
%!%-
{
  variable lc, period, orb = NULL;
  switch(_NARGS)
    { case 2: (lc,period) = (); }
    { case 3: (lc,period,orb) = (); }
    { help(_function_name()); return; }

  % convert a constant given period into a ephemeris structure
  variable t0 = qualifier("t0", lc.time[0]); % time of phase zero
  if (typeof(period) == Double_Type) {
    period = struct { p0 = period, t0 = t0 };
  }

  % check input structures
  if (not check_pulseperiod_orbit_struct(period)) {
    vmessage("error (%s): pulse period is not given properly", _function_name);
    return;
  }
  if (orb != NULL && not check_pulseperiod_orbit_struct(orb)) {
    vmessage("error (%s): orbit is not given properly", _function_name);
    return;
  }

  % calculate the pulse phase at each time of the lightcurve
  variable phiqual = qualifier("phase", NULL);
  variable phi = typeof(phiqual) == Array_Type ? phiqual : pulseperiod2phase(lc.time, period; sameunit);
  if (typeof(phiqual) == Ref_Type) { @(phiqual) = phi; }
  if (length(phi) != length(lc.time)) {
    vmessage("error (%s): length of phase grid does not match the time grid", _function_name);
    return;
  }

  % initialize output structure
  variable sl = struct {
    time = Double_Type[0], rate = Double_Type[0],
    error = Double_Type[0], dphi = Integer_Type[0]
  };

  % loop over lightcurve
  variable ci = 0; % first index of current pulse
  variable phi0 = phi[0]; % phase of first index of current pulse
  variable gaptol = qualifier("gaptol", 2.*min(diff(lc.time)));
  variable i, ix, frac, bt, ct, gap;
  variable last = struct { ct = lc.time[0], frac = 0, bt, rate = 0, error = 0, gap = 1 };
  _for i (1, length(lc.time)-1, 1) {
    % check on a gap (end of the lightcurve is equal to a gap as well)
    % note that gap=0 if a gap is detected
    gap = not (lc.time[i] - lc.time[i-1] > gaptol || i == length(lc.time)-1);
    % -> multiply last index fraction by zero, see below
    % check if current phase is greater than phi0+1 or a gap was detected
    % -> one full pulse -> average flux and add to output
    if (phi[i] >= phi0+1 || gap==0) {
      % indices completely within the pulse
      ix = [ci:i-1];
      % current index is already within the next pulse
      % -> fraction to the current pulse
      frac = (phi[ci]+1. - phi[i-1]) / (phi[i] - phi[i-1]) * gap; % note gap=0 here
      % time of phase+1
      ct = lc.time[i-1] + frac*(lc.time[i]-lc.time[i-1]);
      % time binning of the indices (including last one)
      bt = diff([lc.time[ix], ct]);
      % time binning of the last index of the former pulse
      last.bt = (lc.time[ci]-last.ct)*last.gap; % note last.gap=0 here
      % add to output and take former pulse into account
      sl.time  = [sl.time, last.ct + .5*(last.bt + sum(bt))];
      sl.rate  = [sl.rate, weighted_mean([last.rate, lc.rate[ix]], [last.bt, bt])];
      sl.error = [sl.error, sqrt(sqr(last.error*last.bt)+sum(sqr(lc.error[ix]*bt)))
		  / (last.bt+sum(bt))]; % error propagation of weighted_mean
      sl.dphi  = [sl.dphi, gap ? 1. : phi[i-1] - phi0]; % phase coverage
      % resets first index and remember last index properties, note gap=0 here
      ci = i;
      phi0 = (gap ? phi0+1 : phi[i]); % note gap==1 means _no_ gap
      last.ct = (gap ? ct : lc.time[i]);
      last.frac = (1.-frac)*gap;
      last.rate = lc.rate[i-1]*gap;
      last.error = lc.error[i-1]*gap;
      last.gap = gap;
    }
  }

  % ignore bad covered pulses
  variable dphitol = qualifier("dphitol", .95);
  if (dphitol > 0) {
    struct_filter(sl, where(sl.dphi >= dphitol));
  }
  
  % interpolate time grid
  if (qualifier_exists("remap"))
  {
    variable intfun = qualifier("interpol", &interpol_points);
    sl.rate = @intfun(lc.time, sl.time, sl.rate);
    % estimate uncertainties
    variable oldslerr = @sl.error, n;
    sl.error = Double_Type[length(lc.time)];
    _for n (0, length(lc.time)-1, 1) {
      sl.error[n] = oldslerr[where_min(abs(sl.time - lc.time[n]))[0]];
    }
    sl.time = lc.time;
  }
  
  return sl;
}
