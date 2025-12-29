%%%%%%%%%%%%%%%%%%%%%%%%
define shift_intpol()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{shift_intpol}
%\synopsis{Shifts the elements of an array continuously}
%\usage{Array_Type shift_intpol(Array_Type array, Double_Type n)}
%\description
%    This function does in principle work like the 'shift'
%    function, with the exception that the amount of the
%    shift may be a floating point number. The values of
%    the resulting array are in that case re-distributed
%    by linear interpolation. Thereby, the the sum of the
%    array values is still preserved.
%\seealso{shift}
%!%-
{
  variable x, n;
  switch(_NARGS)
    { case 2: (x,n) = (); }
    { help(_function_name()); return; }
  
  variable len = length(x);
  ifnot (len) return x;

  % allow n to be negative and large (adopted from 'shift')
  n = n mod len + len;
  % fraction of a value to be distributed into following index
  variable c = n - int(n);
  % rotate and redistribute
  n = int(n); n = [n:n+len-1];
  return x[n mod len]*(1.-c) + x[(n+1) mod len]*c;
}


%%%%%%%%%%%%%%%%%%%%%%%%
private define unshift_fit(lo, hi, pars) {
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{unshift}
%\synopsis{fit function to determine the shift of an array to a reference one}
%\usage{unshift(id)}
%\description
%    The function 'shift' rotates an array by a given number
%    of indices. The fit function described here tries to
%    get this number back: the counts of the dataset 'id'
%    are assumed to be a shifted version of a reference
%    array. In order to do the fit, this reference array
%    has to be associated to the dataset via:
%    
%      set_dataset_metadata(id, reference_array)
%      
%    It is also possible to scale the array values to match
%    the reference ones or to add an offest to the array.
%    Summarized, the fit parameters are as follows:
%      shift  - relative shift of the counts to the
%               reference array
%      scale  - factor the reference is multiplied with
%      offset - offset added to the model counts
% 
%    The model counts are calculated by
%      model = scale*shift(reference_array, shift) + offset
%\seealso{backshift, shift_intpol, set_dataset_metadata, shift}
%!%-
  % get in array
  variable in = get_dataset_metadata(Isis_Active_Dataset);
  ifnot (typeof(in) == Array_Type) { vmessage("error (%s): metadata has to be an array! aborting...", _function_name); return in; }
  return shift_intpol(in, pars[0]*length(in))*pars[1] + pars[2];
}
add_slang_function("unshift", ["shift","scale","offset"]);
private define unshift_default_hook(i) {
  variable var = [
    struct { value = 0.2, freeze = 0, hard_min = -2, hard_max = 2, min = 0.0, max = 1.0, step = 1e-1, relstep = 1e-3 },
    struct { value = 1.0, freeze = 1, hard_min = 0, hard_max = 2, min = 0.0, max = 1.0, step = 1e-3, relstep = 1e-5 },
    struct { value = 0.0, freeze = 1, hard_min = -DOUBLE_MAX, hard_max = DOUBLE_MAX, min = 0.0, max = 0.0, step = 1e-3, relstep = 1e-5 }
  ];
  return var[i];
}
set_param_default_hook("unshift", &unshift_default_hook);


%%%%%%%%%%%%%%%%%%%%%%%%
define backshift()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{backshift}
%\synopsis{determines the shift of an array to a reference one}
%\usage{Struct_Type backshift(Double_Type[] in, Double_Type[] ref[, Double_Type[] error]);}
% \altusage{Double_Type[] backshift(Double_Type[] in, Double_Type[] ref[, Double_Type[] error]; retarr);}
%\qualifiers{
%    \qualifier{retarr}{function returns the unshifted array instead
%             of the structure defined below}
%}
%\description
%    The function 'shift' rotates an array by a given number
%    of indices. The function described here tries to get
%    this number back: an input array 'in' is assumed to be
%    a shifted version of the reference array 'ref'. The
%    shift is then determined by using the fit-function
%    'unshift', also taking optional 'error's into acocunt.
%    The returned structure, if the 'retarr'-qualifier is
%    not set, is defined as follows:
%      shift         - shift in number of indices
%      shift_conf    - its [lower, upper] confidence limits
%      relative      - relative shift between 0 and 1
%      relative_conf - its [lower, upper] confidence limits
%      redChiSqr     - reduced chi-square value of the fit
%\seealso{unshift, shift_intpol, shift}
%!%-
{
  variable in, ref, err, noerr = 0;
  switch(_NARGS)
    { case 2: (in,ref) = (); err = _typeof(in)[length(in)] + DOUBLE_EPSILON; noerr = 1; }
    { case 3: (in,ref,err) = (); }
    { help(_function_name()); return; }

  ifnot (length(in) == length(ref) && length(ref) == length(err)) { vmessage("error (%s): input arrays have to be of equal length", _function_name); return; }

  % save actual fit function and exclude all data from fit
  variable ff = get_fit_fun;
  if (ff == NULL) ff = "";
  exclude(all_data);
  % define the data
  if (min(err) < Minimum_Stat_Err || Minimum_Stat_Err == -1) {
    vmessage("warning (%s): changed Minimum_Stat_Err to match given input uncertainties", _function_name);
    Minimum_Stat_Err = .9 * min(err);
  }
  variable i = define_counts([1:length(in)], [2:length(in)+1], in, err);
  set_dataset_metadata(i, ref);
  % set the fit function and fit
  fit_fun("unshift(1)");
  set_par("unshift(1).shift", 0.2, 0, 0.0, 1.0);
  ()=fit_counts(; fit_verbose = -1);
  % error estimation
  set_par("unshift(1).shift", get_par("unshift(1).shift"), 0, get_par("unshift(1).shift")-.5, get_par("unshift(1).shift")+.5);
  variable mn, mx, stat;
  ifnot (noerr) (mn,mx) = conf_loop("unshift(1).shift"; cl_verbose = -1, fit_verbose = -1);
  ()=eval_counts(&stat; fit_verbose = -1);
  % return value
  variable ret = qualifier_exists("retarr") ? shift(in, -int(round(get_par("unshift(1).shift")*length(in)))) : struct {
    shift = get_par("unshift(1).shift")*length(in),
    shift_conf = (noerr ? NULL : [mn[0], mx[0]]*length(in)),
    relative = get_par("unshift(1).shift"),
    relative_conf = (noerr ? NULL : [mn[0], mx[0]]),
    redChiSqr = stat.statistic / (stat.num_bins - stat.num_variable_params)
  };
  % delete the previously defined data and restore fit function
  set_dataset_metadata(i, NULL);
  delete_data(i);
  fit_fun(ff);
  include(all_data);
  return ret;
}
