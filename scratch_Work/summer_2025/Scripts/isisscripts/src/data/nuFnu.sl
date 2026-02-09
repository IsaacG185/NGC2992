
define nuFnu()
%%%%%%%%%%%%%%%%
%!%+
%\function{nuFnu}
%
%\synopsis{changes an Energy/Flux Spectrum to a Frequency/Flux*Frequency Spectrum}
%\usage{Struct_Type = nuFnu (hist_index, E_min(keV), E_max(keV));}
%
%\description
%    Use this function on a dataset that has been modeled.
%    This function uses get_data_flux/eval_fun_keV to load
%    spectral data into isis and convert energy bins in a 
%    given range to frequency (s^-1) bins as well as Flux 
%    to flux*frequency.
%    If no range specified: E_min=0.5 keV, E_max=10 keV.
%    Values and Errors are given in erg s^-1 cm^-2.
%
%    WARNING: Currently only frequency has been implemented 
%             as x-unit.
%             
%    For the evaluation of a deabsorbed component use the 
%    qualifier "deabs". deabs will try to calculate the 
%    factor between absorbed and deabsorbed model 
%    components and correct the data.
%
%    WARNING: This does not work when a convolution 
%             normalization (e.g., cflux, enflux, phflux)
%             is part of the model!
%
%    The "numbin" qualifier allows to specify the number
%    of output bins. Currently only a logarithmic grid 
%    has been implemented. If numbin is not specified 
%    the flux for the current grid will be returned.
%
%    The "group" qualifier allows to specify the S/N that
%    will be used for the flux calculation. Flux calculations
%    are only correct for large number of bins. The final 
%    grid can be smaller (qualifier: numbin).
%
%
%    WARNING: Currently tested only on low counts spectra.
%             S/N might have to be increased for large 
%             number of counts.
%
%\qualifiers{
%\qualifier{deabs}{   evaluate deabsorbed flux}
%\qualifier{ff}{      define deabsorbed fit function}
%\qualifier{numbin}{  define number of bins}
%\qualifier{group}{  define S/N for grouping}
%}
%
%\example
%    isis>xray = load_data("data.pha");
%    isis>load_par("x.par");
%    isis>() = fit_counts;
%    isis>new=nuFnu(xray,2,10);	 %change spectrum (2-10 keV) into frequency spectrum
%
%    %Plot data:
%    isis>hplot(new.lo, new.hi, new.val);
%
%    % Evaluate Function for deabsorbed model
%    % (WARNING: DOES NOT WORK IF ENFLUX IS USED IN FIT FUNCTION)
%
%    isis>xray = load_data("data.pha");
%    isis>fit_fun("tbnew_simple_z(1)*powerlaw(1)");
%    isis>() = fit_counts;
%    isis>new = nuFnu(xray,2,10; deabs, ff="powerlaw(1)");
%    isis>%Calculate a deabsorbed powerlaw
%
%\seealso{get_data_flux, rebin_mean, eval_fun_keV, group}
%!%-
{
    variable dset;
    variable emin = NULL, emax = NULL;
    switch(_NARGS)
    { case 1: dset  = (); }
    { case 3: (dset,emin,emax) = ();}
    { help(_function_name()); return; }

    variable deabs = qualifier("deabs");  
    variable ffq = qualifier("ff", NULL);
    variable numbin = qualifier("numbin", NULL);  
    variable sngroup = qualifier("group", NULL); 

    % Check if emin & emax & numbin have been specified

    if (emin == NULL) 
    {
	emin=0.5;
    }
    if (emax == NULL) 
    {
	emax=10.;
    }


    % Define Constants 

    variable pla = 4.13566751e-18; %planck in keV*s
    variable newflu, newerr,newfac,blo,bhi;

    % Rebin here to low S/N
    % Find optimal binning!!

    variable gdi = get_data_info(dset);
    if(length(gdi.notice) != length(gdi.rebin))
    {	
	if (sngroup != NULL)
	{
	    group(dset;min_sn=sngroup,bounds=emin,unit="keV");
	}
    }


    % Get data flux

    flux_corr(dset);

    variable datflux = _A(get_data_flux(dset));
    struct_filter(datflux, where(datflux.bin_lo > 0.99*emin));
    struct_filter(datflux, where(datflux.bin_hi < emax));

    % Central bin energy in erg
    variable bincen = keV2erg(0.5*(datflux.bin_lo+datflux.bin_hi));

    %# FIX THIS LATER!!!!
    % Get bins in Hz
    datflux.bin_lo = datflux.bin_lo/pla;
    datflux.bin_hi = datflux.bin_hi/pla;


    % Central bin energy in Hz
    variable bincenhz = 0.5*(datflux.bin_lo+datflux.bin_hi);

    % Calculate flux values
    datflux.value = datflux.value/(datflux.bin_hi-datflux.bin_lo)*bincen*bincenhz;
    datflux.err = datflux.err/(datflux.bin_hi-datflux.bin_lo)*bincen*bincenhz;


    % Make grid - optional
    if (numbin != NULL)
    {	
	variable logrid,higrid;
        (logrid,higrid) = log_grid(emin/pla,emax/pla,numbin);
	newflu = rebin_mean(logrid,higrid,datflux.bin_lo,datflux.bin_hi,
	datflux.value);
	newerr = rebin_mean(logrid,higrid,datflux.bin_lo,datflux.bin_hi,datflux.err);
	blo = logrid;
	bhi = higrid;
    }
    else
    {
	% Restore bins & bounds
	rebin_data(dset,gdi.rebin);
	notice_list(dset,gdi.notice_list); 

	% Get original binning
	variable datcounts = _A(get_data_counts(dset));
	struct_filter(datcounts, where(datcounts.bin_lo > 0.99*emin));
	struct_filter(datcounts, where(datcounts.bin_hi < emax));

	% Get bins in Hz
	datcounts.bin_lo = datcounts.bin_lo/pla;
	datcounts.bin_hi = datcounts.bin_hi/pla;


	blo = datcounts.bin_lo;
	bhi = datcounts.bin_hi;
	
	if (length(datcounts.bin_lo) != length(datflux.bin_lo))
	{
	    newflu = rebin_mean(datcounts.bin_lo,datcounts.bin_hi,datflux.bin_lo,datflux.bin_hi,datflux.value);
	    newerr = rebin_mean(datcounts.bin_lo,datcounts.bin_hi,datflux.bin_lo,datflux.bin_hi,datflux.err);
	}
	else
	{
	    newflu = datflux.value;
	    newerr = datflux.err;
	}


    }

    % Get Absorption Factor

    if (qualifier_exists("deabs"))
    {
	variable gff = get_fit_fun;
	save_par("yxzylabyxpar.par");
	if (gff == NULL) 
	{
	    vmessage("No Fit Function specified");
	    variable all_data_n;
	}
	else
	{
	    % Get Fit Functions
	    variable agd = _A(get_data_counts(1));
	    struct_filter(agd, where(agd.bin_lo > 0.99*emin));
	    struct_filter(agd, where(agd.bin_hi < emax));
	    variable abs2 = eval_fun_keV(agd.bin_lo, agd.bin_hi);
	    fit_fun(ffq);
	    variable newgff = get_fit_fun;
	    vmessage(sprintf("Deabsorbed Fit Function found: %s", newgff));
	    vmessage(sprintf("Fit Function found: %s", gff));

	    variable fverb = Fit_Verbose;
	    Fit_Verbose=-1;
	    () = eval_counts;
	    Fit_Verbose=fverb;
	   
	    variable deabs2 = eval_fun_keV(agd.bin_lo, agd.bin_hi);

	    %Calculate deabsorbing factor
	    variable factor=deabs2/abs2;

	    if (numbin != NULL)
	    {
		newfac = rebin_mean(logrid,higrid,datflux.bin_lo,datflux.bin_hi,factor);
	    }
	    else 
	    {

		if (length(datcounts.bin_lo) != length(datflux.bin_lo))
		{
		    newfac = rebin_mean(datcounts.bin_lo,datcounts.bin_hi,datflux.bin_lo,datflux.bin_hi,factor);
		}
		else
		{
		    newfac=factor;
		}
		
	    }

	    newflu = newflu*newfac;
	    newerr = newerr*newfac;

	}
    }
    
    variable new_struct = struct {bin_lo = blo, bin_hi = bhi, value=newflu, err=newerr };

    return new_struct;
}

