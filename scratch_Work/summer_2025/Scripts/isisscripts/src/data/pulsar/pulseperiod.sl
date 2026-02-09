% -*- mode: slang; mode: fold -*-

%%%%%%%%%%%%%%%%%%%%%%%%
define check_pulseperiod_orbit_struct()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{check_pulseperiod_orbit_struct}
%\synopsis{checks if the pulse period- and/or orbit-structure are valid}
%\usage{Integer_Type check_pulseperiod_orbit_struct(Struct_Type structure);
% or Struct_Type check_pulseperiod_orbit_struct(Double_Type pulseperiod);}
%\description
%    This function performs a checks whether the given
%    structure matches one of the following definitions
%    of a pulse period- or orbital parameter structure:
%
%    1) pulseperiod struct { % given as period over time
%        Double_Type[] time, % in MJD
%        Double_Type[] period % in seconds
%       }
%
%    2) pulseperiod struct { % given as taylor coefficients
%        Double_Type t0, % reference time in MJD
%        Double_Type p0[, % pulse period at t0 in seconds
%        Double_Type pdot[, % first derivative in s/s
%        Double_Type p2dot[, % second derivative in s/s^2
%        ...
%        Double_Type pNdot]]] % higher orders
%       }
%
%    3) orbit struct {
%        Double_Type tau or t90, % time of periastron passage
%                    % or mean longitude of 90 degrees in MJD
%        Double_Type porb, % orbital period in days
%        Double_Type asini, % projected semi-major axis in lt-s
%        Double_Type ecc[, % eccentricity
%        Double_Type omega] % longitude of periastron in degrees
%                                          % required if ecc > 0     
%       }
%
%    On a successful match the number of the definition
%    (1-3) is returned, 0 otherwise.
%    Note that additional field names are allowed.
%    
%    If an input pulse period (as a number) is given
%    instead a structure, a new pulse period structure
%    (type 2) is returned with t0 set to 0 and the
%    pulse period as given.
%
%    Note that units cannot checked by this function, but
%    are a suggestion. Read the help of any function using
%    the same definition on their required units.
%\seealso{pulseperiod}
%!%-
{
  variable s;
  switch(_NARGS)
    { case 1: (s) = (); }
    { help(_function_name()); return; }

  % return value depends on input type
  switch (typeof(s))
    % new pulse period structure
    { case Double_Type: return struct { p0 = s, t0 = 0. }; }
    % check input structure
    { case Struct_Type:
      variable fields = get_struct_field_names(s);

      %%% check required field names on existence
      % type 1
      if (length(complement(["time","period"], fields)) == 0) {
        if (all([typeof(s.time), typeof(s.period)] == Array_Type)) {
          if (all(s.period > 0)) { return 1; }
	  else {
	    vmessage("warning (%s): 'time' and 'period' have to be greater zero", _function_name);
	  }
        }
        vmessage("warning (%s): 'time' and 'period' have to be arrays", _function_name);
      }
      % type 2
      else if (length(complement(["t0","p0"], fields)) == 0) {
        if (all([typeof(s.t0), typeof(s.p0)] == Double_Type)) {
 	  if (s.p0 > 0) { return 2; }
	  else {
	    vmessage("warning (%s): 't0' and 'p0' have to be greater zero", _function_name);
	  }
        }
        vmessage("warning (%s): 't0' and 'p0' have to be numbers", _function_name);
      }
      % type 3
      else if (length(complement(["porb","asini","ecc"], fields)) == 0
 	       && length(complement(["tau", "t90"], fields)) == 1) {
        if (all([typeof(s.porb), typeof(s.asini), typeof(s.ecc)] == Double_Type)) {
	  if (s.porb < 0 or s.asini < 0) {
            vmessage("warning (%s): 'porb' and 'asini' have to be greater zero", _function_name);
	    return 0;
	  }
          if (s.ecc != 0) {
	    ifnot (0 < s.ecc < 1) {
	      vmessage("warning (%s): 'ecc' has to be between 0 and 1", _function_name);
	      return 0;
	    }
	    if (any(fields == "omega")) {
              if (typeof(s.omega) == Double_Type) { return 3; }
	      vmessage("warning (%s): 'omega' has to be a number", _function_name);
	      return 0;
	    }
            vmessage("warning (%s): 'omega' has to exist because 'ecc' > 0", _function_name);
	    return 0;
          }
	  return 3;
        }
        vmessage("warning (%s): 'porb', 'asini', 'ecc', 'tau'/'t90' have to be numbers", _function_name);
      }
     
      return 0;
    }
    % neither structure nor pulse period given
    { vmessage("warning (%s): input has to be a structure or a single pulse period", _function_name); return 0; }
  % end of switch
  
  vmessage("error (%s): this should not happen", _function_name);
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define pulseperiod_transform()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulseperiod_transform}
%\synopsis{transforms a period evolution given as taylor coefficients to a new t0}
%\usage{Struct_Type pulse_transform(Double_Type new_t0, Struct_Type pulseperiod);}
%\qualifiers{
%    \qualifier{sameunit}{set if the unit of 'time' is in the same
%               unit as the pulse period or set to the
%               conversion factor from days to 'time'}
%}
%\description
%    The structure containing the pulse period and its
%    derivatives at a certain time t0 must fullfil the
%    conditions given in 'check_pulseperiod_orbit_struct'.
%    This description of the pulse period evolution is
%    transformed to a new given t0. In case this time is
%    given as an array an array of transformed structures
%    is returned.
%
%    Note, that the uncertainty of the transformed pulse
%    ephemeris scales with (t - new_t0)^N * pNdot with
%    the highest order N of the taylor series.
%\seealso{check_pulseperiod_orbit_struct}
%!%-
{
  variable t, s;
  switch(_NARGS)
    { case 2: (t,s) = (); }
    { help(_function_name()); return; }

  % check input structure
  if (check_pulseperiod_orbit_struct(s) != 2) {
    vmessage("error (%s): input structure is not a valid type 2 period evolution", _function_name);
    return;
  }

  variable tconv = qualifier("sameunit", 86400.);
  if (tconv == NULL) { tconv = 1.; }

  % get taylor coefficients from structure
  variable coeff = taylorcoeff_from_struct(s, "p0", "p\([0-9]*\)dot"R);

  % loop over input times and build output structures
  variable i, fnames = [
    "p0", length(coeff) > 1 ? "pdot" : String_Type[0],
    array_map(String_Type, &sprintf, "p%ddot", [2:length(coeff)-1])
  ];
  variable f, snew = struct_array(length(t), struct_combine(struct { t0 }, fnames));
  _for i (0, length(t)-1, 1) {
    % transform coefficients
    snew[i].t0 = t[i];
    _for f (0, length(coeff)-1, 1) {
      set_struct_field(snew[i], fnames[f],
        taylor((t[i]-s.t0)*tconv, coeff[[f:]])[0]
      );
    }
  }

  return typeof(t) == Double_Type ? snew[0] : snew;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define pulseperiod()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulseperiod}
