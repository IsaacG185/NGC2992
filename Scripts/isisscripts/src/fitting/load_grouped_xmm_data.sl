define load_grouped_xmm_data()
%!%+
%\function{load_grouped_xmm_data}
%\synopsis{wrapper for load_data, which sets already a few basic options}
%\usage{Integer_Type Index = load_grouped_xmm_data([String_Type Path], [E_lo, E_hi]);}
%\qualifiers{
%\qualifier{min_sn[=5]}{[\code{=5}]: Set the minimal S/N ratio (see help("group");) }
%\qualifier{min_chan[=2]}{[\code{=2}]: Set the minimal number of Channels do be rebinned (see help("group");) }
%\qualifier{delete_data}{If set, any data sets loaded previously will be deleted.}
%}
%\description
%   This functions loads data (by default "src_sd.pha"), groups it,
%   and notices the energy bins between E_lo[=1keV] and E_hi[=10keV]. 
%   When changing all default values, it can be easily used for any
%   other satellite.
%!%-
{
   variable spec, emin=1.,emax=10.;
   switch (_NARGS)
   {case 0: spec ="src_sd.pha" ; }
   {case 1: spec = (); }
   {case 2: spec ="src_sd.pha" ; (emin, emax) = (); }
   {case 3: (spec, emin, emax) = (); }
   { help(_function_name()); return; }

   if(qualifier_exists("delete_data")) delete_data(all_data);
   
   variable id = load_data(spec);

   
   group(id;
	 min_sn=qualifier("min_sn",5),
	 min_chan=qualifier("min_chan",2));
   variable rng = qualifier("range",[1,10]);
   ignore_en(id,,emin);
   ignore_en(id,emax,);

   return id;
}
