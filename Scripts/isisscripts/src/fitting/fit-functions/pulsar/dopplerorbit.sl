%%%%%%%%%%%%%%%%%%%%%
private define dopplerorbit_fit(lo, hi, par)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{dopplerorbit}
%\synopsis{fit-function for the orbital Doppler shift factor}
%\usage{fit_fun("dopplerorbit(1; qualifiers) * ...");}
%\qualifiers{
%    \qualifier{t90}{switch to the time of mean longitude 90 degrees (see below)}
%    \qualifier{K}{switch to velocity semi amplitude (see below)}
%    \qualifier{metacor}{string array of structure-field-paths inside the meta-
%             data of the current dataset, which will be assumed to
%             be time in MJD and corrected for binary motion (default:
%             ["time"]). Set to NULL to disable any correction.}
%}
%\description
%    Calculates the radial velocoity, v_rad, of a star in a binary and
%    returns the corresponding Doppler factor, beta, given by
%      beta = (1 + V_rad/Const_c)
%    assuming that V_rad/Const_c << 1. The grid of the data (lo,hi)
%    the model is fitted to needs has to be the time in MJD.
%
%    The parameters of the fit-function are:
%      asini - semi major axis (lt-s)
%           or velocity semi amplitude (km/s)
%      porb  - orbital period (days)
%      tau   - time of periastron passage (MJD)
%           or time of mean longitude 90 degrees (MJD)
%      ecc   - eccentricity
%      omega - longitude of periastron (degrees)
%      v0    - systemic velocity (km/s)
%
%    In case the 't90'-qualifier is set, the parameter 'tau' has the
%    meaning of the time of mean longitude of 90 degrees. In case the
%    'K'-qualifiers is set, the parameter 'asini' has the meaning of
%    the velocity semi amplitude.
%
%    The influence of the binary motion is removed from the input
%    time-array 'lo' using 'BinaryCor'. The corrected times are saved
%    as 'binarytime' into the fitfun_cache of the fit-function. This
%    can be used by other fit-functions, like 'pulsartaylor'.
%
%    The fit-function also corrects time arrays inside the metadata of
%    the current dataset (Isis_Active_Dataset). The name of the fields
%    are set by the 'metacor'-qualifier, which is an array of strings
%    giving the "path" to the field. By default, the 'time'-field
%    inside the metadata is corrected in order to simplify the usage
%    of, e.g., 'pulsartorque'. The corrected times are save into the
%    'metacor'-struct inside the cache using the same "path".
%\seealso{radial_velocity_binary, BinaryCor, KeplerEquation}
%!%-
{
  % input parameters
  variable asini = par[0], porb = par[1], tau = par[2],
           ecc = par[3], omega = par[4], v0 = par[5];

  % sanity checks
  if (porb <= 0 || asini <= 0) {
    throw InvalidParmError, "porb and asini have to be greater zero"$;
  }

  % build qualifier struct for 'radial_velocity_binary'
  % and 'BinaryCor'
  variable rvb = struct {
    P = porb, omega = omega, e = ecc, degrees, v0 = v0
  };
  variable bc = struct {
    porb = porb, eccentricity = ecc, omega = omega   
  };
  if (qualifier_exists("t90")) {
    rvb = struct_combine(rvb, struct { T90 = tau });
    bc = struct_combine(bc, struct { t90 = tau });
  } else {
    rvb = struct_combine(rvb, struct { T0 = tau });
    bc = struct_combine(bc, struct { t0 = tau });
  }
  if (qualifier_exists("K")) {
    rvb = struct_combine(rvb, struct { K = asini });
    bc = struct_combine(bc, struct { % need to convert K to asini
      asini = asini / (2*PI) * (porb*86400. * sqrt((1.-ecc)*(1.+ecc))) / (Const_c*1e-5)
    });
  } else {
    rvb = struct_combine(rvb, struct { asini = asini*Const_c*1e-5 });
    bc = struct_combine(bc, struct { asini = asini });
  }

  % transform times into binary's barycenter
  variable cache = fitfun_get_cache();
  variable dometacor = 0;
  if (cache.binarytime == NULL || any(cache.lastpar[[:4]] != par[[:4]])) {
    cache.binarytime = BinaryCor(lo;; bc);
    cache.lastpar = par;
    dometacor = 1;
  }
  
  % purge binary corrected metadata
  variable metafields = qualifier("metacor", ["time"]);
  variable metacor = length(get_struct_field_names(cache.metacor));
  if (metafields == NULL) {
    set_struct_field(cache, "metacor", @Struct_Type(String_Type[0]));
  }
  else if (length(metafields) != metacor) { dometacor = 1; }
  % binary correct metadata
  if (dometacor) {
    % transform metadata fields
    if (metafields != NULL) {
      variable f, tfield, cfield, cname;
      % loop over fields to correct
      _for f (0, length(metafields)-1, 1) {
	tfield = get_dataset_metadata(Isis_Active_Dataset);
	cname = "metacor"; cfield = cache;
	if (tfield == NULL) { continue; }
	% walk along the path and recursively set 'tfield' and 'cfield'
	variable path;
	foreach path (strchop(metafields[f], '.', 0)) {
	  ifnot (struct_field_exists(tfield, path)) { tfield = NULL; break; }
	  % create path inside the cache if necessary
	  ifnot (struct_field_exists(get_struct_field(cfield, cname), path)) {
	    set_struct_field(cfield, cname, struct_combine(
	      get_struct_field(cfield, cname), path
	    ));
	  }
	  % set 'tfield' and 'cfield'
	  tfield = get_struct_field(tfield, path);
	  cfield = get_struct_field(cfield, cname);
	  cname = path;
	  % create empty structure in 'cfield'
	  if (typeof(tfield) == Struct_Type) {
	    if (get_struct_field(cfield, path) == NULL) {
	      set_struct_field(cfield, path, @Struct_Type(String_Type[0]));
	    }
	  }
	}
	if (tfield == NULL) { continue; }
	% correct the times
	set_struct_field(cfield, cname, BinaryCor(tfield;; bc));
      }
    }
  }

  % compute radial velocity and corresponding Doppler factor
  return (1. + radial_velocity_binary(cache.binarytime;; rvb) / (Const_c*1e-5));
}


