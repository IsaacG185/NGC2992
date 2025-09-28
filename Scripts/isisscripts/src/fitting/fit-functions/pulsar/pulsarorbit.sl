%%%%%%%%%%%%%%%%%%%%%
private define pulsarorbit_fit(lo, hi, par)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsarorbit}
%\synopsis{fit-function modelling a neutron star pulse period evolution}
%\usage{fit_fun("pulsarorbit");}
%\description
%    DEPRECATED, use 
%      fit_fun("dopplerorbit*pulsartorque");
%    from now on.
%!%-
{
  message("*** DEPRECATED ***");
  return eval_fun2("dopplerorbit", lo, hi, [par[[6:]], 0])
       * eval_fun2("pulsartorque", lo, hi, [par[[:5]], 0.]);
}


% add fit-function
add_slang_function("pulsarorbit", [
  "p [s]", "t0 [MJD]", "a [s/s]", "b [s/s @ (L0,p)]", "alpha", "L0",
  "asini [lt-s]", "porb [days]", "tau [MJD]", "ecc", "omega [degrees]"
]);
set_function_category("pulsarorbit", ISIS_FUN_ADDMUL);


% define parameter defaults
private define pulsarorbit_defaults(i) {
  return [
    struct { value = 100.0, freeze = 0, hard_min = 0.0, hard_max = 10000, min = 0, max = 300, step = 1e-6, relstep = 1e-8 },
    struct { value = 56000.0, freeze = 1, hard_min = 15000, hard_max = int(ceil(UNIXtime2MJD(_time))), min = 15000, max = int(ceil(UNIXtime2MJD(_time))), step = 1e-1, relstep = 1e-3 },
    struct { value = 0.0, freeze = 1, hard_min = -1e-7, hard_max = 1e-7, min = 0, max = 1e-7, step = 1e-10, relstep = 1e-12 },
    struct { value = 0.0, freeze = 1, hard_min = 0, hard_max = 1e-7, min = 0, max = 1e-7, step = 1e-10, relstep = 1e-12 },
    struct { value = 6./7., freeze = 1, hard_min = 0, hard_max = 10, min = 6./7., max = 1., step = 1e-2, relstep = 1e-3 },
    struct { value = 1., freeze = 1, hard_min = 0, hard_max = DOUBLE_MAX, min = 0, max = 0, step = 0, relstep = 0 },
    struct { value = 100.0, freeze = 0, hard_min = 0.0, hard_max = 10000, min = 0, max = 1000, step = 1e-2, relstep = 1e-4 },
    struct { value = 10.0, freeze = 0, hard_min = 0.0, hard_max = 10000, min = 0, max = 1000, step = 1e-2, relstep = 1e-4 },
    struct { value = 56000.0, freeze = 0, hard_min = 15000, hard_max = int(ceil(UNIXtime2MJD(_time))), min = 15000, max = int(ceil(UNIXtime2MJD(_time))), step = 1e-1, relstep = 1e-3 },
    struct { value = 0.0, freeze = 0, hard_min = 0.0, hard_max = 1.0, min = 0, max = 1.0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = -360, hard_max = 360, min = -180, max = 180, step = 1e-1, relstep = 1e-3 }
  ][i];
}
set_param_default_hook("pulsarorbit", &pulsarorbit_defaults);


%%%%%%%%%%%%%%%%%%%%%
private define pulsar_fit(lo, hi, par)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsar}
%\synopsis{fit-function modelling a neutron star pulse period evolution}
%\usage{fit_fun("pulsar");}
%\description
%    Deprecated, use 
%      fit_fun("pulsartorque");
%    from now on.
%!%-
{
  message("*** DEPRECATED ***");
  return eval_fun2("pulsartorque", lo, hi, [par, 0.]);
}


% add fit-function
add_slang_function("pulsar", [
  "p [s]", "t0 [MJD]", "a [s/s]", "b [s/s @ (L0,p)]", "alpha", "L0"]
);
set_function_category("pulsar", ISIS_FUN_ADDMUL);


% define parameter defaults
set_param_default_hook("pulsar", &pulsarorbit_defaults);
