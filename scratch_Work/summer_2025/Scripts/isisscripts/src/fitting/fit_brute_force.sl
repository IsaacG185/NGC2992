%%%%%%%%%%%%%%%%%%%%%
define fit_brute_force()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fit_brute_force}
%\synopsis{Performs a fit by stepping the given parameters and does a
%    usual fit for the remaining ones}
%
%\usage{Struct_Type fit_brute_force(Integer_Type[] par [, Double_Type[] stepsize])
% or Struct_Type fit_brute_force(String_Type[] par [, Double_Type[] stepsize])}
%\qualifiers{
%\qualifier{nofit}{instead of fitting the remaining parameters the
%             model is just evaluated}
%\qualifier{nomap}{the chi-square map will not be created}
%\qualifier{chatty}{boolean value to show the remaining time
%              (default=1)}
%}
%\description
%    For the given parameters the best fit of the actual model
%    is found by going through the complete parameter range.
%    The parameters can be passed as an array containing their
%    indices or names. The stepsize for each parameter can
%    either be given by the second `stepsize' parameter or the
%    intrinsic stepsizes are used, which can be set using a
%    qualifier of the `set_par' function. The latter can also
%    be used to determine the minimum and maximum value of each
%    parameter. While the given parameters are stepped the other
%    parameters of the model are fitted by the actual fitting
%    method, that means the function `fit_counts' is called.
%    If the qualifier `nofit' is given `eval_counts' is used
%    instead, evaluating the model without performing a chi-
%    square minimization.
%    This function is very similar to the `get_confmap' function.
%    But this function steps n given parameters in a very small
%    grid. In contrast it is possible to perform a fit for all
%    parameters of the model. However BE CAREFUL as the runtime
%    rises exponentially with the number of parameters!! For
%    this reason the function is chatty by default to show the
%    estimated remaining time during the fit.
%    The returned structure contains an array `bestpar' of the
%    best values found for each given parameter, the corres-
%    ponding reduced chi-square value `bestchi' and a structure
%    `chimap', which holds the chi-square values for each tested
%    parameter combination up to two given parameters. Because
%    this map may be very big its creation can be suppressed by
%    the `nomap' qualifier. In the structure the one or two
%    dimensional array (depending on the number of parameters)
%    `chisqr' contains the reduced chi-square values. In case of
%    two dimensions the first one specifies the second parameter
%    to directly pass it to image function like `plot_image'. The
%    corresponding parameter values are stored in the x-field for
%    the first parameters and y-field for the second one.
%\seealso{get_confmap, fit_counts, eval_counts, set_par, plot_image}
%!%-
{
 variable par, inc = NULL;
 switch(_NARGS)
   { case 1: (par) = (); }
   { case 2: (par, inc) = (); }
   { help(_function_name()); return; }
 if (typeof(par)!=Array_Type) par=[par];

 variable i, j, st, dst, ok, stat, chi, tact, tstart, freep, bestfreep;
 variable n = length(par);
 ifnot (inc == NULL || length(inc) == n) throw RunTimeError, sprintf("error (%s): length of step size parameter must be equal number of parameters",_function_name);
 if (inc == NULL) inc = 0.*ones(n);
 variable mn = Double_Type[n];
 variable mx = Double_Type[n];
 variable fr = Double_Type[n];
 variable bestchi = DOUBLE_MAX, bestpar = Double_Type[n];

 % get minimum, maximum and step size of each parameter
 _for i (0, n-1, 1)
 {
  mn[i] = get_par_info(par[i]).min;
  mx[i] = get_par_info(par[i]).max;
  if (inc[i] == 0.0) inc[i] = get_par_info(par[i]).step;
  if (inc[i] == 0.0)
  {
    vmessage("warning (%s): step size of parameter %d is zero, using 100 steps", _function_name, par[i]);
    inc[i] = 1.0/99.*(mx[i]-mn[i]);
  }
  fr[i] = get_par_info(par[i]).freeze;
 }
 variable chatty = qualifier("chatty",1);
 % number of steps for each parameter
 variable num = int(round((mx - mn) / inc)) + 1;
 variable tnum = int(prod(num)); % total number of steps
 % initialise confidence map, if number of parameters smaller 3
 variable chimap;
 if (n>2 or qualifier_exists("nomap")) chimap = NULL;
 else if (n==2) chimap = struct { x = Double_Type[num[0]], y = Double_Type[num[1]], chisqr = Double_Type[num[1],num[0]] };
 else chimap = struct { x = Double_Type[num[0]], chisqr = Double_Type[num[0]] };
 if (chatty)
 {
  vmessage("Number of steps: %d", tnum);
  message("Estimating remaining time roughly,");
  message("which will take at least one minute...");
 }
 st = 0; % total step number
 % freeze parameters
 freeze(par);
 % set initial parameters
 _for i (0, n-1, 1) set_par(par[i], mn[i]);
 % get initial values of free parameters
 freep = Double_Type[length(freeParameters),2];
 freep[*,0] = freeParameters;
 bestfreep = Double_Type[length(freeParameters)];
 _for i (0, length(freep[*,0])-1, 1) freep[i,1] = get_par(int(freep[i,0]));
 variable nofit = (qualifier_exists("nofit") || length(freep[*,0]) == 0);

 % main loop until number of steps is reached
 i = ones(n)*0; % actual step number of each parameter
 tstart = _time; dst=1; % initialise timing
 while (st < tnum)
 {
  % set free parameters
  _for j (0, length(freep[*,0])-1, 1) set_par(int(freep[j,0]),freep[j,1]);
  % fit free parameters
  if (nofit) ()=eval_counts(&stat; fit_verbose=-2);
  else ()=fit_counts(&stat; fit_verbose=-2);
  % compare actual chi square value with best value
  chi = stat.statistic / (stat.num_bins - stat.num_variable_params);
  if (chi<bestchi)
  {
   bestchi = chi;
   _for j (0, n-1, 1) bestpar[j] = get_par_info(par[j]).value;
   _for j (0, length(bestfreep)-1, 1) bestfreep[j] = get_par_info(int(freep[j,0])).value;
  }
  % store chi square value
  if (typeof(chimap) != Null_Type)
  {
   if (n==2) { chimap.chisqr[i[1],i[0]] = chi; chimap.x[i[0]] = get_par(par[0]); chimap.y[i[1]] = get_par(par[1]); }
   else { chimap.chisqr[i[0]] = chi; chimap.x[i[0]] = get_par(par[0]); }
  }

  % increase step number recursivly and set new parameter values
  j = 0; ok = 1;
  do
  {
   if (ok==0) j++;
   i[j]++;
   if (i[j]==num[j] and j<n-1) { i[j] = 0; ok = 0; }
   else ok = 1;
   if (i[j]==num[j]-1) set_par(par[j], mx[j]);
   else if (i[j]<num[j]-1) set_par(par[j], mn[j] + i[j]*inc[j]);
  }
  while (ok==0);

  st++;
  % determine remaining time
  if (chatty)
  {
   tact = _time; % actual time
   if (dst > 0)
   {
    if (tact-tstart>60 && st mod dst==0)
    {
      tact = (tact - tstart)*(tnum-st)/st;
      vmessage("  ...remaining time: %02d:%02d:%02d", tact/3600, tact mod 3600 / 60, tact mod 60);
      if (dst==1) dst = (tnum-st)/9;
    }
   }
  }
 }

 if (chatty)
 {
  tact = _time - tstart;
  vmessage("Total runtime: %02d:%02d:%02d", tact/3600, tact mod 3600 / 60, tact mod 60);
  vmessage("Best chi^2 = %.2f", bestchi);
 }
 % set best values
 _for i (0, n-1, 1) set_par(par[i], bestpar[i]);
 _for i (0, length(bestfreep)-1, 1) set_par(int(freep[i,0]), bestfreep[i]);
 % evaluate
 ()=eval_counts(; fit_verbose=-2);
 % restore freeze status of parameters
 _for i (0, n-1, 1) if (fr[i]==0) thaw(par[i]);

 return struct { bestpar = bestpar, bestchi = bestchi, chimap = chimap };
}