% add fit-function
add_slang_function("dopplerorbit", [
  "asini [lt-s]", "porb [days]", "tau [MJD]", "ecc", "omega [degrees]", "v0 [km/s]"
]);
set_function_category("dopplerorbit", ISIS_FUN_ADDMUL);


% define parameter defaults
private define dopplerorbit_defaults(i) {
  return [
    struct { value = 100.0, freeze = 0, hard_min = 1, hard_max = 10000, min = 10, max = 1000, step = 1e-2, relstep = 1e-4 },
    struct { value = 10.0, freeze = 0, hard_min = 0.007, hard_max = 10000, min = 1, max = 1000, step = 1e-2, relstep = 1e-4 },
    struct { value = 56000.0, freeze = 0, hard_min = 15000, hard_max = 100000, min = 15000, max = int(ceil(UNIXtime2MJD(_time))), step = 1e-1, relstep = 1e-3 },
    struct { value = 0.0, freeze = 0, hard_min = 0.0, hard_max = 1.0, min = 0, max = 1.0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = -360, hard_max = 360, min = -180, max = 180, step = 1e-1, relstep = 1e-3 },
    struct { value = 0.0, freeze = 1, hard_min = -1000.0, hard_max = 1000.0, min = -200, max = 200, step = 1e-2, relstep = 1e-4 }
  ][i];
}
set_param_default_hook("dopplerorbit", &dopplerorbit_defaults);


% setup the fit-function's cache
fitfun_init_cache("dopplerorbit", &dopplerorbit_fit, struct {
  binarytime = NULL, lastpar, metacor = @Struct_Type(String_Type[0])
});
