%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_list_fit_pars(){
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_list_fit_pars}
%\synopsis{Lists parameter values and confidence intervals for a file saved with fits_save_fit.}
%\usage{fits_list_fit_pars(String_Type fit.fits)}
%\description
%    When loading a previously saved fit with fits_load_fit, \code{list_par}
%    does not print the borders of the parameter confidence intervals saved
%    in appropriate fields of fit.fits.
%    Instead the parameter limits are printed.
%    As a work-around use this function to get a similar list as for
%    \code{list_par} including the confidence intervals if already determined.
%\example
%    isis> fits_list_fit_pars("fit.fits");
%\seealso{fits_save_fit,fits_load_fit}
%!%-

  variable fit;
  switch(_NARGS)
  { case 1: (fit) = ();}
  { help(_function_name()); return; }
  
  variable fit_struct, fields, i, cnf_lo_frmt, cnf_hi_frmt, val_frmt, lim_lo_frmt, lim_hi_frmt;
  
  variable val = Double_Type[0];
  variable cnf_lo = Double_Type[0];
  variable cnf_hi = Double_Type[0];
  variable lim_lo = Double_Type[0];
  variable lim_hi = Double_Type[0];
  variable tie = String_Type[0];
  variable frz = Integer_Type[0];
  variable name = String_Type[0];
  
  fit_struct=fits_load_fit_struct(fit);
  fields=get_struct_field_names(fit_struct);
  
  vmessage(fit_struct.fit_fun[0]);
  vmessage("%-30s%-10s%-10s%-15s%-15s%-15s%-15s%-15s","param","tie-to","freeze","lim_lo","conf_min","value","conf_max","lim_hi");
  vmessage("----------------------------------------------------------------------------------------------------------------------------------------");
  for (i=0;i<length(fields);i++) {
    if (is_substr(fields[i],"value")>0) val=[val,get_struct_field(fit_struct,fields[i])[0]];
    if (is_substr(fields[i],"conf")>0) {
      cnf_lo=[cnf_lo,get_struct_field(fit_struct,fields[i])[0,0]];
      cnf_hi=[cnf_hi,get_struct_field(fit_struct,fields[i])[0,1]];
      name=[name,fields[i]];
    }
    if (is_substr(fields[i],"lim")>0) {
      lim_lo=[lim_lo,get_struct_field(fit_struct,fields[i])[0,0]];
      lim_hi=[lim_hi,get_struct_field(fit_struct,fields[i])[0,1]];
    }
    if (is_substr(fields[i],"tie")>0) {
      if (typeof(get_struct_field(fit_struct,fields[i])[0]) == String_Type) {
	tie=[tie,get_struct_field(fit_struct,fields[i])[0]];
      }
      else tie=[tie,string(get_struct_field(fit_struct,fields[i])[0])];
    }
    if (is_substr(fields[i],"freeze")>0) frz=[frz,get_struct_field(fit_struct,fields[i])[0]];
  }
  for (i=0;i<length(name);i++) {

#ifdef    
    if ((floor(cnf_lo[i]*10000)==0. || floor(cnf_lo[i]/1000.)>0) && cnf_lo[i]!=0.) cnf_lo_frmt = "%-15.2e";
    else if ((floor(cnf_lo[i]*10000)>0. || floor(cnf_lo[i]/1000.)==0) && cnf_lo[i]!=0.) cnf_lo_frmt = "%-15.3f";
    else if (cnf_lo[i]==0.) cnf_lo_frmt = "%-15.0f";
    if ((floor(cnf_hi[i]*10000)==0. || floor(cnf_hi[i]/1000.)>0) && cnf_hi[i]!=0.) cnf_hi_frmt = "%-15.2e";
    else if ((floor(cnf_hi[i]*10000)>0. || floor(cnf_hi[i]/1000.)==0) && cnf_hi[i]!=0.) cnf_hi_frmt = "%-15.3f";
    else if (cnf_hi[i]==0.) cnf_hi_frmt = "%-15.0f";
    
    if ((floor(lim_lo[i]*10000)==0. || floor(lim_lo[i]/1000.)>0) && lim_lo[i]!=0.) lim_lo_frmt = "%-15.2e";
    else if ((floor(lim_lo[i]*10000)>0. || floor(lim_lo[i]/1000.)==0) && lim_lo[i]!=0.) lim_lo_frmt = "%-15.3f";
    else if (lim_lo[i]==0.) lim_lo_frmt = "%-15.0f";
    if ((floor(lim_hi[i]*10000)==0. || floor(lim_hi[i]/1000.)>0) && lim_hi[i]!=0.) lim_hi_frmt = "%-15.2e";
    else if ((floor(lim_hi[i]*10000)>0. || floor(lim_hi[i]/1000.)==0) && lim_hi[i]!=0.) lim_hi_frmt = "%-15.3f";
    else if (lim_hi[i]==0.) lim_hi_frmt = "%-15.0f";
#endif    

    if ((floor(cnf_lo[i]*1000)==0.) && cnf_lo[i]!=0.) cnf_lo_frmt = "%-15.3e";
    else if ((floor(cnf_lo[i]*1000)>0.)) cnf_lo_frmt = "%-15.4f";
    if ((floor(cnf_lo[i])>1000.)) cnf_lo_frmt = "%-15.3e";    
    else if (cnf_lo[i]==0.) cnf_lo_frmt = "%-15.0f";
    if ((floor(cnf_hi[i]*1000)==0.) && cnf_hi[i]!=0.) cnf_hi_frmt = "%-15.3e";
    else if ((floor(cnf_hi[i]*1000)>0.)) cnf_hi_frmt = "%-15.4f";
    if ((floor(cnf_hi[i])>1000.)) cnf_hi_frmt = "%-15.3e";    
    else if (cnf_hi[i]==0.) cnf_hi_frmt = "%-15.0f";
    
    if ((floor(lim_lo[i]*1000)==0.) && lim_lo[i]!=0.) lim_lo_frmt = "%-15.3e";
    else if ((floor(lim_lo[i]*1000)>0.)) lim_lo_frmt = "%-15.4f";
    if ((floor(lim_lo[i])>1000.)) lim_lo_frmt = "%-15.3e";    
    else if (lim_lo[i]==0.) lim_lo_frmt = "%-15.0f";
    if ((floor(lim_hi[i]*1000)==0.) && lim_hi[i]!=0.) lim_hi_frmt = "%-15.3e";
    else if ((floor(lim_hi[i]*1000)>0.)) lim_hi_frmt = "%-15.4f";
    if ((floor(lim_hi[i])>1000.)) lim_hi_frmt = "%-15.3e";    
    else if (lim_hi[i]==0.) lim_hi_frmt = "%-15.0f";
    
    if ((floor(val[i]*1000)==0.) && val[i]!=0.) val_frmt = "%-15.3e";
    else if ((floor(val[i]*1000)>0.)) val_frmt = "%-15.4f";
    if ((floor(val[i])>1000.)) val_frmt = "%-15.3e";    
    else if (val[i]==0.) val_frmt = "%-15.0f";

    variable formatstring = "%-30s%-10s%-10u"+sprintf("%s%s%s%s%s",lim_lo_frmt,cnf_lo_frmt,val_frmt,cnf_hi_frmt,lim_hi_frmt);
    vmessage(formatstring,strreplace(name[i],"_conf",""),tie[i],frz[i],lim_lo[i],cnf_lo[i],val[i],cnf_hi[i],lim_hi[i]);        
  }
}