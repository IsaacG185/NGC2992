%%%%%%%%%%%%%%%%%%%%%%%%
define fake_pulsar_lightcurve()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fake_pulsar_lightcurve}
%\synopsis{creates a synthetic lightcurve of a pulsar}
%\usage{Struct_Type synthetic_pulsar_lightcurve(
%      Struct_Type lightcurve or Double_Type[] time,
%      Double_Type or Struct_Type period[, Struct_Type orbit
%      [, Struct_Type profile[, Struct_Type or Double_type fluxevolution
%      [, Ref_Type noise_fun]]]]
%    );}
%\qualifiers{
%    \qualifier{lcdt}{time resolution of the input lightcurve in days
%           (default: difference of first two time bins)}
%    \qualifier{interpol}{function reference used to to time-grid interpolations
%               (default: &interpol_points)}
%    \qualifier{pfold}{structure of qualifiers to be passed to 'pfold'
%            (default: struct { nbins = 32, dt = ..., t0 = ..., pdot = ... })}
%    \qualifier{fluxlc}{structure of qualifiers to be passed to 'pulse2pulse_flux_lc'
%             (default: NULL)}
%    \qualifier{tophase}{structure of qualifiers to be passed to 'pulseperiod2phase'
%              (default: struct { t0 = ... })}
%    \qualifier{chatty}{show or hide output messages (default: 1)}
%}
%\description
%    This function fakes a pulsar's lightcurve including the following aspects:
%    - longterm flux evolution (on timescales larger than the pulse period)
%    - lightcurve modulation by pulse profile
%    - pulse period change including orbital motion
%    - gaussian or user-defined observation noise
%
%    Two modi are possible:
%    a) providing an observed initial lightcurve from which all needed aspects
%       are derived. A pulse period or its evolution is mandatory. Certain
%       aspects can be overwritten by user input. The resulting faked and
%       the input lightcurve have the same time-grid.
%    b) providing the output time-grid. The to be included aspects have to be
%       given explicitely.
%\seealso{check_pulseperiod_orbit_struct,pulse2pulse_flux_lc,pulseperiod2phase,pfold}
%!%-
{
  variable in, period, orbit = NULL, profile = NULL, flux = NULL, noise = 1;
  switch (_NARGS)
    { case 2: (in, period) = (); }
    { case 3: (in, period, orbit) = (); }
    { case 4: (in, period, orbit, profile) = (); }
    { case 5: (in, period, orbit, profile, flux) = (); }
    { case 6: (in, period, orbit, profile, flux, noise) = (); }
    { help(_function_name); }

  % qualifiers
  variable chatty = qualifier("chatty", 1);
  variable lcdt = qualifier("lcdt", NULL);
  variable intpol = qualifier("interpol", &interpol_points);

  % determine mode: lightcurve or time-grid given
  variable mode;
  switch (typeof(in))
    { case Struct_Type:
      ifnot (struct_field_exists(in, "time") && struct_field_exists(in, "rate")) {
	vmessage("error (%s): input lightcurve needs 'time' and 'rate'", _function_name);
	return;
      }
      if (chatty) { message("mode 1: lightcurve given"); }
      if (lcdt == NULL) {
	lcdt = in.time[1]-in.time[0];
	if (chatty) { vmessage("  - assuming %f s time resolution", lcdt*86400); }
      }
      if (any(in.fracexp < 1) > 0) {
	message("warning: input lightcurve has bins with fracexp < 1");
	message("         results might be wrong");
      }
      mode = 1;
    }
    { case Array_Type:
      ifnot (_typeof(in) == Double_Type) {
	vmessage("error (%s): input time-grid is not of Double_Type", _function_name);
	return;
      }
      mode = 2;
      if (chatty) { message("mode 2: time-grid given"); }
      if ((profile == NULL && period != NULL) || typeof(flux) != Struct_Type) {
	vmessage("error (%s): a profile and flux evolution is mandatory in this mode", _function_name);
	return;
      }
    }

  % init fake lightcurve
  variable fakelc = struct {
    time = mode == 1 ? in.time : in, rate, error
  };

  % check period evolution
  variable periodtype;
  if (period != NULL) { % if period==NULL: switch pulsations off
    periodtype = check_pulseperiod_orbit_struct(period);
    if (typeof(periodtype) == Integer_Type) {
      ifnot (0 < periodtype < 3) {
        vmessage("error (%s): period is not given properly", _function_name);
        return;
      }
    } else { period = periodtype; periodtype = 2; }
  }

  % check orbit structure
  if (orbit != NULL && check_pulseperiod_orbit_struct(orbit) != 3) {
    vmessage("error (%s): orbit is not given properly", _function_name);
  }
  
  % calculate flux evolution (evolution always given in mode 2 -> assuming mode 1)
  if (flux == NULL && period != NULL) {
    if (chatty) {
      message("calculating flux evolution");
      message("  - from pulse to pulse variations");
    }
    flux = pulse2pulse_flux_lc(in, period, orbit;; qualifier("fluxlc"));
  }
  % if flux is a number -> average over larger (given) time intervals
  if (typeof(flux) == Double_Type) {
    if (chatty) {
      message("calculating flux evolution");
      message("  - from lightcurve flux evolution");
    }
    flux = pulse2pulse_flux_lc(in, flux;; qualifier("fluxlc", NULL));
  }
  % interpol flux evolution
  if (typeof(flux) == Struct_Type) {
    flux = @intpol(fakelc.time, flux.time, flux.rate);
  }

  % calculate profile (subtract the flux evolution)
  if (period != NULL && profile == NULL) { % if mode=2: profile always given
    variable tmp = struct { p0, t0 = in.time[0], pdot = 0, pddot = 0 };
    if (chatty) { message("calculating profile"); }
    if (periodtype == 2) {
      tmp.p0 = period.p0;
      if (struct_field_exists(period, "pdot")) { tmp.pdot = period.pdot; }
      if (struct_field_exists(period, "p2dot")) { tmp.pddot = period.p2dot; }
    } else {
      tmp.p0 = @intpol(tmp.t0, period.time, period.period);
    }
    if (chatty) { vmessage("  - period %f s", tmp.p0); }
    profile = pfold(in.time, in.rate-flux, tmp.p0/86400;; struct_combine(struct {
      nbins = 32, pdot = tmp.pdot, pddot = tmp.pddot*86400,
      dt = in.fracexp*lcdt, t0 = tmp.t0
    }, qualifier("pfold", NULL)));
    hplot(profile);
  }

  % calculate pulse phase
  variable inphi;
  if (period != NULL) {
    if (chatty) { message("calculating pulse phase"); }
    inphi = pulseperiod2phase(mode == 1 ? in.time : in, struct_combine(
      period, struct { t0 = mode == 1 ? in.time[0] : in[0] }, qualifier("tophase", NULL))
    );
  }
  
  %%% now start to fake the lightcurve
  if (chatty) { vmessage("creating synthetic lightcurve"); }
  fakelc.rate = Double_Type[length(fakelc.time)];
  fakelc.error = @(fakelc.rate);
  % add flux evolution
  if (flux != NULL) {
    if (chatty) vmessage("  - flux evolution");
    fakelc.rate += flux;
  }
  % add pulse profile (here the pulse phase is important! -> orbit, spin-change)
  if (period != NULL && profile != NULL) {
    if (chatty) vmessage("  - pulse profile and period changes");
    fakelc.rate += @intpol(
      inphi mod 1, .5*(profile.bin_lo + profile.bin_hi), profile.value-mean(profile.value)
    );
  }

  % if input lightcurve given match the mean value
  if (mode == 1) {
    if (chatty) { message("  - aligning means of input and fake"); }
    fakelc.rate +=  mean(in.rate) - mean(fakelc.rate);
  }

  % add noise
  if (typeof(noise) == Ref_Type) {
    if (chatty) { message("  - calling noise function"); }
    (fakelc.rate, fakelc.error) = mode == 1
                                ? (@noise)(fakelc.rate, in.rate)
	                        : (@noise)(fakelc.rate);
  } else if (noise != NULL) {
    if (mode == 1) {
      variable sdev = moment(in.rate - fakelc.rate).sdev; % just get the noise, no features
      if (chatty) {
	vmessage("  - adding gaussian noise\n    - input has sigma = %f", sdev);
      }
      fakelc.error = sdev * ones(length(fakelc.time));
    } else {
      if (chatty) { message("  - adding gaussian noise\n    - assuming cts/s"); }
      fakelc.error = sqrt(fakelc.rate/(make_hi_grid(in)-in)/86400);
    }
    fakelc.rate += grand(length(fakelc.rate)) * fakelc.error;
  }

  return fakelc;
}
