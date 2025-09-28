%%%%%%%%%%%%%%%%%%%%%%%%
private define galridge_fit(lo, hi, par)
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{galridge (fit-function)}
%\synopsis{model for Galactic Ridge Emission}
%\description
%    Model for Galactic Ridge emission based on measurements
%    and analysis by:
%    Ebisawa, K., et al., 2008, PASJ, 60, S223-S230
%    Obst, M., 2011, Bsc-Thesis, Remeis observatory
%
%    The model consists of two bremsstrahlung continua and
%    three gaussian emission lines, which originate from
%    neutral, hydrogen- and helium-like Fe K_alpha lines
%    at 6.40, 6.67 and 7.00 keV:
%      2*bremss + 3*egauss
%    The equivlant widths (areas) of those lines are set to
%    free by default, but scaled initially by
%      85:458:129
%    as found by Ebisawa. To fix those ratios or different
%    ones, one might use 'set_par_fun', e.g.
%    
%    set_par_fun("galridge(1).Fe67","galridge(1).Fe64/85*458");
%    set_par_fun("galridge(1).Fe70","galridge(1).Fe64/85*129");
%
%    The line widths are all freezed to 0.05 keV.
%    The two continua are each described by a normalization
%    factor (norm1/norm2) and a plasma temperature (kT1/kT2).
%    By default, the second bremsstrahlung continuum is
%    disabled by setting its norm to zero.
%\seealso{bremss,egauss,set_par_fun}
%!%-
{
  % parameters of the Bremsstrahlung models [norm, kT]
  variable bremss1Par = par[[0,2]];
  variable bremss2Par = par[[1,3]];
  % parameters of the iron lines [area, center, sigma]
  variable egauss1Par = [par[4], 6.40, 0.05];
  variable egauss2Par = [par[5], 6.67, 0.05];
  variable egauss3Par = [par[6], 7.00, 0.05];
  % 2*bremss + 3*egauss
  return eval_fun2("bremss", lo, hi, bremss1Par)
       + eval_fun2("bremss", lo, hi, bremss2Par)
       + eval_fun2("egauss", lo, hi, egauss1Par)
       + eval_fun2("egauss", lo, hi, egauss2Par)
       + eval_fun2("egauss", lo, hi, egauss3Par);        
}

private define galridge_default(i)
{
 variable defs = Struct_Type[7], w = 1e-5, s1 = 458./85, s2 = 129./85;
 defs[0] = struct { value = 0.01, freeze = 0, min = 0, max = 0.1,  hard_min = 0, hard_max = 1  , step = 1e-4, relstep = 1e-5 };
 defs[1] = struct { value = 0,    freeze = 1, min = 0, max = 0.2,  hard_min = 0, hard_max = 1  , step = 1e-4, relstep = 1e-5 };
 defs[2] = struct { value = 4,    freeze = 0, min = 0, max = 30,   hard_min = 0, hard_max = 100, step = 1e-2, relstep = 1e-5 };
 defs[3] = struct { value = 2,    freeze = 1, min = 0, max = 15,   hard_min = 0, hard_max = 100, step = 1e-2, relstep = 1e-5 };
 defs[4] = struct { value = w,    freeze = 0, min = 0, max = 0.01, hard_min = 0, hard_max = 1  , step = 1e-7, relstep = 1e-5 };
 defs[5] = struct { value = w*s1, freeze = 0, min = 0, max = 0.01, hard_min = 0, hard_max = 1  , step = 1e-7, relstep = 1e-5 };
 defs[6] = struct { value = w*s2, freeze = 0, min = 0, max = 0.01, hard_min = 0, hard_max = 1  , step = 1e-7, relstep = 1e-5 };
 return defs[i];
}

add_slang_function("galridge", ["norm1","norm2","kT1 [keV]","kT2 [keV]","Fe64 [photons/s/cm^2]","Fe67 [photons/s/cm^2]","Fe70 [photons/s/cm^2]"]);
set_param_default_hook("galridge", "galridge_default");
