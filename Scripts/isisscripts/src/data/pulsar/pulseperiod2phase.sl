
%%%%%%%%%%%%%%%%%%%%%%%%
define pulseperiod2phase()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulseperiod2phase}
%\synopsis{calculates the pulse phase from a given pulse period}
%\usage{Double_Type[] pulseperiod2phase(
%      Double_Type[] time,
%      Struct_Type pulseperiod[, Struct_Type orbit]
%    );}
%\qualifiers{
%    \qualifier{interpol}{interpolation method to re-map
%               the period- onto the input time-
%               grid (default: &interpol_points)}
%    \qualifier{getphi}{variable reference to return the
%               phase on the given period over time
%               grid (method (a), see below).}
%    \qualifier{sameunit}{set if the unit of 'time' is in the same
%               unit as the pulse period or set to the
%               conversion factor from days to 'time'}
%}
%\description
%    The pulse period p(t) of a pulsar and its pulse
%    phase phi(t) are connected by
%      dphi(t) / dt = 1. / p(t)
%    Thus, from a given pulse period the phase can be
%    calculated by integration, which this function
%    provides.
%
%    The pulse period may be given as
%      a) the pulse period over time
%         struct { time, period }
%      b) the taylor coefficients of the pulse
%         ephemeris via
%         struct { p0[, t0, pdot[, p2dot]] }
%    as defined in 'check_pulseperiod_orbit_struct'.
%
%    It is assumed that the unit of the pulse period
%    is a factor of 86400 larger than the time unit of
%    the light curve, i.e., light curve in days and
%    pulse period in seconds. If both have the same
%    unit (regardless whether its seconds or days)
%    use the sameunit-qualifier.
%    
%    In case a), the phase is numerically integrated
%    using the trapez method on the full provided period
%    time grid. Finally, the calculated phase is re-mapped
%    onto the input time grid by interpolation.
%
%    In case b), the phase is calculated analytically by
%    a taylor-series:
%      phi(t) = (t-t0)/p0 - pdot/p0^2*(t-t0)^2 + ...
%
%    Note, that the analytical calculation only supports
%    a pulse ephemeris up the the second order (p2dot).
%    If you need higher orders, you can first calculate
%    the pulse period over time via a taylor-series and
%    finally use method a).
%
%    In case orbital elements are provided, the additional
%    phase shift is calculated after Hilditch Eq 3.43:
%      delta phi = z(t)/c (f0 zdot(t)/c - f(t-t0))
%    with the projected position z(t) of the neutron star
%    and its spin frequency evolution f(t) = 1 / p(t),
%    where p(t) is the given pulse period evolution.
%\seealso{pulse_period, taylor, BinaryPos, radial_velocity_binary}
%!%-
{
  variable t, p, orb = NULL;
  switch (_NARGS)
    { case 2: (t,p) = (); }
    { case 3: (t,p,orb) = (); }
    { help(_function_name); return; }

  % determine input type and sanity checks
  if (typeof(p) != Struct_Type) {
    vmessage("error(%s): pulse period must be of Struct_Type", _function_name);
    return;
  }
  variable type = check_pulseperiod_orbit_struct(p);
  if (type == 1) {
    if (t[0] < p.time[0] or t[-1] > p.time[-1]) {
     vmessage("error(%s): pulse period over time does not cover the required time range", _function_name);
      return;
    }
  } else if (type == 2) {
    if (struct_field_exists(p, "p3dot")) {
      vmessage("error(%s): analytical solution only accounts orders up to p2dot", _function_name);
      return;
    }
  } else {
    vmessage("error(%s): pulse period over time is not given properly", _function_name);
    return;
  }
  if (orb != NULL && check_pulseperiod_orbit_struct(orb) != 3) {
    vmessage("error(%s): orbital parameters are not given properly", _function_name);
  }

  variable tconv = qualifier("sameunit", 86400.);
  if (tconv == NULL) { tconv = 1.; }

  % calculate neutron star position and its radial velocity if required
  variable zpos = 0., vrad = 0.;
  if (orb != NULL) {
    zpos = BinaryPos(t; asini = orb.asini, porb = orb.porb, t0 = orb.tau,
		     eccentricity = orb.ecc, omega = orb.omega);
    vrad = radial_velocity_binary(t; asini = orb.asini, P = orb.porb, T0 = orb.tau,
				  e = orb.ecc, omega = orb.omega, degrees);
  }

  % period over time given
  if (type == 1) {
    % calculate pulse phase by integrating 1/p(t)
    variable i, phi = Double_Type[length(p.time)];
%    variable integrate = qualifier("integrate", &integrate_trapez);
    _for i (1, length(phi)-1, 1) {
      % trapez (or triangle?) method
      % using integrate_trapez is much slower because of the loop
      phi[i] = phi[i-1] +
               .5*tconv*(p.time[i]-p.time[i-1])*(1./p.period[i]+1./p.period[i-1]);
%      phi[i] = @integrate(
%        p.time[[:i]], 1./p.period[[:i]]
%      );
    }

    if (qualifier_exists("getphi")) {
      @(qualifier("getphi")) = phi;
    }
    
    % interpolate on input time grid
    variable interpol = qualifier("interpol", &interpol_points);
    return @interpol(
      t, p.time, phi
    ) + vrad;
  }

  % period ephemeris given
  if (type == 2) {
    variable p0 = p.p0;
    variable t0 = struct_field_exists(p, "t0") ? p.t0 : t[0];
    variable pdot = struct_field_exists(p, "pdot") ? p.pdot : 0;
    variable p2dot = struct_field_exists(p, "p2dot") ? p.p2dot : 0;

    return taylor((t-t0)*tconv, [0, 1./p0, -pdot/p0^2, (2*p0*pdot^2 - p2dot*p0^2)/(p0^4)]);
  }

  vmessage("error(%s): case unknown, this should not happen", _function_name);
  return;
}
