% -*- slang -*-

% Last Updated: April 12, 2012

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Public Functions in This File

% simple_gpile_fit : Gratings Pileup correction function
%                    (New, better version than in "ABC Guide to Pileup")

% Manfred Hanke's even better simple_gpile + associated functions

% simple_gpile2_fit 
% use_simple_gpile
% get_unpiled_fit_fun
% get_unpiled_data_flux

% The following work presuming data x-axis follows keV (i.e., Hz -> keV
% for PSD):

% mgauss_fit     : Gaussian absorption that's never < 0 (multiplicative)
% qpo_fit        : Lorentzian, normalized to QPO rms (counts/bin)
% zfc_fit        : Zero-frequency centered Lorentzian (counts/bin)
% plaw_fit       : Counts/bin power-law
% bkn_plaw_fit   : Counts/bin broken power-law
% dbkn_plaw_fit  : Counts/bin doubly broken power-law
% rms_gauss_fit  : Counts/bin Guassian, normalized to RMS.
% sinwave_fit    : Counts/bin sine wave
% four_chip_fit  : Renorm for specific ACIS chips
% three_chip_fit : Renorm for specific ACIS chips
% chip()         : Combining the above two

% The following work presuming x-axis follows Angstrom:

% aqpo_fit       : Lorentzian, normalized to QPO rms (counts/bin)
% azfc_fit       : Zero-frequency centered Lorentzian (counts/bin)
% aplaw_fit      : Counts/bin power-law
% abkn_plaw_fit  : Counts/bin broken power-law
% adbkn_plaw_fit : Counts/bin doubly broken power-law
% asinwave_fit   : Counts/bin sine wave
% asqrwave_fit   : Counts/bin square wave

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define param_default_structure(value,freeze,pmin,pmax,
                                             hmin,hmax,pstep,prstep)
{
   variable param_def = struct{value, freeze, min, max,
                               hard_min, hard_max, step, relstep};
   param_def.value=value;
   param_def.freeze=freeze;
   param_def.min=pmin;
   param_def.max=pmax;
   param_def.hard_min=hmin;
   param_def.hard_max=hmax;
   param_def.step=pstep;
   param_def.relstep=prstep;
   return param_def;
}

%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%% 
%% Minus Gaussian  %% 
%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%% 

define mgauss_fit(lo,hi,par)
{  
   % par[0] is unit normalization
   variable norm = par[0];

   % par[1] is line energy in keV
   variable kev = par[1];

   % par[2] is line width (sigma) in keV 
   variable sig = par[2];

   variable eavg = reverse(_A(lo)+_A(hi))/2.;
   variable scl = (1. - norm * exp(-((eavg-kev)/sig)^2/2.) );

   variable iw = where( scl < 0. );
   scl[iw] = 0.;
  
   return scl;
}

add_slang_function("mgauss",["norm","LineE","Sigma"]);

define mgauss_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(1.,0,0.,100.,0.,100.,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(6.7,0,0.001,1000.,1.e-6,1.e6,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(0.1,0,0.0001,10.,1.e-8,1.e6,1.e-3,1.e-3);
   }
}

set_param_default_hook("mgauss","mgauss_defaults");

%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%
%% QPO (Lorentzian) %% 
%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%

% Define a s-lang qpo that works better. Properly averages over bin,
% and thus yields a smoother fit.

define qpo_fit(lo,hi,par)
{
   variable l,r,q,f,al,ah;

   % Go from Angstrom to keV (which we pretend is Fourier Hz),
   % Hence it's F[(al-f)/f] - F[(ah-f)/f] below...

   al = _A(lo);
   ah = _A(hi);

   q = par[1];
   f = par[2];

   % In this formulation, par[0] is rms amplitude

   r = par[0]/(0.5 - atan(-2.*q)/PI);

   l = r^2/(al-ah)/PI * 
       ( atan(2.*q*(al-f)/f) - atan(2.*q*(ah-f)/f) );

   l = reverse(l);

   return l;
}

add_slang_function("qpo",["norm [rms]","Q [f/FWHM]","f [Hz]"]);

define qpo_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,0.,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,0.01,1.e3,1.e-6,1.e9,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1,0,0.,1.e4,0.,1.e16,1.e-3,1.e-3);
   }
}