%\synopsis{calculates the pulse period at the given time depending
%    on the given pulse period evolution}
%\usage{Double_Type[] pulse_period(Double_Type[] time, Struct_Type pulseperiod[, Struct_Type orbit]);}
%\qualifiers{
%    \qualifier{interpol}{reference to a function to interpolate the
%               pulse period evolution on the requested
%               time grid (default: &interpol_points)}
%    \qualifier{sameunit}{set if the unit of 'time' is in the same
%               unit as the pulse period or set to the
%               conversion factor from days to 'time'}
%}
%\description
%    Calculates the expected pulse period at the given time
%    (in days), which may be a single value or an array.
%    The structures containing the pulse period and the
%    optional orbital parameters must follow the conditions
%    described in 'check_pulseperiod_orbit_struct'.
%
%    If the pulse period is given as evolution (time vs.
%    period) the period at the requested time is calculated
%    by interpolation. Otherwise the pulse period is
%    calculated by a 'taylor' series using a given period
%    and its derivatives at a reference time in. In any
%    case the requested time has to be in MJD and the period
%    (and its Nth derivative) in seconds (/seconds^N)
%
%    Finally, if any orbital parameters are provided, the
%    returned period gets modified by the binary motion.
%\seealso{check_pulseperiod_orbit_struct, taylor, radial_velocity_binary}
%!%-
{
  variable t, period, orb = NULL;
  switch(_NARGS)
    { case 2: (t,period) = (); }
    { case 3: (t,period,orb) = ();}
    { help(_function_name()); return; }

  % check input structures
  variable type = check_pulseperiod_orbit_struct(period);
  if (typeof(type) == Struct_Type) {
    period = type; type = 2;
  } else {
    if (type == 0) {
      vmessage("error (%s): period is not given properly", _function_name);
    }
  }
  if (orb != NULL && check_pulseperiod_orbit_struct(orb) == 0) {
    vmessage("error (%s): orbit is not given properly", _function_name);
  }

  variable retper;

  variable tconv = qualifier("sameunit", 86400.);
  if (tconv == NULL) { tconv = 1.; }

  % period over time given
  if (type == 1) {
    variable inter = qualifier("inter", &interpol_points);
    retper = @inter(t, period.time, period.period);
  }
  % taylor coefficients given - get those from the structure
  else {
    variable coeff = taylorcoeff_from_struct(period, "p0", "p\([0-9]*\)dot"R);
    retper = taylor((t-period.t0)*tconv, coeff);
  }

  % take orbit into account
  if (orb != NULL) {
    % build qualifier-structure
    variable qual = struct { P = orb.porb, e = orb.ecc, asini = orb.asini };
    if (struct_field_exists(orb, "tau")) {
      qual = struct_combine(qual, struct { T0 = orb.tau });
    } else { qual = struct_combine(qual, struct { T90 = orb.t90 }); }
    if (struct_field_exists(orb, "omega")) {
      qual = struct_combine(qual, struct { omega = orb.omega, degrees });
    }
    retper *= (1. + radial_velocity_binary(t;; qual));
  }

  return retper;
} %}}}
