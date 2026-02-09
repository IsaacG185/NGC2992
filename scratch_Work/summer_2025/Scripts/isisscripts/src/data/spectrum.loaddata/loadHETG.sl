
define loadHETGspec()
{
%!%+
%\function{loadHETGspec}
%\synopsis{Load locally extracted Chandra HETG spectra and responses}
%\usage{Struct_Type ids = loadHETGspec();}
%\qualifiers{
%\qualifier{dir [="."]}{     : path to the extracted spectra}
%\qualifier{heg [=1]}{       : load HEG spectra (=0: don't load)}
%\qualifier{meg [=1]}{       : load MEG spectra (=0: don't load)}
%\qualifier{order [=[-1,1]]}{: diffraction orders to load. Sign matters.}
%}
%\description
%   Load Chandra HETG spectra extracted with the (new) Remeis
%   extraction scripts and return a structure with the dataset indices.
%   
%   The new (summer 2014) Remeis Chandra gratings extraction scripts
%   do not longer specify observation / extraction specific information 
%   in the file name, but only the arm and diffraction order of the
%   spectrum, e.g., heg_m1.pha or meg_p1.pha. The old extraction
%   scripts used to generate a loaddata0.sl file for convenience. With
%   the more generic file names, this function replaces the load
%   script. To ensure backwards compatibility with dataset-index
%   sensitive par files, the function loads the arms and orders in the
%   exact same order as the old load scripts used to: 
%      heg_m1 heg_p1 meg_m1 meg_p1 heg_m2 heg_p2 meg_m2 meg_p2 ...
%   
%   The returned structure is then in the form (in case of the defaults):
%      struct{
%        dir = ".",
%        orders = [-1,1],
%        arms = ["heg","meg"],
%        heg_m1 = 1,
%        heg_p1 = 2,
%        meg_m1 = 3,
%        ...
%      }
%   The function returns -1 if both arms are ignored, i.e., no spectra
%   chosen.
%      
%   Negative and positive diffraction orders can be chosen independently
%   of each other. However, all selected orders are applied to all
%   selected grating arms: You can load HEG without MEG and vice versa. 
%   But if you load them both in a single call of loadHETGspec, the
%   same orders will be loaded for both of them. 
%      
%   If you would like to load configurations like [heg_m1, meg_p1],
%   where different orders are loaded for each grating arms, you have
%   to call the function multiple times or load the spectra by hand. 
%   
%\seealso{loadHETGlcs, loadHETGlc_sum}
%!%-
   variable dir = qualifier("dir",".")+"/";
   variable heg = qualifier("heg",1);
   variable meg = qualifier("meg",1);
   variable order = int(qualifier("order",[-1,1]));

   variable arm = String_Type[0];
   if(heg) arm = [arm,"heg"];
   if(meg) arm = [arm,"meg"];
   if(length(arm)==0) return -1;
   
   variable aos = abs(order[unique(abs(order))]);
   aos = aos[array_sort(aos)];
   
   variable ids = struct{dir = dir, orders=order, arms = arm};
   variable o,a,v, w,str, did;
   foreach o (aos)
	 {
		foreach a (arm)
		  {
			 foreach v([0,1])
			   {
				  w = where(order == o * [-1,1][v]);
				  if(length(w)>0)	
					{				  
					   str = sprintf("%s_%s%d",a,["m","p"][v],o);
					   ids = struct_combine(ids,str);	
					   did = load_data(dir+str+".pha");
					   set_struct_field(ids,str,did);
					}
				  
			   }
		  }
		
	 }
   return ids;
}

define loadHETGlcs()
{
%!%+
%\function{loadHETGlcs}
%\synopsis{Load Chandra HETG lightcurves}
%\usage{lcs = loadHETGlcs();}
%\qualifiers{
%\qualifier{dir [="."]}{     : path to the extracted spectra}
%\qualifier{heg [=1]}{       : load HEG spectra (=0: don't load)}
%\qualifier{meg [=1]}{       : load MEG spectra (=0: don't load)}
%\qualifier{order [=[-1,1]]}{: diffraction orders to load. Sign matters.}
%\qualifier{energyband [=[500,10000]]}{: extracted energy bands. See
%                                 description below for details.}
%\qualifier{unit [="eV"]}{   : Unit for the energyband: eV, keV, A}
%}
%\description   
%   Load Chandra HETG lightcurves extracted with the (new) Remeis
%   extraction scripts and return a structure with the results.
%   
%   The new (summer 2014) Remeis Chandra gratings extraction scripts
%   do not longer specify observation / extraction specific
%   information in the file name, but only the arm, diffraction order,
%   and energyband of the lightcurve, e.g., heg_m1_500-1000.lc or
%   meg_p1_3500-10000.lc. 
%   
%   loadHETGlcs reads the corresponding lightcurve for each specified arm,
%   diffraction order, and enegeryband and stores it as a field in a
%   structure. 
%   The returned structure is then in the form (in case of the defaults):
%      struct{
%        dir = ".",
%        orders = [-1,1],
%        arms = ["heg","meg"],
%        energyband = [500, 10000],
%        unit = "eV",
%        heg_m1_500_10000 = Struct_Type, % content of the fits file
%        heg_p1_500_10000 = Struct_Type,
%        meg_m1_500_10000 = Struct_Type,
%        ...
%      }
%   The function returns -1 if both arms are ignored, i.e., no
%   lightcurves chosen.
%   
%   The energyband can be specified in multiple ways:
%     * a list or array of limits: [0.5,1.5,3,10] keV. In this case, the
%       energybands for the lightcurves are assumed to be 0.5-1.5,
%       1.5-3, and 3-10 keV, i.e., there are no gaps.
%     * a list or an array of energy pairs: {[0.5,1.5],[3,10]} or
%       [{0.5,1.5},{3,10}] keV. Then the bands are taken as they are,
%       i.e., it is possible to have gaps between energy bands. 
%  
%\seealso{loadHETGlc_sum, loadHETGspec}
%!%-
   variable dir = qualifier("dir",".")+"/";
   variable heg = qualifier("heg",1);
   variable meg = qualifier("meg",1);
   variable order = qualifier("order",[-1,1]);
   variable enb = qualifier("energyband",[500,10000]);
   variable unit = qualifier("unit","eV");
   variable en,i;
   if(typeof(enb[0]) == Double_Type or typeof(enb[0]) == Integer_Type)
	 {
		en = Array_Type[length(enb)-1];
		_for i (1,length(enb)-1,1)
		  {
			 en[i-1] = enb[[i-1,i]]; 
		  }
	 }else{
		en = enb;
	 }
   _for i (0,length(en),1)
	 {
		if(unit == "keV") en[i] *=1e3;
		if(unit == "A") en[i] = 12398.42/en[i];
	 }
   
   variable arm = String_Type[0];
   if(heg) arm = [arm,"heg"];
   if(meg) arm = [arm,"meg"];
   if(length(arm)==0) return -1;
   
   variable aos = abs(order[unique(abs(order))]);
   aos = aos[array_sort(aos)];
   
   variable lcs = struct{dir = dir, orders=order, arms = arm,
	  energyband = enb, unit=unit};
   variable o,a,v,e, w,str, did;
   foreach o (aos)
	 {
		foreach a (arm)
		  {
			 foreach v([0,1])
			   {
				  w = where(order == o * [-1,1][v]);
				  if(length(w)>0)	
					{
					   _for e (0,length(en)-1,1)
						 {
							str = sprintf("%s_%s%d_%04d-%04d",
										  a,["m","p"][v],o,
										  int(en[e][0]),int(en[e][1]));
							did = fits_read_table(dir+str+".lc");
							str = sprintf("%s_%s%d_%04d_%04d",
										  a,["m","p"][v],o,
										  int(en[e][0]),int(en[e][1]));
							lcs = struct_combine(lcs,str);	
							set_struct_field(lcs,str,did);
						 }
					}
			   }
		  }
	 }
   return lcs;
}

define loadHETGlc_sum()
{
%!%+
%\function{loadHETGlc_sum}
%\synopsis{ADD Chandra HETG lightcurves}
%\usage{Struct_Type lcsum = loadHETGlcs( [lcs] );}
%\qualifiers{
%\qualifier{dir [="."]}{     : path to the extracted spectra}
%\qualifier{heg [=1]}{       : load HEG spectra (=0: don't load)}
%\qualifier{meg [=1]}{       : load MEG spectra (=0: don't load)}
%\qualifier{order [=[-1,1]]}{: diffraction orders to load. Sign matters.}
%\qualifier{energyband [=[500,10000]]}{: extracted energy bands. See
%                                 description below for details.}
%\qualifier{unit [="eV"]}{   : Unit for the energyband: eV, keV, A}
%}
%\description   
%   Sum multiple Chandra HETG lightcurves extracted with the (new) Remeis
%   extraction scripts and return a structure with the result.
%   
%   The new (summer 2014) Remeis Chandra gratings extraction scripts
%   do not longer specify observation / extraction specific
%   information in the file name, but only the arm, diffraction order,
%   and energyband of the lightcurve, e.g., heg_m1_500-1000.lc or
%   meg_p1_3500-10000.lc, and only extract lightcurves on a per
%   arm/order basis. 
%   
%   Often, we are more interested in the combined lightcurve of
%   multiple arms / orders. 
%   loadHETGlc_sum can be used in 2 ways:
%     - call the function with no arguments and use the qualifiers to
%       specify which lightcurves you are interested in. The
%       qualifiers are passed to loadHETGlcs to load the lightcurves
%       first.
%     - call the function with 1 argument: the lightcurves produced by
%       a previous call of loadHETGlcs. In this case, all lightcurves
%       contained in the structure will be summed, and the qualifiers
%       will have no effect [in the future, they could be used to
%       choose a subset of the given lightcurves, but this is not
%       implemented yet].
%   
%   The returned structure has the same fields as simply reading a
%   single lightcurve file would produce. If reading of the
%   lightcurves fails, the return value is -1. 
%   
%   The function assumes that the lightcurves have not been tempered
%   with, i.e., that they are correctly (Chandra) formatted
%   lightcurves and have the same length, time grid, etc. No checks
%   are performed. Fields like time and exposure are taken from the
%   first lightcurve in the structure, since they are expected to be
%   the same for various extractions of the same ObsID. 
%   
%   The energyband can be specified in multiple ways:
%     * a list or array of limits: [0.5,1.5,3,10] keV. In this case, the
%       energybands for the lightcurves are assumed to be 0.5-1.5,
%       1.5-3, and 3-10 keV, i.e., there are no gaps.
%     * a list or an array of energy pairs: {[0.5,1.5],[3,10]} or
%       [{0.5,1.5},{3,10}] keV. Then the bands are taken as they are,
%       i.e., it is possible to have gaps between energy bands. 
%  
%\seealso{loadHETGlcs, loadHETGspec}
%!%-   
   variable qq, lcs;
   if(_NARGS==1) { lcs = (); }
   else
	 {
		qq = __qualifiers();
		lcs = loadHETGlcs(;;qq);
	 }
   
   if( not( typeof(lcs)==Struct_Type)) return -1;
   
   variable fields = get_struct_field_names(lcs);
   variable fld;
   foreach fld (["dir","orders","arms","energyband","unit"])
	 {fields[where(fields==fld)] = "";}
   fields = fields[where(fields!="")];

%   variable lcfields = get_struct_field_names(get_struct_field(lcs,fields[0]));
%   variable ssum = @Struct_Type(lcfields);
   variable ssum = get_struct_field(lcs,fields[0]);
   ssum.stat_err = ssum.stat_err^2;
   ssum.count_rate_err = ssum.count_rate_err^2;
   variable dum,i;
   _for i (1,length(fields)-1,1)
	 {
		dum = get_struct_field(lcs,fields[i]);
		ssum.counts += dum.counts;
		ssum.stat_err += dum.stat_err^2;
		ssum.count_rate += dum.count_rate;
		ssum.count_rate_err += dum.count_rate_err^2;
	 }
   ssum.stat_err = sqrt(ssum.stat_err);
   ssum.count_rate_err = sqrt(ssum.count_rate_err);
   return ssum;
}