set_param_default_hook("qpo","qpo_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Zero Freq. Centered Lorentzian  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define zfc_fit(lo,hi,par)
{
   variable a,f,al,ah,l;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),
   % Hence it's atan(al/f) - atan(ah/f) below...

   al = _A(lo);
   ah = _A(hi);
   f = par[1];
   
   % In this formulation, par[0] is RMS

   a = par[0]^2 * PI/2./f;

   l = a*f/(al-ah) *  ( atan(al/f) - atan(ah/f) );

   l = reverse(l);

   return l;
}

add_slang_function("zfc",["norm [rms]","f [Hz]"]);

define zfc_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,1.e-6,1.e3,0,1.e16,1.e-3,1.e-3);
   }
}

set_param_default_hook("zfc","zfc_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Counts/Bin Powerlaw  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

define plaw_fit(lo,hi,par)
{
   variable a,s,al,ah,l;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),

   al = _A(lo);
   ah = _A(hi);

   a = par[0];
   s = par[1];
   
   if(s != -1)
   {
      l = a/(s+1) * (al^(s+1) - ah^(s+1));
   }
   else
   {
      l = a * ( log(al) - log(ah) );
   }

   l = reverse(l/(al - ah));

   return l;
}

add_slang_function("plaw",["norm","slope"]);

define plaw_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,0.,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(-2,0,-5,5,-10,10,1.e-3,1.e-3);
   }
}

set_param_default_hook("plaw","plaw_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Broken Counts/Bin Powerlaw  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define bkn_plaw_fit(lo,hi,par)
{
   variable a,sa,b,sb,al,ah,aa,l;
   variable iwl,iwh,liwl,liwh;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),

   al = _A(lo);
   ah = _A(hi);
   aa = (al+ah)/2.;
   l = @al;

   a = par[0];
   sa = par[1];
   b = par[2];
   sb = par[3];

   iwl = where(aa<= b);
   iwh = where(aa > b);

   liwl = length(iwl);
   liwh = length(iwh);
   
   if(liwl != 0)
   {
      l[iwl] = a * aa[iwl]^sa;
   }

   if(liwh != 0)
   {
      l[iwh] = a * b^sa * ( aa[iwh]/b )^sb;
   }

   l = reverse(l);

   return l;
}

add_slang_function("bkn_plaw",["norm","slope_1","f_break [Hz]","slope_2"]);

define bkn_plaw_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(0,0,-5,5,-10,10,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1,0,0.,1.e4,0.,1.e16,1.e-3,1.e-3);
   }
   {case 3:
      return param_default_structure(-2,0,-5,5,-10,10);
   }
}

set_param_default_hook("bkn_plaw","bkn_plaw_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Double Broken Counts/Bin Powerlaw  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define dbkn_plaw_fit(lo,hi,par)
{
   variable a,sa,ba,sb,bb,sc,al,ah,aa,l;
   variable iwl,iwm,iwh,liwl,liwm,liwh;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),

   al = _A(lo);
   ah = _A(hi);
   aa = (al+ah)/2.;
   l = @al;

   a = par[0];
   sa = par[1];
   ba = par[2];
   sb = par[3];
   bb = par[4];
   sc = par[5];

   iwl = where(aa <= ba);
   iwm = where(aa > ba and aa <= bb);
   iwh = where(aa > bb);

   liwl = length(iwl);
   liwm = length(iwm);
   liwh = length(iwh);
   
   if(liwl != 0)
   {
      l[iwl] = a * aa[iwl]^sa;
   }

   if(liwm != 0)
   {
      l[iwm] = a * ba^sa * ( aa[iwm]/ba )^sb;
   }

   if(liwh != 0)
   {
      l[iwh] = a * ba^sa * (bb/ba)^sb * (aa[iwh]/bb)^sc;
   }

   l = reverse(l);

   return l;
}

add_slang_function("dbkn_plaw",["norm","slope_1","f_brk_1 [Hz]",
                   "slope_2","f_brk_2 [Hz]","slope_3"]);

define dbkn_plaw_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(0,0,-5,5,-10,10,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1,0,0.,1.e4,0.,1.e16,1.e-3,1.e-3);
   }
   {case 3:
      return param_default_structure(-1,0,-5,5,-10,10,1.e-3,1.e-3);
   }
   {case 4:
      return param_default_structure(10,0,0.,1.e4,0.,1.e16,1.e-3,1.e-3);
   }
   {case 5:
      return param_default_structure(-2,0,-5,5,-10,10,1.e-3,1.e3);
   }
}

