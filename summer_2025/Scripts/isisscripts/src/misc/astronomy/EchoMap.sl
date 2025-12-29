require( "vector" );

% mirror-like redistribution function
private define EchoMap_redist(power, mu, surf, pcase) { return power*mu; }
% mirror-like reponse function
private define EchoMap_respon() { return struct { time = [0.], power = [1.] }; }

%%%%%%%%%%%%%%%%%%%%%
define EchoMap_makelc()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{EchoMap_makelc}
%\synopsis{takes reprocessing information to produce a response signal}
%\usage{Struct_Type EchoMap_makelc(
%      Struct_Type reproment, Struct_Type signal[, Double_Type length]
%    );}
%\qualifiers{
%    \qualifier{noDoppler}{disable Doppler Shift}
%    \qualifier{response}{reference to a function returning the
%                relative emissivity of a surface element
%                as response to an incoming power peak at
%                t = 0. For details see the description
%                (default: delta peak at t=0)}
%    \qualifier{surfsigs}{reference to a variable, which will get the
%                output signal for each element (2dim-array
%                defined as [element,power]; use the time
%                from the returned total signal)}
%}
%\description
%    Takes the 'reproment' structure of a former run of
%    EchoMap and returnes the output signal produced by
%    reprocessing the input 'signal' on the surface used
%    to caluclate the reproment (i.e., the geometrical
%    effect of the reprocessing). By default, the returned
%    power vs. time is the total response to the incomming
%    signal. However, if the optional argument 'length' is
%    provided, the input signal is periodically repeated
%    until the output signal has at least the given length.
%    Furthermore, the signal is repeated backwards in time
%    as well such that no rising or declining parts of the
%    echo is visible in the output.
%
%    By default, it is assumed that each surface element
%    mirrors the incoming power instantaneously. More complex
%    behaviour can be implemented easily using the 'response'
%    qualifier, which defines a function returning the
%    relative 'power' emissivity over 'time' (in seconds) of
%    a surface element. Furthermore, the response has to
%    fullfil energy conservation such that the integrated
%    power does not exceed 1, but may be less, i.e. power is
%    reprocessed via non-radiative processes. The time
%    resolution of the response has to be equal or better
%    than the input signal!
%\seealso{EchoMap}
%!%-
{
  variable repro, sig, T = NULL, cyc = 0;
  switch(_NARGS)
    { case 2: (repro, sig) = (); }
    { case 3: (repro, sig, T) = (); cyc = 1; }
    { help(_function_name()); return; }

  % parameter validity checks
  ifnot (typeof(sig) == Struct_Type) { vmessage("error (%s): 'signal' must be of Struct_Type", _function_name); return; }
  ifnot (struct_field_exists(sig, "time") and struct_field_exists(sig, "power")) { vmessage("error (%s): 'signal' does not have the required fields", _function_name); return; }
  ifnot (length(sig.time) > 1 and length(sig.power > 1)) { vmessage("error (%s): 'signal' arrays have to have more than one element", _function_name); return; }
  ifnot (length(sig.time) == length(sig.power > 1)) { vmessage("error (%s): field lengths of 'signal' must be equal", _function_name); return; }
  ifnot (typeof(repro) == Struct_Type) { vmessage("error (%s): 'reproment' must be of Struct_Type", _function_name); return; }
  variable reprofields = ["visible_obs", "visible_sig", "lt_surf", "lt_obs", "doppler", "flux_rec", "flux_emi", "flux_int"];
  ifnot (sum(array_map(Integer_Type, &struct_field_exists, repro, reprofields)) == length(reprofields)) { vmessage("error (%s): 'reproment' does not have the required fields", _function_name); return; }
  
  % only use surface elements visible by observer
  repro = struct_filter(repro, where(repro.visible_obs); copy);

  % get response function
  variable response = @(qualifier("response", &EchoMap_respon))();
  ifnot (struct_field_exists(response, "time") and struct_field_exists(response, "power")) { vmessage("error (%s): 'response' does not have the required fields", _function_name); return; }
  % interpolate it to match the signal time resolution
  variable dt = (sig.time[-1]-sig.time[0]) / (length(sig.time)-1); % time resolution of input signal
  variable iresp = struct { time, power };
  if (length(response.time) > 1) {
    iresp.time = [response.time[0]:response.time[-1]:dt];
    iresp.power = interpol(iresp.time, response.time, response.power);
    iresp.power /= sum(iresp.power)/sum(response.power); % still the same amount of energy
    response = iresp; % caution: both variables point to the same structure
  }

  %%% calculate the response of an element in its co-moving frame
    % (still independent from any specific element)
  variable resig = COPY(sig), i, l = length(response.time);
  if (l == 0) { vmessage("error (%s): length of interpolated 'response' is zero", _function_name); return; } % should not happen...
  % if the response is delayed shift the time
  if (response.time[0] > 0) {
    resig.time += response.time[0];
    response.time -= response.time[0]; % acutally is not necessary since response.time is not used from now on
  }
  % in case of a one bin response just scale the power
  if (l == 1) { resig.power *= response.power[0]; }
  % otherwise fold the signal with the reponse and
  % increase time and power array in case of a none periodic signal
  else {
    ifnot (cyc) {
      resig.time = [resig.time, dt*[1:l-1] + resig.time[-1]];
      resig.power = Double_Type[length(resig.power) + l-1];
    }
    % fold
    _for i (0, length(sig.power)-1, 1) { % modulo only affects periodic signals here
      resig.power[i+[0:l-1] mod length(resig.power)] += sig.power[i] * response.power;
    }
  }

  %%% initialize output lightcurve
  % if a length of the output lightcurve is not given a non-periodic
  % signal is assumed -> calculate the required length (upper limit)
  ifnot (cyc) {
    T = (sig.time[-1] - sig.time[0] % length of the input signal
       + max(repro.lt_surf + repro.lt_obs) % largest time delay
       + response.time[-1] % length of the response function
	) * (qualifier_exists("noDoppler") ? 1. : max(repro.doppler)); % highest Doppler factor
  }
  % on the other hand, if it is a periodic signal the response signal
  % has to be repeated until its length matches at least the given length
  else {
    % let the periodic signal start as early as possible such that after
    % the transformation into the observing frame the first time bin < 0
    l = max(repro.lt_surf + repro.lt_obs) * max(repro.doppler); % upper limit for latest possible signal in output lightcurve
    i = sig.time[-1] - sig.time[0]; % length of the input signal
    resig.time -= ceil(l/i) * i; % move l/i signal loops back in time
    % copy signal periodically until its length matches the required one
    l = COPY(resig.power); % this copy will be inserted into the signal
    while (resig.time[-1] < T) {
      resig.time = [resig.time, resig.time[-1] + dt*[1:length(l)]];
      resig.power = [resig.power, l];
    }
  }

  %%% build echo -> the fun part
  variable outsig = struct { time = [0:T:dt] + sig.time[0], power };
           outsig.power = Double_Type[length(outsig.time)];
  variable surfsig, surfsigs = qualifier("surfsigs", NULL);
  if (surfsigs != NULL) { @surfsigs = Double_Type[length(repro.visible_obs), length(outsig.power)]; }
  % loop over visible surface
  _for l (0, length(repro.visible_obs)-1, 1) {
    % transform the time into the observing frame and apply flux projection
    % black-magic one-liner: interpolate power on the output time grid, but DON'T extrapolate
    if (repro.visible_sig[l]) {
      surfsig = interpol(outsig.time, % output time grid
			 (@(resig.time) + repro.lt_surf[l] + repro.lt_obs[l])       % add time delay and
			 * (qualifier_exists("noDoppler") ? 1. : repro.doppler[l]), % Doppler factor to co-moving frame -> observing frame
			 @(resig.power) * repro.flux_emi[l]; % apply flux projection on signal power
			 extrapolate = "none", null_value = 0.); % no flux outside of the time signal
    }
    % othwerwise a "dark" surface element if not visible from signal origin
    else { surfsig = Double_Type[length(outsig.time)]; }
    % add instrinsic power
    surfsig += repro.flux_int[l];
    % add to output lightcurve
    outsig.power += surfsig;
    if (surfsigs != NULL) { surfsigs[l,*] = surfsig; }
  }

  return outsig;
}


