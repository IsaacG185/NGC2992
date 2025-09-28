require("pcre");

private define get_mod_num(name) {
  return pcre_matches ([0-9],name)[0];
}

define par_names_to_tex() {
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %!%+
  %\function{par_names_to_tex}
  %\synopsis{Extract the function name, LaTeX parameter name
  %and unit from a parameter string such as
  %'powerlaw(2).PhoIndex' as provided by fits_load_fit_struct.}
  %\usage{ String_Type (name,fun,unit) = par_names_to_tex(paramater-string,unit);}
  %\description
  %   This function is required by par2tex.
  %\example
  %   par_names_to_tex("powerlaw(2).PhoIndex");
  %   output: "PL 2", "$\Gamma$", ""
  %\seealso{fits_save_fit, fits_load_fit_struct, par2tex, table_print_TeX}
  %!%-
  variable name, unit, fun;
  switch(_NARGS)
  {case 2 : (name,unit)=();}
  { help(_function_name()); return; }

  if(is_substr(name, "detconst") > 0)
  {
    if (is_substr(name , "XIS0") >0) fun = "XIS\,0"R;
    if (is_substr(name , "XIS1") >0) fun = "XIS\,1"R;
    if (is_substr(name , "XIS3") >0) fun = "XIS\,3"R;
    if (is_substr(name , "HXD") >0) fun = "HXD";
    if (is_substr(name , "PIN") >0) fun = "HXD";
    name = "Detconst";
  }
  if(is_substr(name, "absori") > 0)
  {
    if (is_substr(name , "PhoIndex") >0) fun = "$\\Gamma$";
    if (is_substr(name , "nH") >0) fun = "$N_\text{H}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    if (is_substr(name , "Redshift") >0) fun = "$z$";
    if (is_substr(name , "Temp_abs") >0) fun = "$T_{\\text{abs}}$ (K)";
    if (is_substr(name , "xi") >0) fun = "$\\xi$";
    if (is_substr(name , "Fe_abund") >0) fun = "${\tt Fe}-abund$";
    name = sprintf("WA %s",get_mod_num(name));
  }
  if(is_substr(name, "zpcfabs") > 0)
  {
    if (is_substr(name , "nH") >0) fun = "$N_\text{H}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    if (is_substr(name , "CvrFract") >0) fun = "f$_\\text{cvr}$";
    if (is_substr(name , "Redshift") >0) fun = "$z$";
    name = "Partial covering with cold absorption";
  }
  if(is_substr(name , "zxipcf") >0)
  {
    if (is_substr(name , "Nh") >0) fun = "$N_\text{H}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    if (is_substr(name , "log") >0) fun = "$\log\xi$\,($\mathrm{erg}\,\mathrm{cm}\,\mathrm{s}^{-1}$)"R;
    if (is_substr(name , "CvrFract") >0) fun = "f$_\\text{cvr}$";
    if (is_substr(name , "Redshift") >0) fun = "$z$";
    name = sprintf("WA %s",pcre_matches ([0-9],name)[0]);
  }

  if(is_substr(name , "ztbabs")>0)
  {
    if (is_substr(name , "nH") >0) fun = "$N_\text{H}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    if (is_substr(name , "Redshift") >0) fun = "$z$";
    name = "Internal cold absorption";
  }
  if(is_substr(name , "powerlaw")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "PhoIndex") >0) fun = "$\\Gamma$";
    name = sprintf("PL %s",get_mod_num(name));
  }
  if(is_substr(name , "cutoffpl")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "PhoIndex") >0) fun = "$\\Gamma$";
    if (is_substr(name , "HighECut") >0) fun = "$\\mathrm{E}_\mathrm{c}$";
    name = sprintf("PL %s",get_mod_num(name));
  }
  if(is_substr(name , "zgauss")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "LineE") >0) fun = "Energy\\,(keV)";
    if (is_substr(name , "Sigma") >0) fun = "$\\sigma$\\,(keV)";
    if (is_substr(name , "Redshift") >0) fun = "$z$";
    name = sprintf("Gauss %s",get_mod_num(name));
  }
  if(is_substr(name , "redge")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "edge") >0) fun = "Energy\\,(keV)";
    if (is_substr(name , "kT") >0) fun = "$kT$\\,(keV)";
    name = sprintf("Redge %s",get_mod_num(name));
  }
  if(is_substr(name , "egauss")>0)
  {
    if (is_substr(name , "area") >0) fun = "area";
    if (is_substr(name , "center") >0) fun = "Energy\\,(keV)";
    if (is_substr(name , "sigma") >0) fun = "$\\sigma$\\,(keV)";
    name = sprintf("Gauss %s",get_mod_num(name));
  }
  if(is_substr(name , "tbabs")>0)
  {
    if (is_substr(name , "nH") >0) fun = "$N_\text{H,Gal}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    name = "Galactic absorption";
  }
  if((is_substr(name , "tbnew_simple")>0) && (is_substr(name , "tbnew_simple_z")==0))
  {
    if (is_substr(name , "nH") >0) fun = "$N_\text{H,Gal}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    name = "CA";
  }
  if(is_substr(name , "tbnew_simple_z")>0)
  {
    if (is_substr(name , "nH") >0) fun = "$N_\text{H,int}$\,($10^{22}\mathrm{cm}^{-2}$)"R;
    if (is_substr(name , ".z") >0) fun = "$z$";
    name = sprintf("CA",get_mod_num(name));
  }
  if(is_substr(name , "comptt")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "T0") >0) fun = "T$_{0}$\\,(keV)";
    if (is_substr(name , "kT") >0) fun = "$k_\\text{B}T$\\,(keV)";
    if (is_substr(name , "taup") >0) fun = "$\\tau$";
    if (is_substr(name , "Redshift") >0) fun = "$z$";
    if (is_substr(name , "approx") >0) fun = "";
    name = "Comptonization of soft photons";
  }
  if(is_substr(name , "constant")>0)
  {
    if (is_substr(name , "factor") >0) fun = "f$_\\text{cvr}$";
    name = "Covering Factor";
  }
  if(is_substr(name , "xillver")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "Gamma") >0) fun = "$\\Gamma$";
    if (is_substr(name , "logXi") >0) fun = "$\log\xi$\,($\mathrm{erg}\,\mathrm{cm}\,\mathrm{s}^{-1}$)"R;
    if (is_substr(name , "A_Fe") >0) fun = "$A_\\mathrm{Fe}$";
    if (is_substr(name , "redshift") >0) fun = "$z$";
    name = "Ion. Refl.";
  }
  if(is_substr(name , "relxill")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , "Index1") >0) fun = "Index 1";
    if (is_substr(name , "Index2") >0) fun = "Index 2";
    if (is_substr(name , "Rbr") >0) fun = "break rad.";
    if ((is_substr(name , ".a") >0) && (is_substr(name ,".angleon") ==0)) fun = "$a$";
    if (is_substr(name , "Incl") >0) fun = "$i$";
    if (is_substr(name , "Rin") >0) fun = "$R_\mathrm{in}$"R;
    if (is_substr(name , "Rout") >0) fun = "$R_\mathrm{out}$"R;
    if (is_substr(name , ".z") >0) fun = "$z$";
    if (is_substr(name , "gamma") >0) fun = "$\Gamma$"R;
    if (is_substr(name , "logxi") >0) fun = "$\log\xi$\,($\mathrm{erg}\,\mathrm{cm}\,\mathrm{s}^{-1}$)"R;
    if (is_substr(name , "Afe") >0) fun = "$Z_\\mathrm{Fe}$";
    if (is_substr(name , "Ecut") >0) fun = "$E_\mathrm{cut}$"R;
    if (is_substr(name , "refl_frac") >0) fun = "$R_\mathrm{f}$";
    if (is_substr(name , "angleon") >0) fun = "angle averaging";
    name = "Relativ. Refl.";
  }
  if(is_substr(name , "relxilllp")>0)
  {
    if (is_substr(name , "norm") >0) fun = "norm";
    if (is_substr(name , ".h") >0) fun = "height";
    if ((is_substr(name , ".a") >0) && (is_substr(name ,".angleon") ==0)) fun = "$a$";
    if (is_substr(name , "Incl") >0) fun = "$i$";
    if (is_substr(name , "Rin") >0) fun = "$R_\mathrm{in}$"R;
    if (is_substr(name , "Rout") >0) fun = "$R_\mathrm{out}$"R;
    if (is_substr(name , ".z") >0) fun = "$z$";
    if (is_substr(name , "gamma") >0) fun = "$\Gamma$"R;
    if (is_substr(name , "logxi") >0) fun = "$\log\xi$\,($\mathrm{erg}\,\mathrm{cm}\,\mathrm{s}^{-1}$)"R;
    if (is_substr(name , "Afe") >0) fun = "$Z_\\mathrm{Fe}$";
    if (is_substr(name , "Ecut") >0) fun = "$E_\mathrm{cut}$"R;
    if (is_substr(name , "refl_frac") >0) fun = "$R_\mathrm{f}$"R;
    if (is_substr(name , "fixReflFrac") >0) fun = "freeze refl. fract.";
    if (is_substr(name , "angleon") >0) fun = "angle averaging";
    name = "Relativ. Refl.";
  }

  if(unit!=NULL && is_substr(unit , "10^22")>0)
  {
    unit = "$\\times\\,10^{22}$";
  }

  return name,fun,unit;

}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define par2tex()
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %!%+
  %\function{par2tex}
  %\synopsis{Write a LaTeX parameter table from a fit saved with fits_save_fit}
  %\usage{ Integer_Type status = par2tex(fits-fit);}
  %\qualifiers{
  %\qualifier{Obsid}{observation identifier (e.g. obsid)}
  %\qualifier{Src}{source string}
  %}
  %\description
  %   Uses fit saved with fits_save_fit (basename.fits) to write
  %   a LaTeX parameter table (basename.table). The functions
  %   must be defined in the called function 'par_names_to_tex'!
  %   ---- This is the updated version of table_print_TeX ------
  %\example
  %   par2tex("basename.fits";"0102030405",Src="NGC 1234");
  %\seealso{fits_save_fit, par_names_to_tex, table_print_TeX}
  %!%-
{
  variable fits;
  switch(_NARGS)
  {case 1 : fits=();}
  { help(_function_name()); return; }

  variable obsid = qualifier("Obsid","");

  variable i,j,k,l,p,f,fitfun,fall;

  fall=fopen(sprintf("%s/%s.table",path_dirname(fits),path_basename_sans_extname(fits)),"w");
  (qualifier_exists("loadscript") ? evalfile(qualifier("loadscript")) : fits_load_fit(sprintf("%s",fits);ROC=0));
  variable fs = fits_load_fit_struct(sprintf("%s",fits));
  fitfun = get_fit_fun;

  ()=fputs("\\begin{tabular}[ht]{llll}\n",fall);
  ()=fputs("\\midrule\\midrule\n",fall);
  ()=fputs(sprintf("\\multicolumn{4}{c}{%s}\\\\\n",fitfun),fall);
  ()=fputs("\\midrule\n",fall);
  ()=fputs("model component & Parameter & freeze & value\\\\\n",fall);
  ()=fputs("\\midrule\n",fall);

  p = get_params;
  variable fun = String_Type[length(p)];
  variable count = Integer_Type[length(p)];
  variable stat_info;
  eval_counts(&stat_info);
  variable stat = stat_info.statistic;
  variable free = stat_info.num_bins - stat_info.num_variable_params;

  delete_data(1);
  delete_arf(1);
  delete_rmf(1);

  ()=fputs(sprintf("\\multicolumn{4}{c}{%s: $\\chi^2$\\,(dof) = %.2f\\,(%u)}\\\\\n",obsid,stat,free),fall);
  ()=fputs("\\midrule\n",fall);

  variable conf_name_split;
  variable conf_name = String_Type[length(p)];
  % read conf levens from fits_save
  for (i=0;i<length(p);i++) {
    conf_name_split = pcre_matches (`(.*?)(\(.*?\).)(.*)`, p[i].name);
    conf_name[i] = sprintf("%s_%s_%s_conf",conf_name_split[1],pcre_matches (`[0-9]`,p[i].name)[0],conf_name_split[3]);
    conf_name[i] = strreplace(conf_name[i],"(","_");
    conf_name[i] = strreplace(conf_name[i],")","_");
    %    vmessage("%s: %.2e < %.2e < %.2e",conf_name[i],get_struct_field(fs,conf_name[i])[0,0],p[i].value,get_struct_field(fs,conf_name[i])[0,1]);
    p[i].min = p[i].value-get_struct_field(fs,conf_name[i])[0,0];
    p[i].max = get_struct_field(fs,conf_name[i])[0,1]-p[i].value;
    %    vmessage("%s: min=%.2e, max=%.2e",conf_name[i],p[i].min,p[i].max);
  }

  for (i=0;i<length(p);i++)
  {
    variable name_tmp,fun_tmp,unit_tmp;
    (name_tmp,fun_tmp,unit_tmp)=par_names_to_tex(p[i].name,p[i].units);
    %    vmessage("fun = %s",fun_tmp);
    p[i].name=name_tmp;
    p[i].units=unit_tmp;
    fun[i]=fun_tmp;
  }

  % eliminate double par names
  count = Integer_Type[length(p)];
  for (j=0;j<length(p)-1;j++)
  {
    if (p[j+1].name == p[j].name)
    {
      count[j+1] = count[j]+1;
    }
  }
  for (j=0;j<length(p);j++)
  {
    if (count[j] > 0) p[j].name = "";
  }

  for (i=0;i<length(p);i++)
  {
    %    vmessage("parname=%s",p[i].name);
    vmessage("%s",conf_name[i]);
    if (get_struct_field(fs,conf_name[i])[0,0] != 0.) {
      variable tex = TeX_value_pm_error (p[i].value,p[i].value-p[i].min,p[i].value+p[i].max);
      ()=fputs(sprintf("%s & %s & %d & %s\\\\\n",p[i].name,fun[i],p[i].freeze,tex),fall);
    }
    else {
      %      vmessage("%.2f | min=%.2f  max=%.2f",p[i].value,p[i].min,p[i].max);
      ()=fputs(sprintf("%s & %s & %d & %.3g\\\\\n",p[i].name,fun[i],p[i].freeze,p[i].value),fall);
    }
  }

  ()=fputs("\\bottomrule\n",fall);
  ()=fputs("\\end{tabular}\n\n",fall);
  fclose(fall);

  variable status;
  if (length(glob(sprintf("%s/%s.table",path_dirname(fits),path_basename_sans_extname(fits)))) == 1) status = 1;
  else status = 0;

  return status;
}
