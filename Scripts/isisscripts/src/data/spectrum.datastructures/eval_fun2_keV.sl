%%%%%%%%%%%%%%%%%%%%
define eval_fun2_keV()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{eval_fun2_keV}
%\synopsis{evaluate a fit-function on a user-defined energy-grid}
%\usage{flux = eval_fun2_keV(handle, E_bin_lo, E_bin_hi[, params[, args]]);}
%\description
%    The fit-function given by \code{handle} (\code{S_E(E)}) is evaluated
%    on an arbitrary grid  defined by \code{E_bin_lo} and \code{E_bin_hi} (in keV):\n
%       \code{flux = int_{E_bin_lo}^{E_bin_hi} S_E(E) dE}\n
%    The unit of \code{flux} is ph/s/cm^2/bin.
%\seealso{eval_fun2, eval_fun_keV}
%!%-
{
  variable handle, keV_bin_lo, keV_bin_hi, params, args;
  switch(_NARGS)
  { case 3: (handle, keV_bin_lo, keV_bin_hi) = (); }
  { case 4: (handle, keV_bin_lo, keV_bin_hi, params) = (); }
  { case 5: (handle, keV_bin_lo, keV_bin_hi, params, args) = (); }
  { help(_function_name()); return; }

  variable A_bin_lo = _A(keV_bin_hi);
  variable A_bin_hi = _A(keV_bin_lo);
  variable flux;
  switch(_NARGS)
  { case 3: flux = eval_fun2(handle, A_bin_lo, A_bin_hi); }
  { case 4: flux = eval_fun2(handle, A_bin_lo, A_bin_hi, params); }
  { case 5: flux = eval_fun2(handle, A_bin_lo, A_bin_hi, params, args); }
  return reverse(flux);
}
