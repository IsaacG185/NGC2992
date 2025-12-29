%%%%%%%%%%%%%%%%%%%%%%%%
define simple_gpile3_fit(lo, hi, par, fun)
%%%%%%%%%%%%%%%%%%%%%%%%
{
  % 2011-02    - parameterize beta relative to  beta0 = 3 * Dlambda * Tframe
  % 2007-08-14 - fracexpo does not have to be an array
  % 2007-05-03 - correct rebinning of the arf
  % 2007-01-22 - no explicit refering to max(mod_cts)
  % 2005-10-25 - New and improved functionality, especially
  %              in the dithered regions of the chips!

  variable beta = par[0];
  if(beta == 0.)
    return fun;  % quick escape; nothing to be changed

  variable info = get_data_info(Isis_Active_Dataset);

  % get ARF index (not necessarily the same as Isis_Active_Dataset)
  variable arf_indx = info.arfs;

  % get ARF data
  variable arf = get_arf(arf_indx[0]);

  % In dither regions (or bad pixel areas), counts are down not
  % from lack of area, but lack of exposure.  Pileup fraction
  % therefore should scale with count rate assuming full exposure.
  % Use the arf "fracexpo" column to correct for this effect
  variable fracexpo = get_arf_info(arf_indx[0]).fracexpo;
  if(length(fracexpo)>1)
    fracexpo[where(fracexpo==0)] = 1.;
  else
    if(fracexpo==0)  fracexpo = 1.;

  % get ("corrected") model counts spectrum
  variable mod_cts
    = fun * rebin(lo, hi,
	          arf.bin_lo, arf.bin_hi,
	          arf.value/fracexpo*(arf.bin_hi-arf.bin_lo)   % = "bin-integrated" ARF (cm^2*A), needed for rebinning
	         )                  /sqr(     hi-        lo);  % one factor (hi-lo) to get again a bin-averaged ARF
                                                               % second to go from  bin-integrated(ph/cm^2/s) * bin-average(cm^2)
                                                               %                to  bin-density(cts/s/A)

  % Use 2nd and 3rd order arfs to include their contribution.
  % Will probably work best if one chooses a user grid that extends
  % from 1/3 of the minimum wavelength to the maximum, and has
  % at least 3 times the resolution of the first order grid.
  variable indx, mod_ord;
  if(par[1] > 0)
  {
    indx = int(par[1]);
    arf = get_arf(indx);
    fracexpo = get_arf_info(indx).fracexpo;
    if(length(fracexpo)>1)
      fracexpo[where(fracexpo==0)] = 1.;
    else
      if(fracexpo==0)  fracexpo = 1.;
    mod_ord = arf.value/fracexpo * rebin(arf.bin_lo, arf.bin_hi,  lo, hi,  fun);
    mod_cts += rebin(lo, hi,
		     2*arf.bin_lo, 2*arf.bin_hi,
		     mod_ord
		    )/(hi-lo);
  }
  if(par[2] > 0)
  {
    indx = int(par[2]);
    arf = get_arf(indx);
    fracexpo = get_arf_info(indx).fracexpo;
    if(length(fracexpo)>1)
      fracexpo[where(fracexpo==0)] = 1.;
    else
      if(fracexpo==0)  fracexpo = 1.;
    mod_ord = arf.value/fracexpo * rebin(arf.bin_lo, arf.bin_hi,  lo, hi,  fun);
    mod_cts += rebin(lo, hi,
		     3*arf.bin_lo, 3*arf.bin_hi,
		     mod_ord
		    )/(hi-lo);
  }

  % Peak pileup correction goes as:
  %    exp( - beta * [spectral count rate] )
  % where [spectral count rate] in given in units of cts/s/A
  % and    beta  ~  beta0 = 3 * Dlambda * Tframe
  %     Dlambda  =   5.5 mA   for HEG  (info.part == 1)
  %              =  11   mA   for MEG  (info.part == 2)
  if(1 <= info.part <= 2)  % for Chandra HETGS spectrum
    beta *= 3 * 0.0055*info.part * info.frame_time;
  else
    vmessage("warning: get_data_info(%d).part==%d\n =>  beta is in units of [s*A/cts] and not [beta0 = 3*Dlambda * Tframe",
	     Isis_Active_Dataset, info.part);
  return exp(-beta * mod_cts) * fun;

  % References: Nowak et al. (2008), ApJ, 689 : 1199-1214
  %             Hanke et al. (2009), ApJ, 690 : 330-346
}

add_slang_function("simple_gpile3", ["beta [beta0]", "arf2_indx", "arf3_indx"]);
set_function_category("simple_gpile3", ISIS_FUN_OPERATOR);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define simple_gpile3_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
   switch(i)
   { case 0: return (1, 1, 0,  10); }
   { case 1: return (0, 1, 0, 100); }
   { case 2: return (0, 1, 0, 100); }
}

set_param_default_hook("simple_gpile3", "simple_gpile3_defaults");