%%%%%%%%%%%%%%%%%%%%%
define EchoMap()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{EchoMap}
%\synopsis{reprocesses a signal on a given surface}
%\usage{Struct_Type EchoMap(
%      Struct_Type surface, Struct_Type signal
%      Vector_Type observer[, Double_Type length]
%    );}
%\qualifiers{
%    \qualifier{c}{defines the speed of light (default: 1)}
%    \qualifier{noFiniteC}{infinite speed of light}
%    \qualifier{noDoppler}{disable Doppler Shift}
%    \qualifier{powRedist}{reference to a function returning the re-
%                distributed power of all surface elements
%                (i.e., all parameters are arrays!) in
%                direction to the observer. The parameters
%                passed are
%                  * the power to be redistributed
%                  * the cosine of the angle between the
%                    element and the observer
%                  * the surface element as structure with
%                    the corresponding fields as below
%                  * wether the passed power is the surface's
%                    intrinsic one (1) or incident power (2)
%                  * a reference to a variable, which may be
%                    set to 1 to trigger re-calculating the
%                    powers (i.e. the given function is called
%                    again for the two cases *after* it was
%                    called for both cases in the first place;
%                    might be useful if, e.g., the incident
%                    power changes properties of the surface)
%                This function is called twice: (1) for the
%                intrinsic power of a surface element and
%                (2) the reprocessed relative (!!) power. The
%                last parameter specifies these two cases.
%                If you need to pass additional qualifiers
%                you may set the powRedistQual-qualifier
%                to a structure holding the qualifiers
%                (default: power*cosine_to_observer)}
%    \qualifier{response}{response function of a surface element,
%                see EchoMap_makelc for details}
%    \qualifier{reproment}{instead of returning the echo signal the
%                reproment structure is returned (see text)}
%}
%\description
%    This function propagates the given 'signal' on an object
%    defined by a 'surface'. There the signal is absorbed and
%    re-emitted (reprocessed) by each surface element. The
%    resulting response signal, as seen in direction to an
%    'observer', is returned by calling EchoMap_makelc after
%    all geometrical have been calculated (called reproment
%    here). If the corresponding qualifier is set, the latter
%    call is skipped and the reproment structure is returned
%    instead. This structure has the following fields:
%      visible_obs - boolean value if the surface is visible
%      visible_sig   by the observer and the signal origin
%      lt_surf - light travel times from the signal to the
%      lt_obs    surface and from there to the observing plane
%      doppler - Doppler factor in direction to the observer
%      flux_int - intrinsic flux of the surface as seen by
%                 the observer
%      flux_rec - received signal flux of the surface
%      flux_emi - emitted relative flux of the surface as seen
%                 by the observer
%
%    The following effects are taken into account during the
%    calculation of the response signal:
%    - light travel time between each surface element to the
%      signal source and to the observing plane
%    - Doppler shift by a moving surface
%    - effective areas and projection effects
%    - power redistribution function at the surface (qualifier
%      'powRedist')
%    - power response function of the surface (qualifier
%      'response', see EchoMap_makelc for details)
%
%    Restrictions:
%    - sqrt(surface.A) << vector_norm(surface.r-signal.origin)
%      (small surface elements relative to distance to source)
%    - surface.v << c
%    - vector_norm(observer) != 1
%    - signal fields have to be sorted by time
%                
%    all qualifiers are passed to EchoMap_makelc
%    
%    The 'surface' structure contains the surface elements,
%    defined by the fields
%      Vector_Type[] r - position vector to each element
%      Double_Type[] A - area of each element
%      Vector_Type[] n - normal vector of each element
%      Vector_Type[] v - velocity vector of each element
%                        (optional)
%      Double_Type[] L - intrinsic power of each element,
%                        which will be added to the response
%                        signal (optional, in energy/time)
%    The 'signal' is treated as power (energy/time) as a
%    function of time and defined by the fields
%      Double_Type[] time  - lower time bin (in seconds)
%      Double_Type[] power - power in each time bin
%      Vector_Type origin  - position vector to the signal's
%                            source (default: (0,0,0))
%    Any length is considered to be in units of the speed of
%    light (lt-s). If another unit is used, the internal speed
%    of light has to be changed via the 'c' qualifier.
%\seealso{EchoMap_makelc, EchoMap_binary, Vectory_Type}
%!%-
{
  variable surf, sig, obs, T = NULL;
  switch(_NARGS)
    { case 3: (surf, sig, obs) = (); }
    { case 4: (surf, sig, obs, T) = (); }
    { help(_function_name()); return; }

  % parameter validity checks
  ifnot (typeof(surf) == Struct_Type) { vmessage("error (%s): 'surface' must be of Struct_Type", _function_name); return; }
  ifnot (typeof(sig) == Struct_Type) { vmessage("error (%s): 'signal' must be of Struct_Type", _function_name); return; }
  ifnot (typeof(obs) == Vector_Type) { vmessage("error (%s): 'observer' must be of Vector_Type", _function_name); return; }
  ifnot (struct_field_exists(surf, "r") and struct_field_exists(surf, "n") and struct_field_exists(surf, "A")) { vmessage("error (%s): 'surface' does not have the required fields", _function_name); return; }
  ifnot (length(surf.r) == length(surf.A) and length(surf.r) == length(surf.n)) { vmessage("error (%s): field lengths of 'surface' must be equal", _function_name); return; }
  ifnot (struct_field_exists(sig, "time") and struct_field_exists(sig, "power")) { vmessage("error (%s): 'signal' does not have the required fields", _function_name); return; }
  ifnot (length(sig.time) > 1 and length(sig.power > 1)) { vmessage("error (%s): 'signal' arrays have to have more than one element", _function_name); return; }
  ifnot (length(sig.time) == length(sig.power > 1)) { vmessage("error (%s): field lengths of 'signal' must be equal", _function_name); return; }

  % input functions
  variable powerRedist = qualifier("powRedist", &EchoMap_redist);
  
  % some variable definitions
  normalize_vector(obs); % make sure vector to observer is normalized
  variable rsig = (struct_field_exists(sig, "origin") ? sig.origin : vector(0,0,0)); % vector to signal origin
  variable c = qualifier("c", 1.); % speed of light (default 1.0)
  if (qualifier_exists("noFiniteC")) c = _Inf;
  % initialize 'reproment' variable
  variable repro =  struct {
    visible_sig, % element visible from signal origin
    visible_obs, % element visible by observer
    lt_surf = Double_Type[length(surf.r)], % light travel time from signal origin to element
    lt_obs = Double_Type[length(surf.r)], % light travel time from element to observation plane
    doppler = Double_Type[length(surf.r)], % Doppler factor
    flux_rec = Double_Type[length(surf.r)], % received input flux by element
    flux_emi = Double_Type[length(surf.r)], % reprocessed flux by element to observer
    flux_int = Double_Type[length(surf.r)] % intrinsic flux emitted by element to observer
  };

  %%% calculate reproment (geometry parameters of the echo signal) for each surface element
    % - the light travel times (signal origin to element, element to observing plane
    % - Doppler factor
    % - received and emitted total power
  variable rsurfsig = surf.r - rsig; % vectors from signal origin to each surface element
  variable lsurfsig = array_map(Double_Type, &vector_norm, rsurfsig); % length of these vectors
  variable sigproj = -surf.n * rsurfsig / lsurfsig; % cosine of angle between surface elements and signal origin
  variable obsproj = surf.n * obs; % cosine of angle between surface elements and observer
  variable rsurfobs = rsurfsig * obs; % distance of surface to observing plane (at signal origin)
  % surface elements visible from signal origin and by observer
  repro.visible_sig = sigproj > 0;
  repro.visible_obs = obsproj > 0;
  % proceed with elements visible by observer only
  variable n = where(repro.visible_obs), m, redo = 0, r = 0, surfcopy;
  if (length(n) > 0) {
    % calculate light travel times
    repro.lt_surf[n] = lsurfsig[n]/c;
    repro.lt_obs[n] = - rsurfobs[n]/c; % note minus sign here (rsurfobs = rsurfsig * obs)
    % calculate Doppler factor
    repro.doppler[n] = struct_field_exists(surf, "v") and not qualifier_exists("noDoppler")
                     ? 1.-(surf.v[n]*obs)/c
                     : 1. + repro.doppler[n]; % here, repro.doppler is zero as initialized

    do {
      redo = 0;
      surfcopy = struct_filter(surf, n; copy);
      % calculate intrinsic flux of each element as seen by observer
      if (struct_field_exists(surf, "L")) {
        repro.flux_int[n] = (@powerRedist)(
          surf.L[n], obsproj[n], surfcopy, 1, &redo
	  ;; qualifier("powRedistQual", NULL)
        );
      }
      % proceed with elements visible from signal origin as well
      m = n[where(repro.visible_sig[n])];
      if (length(m) > 0) {
        % calculate received relative power
        repro.flux_rec[m] = 1./4/PI/lsurfsig[m]/lsurfsig[m] * surf.A[m] * sigproj[m];
        % calculate emitted relative flux
        repro.flux_emi[m] = (@powerRedist)(
	  repro.flux_rec[m], obsproj[m], struct_filter(surf, m; copy), 2, &redo
	  ;; qualifier("powRedistQual", NULL)
        );
      }
      r++;
    } while (redo and r<10); % re-calculate if redistribution function triggered it
    if (r == 10) { vmessage("warning (%s): re-calculation aborted after 10 iterations", _function_name); }
  }

  % eventually return reproment only
  if (qualifier_exists("reproment")) { return repro; }

  % proceed and calculate echo signal
  return T == NULL
    ? EchoMap_makelc(repro, sig;; __qualifiers)
    : EchoMap_makelc(repro, sig, T;; __qualifiers);
}

  
%%%%%%%%%%%%%%%%%%%%%
define EchoMap_binary()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{EchoMap_binary}
%\synopsis{reprocesses a signal on the companion of a binary}
%\usage{Struct_Type EchoMap_binary(
%      Struct_Type surface, Double_Type lum, Struct_Type signal,
%      Struct_Type orb, Double_Type phiorb, Double_Type mq
%      [, Double_Type length]
%    );}
%\qualifiers{
%    \qualifier{remark: }{any qualifiers are passed to 'EchoMap'}
%}
%\description
%    Uses the 'EchoMap' function to reprocess an input 'signal'
%    on the 'surface' of the secondary star with total luminosity
%    'lum'. The fields required for the 'surface' and 'signal'
%    structure are described in the 'EchoMap' help. The
%    'Roche_lobe_surface' function might be useful to calculate
%    the deformed surface of the star within the Roche potential.
%    Note, that the velocities of the surface elements are
%    calculated automatically if no 'v' field is specified. If
%    not specified, the luminosity field 'L' for each surface
%    element is calculated as well. Thereby, it is assumed that
%    each surface element has the same area luminosity, such
%    that the total luminosity still is 'lum'.
%    The orbit of the binary is described by the 'orb'ital
%    structure an has to contain the fields as described in the
%    'check_ephemeris' help. In addition, the inclination can
%    be specified optionally via the 'i' field. To complete the
%    description of the binary, the mass ratio
%      mq = M_primary / M_companion
%    has to be given at last.
%    As default, the source of the signal is the position of
%    the primary star. It can be changed by setting the 'origin'
%    field of the signal structur to the position vector.
%    Using the 'phiorb' parameter the orbital phase is defined,
%    which corresponds to the viewing angle on the binary.
%
%    As a conclusion and for further details the reference
%    frame is shown in the following:
%#v+
%                                   position of M2 depending
%      omega (right handed)         on orbital phase
%      observer (i = 0)
%        z                                 0.50
%        |  y                              ---
%        | /                              |   |
%        |/                         0.75 |  x  | 0.25
%    M1  o ---- x                         |- -|
%       /                                   | observer
%      o M2 (phiorb = 0)                  0.00
%#v-
%    - orbital plane = x-y-plane (fix)
%    - inclination and orbital phase is realized by rotating
%      the observer accordingly
%    - distance M_1 to M_2 = 1 (fix)
%
%    WARNING: at the moment circular orbits (ecc = 0) are
%             are implemented only!
%    NOTE:    for elliptical orbits, the shape of the stars
%             depends on the orbital phase
%\seealso{EchoMap, Roche_lobe_surface}
%!%-
{
  variable surf, lum, sig, orb, phi, mq, T = NULL;
  switch(_NARGS)
    { case 6: (surf, lum, sig, orb, phi, mq) = (); }
    { case 7: (surf, lum, sig, orb, phi, mq, T) = (); }
    { help(_function_name()); return; }
  surf = COPY(surf);

  % check on inclination
  orb = COPY(orb);
  ifnot (struct_field_exists(orb, "i")) orb = struct_combine(orb, struct { i = 90 });
  
  % parameter validity checks
  ifnot (mq > 0) { vmessage("error (%s): mass ratio 'mq' must be greater zero", _function_name); return; }

  % some variables, note reference frame definition in description above
  variable r2 = vector(0,-1,0); % vector to center of companion (for phi = 0)
  variable ez = vector(0,0,1); % unity vector in z-direction (= omega direction)
  variable obs = vector(0,0,1); % unity vector to observer (for i = 0)
  
  % incline binary by rotating observer
  obs = vector_rotate(obs, vector(1,0,0), PI/180*orb.i);
  % rotate binary by rotating observer in backwards direction
  obs = vector_rotate(obs, ez, -2*PI*phi);

  % calculate surface luminosity
  ifnot (struct_field_exists(surf, "L")) {
    surf = struct_combine(surf, struct {
      L = lum/sum(surf.A)*surf.A
    });
  }

  % make sure M1 is at (0,0,0)
  sig = COPY(sig);
  ifnot (struct_field_exists(sig, "origin")) sig = struct_combine(sig, struct { origin });
  sig.origin = vector(0,0,0);

  surf.r += r2;

  % calculate velocity vector of each surface element (for circular orbits!)
  ifnot (struct_field_exists(surf, "v")) {
    variable xcen = vector(0, -1./(mq + 1), 0); % center of mass (for phi = 0)
    surf = struct_combine(surf, struct {
      v = array_map(Vector_Type, &crossprod, ez, surf.r-xcen) * 2*PI *(1. / orb.porb / 86400)
    });
  }

  % convert unit of length from binary displacement to lt-s via speed of light
  variable newc = 1./radius_to_unit(1, "disp", "lts"; asini = orb.asini, i = orb.i, mq = mq);
  
  variable qual = struct_combine(__qualifiers, struct { c = newc });
  
  return T == NULL
    ? EchoMap(surf, sig, obs;; qual)
    : EchoMap(surf, sig, obs, T;; qual);
}
