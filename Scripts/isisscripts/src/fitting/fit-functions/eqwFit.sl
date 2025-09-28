%%%%%%%%%%%%%%%%%%%%%
define eqwFit_fit(lo, hi, pars)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{eqwFit}
%\synopsis{fit function for replacing a feature's norm by its equivalent width}
%\usage{eqwFit(id, continuum, feature1, ..., featureN)}
%\description
%    The so-called equivalent width of a feature in a spectrum
%    is a measurement for its flux F_{feature} compared to the
%    underlying continuum F_{continuum}. It is defined as the
%    width 'eqw' of a rectangle centered at the features
%    maximum or minimum 'E_0' and with a height equal to
%    the continuum at E_0:
%
%      $\\int F_{feature}(E) dE = F_{continuum}(E_0) * eqw$
%
%    As a result, the equivalent width stays constant if the
%    flux of continuum and the feature are correlated.
%
%    The equivalent width of a feature replaces its norm. Due
%    to that, the norm has to be at a fixed value, e.g, 1.
%    The fit function defined here then scales the feature
%    to the equivalent width, given as a fit parameter.
%    The function provies several fit parameters:
%      E_min  - lower energy boundary for the feature's flux
%      E_max  - higher energy boundary
%      widthN - the equivalent width of the Nth feature
%      multiN - if 1, the feature is considered to be
%               multiplied with the continuum, otherwise
%               its additive
%    The returned value of the fit function is the continuum
%    with all the given features applied!
%
%    *IMPORTANT*
%    The number of features the fit function can handle has
%    to be set beforehand via 'eqwFit_init'. Once set, the
%    number CAN NOT be changed afterwards. The number of
%    given features has to be fulfilled EVERY TIME the fit
%    function is used! If the function should be evaluated
%    for less features, the remaining features have to be
%    set to ZERO!
%
%    *NOTE*
%    Some multiplicative models do not provide a proper
%    normalization, such that the norm N is defined like
%
%      model = N * ...
%
%    For example, although the gaussian absorption 'gabs'
%    has a depth 'tau', due to its definition
%
%      gabs = exp(-tau * exp(...))
%
%    it CAN NOT be used with eqwFit properly! Instead,
%    use additive models to mimic a multiplicative one:
%
%      mygabs = 1 - egauss
%\example
%    % init the fit function to handle two features
%    eqwFit_init(2);
%
%    % equivalent width of a single gaussian,
%    % the resulting model is equal to:
%    % powerlaw(1) + egauss(1)
%    fit_fun("eqwFit(1, powerlaw(1), egauss(1), 0)");%
%    set_par("eqwFit(1).width1", 300); % eqw = 300eV
%    set_par("eqwFit(1).multi1", 0); % additive
%    set_par("egauss(1).area", 1, 1); % freeze area
%
%    % equivalent width of an additive and
%    % multiplicative gaussian,
%    % the resulting model is equal to:
%    % powerlaw(1)*(1 - egauss(2)) + egauss(1)
%    fit_fun("eqwFit(1, powerlaw(1), egauss(1), 1 - egauss(2))");
%    set_par("eqwFit(1).width2", 200); % eqw = 200eV
%    set_par("eqwFit(1).multi2", 1); % multiplicative
%    set_par("egauss(2).area", 1, 1); % freeze area
%\seealso{eqwFit_init, eqw}
%!%-
{
  % get all additional parameters (continuum, feature1, feature2, ...)
  if (_stkdepth < 2) { vmessage("error (%s): need a continuum model and at least one feature model", _function_name); exit; }
  variable feature = Array_Type[(length(pars)-2)/2];
  variable i;
  _for i (length(feature)-1, 0, -1) {
    variable newf = ();
    if (typeof(newf) == Array_Type && length(newf) == length(lo)) feature[i] = newf;
  }
  variable continuum = ();
  variable n = length(feature);
  % useful names for parameters
  variable emin = pars[0], emax = pars[1], eqw = pars[[2:1+n]], mult = pars[[2+n:length(pars)-1]], f;
  % select energy range for eqw calculations
  variable iw = (emin == 0 && emax == 0 ? [0:length(lo)-1] : where(lo >= _A(emax) and hi <= _A(emin)));
  % flux density of continuum
  variable fdcon = reverse(reverse(continuum) / (_A(lo) - _A(hi)));
  % loop over all features
  variable resflux = @continuum;
  _for f (0, n-1, 1) {
    % proceed if feature is non-zero
    if (feature[f] != NULL) {
      % flux and flux density within each feature
      variable featflux = (mult[f] == 0 ? feature[f] : continuum*(feature[f] - 1));
      variable fdfea = reverse(reverse(featflux) / (_A(lo) - _A(hi)));
      % get energy index where each feature has its maximum in flux density  
      variable iwe = min(where_max(abs(fdfea[iw])));
      % flux density of continuum at feature's maximum
      variable fdconmax = fdcon[iw[iwe]];
      % calculate scaling factor of feature, such that given eqw fits
      variable fluxfea = sum(featflux[iw]); % total flux in feature (should be a fixed value!)
      variable c = eqw[f] * fdconmax / fluxfea / 1000; % factor 1000 from keV to eV
      % add feature's flux to the resulting flux
      ifnot (isnan(c) || isinf(c)) resflux += c*featflux;
    }
  }
  return resflux;
}

%%%%%%%%%%%%%%%%%%%%%
define eqwFit_init() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{eqwFit_init}
%\synopsis{initializes the fit function 'eqwFit'}
%\usage{eqwFit_init(Integer_Type N);}
%\description
%    Defines and initializes the equivalent width fit
%    function 'eqwFit' to handle 'N' number of features.
%    Note, that the number has to be set before one can
%    use the fit function and that it can only be set once!
%\seealso{eqwFit, eqw}
%!%-
  if (is_defined("eqwFit")) { vmessage("error(%s): fit function has been initialized already", _function_name); return; }
  variable numfeat;
  switch (_NARGS)
    { case 0: numfeat = 1; }
    { case 1: numfeat = (); }
    { help(_function_name); return; }
  % width and multiplicative parameter names
  variable widthpars = array_map(String_Type, &sprintf, "width%d [eV]", [1:numfeat]);
  variable multipars = array_map(String_Type, &sprintf, "multi%d", [1:numfeat]);
  % define fit functions
  add_slang_function("eqwFit", ["E_min", "E_max", widthpars, multipars]);
  % define fit defaults
  variable eqwFit_defaults = "[\
    struct { value = 0, freeze = 1, hard_min = 0, hard_max = 1000, min = 0.0, max = 1000.0, step = 1e-3, relstep = 1e-5 },\
    struct { value = 0, freeze = 1, hard_min = 0, hard_max = 1000, min = 0.0, max = 1000.0, step = 1e-3, relstep = 1e-5 },\
    struct { value = 1000, freeze = 0, hard_min = -1e6, hard_max = 1e6, min = -10000, max = 10000, step = 1e-3, relstep = 1e-5 },\
    struct { value = 0, freeze = 1, hard_min = 0, hard_max = 1, min = 0, max = 1, step = 1e-3, relstep = 1e-5 }\
  ];";
  % define default hook
  eval(sprintf("define eqwFit_default_hook(i) {\
    variable var = %s;\
    return (i < 2 ? var[i] : (i-2) < %d ? var[2] : var[3]);\
  }\
  set_param_default_hook(\"eqwFit\", &eqwFit_default_hook);", eqwFit_defaults, numfeat));
}