set_param_default_hook("dbkn_plaw","dbkn_plaw_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Counts/Bin Gaussian Normalized to RMS  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#ifexists erf

define rms_gauss_fit(lo,hi,par)
{
   variable r,f,sig,al,ah,l;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),

   al = _A(lo);
   ah = _A(hi);

   r = par[0];
   f = par[1];
   sig = sqrt(2.)*par[2];

   l = r^2/2 * ( erf( (al-f)/sig ) - erf( (ah-f)/sig ) );
   l = reverse(l/(al-ah));

   return l;
}

add_slang_function("rms_gauss",["norm [rms]","f_0 [Hz]","sigma [Hz]"]);

define rms_gauss_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,0,1.e4,0.,1.e16,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(0.2,0,1.e-4,1.e3,1.e-16,1.e16,1.e-3,1.e-3);
   }
}

set_param_default_hook("rms_gauss","rms_gauss_defaults");

#endif

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Counts/bin Sine Wave %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

define sinwave_fit(lo,hi,par)
{
   variable a,f,phs,al,ah,l;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),

   al = _A(lo);
   ah = _A(hi);

   a = par[0];
   f = par[1];
   phs = par[2];

   l = a * ( -cos(2*PI*(f*al-phs)) + cos(2*PI*(f*ah-phs)) )/2/PI/f/(al-ah);
   l = reverse(l);

   return l;
}

add_slang_function("sinwave",["norm","freq","phase"]);

define sinwave_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,0,1.e4,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(0,0,0.,1.,0.,1.,1.e-3,1.e-3);
   }
}

