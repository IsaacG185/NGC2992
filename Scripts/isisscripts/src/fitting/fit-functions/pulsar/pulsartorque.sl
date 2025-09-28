% define the simplified ordinary differential equation
%   \dot{P} = a - b * P^2 L^alpha
% after Ghosh & Lamb (1979), which will be solved by the
% fit-function below.
private define _ode_torque(p, t) {
  variable p0 = qualifier("p0");
  variable a = qualifier("a");
  variable b = qualifier("b");
  variable alpha = qualifier("alpha");
  variable lc = qualifier("lc");

  % select the rate at 't'
  variable rate = interpol(t, lc.time, lc.rate);
  
  return a - b * (p/p0)^2 * sign(rate)*abs(rate)^alpha;
}

%%%%%%%%%%%%%%%%%%%%%
private define pulsartorque_fit(lo, hi, par)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsartorque}
%\synopsis{fit-function modelling the accretion torque of a neutron star (simple way)}
%\usage{fit_fun("pulsartorque");}
% altusage{fit_fun("dopplerorbit*pulsartorque");}
%\description
%    The spin-up of an accreting neutron star is connected with its
%    luminosity via
%      Pdot = - b * P^2 L^alpha
%    as found by Ghosh & Lamb (1979). This fit-function solves this
%    differential equation in order to calculate the spin-evolution of
%    the neutron star.
%
%    The parameters of the fit-function are:
%    p     - spin-period at t0 (s)
%    t0    - reference time t0 (MJD), has to be fixed
%    a     - constant spin-up or -down (s/s)
%    b     - torque strength (s/s @ Lnorm and Pnorm)
%    alpha - exponent of b (try to freeze it)
%    Lnorm - luminosity used for normalization, has to be fixed
%    Pnorm - spin-period user for normaliziation, has to be fixed
%
%    In order to express the torque strength, b, in the usual unit of
%    a spin-change (s/s), the equation is modfied by two normalization
%    constants:
%      Pdot = - b * (P/Pnorm)^2 (L/Lnorm)^alpha
%    where Pnorm is a reference spin-period and Lnorm a reference
%    luminosity. For instance, Pnorm could be tied to parameter p,
%    i.e., the period p at t0. This should be avoided, however, when
%    multiple dataset are fitted with the same torque strength b, but
%    different values for the parameter p. Here Pnorm has to be the
%    same among all datasets! The same applies to Lnorm, which should
%    be fixed to an (arbitrary) flux or rate, for instance
%    corresponding to the flux of the Crab.
%    NOTE: setting Pnorm = 0 (the default) uses Pnorm = p internally
%          in order to ensure backward compatibility.
%
%    The exponent, alpha, of the torque strength, b, depends on the
%    accretion mechanism. After Ghosh & Lamb, alpha=6/7 for disk-, and
%    alpha=1 for wind- accretion.
%
%    In order to calculate the spin-evolution, the count rate over
%    time, i.e., a light curve has to be assigned to the dataset using
%    'set_dataset_metadata' (see example below). The period
%    measurements have to be within the time range of the light
%    curve. The structure assigned to the dataset must contain the
%    following fields:
%      time - time (MJD, ordered)
%      rate - count rate at 'time'
%
%    NOTE: in case you add the Doppler shift of orbital motion to the
%          model using the 'dopplerorbit' fit-function, make sure that
%          this fit-function is calculated *first* in order to
%          transform the times ('lo' parameter of the fit-function
%          /and/ light curve 'time' grid) into the barycenter of the
%          binary! These corrected times are shared among these
%          fit-functions via the ISISscripts caching extension. Then
%          the reference time, t0, is interpreted as binary corrected!
%
%    NOTE: the full Ghosh & Lamb accretion torque theory provides
%          equations for the torque strength, b, as a function of the
%          neutron star parameters. This is not implemented here for
%          simplicity. The full theory is implemented in the
%          'pulsarGL79' fit-function.
%
%    NOTE: the model is calculated on the light curve time grid in
%          order to ensure that the integration includes the reference
%          time, t0. This model is interpolated onto the period time
%          grid in the end.
%\example
%    % define the measured period evolution as ISIS dataset
%    id = define_counts(time, make_hi_grid(time), period, period_err);
%
%    % assign the light curve to this dataset
%    set_dataset_metadata(id, struct {
%      time = lc.time,
%      rate = lc.rate
%    });
%
%    % examples for setting the fit-function
%    fit_fun("pulsartorque(1)");
%    fit_fun("dopplerorbit(1)*pulsartorque(1)"); % add orbital Doppler shift
%\seealso{pulsarGL79, dopplerorbit, set_dataset_metadata, fitfun_cache}
%!%-
{
  % input parameters
  variable p0 = par[0], t0 = par[1], a = par[2]*86400, b = par[3]*86400,
           alpha = par[4], Lnorm = par[5], Pnorm = par[6];
  if (Pnorm < 4*DOUBLE_EPSILON) { Pnorm = p0; }

  % get and check meta-structure
  variable meta = get_dataset_metadata(Isis_Active_Dataset);
  if (typeof(meta) != Struct_Type) {
    throw InvalidParmError, "metadata-structure is not defined!"$;
  }
  if (sum(array_map(Integer_Type, &struct_field_exists, meta,["time", "rate", "flux"])) < 2) {
    throw InvalidParmError, "metadata-structure does not contain required fields!"$;
  }

  % define variables
  variable lcrate;
  variable lctime = @(meta.time);
  if (not struct_field_exists(meta, "rate") && struct_field_exists(meta, "flux")) {
    lcrate = @(meta.flux) / Lnorm; % backward compatibility
  } else  { lcrate = @(meta.rate) / Lnorm; }
  if (lo[0] < meta.time[0] || lo[-1] > meta.time[-1]) {
    throw InvalidParmError, "light curve does not include pulse period data"$;
  }

  % define cache
  variable cache = fitfun_get_cache();

  % get binary corrected times
  variable orbitcache = fitfun_get_cache("dopplerorbit");
  variable binarytime = lo;
  if (orbitcache != NULL) {
    if (orbitcache.binarytime != NULL) {
      binarytime = orbitcache.binarytime;
    }
    if (struct_field_exists(orbitcache.metacor, "time") && orbitcache.metacor.time != NULL) {
      lctime = orbitcache.metacor.time;
    }
  }

  % calculate intrinsic spin period evolution by solving the
  % differential equation on the light curve time grid. this is
  % necessary because the reference time might be outside of the
  % period time range -> using the light curve we still can predict
  % the period at these times. a user-defined time grid using
  % set_eval_grid_method does not work because ISIS rebins (=sums up!)
  % the resulting model onto the data time grid.
  if (b != 0. && (cache.spin == NULL || any(cache.lastpar != par))) {
    cache.spin = solveODEbyIntegrate(
      &_ode_torque, lctime; t0 = t0, x0 = p0, qualifiers = struct {
        p0 = Pnorm, a = a, b = b, alpha = alpha,
        lc = struct { time = lctime, rate = lcrate }
      }
    );
  }
  % b = 0
  else if (cache.spin == NULL || any(cache.lastpar[[:2]] != par[[:2]])) {
    cache.spin = a*(lctime - t0) + p0;
%    if (errorprop) { meta.errorprop = 0; }
  }

  
      % % error propagation
      % if (errorprop) {
      %   variable dt = diff(L.time); dt = [dt, mean(dt)];
      %   _for l (0, length(L.time)-1, 1) {
      %     if (l == n) { dLint[l] = 0.; }
      %     else {
      % 	    i = (n < l ? [n:l] : [l:n]);
      %       dLint[l] = sqrt(sum(sqr(
      %         .5 * (pit[i]/p0)^2 * sign(L.flux[i])*abs(L.flux[i])^(alpha-1) * L.dflux[i] * dt[i]
      %       )));
      % 	  }
      % 	}
      %   dLint = abs(dLint) / Lnorm^(alpha-1);
      % 	% period uncertainties
      % 	meta.errorprop = [interpol(lot, L.time,  b*alpha/Lnorm * dLint*86400)];
      % }
      % cache
      % if (cache) { meta.cache.pit = pit; }

  % update cached parameters
  cache.lastpar = par;

  % return model on the data time grid (as an array always!)
  return [ interpol(binarytime, lctime, cache.spin) ];
}


