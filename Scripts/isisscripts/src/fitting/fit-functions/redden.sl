define redden_fit(lo, hi, par)
%!%+
%\function{redden (fit-function)}
%\synopsis{fits the reddening of optical/UV data}
%\description
%	This function uses fm_unred to fit the reddening of optical/UV data.
%	See fm_unred for details.
%
%\examples
%    % data definition:
%    load_data("optical.pha");
%    fit_fun("redden(1)*powerlaw(1)");
%    
%
%\seealso{fm_unred}
%!%-
{
  %%%%%%%%%%%%%%%%%%%
  %  variable wave= struct{  V=5468, U=3465, B=4392, UVW1=2600, UVW2=1928, UVM2=2246 };
  %  We don't need the wavelength, since middle of bin energy \sim  wavelength%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%5

    variable flux=lo*0+1.;       %We only need the factor
    variable wave = 0.5* (lo+hi);

    %%%%%%%%%%%%%%%%%%%%%%
    variable nh=par[1]*1e22;
    variable rv=par[0];
    variable fac = fm_unred(wave, flux; N_H=nh, R_V=rv,wilm);
    fac[where (fac>1e308)]=1;  %should not be this high -> Need to fix energy range sometime soon
    return 1.0/(fac);
}

add_slang_function("redden", ["R [ ]","nH [10^22/cm^2]"]);

private define redden_defaults(i)
{
    switch(i)
    {case 0 : return (3.1, 1, 2, 8); } % Extinktion: Default R_V= 3.1
    {case 1 : return (0.1, 1, 0, 50);  }
    
}

set_param_default_hook("redden", &redden_defaults);