set_param_default_hook("sinwave","sinwave_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define four_chip_fit(lo,hi,par)
{  
   % Input, but frozen, lower bin boundaries
   variable lb = [par[4],par[6],par[8],par[10]];

   % Input, but frozen, upper bin boundaries
   variable ub = [par[5],par[7],par[9],par[11]];

   % Input effective area constants
   variable ec = [par[0],par[1],par[2],par[3]];

   variable scl = 1.*ones(length(lo));
   variable avg = (lo+hi)/2.;

   variable iw = Array_Type[4];
   variable ib = Array_Type[3];

   variable i=0;
   loop(4)
   {
      iw = where(avg > lb[i] and avg <= ub[i]);
      scl[iw] = ec[i];

      if(i !=3)
      {
         ib = where(avg > ub[i] and avg <= lb[i+1]);
         scl[ib] = (avg[ib]-ub[i])/(lb[i+1]-ub[i]) *
                   (ec[i+1]-ec[i]) + ec[i];
      }
      
      i++;
   }

   return scl;
}

add_slang_function("four_chip",["ccd7_nrm","ccd6_nrm","ccd5_nrm","ccd4_nrm",
                         "ccd7_lb","ccd7_ub","ccd6_lb","ccd6_ub",
                         "ccd5_lb","ccd5_ub","ccd4_lb","ccd4_ub"]);

define four_chip_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(1.,0,0.8,1.2,0,2,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1.,0,0.8,1.2,0,2,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1.,0,0.8,1.2,0,2,1.e-3,1.e-3);
   }
   {case 3:
      return param_default_structure(1.,0,0.8,1.2,0,2,1.e-3,1.e-3);
   }
   {case 4:
      return param_default_structure(1.068,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 5:
      return param_default_structure(1.557,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 6:
      return param_default_structure(1.597,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 7:
      return param_default_structure(7.372,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 8:
      return param_default_structure(7.436,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 9:
      return param_default_structure(13.202,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 10:
      return param_default_structure(13.255,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
   {case 11:
      return param_default_structure(18.980,1,1.0,40.0,0,100,1.e-3,1.e-3);
   }
}


set_param_default_hook("four_chip","four_chip_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define three_chip_fit(lo,hi,par)
{  
   % Input, but frozen, lower bin boundaries
   variable lb = [par[3],par[5],par[7]];

   % Input, but frozen, upper bin boundaries
   variable ub = [par[4],par[6],par[8]];

   % Input effective area constants
   variable ec = [par[0],par[1],par[2]];

   variable scl = 1.*ones(length(lo));
   variable avg = (lo+hi)/2.;

   variable iw = Array_Type[4];
   variable ib = Array_Type[3];

   variable i=0;
   loop(3)
   {
      iw = where(avg > lb[i] and avg <= ub[i]);
      scl[iw] = ec[i];

      if(i !=2)
      {
         ib = where(avg > ub[i] and avg <= lb[i+1]);
         scl[ib] = (avg[ib]-ub[i])/(lb[i+1]-ub[i]) *
                   (ec[i+1]-ec[i]) + ec[i];
      }
      
      i++;
   }

   return scl;
}

add_slang_function("three_chip",["ccd7_nrm","ccd8_nrm","ccd9_nrm",
                         "ccd7_lb","ccd7_ub","ccd8_lb","ccd8_ub",
                         "ccd9_lb","ccd9_ub"]);

define three_chip_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(1.,0,0.8,1.2,0,10,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1.,0,0.8,1.2,0,10,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1.,0,0.8,1.2,0,10,1.e-3,1.e-3);
   }
   {case 3:
      return param_default_structure(1.065,1,1.0,40.0,0,100.,1.e-3,1.e-3);
   }
   {case 4:
      return param_default_structure(8.381,1,1.0,40.0,0,100.,1.e-3,1.e-3);
   }
   {case 5:
      return param_default_structure(8.568,1,1.0,40.0,0,100.,1.e-3,1.e-3);
   }
   {case 6:
      return param_default_structure(20.060,1,1.0,40.0,0,100.,1.e-3,1.e-3);
   }
   {case 7:
      return param_default_structure(20.079,1,1.0,40.0,0,100.,1.e-3,1.e-3);
   }
   {case 8:
      return param_default_structure(31.258,1,1.0,40.0,0,100.,1.e-3,1.e-3);
   }
}


set_param_default_hook("three_chip","three_chip_defaults");

%%%%%%%%%%%%%

define chip()
{
   switch(Isis_Active_Dataset)
   {
    case 1:
    return four_chip(1);
   }
   {
    case 2:
    return three_chip(2);
   }
   {
    case 3:
    return four_chip(3);
   }
   {
    case 4:
    return three_chip(4);
   }
   {
     return 1;
   }
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Gratings Pileup, Take II  (Better Version %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define simple_gpile_fit(lo,hi,par,fun)
{  
   % Peak pileup correction goes as:
   %    exp(log(1-pfrac)*[counts/max(counts)])

   variable pfrac = par[0];

   % Pileup scales with model counts from *data set* indx ...
   variable indx = typecast(par[1],Integer_Type);

   if( indx == 0 or pfrac == 0. )
   {
      return fun;   % Quick escape for no changes ...
   }

   % ... but the arf index could be a different number, so get that

   variable arf_indx = get_data_info(indx).arfs;

   % Get arf information

   variable arf = get_arf(arf_indx[0]);

   % In dither regions (or bad pixel areas), counts are down not
   % from lack of area, but lack of exposure.  Pileup fraction
   % therefore should scale with count rate assuming full exposure.
   % Use the arf "fracexpo" column to correct for this effect

   variable fracexpo = get_arf_info(arf_indx[0]).fracexpo;
   if( length(fracexpo) > 1 )
   {
      fracexpo[where(fracexpo ==0)] = 1.;
   }
   else if( fracexpo==0 )
   {
      fracexpo = 1;
   }

   % Rebin arf to input grid, correct for fractional exposure, and 
   % multiply by "fun" to get ("corrected") model counts per bin

   variable mod_cts;
   mod_cts = fun * rebin( lo, hi,
                          arf.bin_lo, arf.bin_hi,
                          arf.value/fracexpo*(arf.bin_hi-arf.bin_lo) )
                / (hi-lo);

   % Go from cts/bin/s -> cts/angstrom/s 

   mod_cts = mod_cts/(hi-lo);

   % Use 2nd and 3rd order arfs to include their contribution.
   % Will probably work best if one chooses a user grid that extends
   % from 1/3 of the minimum wavelength to the maximum, and has
   % at least 3 times the resolution of the first order grid.

   variable mod_ord;
   if(par[2] > 0)
   {
      indx = typecast(par[2],Integer_Type);
      arf = get_arf(indx);
      fracexpo=get_arf_info(indx).fracexpo;
      if( length(fracexpo) > 1 )
      {
         fracexpo[where(fracexpo ==0)] = 1.;
      }
      else if( fracexpo==0 )
      {
         fracexpo = 1;
      }
      mod_ord = arf.value/fracexpo*
                rebin(arf.bin_lo,arf.bin_hi,lo,hi,fun);
      mod_ord = rebin(lo,hi,2*arf.bin_lo,2*arf.bin_hi,mod_ord)/(hi-lo);
      mod_cts = mod_cts+mod_ord;
   }
   if(par[3] > 0)
   {
      indx = typecast(par[3],Integer_Type);
      arf = get_arf(indx);
      fracexpo=get_arf_info(indx).fracexpo;
      if( length(fracexpo) > 1 )
      {
         fracexpo[where(fracexpo ==0)] = 1.;
      }
      else if( fracexpo==0 )
      {
         fracexpo = 1;
      }
      mod_ord = arf.value/fracexpo*
                rebin(arf.bin_lo,arf.bin_hi,lo,hi,fun);
      mod_ord = rebin(lo,hi,3*arf.bin_lo,3*arf.bin_hi,mod_ord)/(hi-lo);
      mod_cts = mod_cts+mod_ord;
   }

   variable max_mod = max(mod_cts);
   if(max_mod <= 0){ max_mod = 1.;}

   % Scale maximum model counts to pfrac

   mod_cts = log(1-pfrac)*mod_cts/max_mod;

   % Return function multiplied by exponential decrease

   fun = exp(mod_cts) * fun;
  
   return fun;
}

add_slang_function("simple_gpile",
                   ["pile_frac","data_indx","arf2_indx","arf3_indx"]);

define simple_gpile_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,1,0.,0.5,0.,1.,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,1,0,48,0,100,1,1);
   }
   {case 2:
      return param_default_structure(2,1,0,48,0,100,1,1);
   }
   {case 3:
      return param_default_structure(3,1,0,48,0,100,1,1);
   }
}

set_param_default_hook("simple_gpile", "simple_gpile_defaults");

set_function_category("simple_gpile", ISIS_FUN_OPERATOR);

%%%%%%%%%%%%%%%%%%%%%%% ANGSTROM COUNTS/BIN FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%
%% QPO (Lorentzian) %% 
%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%

% Define a s-lang qpo that works better. Properly averages over bin,
% and thus yields a smoother fit.

define aqpo_fit(lo,hi,par)
{
   variable l,r,q,f,al,ah;

   al = hi;
   ah = lo;

   q = par[1];
   f = par[2];

   % In this formulation, par[0] is rms amplitude

   r = par[0]/(0.5 - atan(-2.*q)/PI);

   l = r^2/(al-ah)/PI * 
       ( atan(2.*q*(al-f)/f) - atan(2.*q*(ah-f)/f) );

   return l;
}

add_slang_function("aqpo",["norm [rms]","Q [f/FWHM]","f [Angstrom]"]);

define aqpo_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,0.01,1.e3,1.e-16,1.e16,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1,0,0.,1.e4,-1.e16,1.e16,1.e-3,1.e-3);
   }
}

set_param_default_hook("aqpo","aqpo_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Zero Freq. Centered Lorentzian  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define azfc_fit(lo,hi,par)
{
   variable a,f,al,ah,l;
 
   % Go from Angstrom to keV (which we pretend is Fourier Hz),
   % Hence it's atan(al/f) - atan(ah/f) below...

   al = hi;
   ah = lo;
   f = par[1];
   
   % In this formulation, par[0] is RMS

   a = par[0]^2 * PI/2./f;

   l = a*f/(al-ah) *  ( atan(al/f) - atan(ah/f) );

   return l;
}

add_slang_function("azfc",["norm [rms]","f [Angstrom]"]);

define azfc_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,1.e-6,1.e3,0,1.e16,1.e-3,1.e-3);
   }
}

