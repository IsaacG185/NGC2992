define fits_write_tex_table()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
%!%+
%\function{fits_write_tex_table}
%\synopsis{creates a TeX table ready for input in your document.tex
%          file.}
%
%\usage{fits_write_tex_table(String_Type inputFile);}
%
%\qualifiers{
%\qualifier{pars}{model names given as an array}
%\qualifier{exclude}{parameters to exclude. One can give whole
%                  parameter name as is written in the window output, or just a main
%                  part of it (see examples below).}
%\qualifier{extraInfo}{extra information such as target name,
%                  exposure, etc., the input name is given in
%                  the fits header. This qualifier can lead to
%                  nasty look of your table. }
%\qualifier{texMulti}{tries to fix long extraInfo output in your table.}                  
%\qualifier{everyPar}{parameter name as given can be used as a
%                  qualifier itself for changing:
%                  name, digits, factor and sciMode (see
%                  TeX_value_pm_error on how to use them).
%                  Example:
%                  powerlaw_1_PhoIndex_value={"name","$\\Gamma$","digits",3}
%                  }
%\qualifier{sci}{change scientific output in one step, for
%                  an easier look of the value and its errors in the table.
%                  sci=0   will give you maximally correct output.
%                  sci=1   will also give you nice output, but may not
%                  care about last significant digit.}
%\qualifier{colNames}{give new names for your output columns. Applicable
%                  only when all names change.}  
%\qualifier{fullStat}{prints also chi^2_red values.}
%\qualifier{silent}{No output generated.}
%\qualifier{flip}{flips the table.}
%\qualifier{pdf}{produces pdfout.pdf file for a quick look at
%                  your table.}
%\qualifier{output}{TeX output name, default is "default.tex"}
%}                         
%\description
%    - \code{inFile}   input fits file produced by fits_save_fit.
%                  In the case of several files(in other words
%                  fits for the same model) produced by fits_save_fit,
%                  first add the files with fits_add_fit and use it in 
%                  fits_write_tex_table.
%
%                  Parameter names, digits, factor output have
%                  all default values, but that can be changed
%                  with the last mentioned qualifer in the list
%                  above. 
%
%      NOTE: the function is still under development. Hence, it may
%      not be applicable to all available Xspec or local models.
%      If issues emerge, contact refiz.duro@sternwarte.uni-erlangen.de.   
%
%                           
%\example
%
%   fits_write_tex_table("input.fits";
%                        pars=["cutoffpl","reflionx","diskbb","constant"]
%                       ,exclude=["diskbb_1_tin_value","norm"]
%                       ,constant_1_factor_value=["name","$c_\\mathrm{PCA}$"]
%                       ,output="my_out.tex"
%                       .extraInfo=["target","instrument"]
%                       ,target={"name","Source"}
%                       ,flip
%                       ,pdf);
%
%      will:
%         1.  use input fits_save_fit file "input.fits"
%         2.  look for components "cutoffpl" ,"reflionx", "diskbb" and
%             "constant" in your main model
%         3.  exclude parameter "diskbb_1_tin_value" and all parameters
%             with "norm" in the parameter name
%         4.  change name of now qualifier (actually a parameter)
%             "constant_1_factor_value" to $c_\\mathrm{PCA}$
%         5.  write TeX output to my_out.tex
%         6.  include target and instrument information
%         7.  change name of "target" to "Source"
%         8.  flip your table
%         9.  produce a pdfout.pdf
%
%\seealso{fits_save_fit, fits_add_fit,  TeX_value_pm_error}%
%!%-
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
variable inFile;
   
   switch(_NARGS)
     {case 1 : inFile=();}
     {help (_function_name());return;}
	


   %ASSOCIATIVE ARRAY
   variable assoc=Assoc_Type[Struct_Type];
   %PHABS
   assoc["phabs_nh"]=struct{name=`$N_{\mathrm{H}}$`,unit=`[$10^{22}\mathrm{cm}^{-2}$]`,digits=1};
   %WABS
   assoc["wabs_nh"]=struct{name=`$N_{\mathrm{H}}$`,unit=`[$10^{22}\mathrm{cm}^{-2}$]`,digits=1};
   %PCFABS
   assoc["pcfabs_nh"]=struct{name=`$N_{\mathrm{H}}$`,unit=`[$10^{22}\mathrm{cm}^{-2}$]`,digits=1};
   assoc["pcfabs_cvrfract"]=struct{name=`$Abs_{\mathrm{frac}}$`,digits=1};
   %APPEC
   assoc["apec_norm"]=struct{name=`$A_{\mathrm{apec}}$`,digits=1};
   assoc["apec_kt"]=struct{name=`$kT_\mathrm{apec}$`,unit=`[keV]`,digits=1};
   assoc["apec_abundanc"]=struct{name=`$\mathrm{A}/\mathrm{A}_\odot$`,digits=1};
   assoc["apec_redshift"]=struct{name=`$z$`,digits=1};
   %BAPEC
   assoc["bapec_norm"]=struct{name=`$A_\mathrm{bapec}$`,digits=1};
   assoc["bapec_kt"]=struct{name=`$kT_\mathrm{bapec}$`,unit=`[keV]`,digits=1};
   assoc["bapec_abundanc"]=struct{name=`$\mathrm{A}/\mathrm{A}_\odot$`,digits=1};
   assoc["bapec_redshift"]=struct{name=`$z$`,digits=1};
   assoc["bapec_velocity"]=struct{name=`$v$`,digits=1};
   %TBNEW
   assoc["tbnew_nh"]=struct{name=`$N_{\mathrm{H}}$`,unit=`[$10^{22}\mathrm{cm}^{-2}$]`,digits=3};
   assoc["tbnew_he"]=struct{name=`${\mathrm{He}}$`,digits=2};
   assoc["tbnew_c"]=struct{name=`${\mathrm{C}}$`,digits=2};
   assoc["tbnew_n"]=struct{name=`${\mathrm{N}}$`,digits=2};
   assoc["tbnew_o"]=struct{name=`${\mathrm{O}}$`,digits=2};
   assoc["tbnew_ne"]=struct{name=`${\mathrm{Ne}}$`,digits=2};
   assoc["tbnew_na"]=struct{name=`${\mathrm{Na}}$`,digits=2};
   assoc["tbnew_mg"]=struct{name=`${\mathrm{Mg}}$`,digits=2};
   assoc["tbnew_al"]=struct{name=`${\mathrm{Al}}$`,digits=2};
   assoc["tbnew_si"]=struct{name=`${\mathrm{Si}}$`,digits=2};
   assoc["tbnew_s"]=struct{name=`${\mathrm{S}}$`,digits=2};
   assoc["tbnew_cl"]=struct{name=`${\mathrm{Cl}}$`,digits=2};
   assoc["tbnew_ar"]=struct{name=`${\mathrm{Ar}}$`,digits=2};
   assoc["tbnew_ca"]=struct{name=`${\mathrm{Ca}}$`,digits=2};
   assoc["tbnew_cr"]=struct{name=`${\mathrm{Cr}}$`,digits=2};
   assoc["tbnew_fe"]=struct{name=`${\mathrm{Fe}}$`,digits=2};
   assoc["tbnew_co"]=struct{name=`${\mathrm{Co}}$`,digits=2};
   assoc["tbnew_ni"]=struct{name=`${\mathrm{Ni}}$`,digits=2};
   assoc["tbnew_h2"]=struct{name=`${\mathrm{H2}}$`,digits=2};
   assoc["tbnew_rho"]=struct{name=`${\mathrm{rho}}$`,digits=2};%??
   assoc["tbnew_amin"]=struct{name=`${\mathrm{amin}}$`,digits=2};%??
   assoc["tbnew_amax"]=struct{name=`${\mathrm{amax}}$`,digits=2};%??
   assoc["tbnew_pl"]=struct{name=`${\mathrm{PL}}$`,digits=2};
   assoc["tbnew_h_dep"]=struct{name=`${\mathrm{N_\mathrm{H\_dep}}}$`,digits=2};
   % assoc["tbnew_he_dep"]=struct{name=`${\mathrm{He\_dep}}$`,digits=2};
   % assoc["tbnew_c_dep"]=struct{name=`${\mathrm{C\_dep}}$`,digits=2};
   % assoc["tbnew_n_dep"]=struct{name=`${\mathrm{N\_dep}}$`,digits=2};
   % assoc["tbnew_o_dep"]=struct{name=`${\mathrm{O\_dep}}$`,digits=2};
   % assoc["tbnew_ne_dep"]=struct{name=`${\mathrm{Ne\_dep}}$`,digits=2};
   % assoc["tbnew_na_dep"]=struct{name=`${\mathrm{Na\_dep}}$`,digits=2};
   % assoc["tbnew_mg_dep"]=struct{name=`${\mathrm{Mg\_dep}}$`,digits=2};
   % assoc["tbnew_al_dep"]=struct{name=`${\mathrm{Al\_dep}}$`,digits=2};
   % assoc["tbnew_si_dep"]=struct{name=`${\mathrm{Si\_dep}}$`,digits=2};
   % assoc["tbnew_s_dep"]=struct{name=`${\mathrm{S\_dep}}$`,digits=2};
   % assoc["tbnew_cl_dep"]=struct{name=`${\mathrm{Cl\_dep}}$`,digits=2};
   % assoc["tbnew_ar_dep"]=struct{name=`${\mathrm{Ar\_dep}}$`,digits=2};
   % assoc["tbnew_ca_dep"]=struct{name=`${\mathrm{Ca\_dep}}$`,digits=2};
   % assoc["tbnew_cr_dep"]=struct{name=`${\mathrm{Cr\_dep}}$`,digits=2};
   % assoc["tbnew_fe_dep"]=struct{name=`${\mathrm{Fe\_dep}}$`,digits=2};
   % assoc["tbnew_co_dep"]=struct{name=`${\mathrm{Co\_dep}}$`,digits=2};
   % assoc["tbnew_ni_dep"]=struct{name=`${\mathrm{Ni\_dep}}$`,digits=2};
   assoc["tbnew_redshift"]=struct{name=`${z}$`,digits=2};
   %CUTOFF POWER
   assoc["cutoffpl_phoindex"]=struct{name=`$\Gamma_\mathrm{pl}$`,digits=2};
   assoc["cutoffpl_norm"]=struct{name=`$A_\mathrm{pl}$`,digits=2};
   assoc["cutoffpl_highecut"]=struct{name=`$E_\mathrm{{fold}}$`,digits=1,unit=`[keV]`,sciMode=2};
   %POWER LAW
   assoc["powerlaw_phoindex"]=struct{name=`$\Gamma_\mathrm{pow}$`,digits=2};
   assoc["powerlaw_norm"]=struct{name=`$A_\mathrm{pow}$`,factor=1e4,digits=2};
   %BKN POWER LAW
   assoc["bknpower_phoindx1"]=struct{name=`$\Gamma_\mathrm{1}$`,digits=2};
   assoc["bknpower_norm"]=struct{name=`$A_\mathrm{bkn}$`,digits=2};
   assoc["bknpower_breake"]=struct{name=`$E_\mathrm{pow}$`,unit=`[keV]`,digits=1};
   assoc["bknpower_phoindx2"]=struct{name=`$\Gamma_\mathrm{2}$`,digits=2};
   %BKN2POW
   assoc["bkn2pow_norm"]=struct{name=`$A_\mathrm{bkn}$`,digits=2};
   assoc["bkn2pow_phoindx1"]=struct{name=`$\Gamma_\mathrm{1}$`,digits=2};
   assoc["bkn2pow_breake1"]=struct{name=`$E_\mathrm{1}$`,digits=2};
   assoc["bkn2pow_phoindx2"]=struct{name=`$\Gamma_\mathrm{2}$`,digits=2};
   assoc["bkn2pow_breake2"]=struct{name=`$E_\mathrm{2}$`,digits=2};
   assoc["bkn2pow_phoindx3"]=struct{name=`$\Gamma_\mathrm{3}$`,digits=2};
   %EGAUSS
   assoc["egauss_area"]=struct{name=`$F_\mathrm{6.4\,keV}$`,unit=`[cgs]`,digits=1};%,factor=1e5,,`$[\mathrm{phot}\,\mathrm{s}^{-1}\, \mathrm{cm}^{-1}]$`
   assoc["egauss_center"]=struct{name=`$E_\mathrm{gauss}$`,unit=`[keV]`,digits=2};
   assoc["egauss_sigma"]=struct{name=`$E_\mathrm{\sigma}$`,unit=`[keV]`,digits=2,factor=1e6};
   %GAUSSIAN
   assoc["gaussian_norm"]=struct{name=`$A_\mathrm{gauss}$`,digits=1};%,factor=1e5,,`$[\mathrm{phot}\,\mathrm{s}^{-1}\, \mathrm{cm}^{-1}]$`
   assoc["gaussian_linee"]=struct{name=`$E_\mathrm{gauss}$`,unit=`[keV]`,digits=2};
   assoc["gaussian_sigma"]=struct{name=`$E_\mathrm{\sigma}$`,unit=`[keV]`,digits=2,factor=1e6};
   %GABS
   assoc["gabs_linee"]=struct{name=`$E_\mathrm{gabs}$`,unit=`[keV]`,digits=3};
   assoc["gabs_sigma"]=struct{name=`$E_\mathrm{\sigma}$`,unit=`[keV]`,digits=3};
   assoc["gabs_tau"]=struct{name=`$\tau$`,digits=3,factor=1e3};
   %BREMSS
   assoc["bremss_norm"]=struct{name=`$A_\mathrm{bremss}$`,digits=2};
   assoc["bremss_kt"]=struct{name=`$kT$`,unit=`[keV]`,digits=2};
   %DISK
   assoc["disk_norm"]=struct{name=`$A_\mathrm{disk}$`,digits=2};
   assoc["disk_accrate"]=struct{name=`$Acc$`,digits=2};
   assoc["disk_cenmass"]=struct{name=`$m$`,unit=`$[\mathrm{M}_{\odot}$]`,digits=2};
   assoc["disk_rinn"]=struct{name=`$r_\mathrm{in}$`,digits=2};
   %DISKBB
   assoc["diskbb_tin"]=struct{name=`$kT_\mathrm{BB}$`,digits=2,unit=`[keV]`};
   assoc["diskbb_norm"]=struct{name=`$A_\mathrm{BB}$`,digits=1,sciMode=4};
   %BBODY
   assoc["bbody_kt"]=struct{name=`$kT_\mathrm{bbody}$`,digits=2,unit=`[keV]`};
   assoc["bbody_norm"]=struct{name=`$A_\mathrm{bbody}$`,digits=1,sciMode=4};
   %REFLIONX
   assoc["reflionx_norm"]=struct{name=`$A_\mathrm{ref}$`,digits=3,factor=1e5};
   assoc["reflionx_abund"]=struct{name=`$\mathrm{Fe}/\mathrm{Fe}_\odot$`,digits=2};
   assoc["reflionx_gamma"]=struct{name=`$\Gamma$`,digits=2};
   assoc["reflionx_xi"]=struct{name=`$\xi$`,digits=1,sciMode=4,unit=`$[\mathrm{erg}\,\mathrm{cm}\,\mathrm{s}^{-1}]$`};
   assoc["reflionx_redshift"]=struct{name=`$z$`,digits=1};
   %REFLECT
   assoc["reflect_rel"]=struct{name=`$A_\mathrm{rel\_ref}$`,digits=3};
   assoc["reflect_redshift"]=struct{name=`$z$`,digits=1};
   assoc["reflect_abund"]=struct{name=`$A_\mathrm{abund}$`,digits=1};
   assoc["reflect_fe_abund"]=struct{name=`$\mathrm{Fe}/\mathrm{Fe}_\odot$`,digits=2};
   assoc["reflect_cosincl"]=struct{name=`$\mathrm{cos}\,\theta$`,digits=1};
   %RELCONV 
   assoc["relconv_index1"]=struct{name=`$\epsilon_{1}$`,digits=1};
   assoc["relconv_index2"]=struct{name=`$\epsilon_{2}$`,digits=1};
   assoc["relconv_rbr"]=struct{name=`$r_\mathrm{br}$`,unit=`$[\mathrm{GM\,c}^{-2}]$`,digits=1,sciMode=3};
   assoc["relconv_rin"]=struct{name=`$r_\mathrm{in}$`,digits=1};
   assoc["relconv_rout"]=struct{name=`$r_\mathrm{out}$`,unit=`$[\mathrm{GM\,c}^{-2}]$`,digits=1,sciMode=3};
   assoc["relconv_a"]=struct{name=`a`,digits=3};
   assoc["relconv_incl"]=struct{name=`$i$`,digits=1,unit=`$[\mathrm{deg}]$`};
   assoc["relconv_limb"]=struct{name=`$\mathrm{limb}$`};
   %RELLINE
   assoc["relline_norm"]=struct{name=`$A_\mathrm{relline}$`,digits=3};
   assoc["relline_linee"]=struct{name=`$E_\mathrm{relline}$`,unit=`[keV]`,digits=2};
   assoc["relline_index1"]=struct{name=`$\epsilon_{1}$`,digits=1};
   assoc["relline_index2"]=struct{name=`$\epsilon_{2}$`,digits=1};
   assoc["relline_rbr"]=struct{name=`$r_\mathrm{br}$`,unit=`$[\mathrm{GM\,c}^{-2}]$`,digits=1,sciMode=3};
   assoc["relline_rin"]=struct{name=`$r_\mathrm{in}$`,digits=1};
   assoc["relline_rout"]=struct{name=`$r_\mathrm{out}$`,unit=`$[\mathrm{GM\,c}^{-2}]$`,digits=1,sciMode=3};
   assoc["relline_a"]=struct{name=`a`,digits=3};
   assoc["relline_incl"]=struct{name=`$i$`,digits=1,unit=`$[\mathrm{deg}]$`};
   assoc["relline_limb"]=struct{name=`$\mathrm{limb}$`};
   assoc["relline_z"]=struct{name=`$z$`,digits=1};
   %COMPTT
   assoc["comptt_norm"]=struct{name=`$A_\mathrm{compTT}$`,digits=3};
   assoc["comptt_redshift"]=struct{name=`$z$`,digits=1};
   assoc["comptt_t0"]=struct{name=`$T_{0}$`,digits=1,unit=`[keV]`};
   assoc["comptt_kt"]=struct{name=`$kT$`,digits=1,unit=`[keV]`};
   assoc["comptt_taup"]=struct{name=`$\tau$`,digits=1};
   assoc["comptt_approx"]=struct{name=`$A_\mathrm{approx}$`,digits=1};
  %COMPBB
   assoc["compbb_norm"]=struct{name=`$A_\mathrm{compbb}$`,digits=1};
   assoc["compbb_kt"]=struct{name=`$kT$`,unit=`[keV]`,digits=1};
   assoc["compbb_kte"]=struct{name=`$kTe$`,unit=`[keV]`,digits=1};
   assoc["compbb_tau"]=struct{name=`$\tau$`,digits=1};
   %COMPST
   assoc["compst_norm"]=struct{name=`$A_\mathrm{compst}$`,digits=1};
   assoc["compst_kt"]=struct{name=`$kT$`,unit=`[keV]`,digits=1};
   assoc["compst_tau"]=struct{name=`$\tau$`,digits=1};
   %BBODYRAD
   assoc["bbodyrad_norm"]=struct{name=`$A_\mathrm{bbody}$`,digits=1};
   assoc["bbodyrad_kt"]=struct{name=`$kT$`,unit=`[keV]`,digits=1};
   %BMC
   assoc["bmc_norm"]=struct{name=`$A_\mathrm{bmc}$`,digits=1};
   assoc["bmc_kt"]=struct{name=`$kT$`,unit=`[keV]`,digits=1};
   assoc["bmc_alpha"]=struct{name=`$\alpha$`,digits=1};
   assoc["bmc_log"]=struct{name=`$A_\mathrm{log}$`,digits=1};
   %CONSTANT
   assoc["constant_factor"]=struct{name=`$c$`};
   %GAINSHIFT
   assoc["gainshift_intercept"]=struct{name=`$s_\mathrm{intercept}$`,unit=`[keV]`,digits=2};
   assoc["gainshift_slope"]=struct{name=`$s_\mathrm{gainshift}$`,digits=3};

   variable assoc_keys=assoc_get_keys(assoc);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   %Get all info from table
   variable inputStruct=fits_load_fit_struct(inFile);
   variable names=get_struct_field_names(inputStruct);
   variable rows=fits_read_key(inFile,"NAXIS2");
   variable forTexTable;
   variable i,j,k,z,h;
   variable tempFile="tempFile.txt";
   variable texOut=fopen(tempFile,"w");
   %QUALIFIER INPUT
   variable inputModel=qualifier("pars",NULL);
   variable inputExtraInfo=qualifier("extraInfo",NULL);
   variable inputExclude=qualifier("exclude",NULL);
   variable colNames=qualifier("colNames",NULL);
   variable outputFile=qualifier("output","default.tex");
   variable sciOut=qualifier("sci",NULL);


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %GET MODEL PARAMETER VALUES
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   variable oldName="";
   _for i(0,length(names)-1,1){
      _for j(0,length(inputModel)-1,1){   
	 if(is_substr(names[i],inputModel[j]) and is_substr(names[i],"value")){
	    variable parVal=get_struct_field(inputStruct,names[i]); %get values
	    variable name=names[i];
	 }
	 if(is_substr(names[i],inputModel[j]) and is_substr(names[i],"conf")){
	    variable parConf=get_struct_field(inputStruct,names[i]); %get conf values
	    variable texOutput;
	    %excluded:
	    variable exclude=0;
	    if(inputExclude!=NULL){
	       _for z(0,length(inputExclude)-1,1){
		  if(is_substr(name,inputExclude[z])){
		     exclude=1;
		  }
	       }
	    }
	    %end excluded

	    ifnot(exclude){
	       if (not qualifier_exists("silent")) ()=fprintf(stdout,"%s  \n",name);
	       variable holdName=name;
	       variable holdNameParts=strchop(holdName,'_',0);
	       if(oldName!=holdNameParts[0]){
		  ()=fprintf(texOut,"\\hline \n");
	       }
	       oldName=holdNameParts[0];
	       name=strlow(strreplace(name,"_","\\_"));

	       %ASSOCIATIVE ARRAYS INFO INPUT:
	       variable units="";
	       variable digits=1;
	       variable fac=1;
	       variable sciMode=2;
	       variable startRun;
	       _for z(0,length(assoc_keys)-1,1){
		  variable assocKeysParts=strchop(assoc_keys[z],'_',0);
		  if(is_substr(name,assocKeysParts[0]) and strcmp(strup(assocKeysParts[1]),strup(holdNameParts[2]))==0){
		     name=assoc[assoc_keys[z]].name;
		     variable origName=name;
		     if(struct_field_exists(assoc[assoc_keys[z]],"unit")!=0){
			units=assoc[assoc_keys[z]].unit;
			name=name+"  "+string(units);
		     }
		     if(struct_field_exists(assoc[assoc_keys[z]],"digits")!=0){
			digits=assoc[assoc_keys[z]].digits;
		     }
		     if(struct_field_exists(assoc[assoc_keys[z]],"sciMode")!=0){
			sciMode=assoc[assoc_keys[z]].sciMode;
		     }
		     if(struct_field_exists(assoc[assoc_keys[z]],"factor")!=0){
			fac=assoc[assoc_keys[z]].factor;
			variable inputFactor=sprintf("%e",fac);
			inputFactor=strchop(inputFactor,'e',0);
			inputFactor=inputFactor[1];
			ifnot(is_substr(inputFactor,"00")){
			   if(is_substr(inputFactor,"+")){
			      inputFactor=strtrans(inputFactor,"+","-");
			   }else{
			      inputFactor=strtrans(inputFactor,"-","");
			   }
			   inputFactor=sprintf("[$10^{%s}$]",inputFactor);
			   name=origName+"  "+ inputFactor+" "+string(units);
			}
			
		     }
		  }
	       }
	       %END ASSOCIATIVE ARRAYS INFO INPUT

	       %NEW LOOK INPUT
	       variable factorOut=1;
	       if(qualifier_exists(holdName)){
		  variable newQual=qualifier(holdName);
		  _for z(0,length(newQual)-1,1){
		     variable str=string(newQual[z]);
		     if(is_substr("name",str)){
			name=newQual[z+1];
			origName=name;
		     }
		     if(is_substr("units",str)){
			units=newQual[z+1];name=origName+" "+units;
		     }		     
		     if(is_substr("digits",str))digits=newQual[z+1];
		     if(is_substr("sciMode",str))sciMode=newQual[z+1];
		     if(is_substr("factor",str)){
			fac=newQual[z+1];
			factorOut=fac;
			inputFactor=sprintf("%e",fac);
			inputFactor=strchop(inputFactor,'e',0);
			inputFactor=inputFactor[1];
			ifnot(is_substr(inputFactor,"00")){
			   if(is_substr(inputFactor,"+")){
			      inputFactor=strtrans(inputFactor,"+","-");
			   }else{
			      inputFactor=strtrans(inputFactor,"-","");
			   }
			   inputFactor=sprintf("[$10^{%s}$]",inputFactor);
			   ifnot (__is_initialized(&origName)){
			     name=oldName+"  "+inputFactor+" "+string(units); 
			   }else{
			      name=origName+"  "+inputFactor+" "+string(units);
			   }				
			}
		     }
		  }
	       }
		 
	       ()=fprintf(texOut,"%s  ",name);
	       
	       _for k(0,rows-1,1){
		  ifnot(parConf[k,0]==0 and parConf[k,1]==0){
		     if(sciOut==0){%
			sciMode=10;
			texOutput=TeX_value_pm_error(parVal[k],parConf[k,0],parConf[k,1];factor=fac,sci=sciMode);
		     }else if(sciOut==1){%
			sciMode=10;
			texOutput=TeX_value_pm_error(parVal[k],parConf[k,0],parConf[k,1];factor=fac,sci=sciMode);
			if(is_substr(texOutput,"times10^{1}")){%
			   variable newV, newV_hi,newV_low;
			   ifnot(is_substr(texOutput,"pm")){%
			      %get value, upper and lower error
			      newV=strchop(texOutput,'(',1);
			      newV=strchop(newV[1],'^',1); % newV[0]
			      newV_hi=strchop(newV[1],'+',1);
			      newV_hi=strchop(newV_hi[1],'}',1); %newV_hi[0]
			      newV_low=strchop(newV[1],'-',1);
			      newV_low=strchop(newV_low[1],'}',1); %newV_low[0]%
			      texOutput=sprintf("$%d^{+%d}_{-%d}$",integer(newV[0])*10,integer(newV_hi[0])*10,integer(newV_low[0])*10);
			   }else{
			      newV=strchop(texOutput,'m',1); %newV[0]
			      variable newV_hilow=strchop(newV[1],'\\',1);%newV_hilow[0]
			      newV=strchop(newV[0],'(',1);
			      newV=strchop(newV[1],'\\',1);
			      texOutput=sprintf("$%d\\pm%d$",integer(newV[0])*10,integer(newV_hilow[0])*10);
			   }
			}
		     }else{%
			texOutput=TeX_value_pm_error(parVal[k],parConf[k,0],parConf[k,1];factor=fac,sci=sciMode); 
		     }
		  }else{

		     %FIND CORRECT DECIMAL (for writing non-zero output)
		     variable decim=string(parVal[k]);
		     variable p;
		     if(is_substr(decim,".")){
			_for p(0,strlen(decim)-1,1){
			   if(decim[p]==46){%ascii for .
			      break;
			   }
			}
			variable newDigits=0;
			variable onlyZeros=0;
			p++;
			_for h(p,strlen(decim)-1,1){
			   if(decim[h]!=48){
			      onlyZeros=1;
			      break;
			   }else{
			      newDigits++;
			   }
			}
		     }
		     ifnot(onlyZeros){
			digits=1;
		     }else{
			newDigits=newDigits+2;
			if(newDigits>digits){
			   digits=newDigits;
			}
		     }
		     
		     if(factorOut!=1){
			texOutput=sprintf("%.${digits}f"$,parVal[k]*factorOut);
		     }else{
			texOutput=sprintf("%.${digits}f"$,parVal[k]);
		     }
		  }
		  ()=fprintf(texOut," \&   %s  ",string(texOutput));
	       }
	       ()=fprintf(texOut," \n");
	    }
	 }
      }	       
   }
   
   %END GET MODEL PARAMETER VALUES (with exclusion)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %GET EXTRA INFO
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   
   if(qualifier_exists("extraInfo")){
      ()=fprintf(texOut,"\\hline \n");
      _for j(0,length(inputExtraInfo)-1,1){
	 _for i(0,length(names)-1,1){
	    if(is_substr(names[i],inputExtraInfo[j])){
	       variable extraInfoVal=get_struct_field(inputStruct,names[i]); %get values
	       variable nameExtraInfo=names[i];
	    }
	 }
	 digits=1;
	 
	 %NEW LOOK INPUT
	 if(qualifier_exists(inputExtraInfo[j])){
	    newQual=qualifier(inputExtraInfo[j]);
	    origName=inputExtraInfo[j];
	    name=origName;
	    _for z(0,length(newQual)-1,1){
	       str=string(newQual[z]);
	       if(is_substr("name",str)){
		  name=newQual[z+1];
		  origName=name;
	       }
	       if(is_substr("units",str)){
		  units=newQual[z+1];
		  name=origName+" "+units;
	       }		     
	       if(is_substr("digits",str)){
		  digits=newQual[z+1];
	       }
	    }
	    nameExtraInfo=name;
	 }
	 ()=fprintf(stdout,"%s  \n",string(nameExtraInfo));
	 nameExtraInfo=strreplace(nameExtraInfo,"_","\\_");
	 ()=fprintf(texOut,"%s  ",string(nameExtraInfo));

	 %Find array info
	 variable arrDim,arrNum,arrTyp;
	 (arrDim,arrNum,arrTyp)=array_info(extraInfoVal);
	 _for k(0,rows-1,1){
	    if(arrNum==1){
	       ()=fprintf(texOut," \& ");
	       variable extraInfoVal_clean=strtrans(string(extraInfoVal[k]),"\n"," ");
	       extraInfoVal_clean=strreplace(extraInfoVal_clean,"_","\\_");
	       variable te=strtok(extraInfoVal_clean," ");

	       _for z(0,length(te)-2,1){
		  ()=fprintf(texOut,"  %s \\par ",te[z]);
	       }
	       if(length(te)!=0){
		  ()=fprintf(texOut,"  %s ",te[length(te)-1]);
	       }
	    }else{
	       ()=fprintf(texOut," \& ");
	       variable arrayShape=array_shape(extraInfoVal);

	       if(arrayShape[1]==1){%
		  extraInfoVal_clean=strtrans(string(extraInfoVal[k,0]),"\n"," ");
		  variable te_2=strtok(extraInfoVal_clean," ");
		  ()=fprintf(texOut,"  %.${digits}f"$,atof(te_2[0]));
		  ()=fprintf(texOut,"  \\par");
	       }else{
		  _for z(0,rows-1,1){
		     extraInfoVal_clean=strtrans(string(extraInfoVal[z,0]),"\n"," ");
		     variable te_1=strtok(extraInfoVal_clean," ");
		     ()=fprintf(texOut,"  %.${digits}f"$,atof(te_1[0]));
		     ()=fprintf(texOut,"  \\par");
		  }
	       }
	    }
	 }
	 ()=fprintf(texOut,"\n");
      }
   }
   %END GET EXTRA INFO
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %GET STATISTICS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   _for i(0,length(names)-1,1){
      if(string_matches(names[i],"chi")!=NULL){
	 variable chi=get_struct_field(inputStruct,names[i]); %get values
      }
      if(string_matches(names[i],"dof")!=NULL){
	 variable dof=get_struct_field(inputStruct,names[i]); %get values
      }
      if(string_matches(names[i],"chi_red")!=NULL){
	 variable chi_red=get_struct_field(inputStruct,names[i]); %get values
      }
   }
   ()=fprintf(texOut,"\\hline \n");
   ()=fprintf(texOut,"$\\chi^{2}/\\mathrm{dof}$ ");
   _for j(0,rows-1,1){
      ()=fprintf(texOut,"\&  %.1f/%d",chi[j],dof[j]);
   }
   ()=fprintf(texOut,"  \n");
   if(qualifier_exists("fullStat")){
      ()=fprintf(texOut,"$\\chi^{2}_\\mathrm{red}$ ",);
      _for j(0,rows-1,1){
	 ()=fprintf(texOut,"\&  %.2f",chi_red[j]);
      }
      ()=fprintf(texOut,"  \n");
   }
   %END GET STATISTICS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   ()=fclose(texOut);



   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %WRITE TEX FILE
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   variable lineBreak="";
   variable inTex=fopen(tempFile,"r");
   variable lines=fgetslines(inTex);
   variable outTex=fopen(outputFile,"w");
   %set up tex tabular code
   variable columns="l";
   ()=fprintf(outTex,"\\begin{tabular}{");
   if(qualifier_exists("texMulti")){
      columns="p{4cm}";
   }
   _for k(0,rows,1){
      ()=fprintf(outTex,columns);
   }
   ()=fprintf(outTex,"} \n \\hline \n");

   ()=fprintf(outTex,"Parameter ");
   if(colNames!=NULL and length(colNames)==rows){
      _for k(0,rows-1,1){
	 ()=fprintf(outTex," & %s ",colNames[k]);
      }
   }else{
      _for k(1,rows,1){
	 ()=fprintf(outTex," &  ");
      }
   }
   ()=fprintf(outTex," \\\\ \n");
   
   _for k(0,length(lines)-1,1){
      variable chop=strtrans(lines[k],"\n","");
      
      ifnot(is_substr(lines[k],"\hline")){
	 ()=fprintf(outTex,"%s \\\\ \n",chop);
      }else{
	 ()=fprintf(outTex,"%s \n",chop);
      }
   }
   ()=fprintf(outTex,"\\hline \n");
   ()=fprintf(outTex,"\\end{tabular}");
   ()=fclose(inTex);
   ()=fclose(outTex);
   %END WRITE TEX FILE
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %FLIP
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if(qualifier_exists("flip")){
      variable regTex=fopen(outputFile,"r");
      variable outputTexFile="flip.tex";
      variable flipTex=fopen(outputTexFile,"w");
      variable inLines=fgetslines(regTex);
      %GET NUMBER OF \HLINES
      variable hlines=0;
      _for k(0,length(inLines)-1,1){
	 if(is_substr(inLines[k],"\hline")){
	    hlines++;
	 }
      }
          
      variable arr=Array_Type[length(inLines)-hlines-2];      
      j=0;
      _for i(0,length(inLines)-1,1){
	 ifnot(is_substr(inLines[i],"\hline")){
	    variable lineParts=strchop(inLines[i],'&',0);
	    if(is_substr(inLines[i],"&")){
	       arr[j]=lineParts;
	       j++;
	    }
	 }
      }
      %write flip.tex file
      ()=fprintf(flipTex,"\\begin{tabular}{");
      if(qualifier_exists("texMulti")){
	 _for k(0,length(inLines)-5,1){
	    ()=fprintf(flipTex,`p{4cm}`);
	 }
      }else{
	 _for k(0,length(inLines)-5,1){
	    ()=fprintf(flipTex,`l`);
	 }
      }
      ()=fprintf(flipTex,"} \n \\hline \n");
      
      h=0;
      _for k(0,rows,1){
	 _for j(1,length(arr)-1,1){
	    variable clean=strtrans(arr[j][k],"\n","");
	    (clean,z)=strreplace(clean,`\\`,"",1);
	    if(j==1){
	       ()=fprintf(flipTex," %s ",clean);
	    }else{
	       ()=fprintf(flipTex,"& %s ",clean);	 
	    }
	 }
	 ()=fprintf(flipTex,"\\\\ \n");
	 ifnot(h){
	    ()=fprintf(flipTex,"\\hline \n");
	    h=1;
	 }
      }
      ()=fprintf(flipTex,"\\hline \n");
      ()=fprintf(flipTex,"\\end{tabular}");
      
      ()=fclose(regTex);
      ()=fclose(flipTex);
      ()=system("cp $outputTexFile $outputFile"$);
      ()=system("rm $outputTexFile"$);
   }
   %END FLIP
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %PDF OUTPUT
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if(qualifier_exists("pdf")){
      variable pdf=fopen("pdfout.tex","w");
      ()=fprintf(pdf,"\\documentclass[]{article} \\usepackage[margin=0.5in]{geometry} \\begin{document} \\begin{table}[!ht]");
      ()=fprintf(pdf,"\\input{$outputFile}"$);
      ()=fprintf(pdf,"\\end{table} \\end{document}");
      ()=fclose(pdf);
      ()=system("xelatex pdfout.tex >/dev/null 2>&1");
   }
   %END PDF OUTPUT
   ()= remove("tempFile.txt");
}
