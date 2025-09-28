%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_selected_data_flux_en()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_selected_data_flux_en}
%\synopsis{returns the flux of a data set in energy units}
%\usage{flux = get_selected_data_flux_en(id[, Emin, Emax[, alpha]]);}
%\description
%    \code{flux} is a \code{{ bin_lo, bin_hi, value, err}} structure
%    containing energy bins of data set \code{id}
%    and the spectral photon flux density (in 1/s/cm^2/keV, unless \code{alpha!=0}).\n
%    If \code{Emin} and \code{Emax} are used, only values in this energy range are considered.\n
%    If \code{alpha}!=0, the flux values are multiplied with E^\code{alpha}.
%\example
%    \code{hplot( get_selected_data_flux_en(1, 4, 20, 1) );}\n
%    % plots the spectral energy flux density of data set 1 in the 4--20 keV range
%!%-
{
  variable id, E1=0, E2=1e38, alpha=0;
  switch(_NARGS)
  { case 1 :  id = (); }
  { case 3 : (id, E1, E2) = (); }
  { case 4: (id, E1, E2, alpha) = (); }

  variable f = _A( get_data_flux(id) );
  struct_filter(f, where(E1<=f.bin_lo and f.bin_hi<=E2));
  f.value /= (f.bin_hi - f.bin_lo);
  f.err /= (f.bin_hi - f.bin_lo);

  if(alpha!=0)
  { variable E = (f.bin_lo + f.bin_hi)/2;
    f.value *= E^alpha;
    f.err *= E^alpha;
  }

  return f;
}