set_param_default_hook("azfc","azfc_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Counts/Bin Powerlaw  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

define aplaw_fit(lo,hi,par)
{
   variable a,s,al,ah,l;
 
   al = hi;
   ah = lo;

   a = par[0];
   s = par[1];
   
   if(s != -1)
   {
      l = a/(s+1) * (al^(s+1) - ah^(s+1));
   }
   else
   {
      l = a * ( log(al) - log(ah) );
   }

   l = (l/(al - ah));

   return l;
}

add_slang_function("aplaw",["norm","slope"]);

define aplaw_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(-2,0,-5,5,-10,10,1.e-3,1.e-3);
   }
}

set_param_default_hook("aplaw","aplaw_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Broken Counts/Bin Powerlaw  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define abkn_plaw_fit(lo,hi,par)
{
   variable a,sa,b,sb,al,ah,aa,l;
   variable iwl,iwh,liwl,liwh;
 
   al = hi;
   ah = lo;
   aa = (al+ah)/2.;
   l = @al;

   a = par[0];
   sa = par[1];
   b = par[2];
   sb = par[3];

   iwl = where(aa<= b);
   iwh = where(aa > b);

   liwl = length(iwl);
   liwh = length(iwh);
   
   if(liwl != 0)
   {
      l[iwl] = a * aa[iwl]^sa;
   }

   if(liwh != 0)
   {
      l[iwh] = a * b^sa * ( aa[iwh]/b )^sb;
   }

   return l;
}

add_slang_function("abkn_plaw",["norm","slope_1","f_break [Angstrom]","slope_2"]);

define abkn_plaw_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(0,0,-5,5,-10,10,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1,0,0.,1.e4,0,1.e16,1.e-3,1.e-3);
   }
   {case 3:
      return param_default_structure(-2,0,-5,5,-10,10,1.e-3,1.e-3);
   }
}

