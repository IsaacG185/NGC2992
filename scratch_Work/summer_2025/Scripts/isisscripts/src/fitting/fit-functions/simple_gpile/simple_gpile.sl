%%%%%%%%%%%%%%%%%%%%%%%
define simple_gpile_fit(lo,hi,par,fun)
%%%%%%%%%%%%%%%%%%%%%%%
{
   % October 25, 2005 - New and improved functionality, especially in
   % the dithered regions of the chips!

   % Peak pileup correction goes as:
   %    exp(log(1-pfrac)*[counts/max(counts)])
   variable pfrac = par[0];

   % Pileup scales with model counts from *data set* indx ...
   variable indx = typecast(par[1],Integer_Type);

   if( indx == 0 or pfrac == 0. )
      return fun;   % Quick escape for no changes ...

   % ... but the arf index could be a different number, so get that
   variable arf_indx = get_data_info(indx).arfs;

   % Get arf information
   variable arf = get_arf(arf_indx[0]);

   % In dither regions (or bad pixel areas), counts are down not
   % from lack of area, but lack of exposure.  Pileup fraction
   % therefore should scale with count rate assuming full exposure.
   % Use the arf "fracexpo" column to correct for this effect
   variable fracexpo = get_arf_info(arf_indx[0]).fracexpo;
   fracexpo[where(fracexpo ==0)] = 1.;

   % Rebin arf to input grid, correct for fractional exposure, and
   % multiply by "fun" to get ("corrected") model counts per bin
   variable mod_cts;
   mod_cts = fun * rebin(lo,hi,arf.bin_lo, arf.bin_hi,arf.value/fracexpo);

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
      fracexpo[where(fracexpo ==0)] = 1.;
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
      fracexpo[where(fracexpo ==0)] = 1.;
      mod_ord = arf.value/fracexpo*
                rebin(arf.bin_lo,arf.bin_hi,lo,hi,fun);
      mod_ord = rebin(lo,hi,3*arf.bin_lo,3*arf.bin_hi,mod_ord)/(hi-lo);
      mod_cts = mod_cts+mod_ord;
   }

   % In case something funky happens while wandering parameter space ...
   variable max_mod = max(mod_cts);

   if(max_mod <= 0){ max_mod = 1.;}

   % Scale maximum model counts to pfrac
   mod_cts = log(1-pfrac)*mod_cts/max_mod;

   % Return function multiplied by exponential decrease
   fun = exp(mod_cts) * fun;
   return fun;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define simple_gpile_defaults(i)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
   switch(i)
   {case 0:
      return (0.1,1,0.,0.5);
   }
   {case 1:
      return (1,1,0,100);
   }
   {case 2:
      return (2,1,0,100);
   }
   {case 3:
      return (3,1,0,100);
   }
}

add_slang_function("simple_gpile", ["pile_frac","data_indx","arf2_indx","arf3_indx"]);

set_function_category("simple_gpile", ISIS_FUN_OPERATOR);

set_param_default_hook("simple_gpile", "simple_gpile_defaults");
