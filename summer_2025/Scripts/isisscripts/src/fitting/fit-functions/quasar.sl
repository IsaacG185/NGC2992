
public variable is_table_accr_loaded = 0;
public variable quasar_table;



define quasar_accr_fit(lo,hi,par)
%!%+
%\function{quasar_accr (fit-function)}
%\synopsis{fits a composite quasar spectra in the optical/UV}
%\description        
%	This function fits a composite quasar spectrm to the data, taking into
%       account the redshift z. see Vanden Berk et al. 2001
%  
%
%\examples
%    % data definition:
%    load_data("optical.pha");
%    fit_fun("quasar_accr(1)+powerlaw(1)");
%    
%
%!%-
{

 if ( is_table_accr_loaded == 0)
 {
     quasar_table =  ascii_read_table("/userdata/data/krauss/tanami/host_galaxy/datafile1.txt", [{"%F", "wavelength"}, {"%F", "Flux"} ]); %, {"%F", "Err"}]);

     is_table_accr_loaded = 1;
 }


variable a = quasar_table;

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% GET LO-HI GRID in ANGSTROM

variable b_lo=Double_Type[length(a.wavelength)];
variable b_hi=Double_Type[length(a.wavelength)];

b_lo = a.wavelength;
b_hi = make_hi_grid(b_lo);

% Angstrom rest frame -> Angstrom observed wavelength
%%%%%%%%%%%%%%%%%%%%%
variable z0 = par[1];
variable f0 = par[0];


variable blo = b_lo*(z0+1);
variable bhi = b_hi*(z0+1);

variable mblo = min(blo);
variable mablo = max(blo);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REBIN DATA TO FIT DATA GRID

variable flu=a.Flux;
variable new = rebin_mean (lo, hi, blo, bhi, flu);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USE ONLY OPTICAL DATA IN DATA GRID
variable i;


_for i (0, length(new)-1,1){
    if (lo[i]<mblo){
	new[i] = 0;
    }
}

_for i (0, length(new)-1,1){
    if (hi[i]>mablo){
	new[i] = 0;
    }
}


variable f1 = new*f0;


return f1;

}
add_slang_function("quasar_accr", ["f [ ]","z [ ]"]);

private define quasar_accr_defaults(i)
{
   switch(i)
     {case 0 : return (1, 0, 0.001, 3000); } % Factor
     {case 1 : return (0.01, 1, 0, 10);  } %REDSHIFT
 
}

set_param_default_hook("quasar_accr", &quasar_accr_defaults);
