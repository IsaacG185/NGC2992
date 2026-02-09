require( "gsl", "gsl" );

%%%%%%%%%%%%%%%%%%%%
define cutoffpl2_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{cutoffpl2 (fit-function)}
%\synopsis{describes a power law with exponential cutoff in wavelength space}
%\description
%    S(l) = \code{norm} * l^(-\code{index}) * exp(-l/\code{cutoff})\n
%    The bin-integrated cutoffpl2 fit-function is computed
%    by the incomplete Gamma-function from the GSL library.
%    (The original cutoffpl didn't converge for low energies.)
%\seealso{cutoffpl, gamma_inc}
%!%-
{
  variable norm = par[0];
  variable index = par[1];
  variable cutoff = par[2];
  return norm * cutoff^(1-index) * ( gsl->gamma_inc(1-index, bin_lo/cutoff) - gsl->gamma_inc(1-index, bin_hi/cutoff) );
}

add_slang_function("cutoffpl2", ["norm", "index", "cutoff"]);


%%%%%%%%%%%%%%%%%%%%%%%%%
define cutoffpl2_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return ( 1, 0,  0, 1e10); }
  { case 1: return ( 1, 0, -2,    9); }
  { case 2: return (15, 0,  1,   50); }
}

set_param_default_hook("cutoffpl2", "cutoffpl2_defaults");


  % test code
% variable E_lo, E_hi; (E_lo, E_hi) = log_grid(0.001, 1e3, 10000);
% variable pars = [1, 1, 250];
% fit_fun("cutoffpl(1)");
% set_par(1, pars[0], 0, pars[0], pars[0]);
% set_par(2, pars[1], 0, pars[1], pars[1]);
% set_par(3, pars[2], 0, pars[2], pars[2]);
% variable y1 = eval_fun_keV(E_lo, E_hi);
% variable y2 = eval_fun2("cutoffpl2", E_lo, E_hi, pars);
% multiplot([1,1]); xlog; ylog;
% yrange;
%  hplot(E_lo, E_hi, y1);
% ohplot(E_lo, E_hi, y2);
% yrange(0.5,);
% hplot(E_lo, E_hi, y1/y2);