set_param_default_hook("abkn_plaw","abkn_plaw_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Double Broken Counts/Bin Powerlaw  %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define adbkn_plaw_fit(lo,hi,par)
{
   variable a,sa,ba,sb,bb,sc,al,ah,aa,l;
   variable iwl,iwm,iwh,liwl,liwm,liwh;
 
   al = hi;
   ah = lo;
   aa = (al+ah)/2.;
   l = @al;

   a = par[0];
   sa = par[1];
   ba = par[2];
   sb = par[3];
   bb = par[4];
   sc = par[5];

   iwl = where(aa <= ba);
   iwm = where(aa > ba and aa <= bb);
   iwh = where(aa > bb);

   liwl = length(iwl);
   liwm = length(iwm);
   liwh = length(iwh);
   
   if(liwl != 0)
   {
      l[iwl] = a * aa[iwl]^sa;
   }

   if(liwm != 0)
   {
      l[iwm] = a * ba^sa * ( aa[iwm]/ba )^sb;
   }

   if(liwh != 0)
   {
      l[iwh] = a * ba^sa * (bb/ba)^sb * (aa[iwh]/bb)^sc;
   }

   return l;
}

add_slang_function("adbkn_plaw",["norm","slope_1","f_brk_1 [Angstrom]",
                   "slope_2","f_brk_2 [Angstrom]","slope_3"]);

define adbkn_plaw_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(0,0,-5,5,-10,10,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(1,0,0.,1.e4,0,1.e16,1.e-3,1.e-3);
   }
   {case 3:
      return param_default_structure(-1,0,-5,5,-10,10,1.e-3,1.e-3);
   }
   {case 4:
      return param_default_structure(10,0,0.,1.e4,0,1.e16,1.e-3,1.e-3);
   }
   {case 5:
      return param_default_structure(-2,0,-5,5,-10,10,1.e-3,1.e-3);
   }
}

set_param_default_hook("adbkn_plaw","adbkn_plaw_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Counts/bin Sine Wave %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

define asinwave_fit(lo,hi,par)
{
   variable a,f,phs,al,ah,l;
 
   al = hi;
   ah = lo;

   a = par[0];
   f = par[1];
   phs = par[2];

   l = a * ( -cos(2*PI*(f*al-phs)) + cos(2*PI*(f*ah-phs)) )/2/PI/f/(al-ah);

   return l;
}

add_slang_function("asinwave",["norm","freq","phase"]);

define asinwave_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,0,1.e4,0,1.e16,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(0,0,0.,1.,0,1,1.e-3,1.e-3);
   }
}

