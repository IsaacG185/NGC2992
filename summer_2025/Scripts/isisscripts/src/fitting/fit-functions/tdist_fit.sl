require("gsl", "gsl");

define tdist_fit(bin_lo, bin_hi, par)
%!%+
%\function{tdist_fit}
%\synopsis{Fitting a student's t-distribution to data in energy space}
%\usage{fit_fun("tdist");}
%\description
%    Student's t-distribution with LineE being the centroid energy,
%    Width the full width at half maximum and nu the number of degrees
%    of freedom. nu=1 reproduces a Lorentzian, nu->infty a Gaussian.
%\seealso{tdist_pdf}
%!%-
{
  variable norm = par[0];
  variable linee = par[1];
  variable sigma = par[2];
  variable nu = par[3];
  
  variable energy_grid = .5*(_A(bin_hi) + _A(bin_lo));
  array_reverse(energy_grid);
  
  variable gamma = sigma/2.;
  variable tdist = 1/gamma * gsl->tdist_pdf((energy_grid-linee)/gamma, nu);
  
  %% Non-central t-distribution (https://en.wikipedia.org/wiki/Noncentral_t-distribution#Probability_density_function)
  % variable A = hyperg_1F1((nu+1)/2., 0.5, mu^2*t^2/(2*(t^2+nu)));
  % variable B_prefac = sqrt(2)*mu*t/sqrt(t^2+nu) * gamma(nu/2.+1)/gamma((nu+1)/2.);
  % variable B = B_prefac * hyperg_1F1(nu/2.+1, 3/2., mu^2*t^2/(2*(t^2+nu))); 
  % variable noncentral_tdist = norm * tdist_pdf(energy_grid, nu) * exp(-mu^2/2.) * (A + B);
  
  return norm * tdist;
}

define tdist_default(i)
{
  switch(i)
  { case 0: return (1   , 0   , 0   , 1e10); }
  { case 1: return (1   , 0   , 0   , 1000); }
  { case 2: return (1   , 0   , 1e-6, 100 ); }
  { case 3: return (1   , 0   , 1   , 1000); }
}

add_slang_function("tdist", ["norm", "LineE", "Width", "nu"]);
set_param_default_hook("tdist", &tdist_default);
