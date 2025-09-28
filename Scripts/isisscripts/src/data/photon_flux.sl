define photon_flux()
%!%+
%\function{photon_flux}
%
%\synopsis{}
%\usage{String_Type = photon_flux (hist_index, E_min, E_max);}
%\description
%	This function returns the integrated photon flux of
%	a defined Energy range. 
%	If no energy range specified E_min=0.5, E_max=10.
%
%\seealso{get_data_flux;}
%!%-
 { 
variable dset;
variable emin = NULL, emax = NULL;

switch(_NARGS)
  { case 1: dset  = (); }
  { case 3: (dset,emin,emax) = ();}
  { help(_function_name()); return; }

    
    %%%%%%%%%%%%%
    %Check if Emin & Emax have been specified
    %%%%%%%%%%
    
    if (emin == NULL) emin=0.5;
    if (emax == NULL) emax=10;
        
    %Get Data Counts in Angstrom,
    %Change Bins to keV
    
    flux_corr(dset);
    variable gdfa = _A(get_data_flux(dset)); 
  %  variable gdfk =_A(gdfa);
    
    %%%%%%%%%%
    %% Only notice defined energy range
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    struct_filter(gdfa, where(gdfa.bin_lo>emin));
    struct_filter(gdfa, where(gdfa.bin_hi<emax));


      
    variable gdf =sum(gdfa.value);

    return gdf;    
}
