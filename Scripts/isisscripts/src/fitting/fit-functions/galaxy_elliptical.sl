
public variable is_table_loaded = 0;
public variable galaxy_elliptical_table;

define galaxy_elliptical_fit(lo,hi,par)
%!%+
%\function{galaxy_elliptical (fit-function)}
%\synopsis{fits a host galaxy in the optical/UV}
%\description
%	This function fits an elliptical host galaxy to the data, taking into
%       account the redshift z.
%  
%
%\examples
%    % data definition:
%    load_data("optical.pha");
%    fit_fun("galaxy_elliptical(1)+powerlaw(1)");
%    
%
%!%-
{

  if ( is_table_loaded == 0)
  {
    galaxy_elliptical_table =  ascii_read_table("/userdata/data/krauss/tanami/host_galaxy/all.dat",
						[{"%f", "x"}, {"%f", "E"}, {"%f", "S0"}, {"%f", "Sa"}, {"%f", "Sb"}, {"%f", "Sc"}]);
                                                % loading float (%f instead %F) given the precision
    % provide the table in some other form (function as a modul?) such that it works outside of remeis
    % or define at least a loading function, where the path can be specified (and provide table online)?
    is_table_loaded = 1;
  }
  variable a = galaxy_elliptical_table;
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
  % GET LO-HI GRID in ANGSTROM
  
  variable b_lo=Double_Type[length(a.x)];
  variable b_hi=Double_Type[length(a.x)];
  
  variable x2=a.x*10^4;
  b_lo = x2;
  b_hi = make_hi_grid(b_lo);
  
  % Angstrom rest frame -> Angstrom observed wavelength
  %%%%%%%%%%%%%%%%%%%%%
  variable z0 = par[1];
  variable f0 = par[0];
  
  variable blo = b_lo*(z0+1);
  variable bhi = b_hi*(z0+1);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % GET OPTICAL GRID
  
  %%%%%%%%%%%%%
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % REBIN DATA TO FIT DATA GRID
  
  variable new = rebin_mean (lo, hi, blo, bhi, a.E);
  variable f1 = new*f0;
  
  return f1;
}

add_slang_function("galaxy_elliptical", ["f [normalization factor]","z [ ]"],[0]);
% calculate and provide a proper normalization unit?

private define galaxy_elliptical_defaults(i)
{
  switch(i)
  {case 0 : return (1, 0, 1e-7, 3000); } % Factor
  {case 1 : return (0.01, 1, 0, 10);  } %REDSHIFT
}

set_param_default_hook("galaxy_elliptical", &galaxy_elliptical_defaults);
