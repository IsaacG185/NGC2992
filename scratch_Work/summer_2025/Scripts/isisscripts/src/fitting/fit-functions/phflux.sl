%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define phflux_fit(lo, hi, par, y)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{phflux (fit-function)}
%\synopsis{fits the photon flux in a given energy range}
%\description
%    This function can be used as a convolution model to determine
%    the photon flux [ph/s/cm^2] of the model in the energy range
%    given by \code{E_min} and \code{E_max}. Only bins within(!) this energy range
%    are considered for the calculation of the flux, thus the model
%    should be evaluated on a grid including the values defining the
%    energy range, i.e. \code{E_min} and \code{E_max} are elements
%    of \code{[bin_lo, bin_hi]} of the grid. A user grid can be used
%    for this purpose.
%    As this function fits the normalization of the total convolved
%    model, the normalizations of its components are not defined
%    absolutely, but only relativ to each others. For that reason it
%    is meaningful to freeze the normalization of one component, at
%    best the one of the continuum to avoid ambiguities during
%    fitting.
%
%\examples
%    % data definition:
%    \code{variable lo = _A([1:10]);}
%    \code{variable hi = make_hi_grid(lo);}
%    \code{variable my_data = define_counts(lo,hi,lo,sqrt(lo));}\n
%    \code{variable my_emin = 2.5;}
%    \code{variable my_emax = 6.5;}
%    % defining a grid containing the energy limits for the flux:
%    % (in this way only valid if energy range is covered by the grid
%    % and if these values are not already element of bin_lo, bin_hi)
%    \code{define my_grid(id, s)}
%    \code{\{}
%    \code{   variable mygdc = get_data_counts(id);}
%    \code{   mygdc.bin_lo = [mygdc.bin_lo,_A(my_emax),_A(my_emin)];}
%    \code{   mygdc.bin_hi = [mygdc.bin_hi,_A(my_emax),_A(my_emin)];}
%    \code{   s.bin_lo = mygdc.bin_lo[array_sort(mygdc.bin_lo)];}
%    \code{   s.bin_hi = mygdc.bin_hi[array_sort(mygdc.bin_hi)];}
%    \code{   return s;}
%    \code{\}}
%    
%    \code{set_eval_grid_method (USER_GRID, my_data, &my_grid);}\n
%    \code{fit_fun("phflux(1,powerlaw(1))");}
%
%    \code{set_par("phflux(1).E_min",  my_emin,  1); % keV}
%    \code{set_par("phflux(1).E_max",  my_emax,  1); % keV}
%    \code{freeze("powerlaw(1).norm");}
%    \code{()=fit_counts();}
%    \code{list_par;}
%
%
%    % It is also possible to determine only the flux of certain
%    % model components, e.g., the unabsorbed flux:
%    \code{fit_fun(phabs(1)*phflux(1, powerlaw(1)));}
%
%\seealso{enflux, set_eval_grid_method}
%!%-
{
  variable flux = par[0];  % <-- int_E1^E2 S_E(E) dE  =  int_l1^l2 S_l(l) dl  [in ph/s/cm^2]
  variable l1 = _A(par[2]);
  variable l2 = _A(par[1]);
  if (Fit_Verbose >= 0 && (l1 < lo[0] or l2 > hi[-1]))
    vmessage("warning: enflux energy range (%.2e-%.2e keV) not covered by data grid (%.2e-%.2e keV)",
	     par[1],par[2],_A(hi[-1]),_A(lo[0]));
  variable i = where(l1 <= lo and hi <= l2);
  return y * flux / sum(y[i]);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define phflux_default(i)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{ switch(i)
  { case 0: return struct{value=0.1, freeze=0, min=0, max=1e20, hard_min=0, hard_max=1e100, step=1e-5, relstep=1e-3};}
  { case 1: return (3.0 , 1, 0, 1e20 ); }
  { case 2: return (10. , 1, 0, 1e20 ); }
}

add_slang_function("phflux", ["phflux [ph/s/cm^2]", "E_min [keV]", "E_max [keV]"], [0]);
set_param_default_hook("phflux", "phflux_default");
set_function_category("phflux", ISIS_FUN_OPERATOR);