set_param_default_hook("asinwave","asinwave_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% Counts/bin Square Wave %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

define asqrwave_fit(lo,hi,par)
{
   variable a,c,w,r=@lo,iw;

   r[*]=0;
 
   a = par[0];
   c = par[1];
   w = par[2];

   iw = where( lo>= c-w/2. and hi <= c+w/2. );
   if(length(iw) >0)
   {
      r[iw] = a;
   }

   iw = where( lo< c-w/2. and hi <= c+w/2. );
   if(length(iw) >0)
   {
      r[iw] = a*(hi[iw] - c+w/2.)/(hi[iw]-lo[iw]);
   }

   iw = where( lo >= c-w/2. and hi > c+w/2. );
   if(length(iw) >0)
   {
      r[iw] = a*(c+w/2. - lo[iw])/(hi[iw]-lo[iw]);
   }

   return r;
}

add_slang_function("asqrwave",["norm","center","width"]);

define asqrwave_defaults(i)
{
   switch(i)
   {case 0:
      return param_default_structure(0.1,0,0.,1.e8,-1.e16,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(1,0,0,1.e4,0,1.e16,1.e-3,1.e-3);
   }
   {case 2:
      return param_default_structure(0,0,0.,1.,0,1,1.e-3);
   }
}

set_param_default_hook("asqrwave","asqrwave_defaults");

public define tilt_fit(lo,hi,par)
{
   variable e = (_A(lo)+_A(hi))/2/par[0];
   return reverse( e^par[1] );
}

add_slang_function("tilt",["E0 [keV]","DGamma"]);

define tilt_defaults(i)
{
   switch(i)
   {case 0:
      return(3,1,0.1,10);
   }
   {case 1:
      return(0,0,-0.25,0.25);
   }
}

set_param_default_hook("tilt","tilt_defaults");

%%%%%%%%%%%%%%%%%%%%%%%%
define simple_gpile2_fit(lo, hi, par, fun)
%%%%%%%%%%%%%%%%%%%%%%%%
{  
   % 2007, August 14 - fracexpo does not have to be an array

   % 2007, May 03 - correct rebinning of the arf

   % 2007, January 22 - no explicit refering to max(mod_cts)
   
   % 2005, October 25 - New and improved functionality, especially
   %                    in the dithered regions of the chips!

   % Peak pileup correction goes as:
   %    exp(log(1-pfrac)*[counts/max(counts)])
   %  = exp(- beta * counts/S/A )
   variable beta = par[0];

   % Pileup scales with model counts from *data set* indx
   variable indx = typecast(par[1],Integer_Type);

   if( indx == 0 or beta == 0. )
   { return fun; }  % Quick escape for no changes ... 

   % The arf index could be a different number, so get that
   variable arf_indx = get_data_info(indx).arfs;

   % Get arf information
   variable arf = get_arf(arf_indx[0]);

   % In dither regions (or bad pixel areas), counts are down not
   % from lack of area, but lack of exposure.  Pileup fraction
   % therefore should scale with count rate assuming full exposure.
   % Use the arf "fracexpo" column to correct for this effect
   variable fracexpo = get_arf_info(arf_indx[0]).fracexpo;
   if(length(fracexpo)>1)
   { fracexpo[where(fracexpo==0)] = 1.; }
   else
   { if(fracexpo==0) { fracexpo = 1; } }

   % Rebin arf to input grid, correct for fractional exposure, and 
   % multiply by "fun" to get ("corrected") model counts per bin
   variable mod_cts_int;
   mod_cts_int = fun * rebin(lo, hi,
                             arf.bin_lo, arf.bin_hi,
                             arf.value*(arf.bin_hi-arf.bin_lo)/fracexpo)
                                      / (hi-lo);
   % Go from bin-integrated(ph/cm^2/s) * bin-integrated(cm^2)
   % to cts/s/angstrom
   variable mod_cts = mod_cts_int/(hi-lo);

   % Use 2nd and 3rd order arfs to include their contribution.
   % Will probably work best if one chooses a user grid that extends
   % from 1/3 of the minimum wavelength to the maximum, and has
   % at least 3 times the resolution of the first order grid.
   variable mod_ord;
   if(par[2] > 0)
   {
      indx = typecast(par[2],Integer_Type);
      arf = get_arf(indx);
      fracexpo=get_arf_info(indx).fracexpo;
      if(length(fracexpo)>1)
      { fracexpo[where(fracexpo==0)] = 1.; }
      else
      { if(fracexpo==0) { fracexpo = 1; } }
      mod_ord = arf.value/fracexpo*
                rebin(arf.bin_lo,arf.bin_hi,lo,hi,fun);
      mod_ord = rebin(lo,hi,2*arf.bin_lo,2*arf.bin_hi,mod_ord)/(hi-lo);
      mod_cts = mod_cts+mod_ord;
   }
   if(par[3] > 0)
   {
      indx = typecast(par[3],Integer_Type);
      arf = get_arf(indx);
      fracexpo=get_arf_info(indx).fracexpo;
      if(length(fracexpo)>1)
      { fracexpo[where(fracexpo==0)] = 1.; }
      else
      { if(fracexpo==0) { fracexpo = 1.; } }
      mod_ord = arf.value/fracexpo*
                rebin(arf.bin_lo,arf.bin_hi,lo,hi,fun);
      mod_ord = rebin(lo,hi,3*arf.bin_lo,3*arf.bin_hi,mod_ord)/(hi-lo);
      mod_cts = mod_cts+mod_ord;
   }

   % Return function multiplied by exponential decrease
   return exp(-beta*mod_cts) * fun;
}


add_slang_function("simple_gpile2",
                   ["beta [s*A/cts]","data_indx","arf2_indx","arf3_indx"]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define simple_gpile2_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
   switch(i)
   {case 0:
      return param_default_structure(0.05,1,0,10,0,1.e16,1.e-3,1.e-3);
   }
   {case 1:
      return param_default_structure(0,1,0,48,0,1000,1,1);
   }
   {case 2:
      return param_default_structure(0,1,0,48,0,1000,1,1);
   }
   {case 3:
      return param_default_structure(0,1,0,48,0,1000,1,1);
   }
}

set_param_default_hook("simple_gpile2", "simple_gpile2_defaults");

set_function_category("simple_gpile2", ISIS_FUN_OPERATOR);



%%%%%%%%%%%%%%%%%%%%%%%
define use_simple_gpile()
%%%%%%%%%%%%%%%%%%%%%%%
{
  % process arguments
  variable data1, arf2=NULL, arf3=NULL;
  switch(_NARGS)
  { case 1:  data1 = (); }
  { case 2: (data1, arf2) = (); }
  { case 3: (data1, arf2, arf3) = (); }
  { message("usage: use_simple_gpile(data1[, arf2[, arf3]]);"); return; } 

  if(arf2!=NULL) 
  { arf2 = [arf2];
    if(length(arf2)!=length(data1)) { message("error (use_simple_gpile): arrays data1 and arf2 have different length"); return; }
  }
  if(arf3!=NULL)
  { arf3 = [arf3];
    if(length(arf3)!=length(data1)) { message("error (use_simple_gpile): arrays data1 and arf3 have different length"); return; }
  }
 
  variable simple_gpile_fun = "simple_gpile2";
  variable fitFun = get_fit_fun();
  if(substr(fitFun, 1, strlen(simple_gpile_fun)) != simple_gpile_fun)
  { fit_fun(simple_gpile_fun + "(Isis_Active_Dataset, " + fitFun + ")"); }

  % assign model parameters
  variable i;
  foreach i (all_data)
  { 
    variable simple_gpile_instance = simple_gpile_fun + "(" + string(i) + ")";
    set_par(simple_gpile_instance + ".beta", 0, 1);
    set_par(simple_gpile_instance + ".data_indx", 0, 1);
    set_par(simple_gpile_instance + ".arf2_indx", 0, 1);
    set_par(simple_gpile_instance + ".arf3_indx", 0, 1);
  }
  for(i=0; i<length([data1]); i++)
  {
    variable id = [data1][i];
    simple_gpile_instance = simple_gpile_fun + "(" + string(id) + ")";
    set_par(simple_gpile_instance + ".beta", 0.05, 0);
    set_par(simple_gpile_instance + ".data_indx", id, 1);
    if(arf2!=NULL) { set_par(simple_gpile_instance + ".arf2_indx", arf2[i], 1); }
    if(arf3!=NULL) { set_par(simple_gpile_instance + ".arf3_indx", arf3[i], 1); }
  }
}


%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_unpiled_fit_fun()
%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable fitFun = get_fit_fun();
  variable unpiledFitFun;
  (unpiledFitFun,) = strreplace(fitFun, "simple_gpile2(Isis_Active_Dataset, ", "(", 1);
  return unpiledFitFun;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_unpiled_data_flux()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  % process arguments
  variable id;
  switch(_NARGS)
  { case 1:  id = (); }
  { message("usage: get_unpiled_data_flux(id);"); return; } 

  variable f = get_data_flux(id);
  Isis_Active_Dataset = id;
  variable pm = eval_fun(f.bin_lo, f.bin_hi);
  variable fitFun = get_fit_fun();
  fit_fun(get_unpiled_fit_fun());
  Isis_Active_Dataset = id;
  variable  m = eval_fun(f.bin_lo, f.bin_hi);
  fit_fun(fitFun);
  f.value *= m/pm;
  f.err *= m/pm;
  return f;
}
