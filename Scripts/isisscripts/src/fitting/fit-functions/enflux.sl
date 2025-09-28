%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define enflux_fit(lo, hi, par, y)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{enflux (fit-function)}
%\synopsis{fits the photon flux in a given energy range}
%
%\qualifiers{
%    \qualifier{norm}{If given a reference to a variable, store the
%                     normalization factor in there.}
%}
%\description
%    This function can be used as a convolution model to determine
%    the energy flux [keV/s/cm^2] of the model in the energy range
%    given by \code{E_min} and \code{E_max}. Only bins within(!) this energy range
%    are considered for the calculation of the flux. The energy
%    flux is calculated by multiplying the photon flux in each bin
%    by the mean energy of the bin. For that reason the model should
%    be evaluated on a fine grid. It is strongly recommended to use
%    a very fine user grid for this purpose.
%    As this function fits the normalization of the total convolved
%    model, the normalizations of its components are not defined
%    absolutely, but only relativ to each others. For that reason it
%    is meaningful to freeze the normalization of one component, at
%    best the one of the continuum to avoid ambiguities during
%    fitting.
%
%    IMPORTANT:
%    1) E_min and E_max have to be completely covered by the data grid
%    2) the function requires a fine grid for evaluation
%    3) absolute normalizations of functions convolved with enflux are useless
%    
%    If the 1) and 2) are not fulfilled by the data (RMF grid), a user
%    grid has to be used (see example). In case 1) the command:
%    \code{set_kernel (data_id, "std;eval=all");} is required in order to
%    evaluate the model on bins outside of the range of data set \code{data_id}
%    (see set_eval_grid_method).
%
%\examples
%    % data definition:
%    \code{variable lo = _A([1:10]);}
%    \code{variable hi = make_hi_grid(lo);}
%    \code{variable my_data = define_counts(lo,hi,lo,sqrt(lo));}\n
%    \code{variable my_emin = 2.5;}
%    \code{variable my_emax = 6.5;}
%    % defining a fine user grid
%    \code{define fine_grid(id, s)}
%    \code{\{}
%    \code{   (s.bin_lo,s.bin_hi) = _A(log_grid(1,10,1000));}
%    \code{   return s;}
%    \code{\}}
%    
%    \code{set_eval_grid_method (USER_GRID, my_data, &fine_grid);}\n
%    \code{fit_fun("enflux(1,powerlaw(1))");}
%
%    \code{set_par("enflux(1).E_min",  my_emin,  1); % keV}
%    \code{set_par("enflux(1).E_max",  my_emax,  1); % keV}
%    \code{freeze("powerlaw(1).norm");}
%    \code{()=fit_counts();}
%    \code{list_par;}
%
%
%    % It is also possible to determine only the flux of certain
%    % model components, e.g., the unabsorbed flux:
%    \code{fit_fun(phabs(1)*enflux(1, powerlaw(1)));}
%
%\seealso{phflux, set_eval_grid_method}
%!%-
{
  variable flux = par[0];
  variable l1 = _A(par[2]);
  variable l2 = _A(par[1]);

  variable norm_value;
  variable store_norm = qualifier("norm");

  if (Fit_Verbose >= 0 && (l1 < lo[0] or l2 > hi[-1]))
    vmessage("warning: enflux energy range (%.2e-%.2e keV) not covered by data grid (%.2e-%.2e keV)",
	     par[1],par[2],_A(hi[-1]),_A(lo[0]));
  variable i = where(l1 <= lo and hi <= l2);
  variable mean_e = _A(1.)/(0.5*(hi+lo)[i]);
  norm_value = sum( mean_e*y[i] );

  if (typeof(store_norm) == Ref_Type)
    @store_norm = norm_value;
    
  return y * flux / norm_value;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define enflux_default(i)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{ switch(i)
  { case 0: return struct{value=0.1, freeze=0, min=0, max=1e20, hard_min=0, hard_max=1e100, step=1e-5, relstep=1e-3};}
  { case 1: return (3.0 , 1, 0, 1e20 ); }
  { case 2: return (10. , 1, 0, 1e20 ); }
}

add_slang_function("enflux", ["enflux [keV/s/cm^2]", "E_min [keV]", "E_max [keV]"], [0]);
set_param_default_hook("enflux", "enflux_default");
set_function_category("enflux", ISIS_FUN_OPERATOR);
