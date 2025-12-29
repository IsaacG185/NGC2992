define eval_fun_keV()
%!%+
%\function{eval_fun_keV}
%\synopsis{evaluate the fit-function on a user-defined energy-grid}
%\usage{Double_Type flux[] = eval_fun_keV(Double_Type E_bin_lo[], E_bin_hi[]);}
%\description
%    The currently defined fit-function \code{S_E(E)} is evaluated
%    on an arbitrary grid  defined by \code{E_bin_lo} and \code{E_bin_hi} (in keV):\n
%       \code{flux = int_{E_bin_lo}^{E_bin_hi} S_E(E) dE}\n
%   Note that flux is bin integrated, i.e., the unit of \code{flux} is
%   ph/s/cm^2. To plot the flux density (ph/s/cm^2/keV), you need to
%   divide this quantity by the bin  width de=E_bin_hi - E_bin_lo. 
%\seealso{eval_fun}
%!%-
{
  variable keV_bin_lo, keV_bin_hi;
  switch(_NARGS)
  { case 2: (keV_bin_lo, keV_bin_hi) = (); }
  { help(_function_name()); return; }

  variable A_bin_lo = _A(keV_bin_hi);
  variable A_bin_hi = _A(keV_bin_lo);
  variable flux = eval_fun(A_bin_lo, A_bin_hi);
  return reverse(flux);
}
