% -*- mode: slang; mode: fold -*-
%!%+
%\function{reflection_fraction_relxill}
%\synopsis{calculates the reflection fraction as defined in relxill, using the rel_lp_table of the relxill code}
%\usage{Double_Type fR = 
%        reflection_fraction_relxill(double a, double/array height, double rin, double rout);}
%\qualifiers{
%\qualifier{path}{[getenv("RELXILL_TABLE_PATH")]: path to the table}
%\qualifier{table}{[rel_lp_table_v0.5b.fits: name of the table}
%\qualifier{struct}{if set returns full structure returning fR, f_inf, and f_bh }
%}
%\seealso{kerr_rms,kerr_rplus}
%\description
%   Assumptions:
%   - height, rin, and rout have to be given in R_g, a is the
%     dimensionless spin parameter
%   - height, rin, and rout can also be given in negative values,
%     which is interpreted the same way as the relxill definition:
%     negative heights are in units of the event horizon (kerr_rplus) and
%     and radii in units of the ISCO (kerr_rms)
%   - photons are not allowed to cross the disk plane
%   - produces identical results to relxill
%   
%   This function 
%   
%   If relxill and the RELXILL_TABLE_PATH environment variable is set
%   up correctly, this function will work out of the box. Otherwise
%   the path needs to be set manually.
%   
%   Note: this function has been tested only for
%   rel_lp_table_v0.5b.fits. It is not recommended to change this. Any 
%   deviations are < 0.01.
%   
%   Questions: contact Thomas Dauser
%   
%   Reference: Dauser et al., 2016, A&A, 590, A76
%!%-

private define relat_aberration(th, bet){ %{{{
        return acos((cos(th)-bet) / (1-bet*cos(th)));
}
%}}}


private define interpol_frac(ilo,agrid, a){ %{{{
   return (a - agrid[ilo]) / ( agrid[ilo+1] - agrid[ilo] );
}
%}}}

private define get_reflfrac_hgrid(ind_a,ind,dat,r,rin,rout){ %{{{
   

   variable del = get_struct_field(dat,sprintf("del%i",ind+1))[ind_a,*];

   variable rind = where(rin <= r < rout);
   
   if (length(rind) <= 1){
      message(" *** error: calculating reflection fraction not possible for a disk from rin=%.3f to rout=%.3f",
	      rin,rout);
      return 0.0;
   }
      
   
   variable irlo = rind[0];
   variable irhi = rind[-1];

   variable del_bh,del_ad,fac;
   if (irlo>0){
      fac = interpol_frac(irlo-1,r,rin);      
      del_bh = (1-fac)*del[irlo-1] + fac*del[irlo];
   } else {
      del_bh =  del[irlo];
   }
   
   if (irlo<(length(r)-1)){
      fac = interpol_frac(irhi,r,rout);      
      del_ad = (1-fac)*del[irhi] + fac*del[irhi];
   } else {
      del_ad = del[irhi];
   }

   variable del_ad_max = del[-1];

   variable beta = qualifier("beta",0.0);

   if (beta > 1e-3){
      del_bh = relat_aberration(del_bh, -1. * beta);
      del_ad = relat_aberration(del_ad, -1. * beta);
      del_ad_max = relat_aberration(del_ad_max, -1. * beta);
   }

   
   variable f_bh  = 0.5*(1.0 - cos(del_bh));
   variable f_ad  = 0.5*(cos(del_bh) - cos(del_ad));

   %% photons are not allowed to cross the disk plane
   variable f_inf = 0.5*(1.0 + cos(del_ad_max));
		   
   %%% photons are not allowed to cross the disk plane                                                                                                            
   if (f_inf > 0.5){
     f_inf = 0.5;
   }

   if (qualifier_exists("verbose"))
     vmessage(" R=%.3f [f_ad=%.3f, f_inf=%.3f] for a=%.3f, h=%.3f, rin=%.3f, rout=%.3f",
	      f_ad/f_inf,f_ad,f_inf,dat.a[ind_a],dat.hgrid[ind_a,ind],rin,rout);
   
   return struct {fR = f_ad/f_inf, f_inf=f_inf, f_bh=f_bh};
}
%}}}

private define ipol_reflFracStruct(slo, shi, frac){ %{{{
        
   variable fR    = slo.fR*(1-frac) + shi.fR*frac;
   variable f_inf = slo.f_inf*(1-frac) + shi.f_inf*frac;
   variable f_bh  = slo.f_bh*(1-frac) + shi.f_bh*frac;
   
   return struct{fR=fR, f_inf=f_inf, f_bh=f_bh};
}
%}}}

private define get_reflfrac_agrid(ind_a,dat,h,rin,rout){ %{{{
   
   variable hgrid = dat.hgrid[ind_a,*];
   variable r = dat.r[ind_a,*];

   
   variable ilo = wherefirst(h<hgrid);

   if (ilo != 0){
      ilo--;
   }   
   
   variable frac_h = interpol_frac(ilo,hgrid,h);
   
   variable r_rlo = get_reflfrac_hgrid(ind_a,ilo,dat,r,rin,rout;;__qualifiers);
   variable r_rhi = get_reflfrac_hgrid(ind_a,ilo+1,dat,r,rin,rout;;__qualifiers);

   return ipol_reflFracStruct(r_rlo, r_rhi, frac_h);
}
%}}}

private define get_reflfrac_struct(a,h,rin,rout){ %{{{
   variable path = qualifier("path",getenv("RELXILL_TABLE_PATH"));
   variable fname = qualifier("table","rel_lp_table_v0.5b.fits");
   variable dat = fits_read_table(path+"/"+fname);

      
   variable ilo = wherefirst(a < dat.a);
   if (ilo == length(dat.a)-1){
      ilo--;
   }   
   variable frac_a = interpol_frac(ilo,dat.a,a);

   
   variable ii, n = length(h);
   variable refl_frac = Double_Type[n];
   variable refl_frac_struct = Struct_Type[n];
   
   _for ii(0,n-1){
      variable r_alo = get_reflfrac_agrid(ilo,dat,h[ii],rin,rout;;__qualifiers);
      variable r_ahi = get_reflfrac_agrid(ilo+1,dat,h[ii],rin,rout;;__qualifiers);      

      refl_frac_struct[ii] = ipol_reflFracStruct(r_alo, r_ahi, frac_a);

      refl_frac[ii] = refl_frac_struct[ii].fR;
      if (qualifier_exists("verbose")){
	 vmessage(" R=%.3f for a=%.3f, h=%.3f, rin=%.3f, rout=%.3f",
		 refl_frac[ii],a,h[ii],rin,rout);
      }

   }


   if (n==1){
      return refl_frac_struct[0];
   } else {   
      return merge_struct_arrays(refl_frac_struct);
   }
}
%}}}

private define convert_negative_radius_to_rg(r,a){ %{{{
   if (r<0){
      return kerr_rms(a)*abs(r);
   } else {
      return r;
   }
}
%}}}

private define convert_negative_height_to_rg(h,a){ %{{{

   variable ind_h_negative = where(h<0);
   
   if ( length(ind_h_negative) > 0 ){
      
      h[ind_h_negative] *= -1.0*kerr_rplus(a);
   }

}
%}}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define reflection_fraction_relxill(){

   variable a, height,rin,rout;
   variable rout_max = 1000.;
   
   switch(_NARGS) {
    case 2: 
      (a, height)  = ();
      rin = kerr_rms(a);
      rout = rout_max;
   }
   {
    case 3: 
      (a, height, rin)  = (); 
      rout = rout_max;   
   }
   { 
    case 4: 
      (a, height, rin, rout)  = (); 
   }
   { 
      help(_function_name()); return; 
   }
   
   %% convert height to a double-array, as it is required by the
   %% get_reflfrac_struct
   variable height_array = 1.0*[height];

   
   rin = convert_negative_radius_to_rg(rin,a);
   rout = convert_negative_radius_to_rg(rout,a);

   convert_negative_height_to_rg(height_array,a);
   
   variable refl_frac_struct = get_reflfrac_struct(a,height_array,rin,rout;;__qualifiers());

   
   
   if(qualifier_exists("struct")){
      
      if (length(refl_frac_struct)==1){
	 return refl_frac_struct[0];
      } else {   
	 return refl_frac_struct;
      }      
      
   } else {   
      if (length(refl_frac_struct)==1){
	 return refl_frac_struct[0].fR;
      } else {   
	 return refl_frac_struct.fR;
      }
   }
   
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
