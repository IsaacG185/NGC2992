require("gsl","gsl"); 

%!%+
%\function{gauss_2d_integrated}
%\synopsis{fit a two dimensional Gaussian profile to a bin integrated image}
%\description
%    For fitting 2d data, define_counts_2d can be used to define
%    a pseudo 1d spectrum by reshaping arrays.
%    Contrary to \code{gauss_2d} this function allows to fit bin
%    integrated values. Before using the fit function \code{gauss_2d_integrated}
%    the "counts" have to be defined with \code{define_counts_2d} and the
%    data grid has to be defined with \code{set_2d_data_grid}.
%    To fit integrated values (X_lo,X_hi, Y_lo, Y_hi) have to be specified
%    in \code{set_2d_data_grid}.
%\examples
%    variable delt = 0.1;
%    variable X = [-2:2:delt];
%    variable Y = @X;%
%    variable XX, YY;  (XX, YY) = get_grid(X, Y);
%    variable img = cos(XX)^2*cos(YY)^2*100;
%
%    variable id = define_counts_2d (img);
%    set_2d_data_grid (X-0.5*delt, X+0.5*delt,Y-0.5*delt, Y+0.5*delt); % valid value in pixel center
%    fit_fun("gauss_2d_integrated(1)");
%    set_fit_statistic ("chisqr;sigma=gehrels");
%    set_par("gauss_2d_integrated(1).x0",0);
%    set_par("gauss_2d_integrated(1).A", sum(img));
%    ()=fit_counts;
%    plot_image(get_2d_model(id));
%\seealso{gauss_2d, define_counts_2d, set_2d_data_grid}
%!%-

%%%%%%%%%%%%%%%%%%%
define gauss_2d_integrated_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%
{
  variable x0 = par[0];
  variable y0 = par[1];
  variable sx = par[2];
  variable sy = par[3];
  variable A  = par[4];

  variable X,X_hi, Y,Y_hi;
  (X,X_hi, Y,Y_hi) = get_2d_data_grid(;bins);
  
  variable valx = 0.5*( gsl->erf((X_hi-x0)/(sqrt(2)*sx)) - gsl->erf((X-x0)/(sqrt(2)*sx)));
  variable valy = 0.5*( gsl->erf((Y_hi-y0)/(sqrt(2)*sy)) - gsl->erf((Y-y0)/(sqrt(2)*sy)));

  variable valXX, valYY;  (valXX, valYY) = get_grid(valx, valy);
  return A * valXX * valYY;
}

%%%%%%%%%%%%%%%%%%%%%%%%
define gauss_2d_integrated_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return 0, 0, -1e10, 1e10; }
  { case 1: return 0, 0, -1e10, 1e10; }
  { case 2: return 1, 0, 1e-10, 1e10; }
  { case 3: return 1, 0, 1e-10, 1e10; }
  { case 4: return 1, 0, 0, 1e10; }
}

add_slang_function("gauss_2d_integrated", ["x0", "y0", "sx", "sy", "A"]);
set_param_default_hook("gauss_2d_integrated", "gauss_2d_integrated_defaults");