% add fit-function
add_slang_function("pulsartorque", [
  "p [s]", "t0 [MJD]", "a [s/s]", "b [s/s @ (Lnorm,Pnorm)]", "alpha", "Lnorm", "Pnorm [s]"
]);
set_function_category("pulsarorbit", ISIS_FUN_ADDMUL);


% define parameter defaults
private define pulsartorque_defaults(i) {
  return [
    struct { value = 100.0, freeze = 0, hard_min = 0.0, hard_max = 10000, min = 0, max = 300, step = 1e-6, relstep = 1e-8 },
    struct { value = 56000.0, freeze = 1, hard_min = 15000, hard_max = 100000, min = 15000, max = int(ceil(UNIXtime2MJD(_time))), step = 1e-1, relstep = 1e-3 },
    struct { value = 0.0, freeze = 1, hard_min = -1e-7, hard_max = 1e-7, min = 0, max = 1e-7, step = 1e-10, relstep = 1e-12 },
    struct { value = 0.0, freeze = 1, hard_min = 0, hard_max = 1e-5, min = 0, max = 1e-5, step = 1e-10, relstep = 1e-12 },
    struct { value = 6./7., freeze = 1, hard_min = 0, hard_max = 10, min = 6./7., max = 1., step = 1e-2, relstep = 1e-3 },
  struct { value = 1., freeze = 1, hard_min = 0, hard_max = DOUBLE_MAX, min = 0, max = 0, step = 0, relstep = 0 },
  struct { value = 0.0, freeze = 1, hard_min = 0, hard_max = 10000, min = 0, max = 300, step = 0, relstep = 0 }
  ][i];
}
set_param_default_hook("pulsartorque", &pulsartorque_defaults);


% setup the fit-function's cache
fitfun_init_cache("pulsartorque", &pulsartorque_fit, struct { spin = NULL, lctime, lastpar });


% chi-square statistics taking the model uncertainties into account
define pulsarorbit_fit_constraint(stat, pars) {
  vmessage("error (%s): is being re-implemented", _function_name);
  return;
  % variable dmdl = array_flatten(array_struct_field(array_map(
  %   Struct_Type, &get_dataset_metadata, all_data
  % ), "errorprop"));
  % variable data = array_map(
  %   Struct_Type, &get_data_counts, all_data
  % );
  % variable err = array_flatten(array_struct_field(data, "err"));
  % data = array_flatten(array_struct_field(data, "value"));
  % variable mdl = array_flatten(array_struct_field(array_map(
  %   Struct_Type, &get_model_counts, all_data
  % ), "value"));
  % return sum(sqr(data - mdl) / (sqr(err) + sqr(dmdl)));
}
