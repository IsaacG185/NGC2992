%%%%%%%%%%%%%%%%%%%%%
private define pulsartaylor_fit(lo, hi, par)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsartaylor}
%\synopsis{fit-function modelling the pulse period evolution with a Taylor series}
%\usage{fit_fun("pulsartaylor");}
% altusage{fit_fun("dopplerorbit*pulsartaylor");}
%\description
%    This fit-function computes the pulse period evolution of, e.g.,
%    a neutron star based on a Taylor series. That is
%      p(t) = p0 + Pdot*(t-t0) + .5*Pddot*(t-t0)^2 + ...
%    Here, p0 is the pulse period at the reference time t0 and
%    Pdot, Pddot,... are the higher order derivatives.
%
%    The parameters of the fit-function are:
%    p0    - spin-period at t0 (s)
%    t0    - reference time t0 (MJD), has to be fixed
%    pdot  - period derivative (s/s)
%    p2dot - 2nd period derivative (s/s^2)
%    etc.
%
%    By default the Taylor series is computed up to the second
%    order. If your data requires higher orders, you can change this
%    limit using 'pulsartaylor_set_order'.
%
%    NOTE: in case you add the Doppler shift of orbital motion to the
%          model using the 'dopplerorbit' fit-function, make sure that
%          this fit-function is calculated *first* in order to
%          transform the times ('lo' parameter of the fit-function)
%          into the barycenter of the binary! These corrected times
%          are shared among these fit-functions via the ISISscripts
%          caching extension. Then the reference time, t0, is
%          interpreted as binary corrected!
%
%    NOTE: a Taylor series describes the pulse period evolution
%          phenomenologically. In case of mass-accretion from a donor
%          star the evolution is driven by the mass accretion rate and
%          a Taylor series does not model this correctly. It is likely
%          that further fit-parameters, such as orbital parameters,
%          get biased due to this imperfect modelling (see, e.g., PhD
%          thesis of M. Bissinger)!
%\example
%    % define the measured period evolution as ISIS dataset
%    id = define_counts(time, make_hi_grid(time), period, period_err);
%
%    % set the fit-function
%    fit_fun("pulsartaylor(1)");
%\seealso{pulseperiod, taylor, pulsartaylor_set_order, fitfun_cache}
%!%-
{
  % input parameters
  variable t0 = par[0], p0 = par[1];

  % get binary corrected times
  variable orbitcache = fitfun_get_cache("dopplerorbit");
  variable binarytime = lo;
  if (orbitcache != NULL && orbitcache.binarytime != NULL) {
    binarytime = orbitcache.binarytime;
  }

  % define period structure
  variable p = struct { t0 = t0, p0 = p0 };
  if (length(par) > 1) {
    p = struct_combine(p, struct { pdot = par[2] });
  }
  if (length(par) > 2) {
    variable f = array_map(String_Type, &sprintf, "p%ddot", [[2:length(par)-2]]);
    p = struct_combine(p, @Struct_Type(f));
    array_map(Void_Type, &set_struct_field, p, f, par[[3:]]);
  }
  
  % return model on the data time grid (as an array always!)
  return [ pulseperiod(binarytime, p) ];
}


% define parameter defaults
private define pulsartaylor_defaults(i) {
  switch (i)
  { case 0:
    return struct { value = 56000.0, freeze = 1, hard_min = 15000, hard_max = 100000, min = 15000, max = int(ceil(UNIXtime2MJD(_time))), step = 1e-1, relstep = 1e-3 };
  }
  { case 1:
    return struct { value = 100.0, freeze = 0, hard_min = 1e-6, hard_max = 10000, min = 1e-3, max = 300, step = 1e-6, relstep = 1e-8 };
  }
  {
    return struct { value = 0.0, freeze = i > 2, hard_min = -1e-3, hard_max = 1e-3, min = -10^(-2-3*i), max = 10^(-2-3*i), step = 10^(-5-3*i), relstep = 10^(-7-3*i) };
  }
}

private variable _pulsartaylor_handle = &pulsartaylor_fit;
private variable _pulsartaylor_defaults_handle = &pulsartaylor_defaults;


%%%%%%%%%%%%%%%%%%%%%
define pulsartaylor_set_order()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsartaylor_set_order}
%\synopsis{changes the order of the Taylor series used in 'pulsartaylor'}
%\usage{pulsartaylor_set_order(Integer_Type new_order);}
%\description
%    By default the Taylor series used in the 'pulsartaylor' fit-
%    function is computed up to the second order. This function allows
%    to change this order starting at zero up to the 7th order. The
%    number of fit-parameters are adapted and named accordingly.
%
%    NOTE: changing a fit-function and its parameters on the fly is
%          not supported by ISIS. In order to still achieve this
%          feature here, the fit-function is first deleted using
%          'del_function' and defined again using 'add_slang_function'.
%          Testing revealed, however, that this trick only works once!
%\seealso{pulsartaylor}
%!%-
{
  if (_NARGS != 1) { help(_function_name); }
  if (_pulsartaylor_handle == NULL || _pulsartaylor_defaults_handle == NULL) {
    vmessage("error (%s): setting the order only works once!", _function_name);
    return;
  }
  
  % get and check order
  variable order = ();
  if (order < 0) {
    vmessage("error (%s): order has to be positive");
    return;
  }
  if (order > 7) {
    vmessage("error (%s): only up to the 7th order allowed");
    return;
  }

  % delete old fit-function
  if (any(_isis->_function_list == "pulsartaylor")) {
    del_function("pulsartaylor");
  }
  
  % add fit-function with new order
  variable args = String_Type[order+2];
  args[[0,1]] = ["t0", "p0"];
  if (order > 0) { args[2] = "pdot [s/s]"; }
  if (order > 1) {
    args[[3:]] = array_map(String_Type, &sprintf, "p%ddot [s/s^%d]", [2:order], [2:order]);
  }
  add_slang_function("pulsartaylor", _pulsartaylor_handle, args);
  set_function_category("pulsartaylor", ISIS_FUN_ADDMUL);
  set_param_default_hook("pulsartaylor", _pulsartaylor_defaults_handle);

  % reset fit-function in order to update the parameter list
  fit_fun(get_fit_fun);

  % since re-defining is working only once (acutally the second time,
  % the parameter list is wrong after having called this function the
  % third time), we set the pointers to NULL. Maybe there is a way to
  % let ISIS purge the parameter/fit-function memory?
  if (not qualifier_exists("anyway")) {
    _pulsartaylor_handle = NULL;
    _pulsartaylor_defaults_handle = NULL;
  }
}

% add the fit-function with a default order of 2
pulsartaylor_set_order(2; anyway);
