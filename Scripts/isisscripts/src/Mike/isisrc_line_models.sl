% -*- slang -*-

% Nov. 26, 2017 -- Version 0.4.2

public define minus(){ return -1.; }

try{
   require("xspec");
   alias_fun("constant","minus"; names=["value"], values=[1], freeze=[1], min=[0], max=[1]);
   __set_hard_limits("gaussian","norm",-1.e38,1.e38);
   __set_hard_limits("egauss","norm",-1.e38,1.e38);
   __set_hard_limits("agauss","norm",-1.e38,1.e38);
   __set_hard_limits("gauss","norm",-1.e38,1.e38);
   __set_hard_limits("zagauss","norm",-1.e38,1.e38);
   __set_hard_limits("zgauss","norm",-1.e38,1.e38);
   __set_hard_limits("voigt","norm",-1.e38,1.e38);
   __set_hard_limits("Lorentz","norm",-1.e38,1.e38);
}
catch AnyError: {}

variable fp_stde = stderr;

% Line information:

variable line_name=String_Type[0], 
   line_energy=Double_Type[0], line_energy_min=Double_Type[0], line_energy_max=Double_Type[0],
   line_norm=Double_Type[0], line_norm_min=Double_Type[0], line_norm_max=Double_Type[0],
   line_sigma=Double_Type[0], line_sigma_min=Double_Type[0], line_sigma_max=Double_Type[0],
   line_vtherm=Double_Type[0], line_vtherm_min=Double_Type[0], line_vtherm_max=Double_Type[0],
   line_redshift=Double_Type[0];

% ISIS Angstrom gauss model: g_, ISIS keV egauss model: eg_, ISIS
% voigt model: v_, ISIS Lorentz model: L_, XSPEC keV gaussian model:
% xg_, XSPEC Angstrom agauss model: ag_, XSPEC zgauss model: zg_,
% XSPEC zagauss model: zag_

variable etypes=["voigt","egauss","gaussian","zgauss"];
variable atypes=["agauss","lorentz","gauss","zagauss"];
variable ftype_name = Assoc_Type[String_Type];
ftype_name["voigt"]="v_";
ftype_name["egauss"]="eg_";
ftype_name["gaussian"]="xg_";
ftype_name["zgauss"]="zg_";
ftype_name["lorentz"]="L_";
ftype_name["gauss"]="g_";
ftype_name["agauss"]="ag_";
ftype_name["zagauss"]="zag_";

variable mod_comps = Assoc_Type[Array_Type];
variable mod_values = Assoc_Type[Array_Type];
variable mod_types = Assoc_Type[Array_Type];
variable mod_subtract = Assoc_Type[Array_Type];
variable mod_i_a_d = Assoc_Type[Array_Type];
variable mod_eorder = Assoc_Type[Char_Type];

public define line_model_prefix()
{
   variable args;
   if(_NARGS==2)
   {
      args = __pop_list(_NARGS);
      variable mod_type=args[0], prefix=args[1];

      if(typeof(mod_type) != String_Type || typeof(prefix) != String_Type)
      { message("Names of fit function and associated prefix must be strings"); return; }

      ifnot( assoc_key_exists(ftype_name,strlow(mod_type)) )
      { message("Fit function not implemented in database"); return; }

      ftype_name[strlow(mod_type)]=prefix;
      return;
   }
   else
   {
      () = fprintf(fp_stde, "%s\n", %{{{
`
  line_model_prefix(mod_name,prefix)
  
   Change the prefix associated with line model mod_name when using
   the init_line and add_line function to create a summed line model.
   Note that init_line must be rerun, and the line must be deleted
   (delete_line) and then added again (add_line) to the existing line
   model.
`  ); %}}}
      return;
   }
}


public define minus_fit(lo,hi,par)
{
   return par[0];
}

add_slang_function("minus",["norm"]);

define minus_defaults(i)
{
   variable pdef = struct{value, freeze, min, max, hard_min,
    hard_max, step, relstep};
   pdef.value=-1.;
   pdef.freeze=0;
   pdef.min=-1.e8;
   pdef.max=1.e8;
   pdef.hard_min=-1.e38;
   pdef.hard_max=1.e38;
   pdef.step=1.e-3;
   pdef.relstep=1.e-3;
   return pdef;
}

set_param_default_hook("minus","minus_defaults");

public define init_line()
{
   variable lstruct=NULL;
   if(_NARGS==0 && __qualifiers==NULL)
   {
      () = fprintf(fp_stde, "%s\n", %{{{
`
  init_line(struct; line_id="name", center=#, min=#, max=#,
                    norm=#, norm_min=#, norm_max=#,
                    sigma=#, sigma_min=#, sigma_max=#,
                    vtherm=#, vtherm_min=#, vtherm_max=#,
                    redshift=#, unit="type")'

  Add a line identified by line_id to a database accessed by the
  add_line, delete_line, and find_line functions.  Default values for
  the line can be passed by either a structure or by
  qualifiers. Qualifiers will override the values of the structure
  fields.

  Line sigma have the expected meaning for gaussian profiles, while
  Lorentz and Voigt profile width parameters are chosen such that they
  have full width half maximum of 2*sqrt(2*log*(2))*sigma.

  Some roundoff errors may occur when applying line values input in
  one unit to a model whose defaults are in different units.

  Reusing a line_id will overwrite previously initialized values;
  however, any defined fit function must be reentered or reevaluated
  to see the changes applied.

  Structure Fields/Qualifiers:

   line_id:    String by which the line will identified (default "a")
   center:     line centroid, units of unit qualifier/field (default 6.4)
   center_min: lower limit of centroid (default center-sigma_max)
   center_max: upper limit of centroid (default center+sigma_max)
   norm:       line amplitude (photons/s/cm^2) (default 1.e-4)
   norm_min:   lower limit of line amplitude (default 0)
   norm_max:   upper limit of line amplitude (default 0.1)
   sigma:      line width (presuming a gaussian) (default 0.01)
   sigma_min:  lower limit of line width (default 0)
   sigma_max:  upper limit of line width (default 0.1)
   vtherm:     Maxwellian velocity for voigt model (default 1000 km/s)
   vtherm_min: lower limit of Maxwellian velocity (default 0.1)
   vtherm_max: upper limit of Maxwellian velocity (default 100000 km/s)
   redshift:   line redshift, in redshifted model (default 0)
   unit:       String for units of input center/sigma (default "keV")
`  ); %}}}
      return;
   }
   else if(_NARGS==1)
   {
      lstruct=();
   }
   else if(_NARGS>1)
   {
      message("Too many input variables: only single structure expected");
      variable args = __pop_list(_NARGS);
      return;
   }

   if(typeof(lstruct) != Struct_Type && lstruct != NULL)
   {
      print(lstruct);
      message("Input must be a structure and/or qualifiers");
      return;
   }

   variable line_id="a", center=6.4, center_min,
   center_max, norm=1.e-5, norm_min=0., norm_max=0.1,
   sigma=0.01, sigma_min=0., sigma_max=0.1, vtherm=50.,
   vtherm_min=0.1, vtherm_max=500., redshift=0., unit="kev",
   u_info, center_e, center_e_min, center_e_max,
   center_a, center_a_min, center_a_max,
   sigma_e, sigma_e_min, sigma_e_max,
   sigma_a, sigma_a_min, sigma_a_max;

   try{ unit = get_struct_field(lstruct,"unit"); }
   catch AnyError: {}
   unit = qualifier("unit","keV");
   u_info = unit_info(unit);
   
   try{ line_id = get_struct_field(lstruct,"line_id"); }
   catch AnyError: {}
   line_id = qualifier("line_id","a");
   
   try{ center = get_struct_field(lstruct,"center"); }
   catch AnyError: {}
   center = qualifier("center",center);

   try{ sigma = get_struct_field(lstruct,"sigma"); }
   catch AnyError: {}
   sigma = qualifier("sigma",sigma);

   try{ sigma_min = get_struct_field(lstruct,"sigma_min"); }
   catch AnyError: {}
   sigma_min = qualifier("sigma_min",sigma_min);

   try{ sigma_max = get_struct_field(lstruct,"sigma_max"); }
   catch AnyError: {}
   sigma_max = qualifier("sigma_max",sigma_max);

   if(sigma_max<sigma) sigma_max=sigma;
   if(sigma_min>sigma) sigma_min=0;
   center_min = center-sigma_max;
   center_max = center+sigma_max;
 
   try{ center_min = get_struct_field(lstruct,"center_min"); }
   catch AnyError: {}
   center_min = qualifier("center_min",center_min);

   try{ center_max = get_struct_field(lstruct,"center_max"); }
   catch AnyError: {}
   center_max = qualifier("center_max",center_max);

   try{ norm = get_struct_field(lstruct,"norm"); }
   catch AnyError: {}
   norm = qualifier("norm",norm);

   try{ norm_min = get_struct_field(lstruct,"norm_min"); }
   catch AnyError: {}
   norm_min = qualifier("norm_min",norm_min);

   try{ norm_max = get_struct_field(lstruct,"norm_max"); }
   catch AnyError: {}
   norm_max = qualifier("norm_max",norm_max);   

   if(norm_max<norm) norm_max=norm;
   if(norm_min>norm) norm_min=0;

   try{ vtherm = get_struct_field(lstruct,"vtherm"); }
   catch AnyError: {}
   vtherm= qualifier("vtherm",vtherm);

   try{ vtherm_min = get_struct_field(lstruct,"vtherm_min"); }
   catch AnyError: {}
   vtherm_min = qualifier("vtherm_min",vtherm_min);

   try{ vtherm_max = get_struct_field(lstruct,"vtherm_max"); }
   catch AnyError: {}
   vtherm_max = qualifier("vtherm_max",vtherm_max);

   if(vtherm_max<vtherm) vtherm_max=vtherm;
   if(vtherm_min>vtherm) vtherm_min=vtherm;

   try{ redshift = get_struct_field(lstruct,"redshift"); }
   catch AnyError: {}
   redshift = qualifier("redshift",redshift);

   variable iw = where(line_name != line_id);
   line_name = [line_name[iw],line_id];

   % Convert variables to keV and Angstrom units

   if(u_info.is_energy)
   {
      center_e = center*u_info.scale;
      center_e_min = center_min*u_info.scale;
      center_e_max = center_max*u_info.scale;

      sigma_e = sigma*u_info.scale;
      sigma_e_min = sigma_min*u_info.scale;
      sigma_e_max = sigma_max*u_info.scale;

      center_a = _A(center_e);
      center_a_min = _A(center_e_max);
      center_a_max = _A(center_e_min);

      sigma_a = (sigma_e/center_e)*center_a;
      sigma_a_min = (sigma_e_min/center_e)*center_a;
      sigma_a_max = (sigma_e_max/center_e)*center_a;
   }
   else
   {
      center_a = center*u_info.scale;
      center_a_min = center_min*u_info.scale;
      center_a_max = center_max*u_info.scale;

      sigma_a = sigma*u_info.scale;
      sigma_a_min = sigma_min*u_info.scale;
      sigma_a_max = sigma_max*u_info.scale;

      center_e = _A(center_a);
      center_e_min = _A(center_a_max);
      center_e_max = _A(center_a_min);

      sigma_e = (sigma_a/center_a)*center_e;
      sigma_e_min = (sigma_a_min/center_a)*center_e;
      sigma_e_max = (sigma_a_max/center_a)*center_e;
   }

   line_energy = [line_energy[iw], center_e];
   line_energy_min = [line_energy_min[iw], center_e_min];
   line_energy_max = [line_energy_max[iw], center_e_max];

   line_norm = [line_norm[iw], norm];
   line_norm_min = [line_norm_min[iw], norm_min];
   line_norm_max = [line_norm_max[iw], norm_max];

   line_sigma = [line_sigma[iw], sigma_e];
   line_sigma_min = [line_sigma_min[iw], sigma_e_min];
   line_sigma_max = [line_sigma_max[iw], sigma_e_max];

   line_vtherm = [line_vtherm[iw], vtherm];
   line_vtherm_min = [line_vtherm_min[iw], vtherm_min];
   line_vtherm_max = [line_vtherm_max[iw], vtherm_max];

   line_redshift = [line_redshift[iw], redshift];

   % ISIS Line Models
   alias_fun("gauss",ftype_name["gauss"]+line_name[-1];
             names = ["area [photons/s/cm^2]", "center [A]", "sigma [A]"],
             values = [norm, center_a, sigma_a],
             freeze = [0, 0, 0],
             min = [norm_min, center_a_min, sigma_a_min],
             max = [norm_max, center_a_max, sigma_a_max]);

   alias_fun("egauss",ftype_name["egauss"]+line_name[-1];
             names = ["area [photons/s/cm^2]", "center [keV]", "sigma [keV]"],
             values = [norm, center_e, sigma_e],
             freeze = [0, 0, 0],
             min = [norm_min, center_e_min, sigma_e_min],
             max = [norm_max, center_e_max, sigma_e_max]);

   variable fwhm_scl = 2*sqrt(2*log(2));
   alias_fun("Lorentz",ftype_name["lorentz"]+line_name[-1];
             names = ["area [photons/s/cm^2]", "center [A]", "fwhm [A]"],
             values = [norm, center_a, fwhm_scl*sigma_a],
             freeze = [0, 0, 0],
             min = [norm_min, center_a_min, fwhm_scl*sigma_a_min],
             max = [norm_max, center_a_max, fwhm_scl*sigma_a_max]);

   fwhm_scl *= 2.*PI;
   alias_fun("voigt",ftype_name["voigt"]+line_name[-1];
             names = ["norm [photons/s/cm^2]", "energy [keV]", "fwhm [keV]", "vtherm [km/s]"],
             values = [norm, center_e, fwhm_scl*sigma_e, vtherm],
             freeze = [0, 0, 0, 0],
             min = [norm_min, center_e_min, fwhm_scl*sigma_e_min, vtherm_min],
             max = [norm_max, center_e_max, fwhm_scl*sigma_e_max, vtherm_max]);

   % XSPEC Line Models
   alias_fun("zgauss",ftype_name["zgauss"]+line_name[-1];
             names = ["norm [photons/s/cm^2]", "LineE [keV]", "Sigma [keV]","Redshift"],
             values = [norm, center_e, sigma_e, redshift],
             freeze = [0, 0, 0, 1],
             min = [norm_min, center_e_min, sigma_e_min, -0.999],
             max = [norm_max, center_e_max, sigma_e_max, 10]);

   alias_fun("gaussian",ftype_name["gaussian"]+line_name[-1];
             names = ["norm [photons/s/cm^2]", "LineE [keV]", "Sigma [keV]"],
             values = [norm, center_e, sigma_e],
             freeze = [0, 0, 0],
             min = [norm_min, center_e_min, sigma_e_min],
             max = [norm_max, center_e_max, sigma_e_max]);

   alias_fun("agauss",ftype_name["agauss"]+line_name[-1];
             names = ["norm [photons/s/cm^2]", "LineE [A]", "Sigma [A]"],
             values = [norm, center_a, sigma_a],
             freeze = [0, 0, 0],
             min = [norm_min, center_a_min, sigma_a_min],
             max = [norm_max, center_a_max, sigma_a_max]);

   alias_fun("zagauss",ftype_name["zagauss"]+line_name[-1];
             names = ["norm [photons/s/cm^2]", "LineE [A]", "Sigma [A]","Redshift"],
             values = [norm, center_a, sigma_a, redshift],
             freeze = [0, 0, 0, 1],
             min = [norm_min, center_a_min, sigma_a_min, -0.999],
             max = [norm_max, center_a_max, sigma_a_max, 10]);

}

public define add_line()
{
   variable args;
   if(_NARGS==3)
   {
      args=__pop_list(_NARGS);
      variable lname=args[0], fname=args[1], ftype=args[2];

      if(typeof(lname) != String_Type || 
         typeof(fname) != String_Type || 
         typeof(ftype) != String_Type    )
      { message("Input component, model, and line model type values as strings"); return; }

      ftype=strlow(ftype);

      if(length(where([etypes,atypes]==ftype))==0)
      { message("Unrecognized line model type"); return; }

      if(length(where(line_name==lname))==0)
      { message("Line component not initialized"); return; }

      if(assoc_key_exists(mod_values,fname) && 
         length(where(mod_comps[fname]==lname))>0 )
      { message("Line already in model"); return; }

      ifnot( assoc_key_exists(mod_values,fname) )
      {
         mod_comps[fname]=String_Type[0]; 
         mod_values[fname]=Double_Type[0]; 
         mod_types[fname]=String_Type[0]; 
         mod_subtract[fname]=Char_Type[0]; 
         mod_i_a_d[fname]=String_Type[0]; 
         if(length(etypes==ftype))
         {
            mod_eorder[fname]=1; 
         }
         else
         {
            mod_eorder[fname]=0  ; 
         }
      }

      variable i, iline = where(line_name==lname); 
 
      mod_comps[fname] = [mod_comps[fname],line_name[iline]];
      mod_values[fname] = [mod_values[fname],line_energy[iline]];
      mod_types[fname] = [mod_types[fname],ftype];
      if(qualifier_exists("subtract"))
      {
         mod_subtract[fname] = [mod_subtract[fname],1];
      }
      else
      {
         mod_subtract[fname] = [mod_subtract[fname],0];
      }

      variable i_a_d = qualifier("id","1");
      mod_i_a_d[fname] = [mod_i_a_d[fname],i_a_d];

      mod_eorder[fname] = qualifier("eorder",mod_eorder[fname]);

      variable isrt=array_sort(mod_values[fname]);
      ifnot(mod_eorder[fname]) isrt=reverse(isrt);
      mod_comps[fname] = mod_comps[fname][isrt];
      mod_values[fname] = mod_values[fname][isrt];
      mod_types[fname] = mod_types[fname][isrt];
      mod_subtract[fname] = mod_subtract[fname][isrt];
      mod_i_a_d[fname] = mod_i_a_d[fname][isrt];

      variable meval="public define "+fname+"(){ variable y;";

      if(mod_subtract[fname][0])
      {
         meval += "y=-minus("+mod_i_a_d[fname][0]+")*"+ftype_name[mod_types[fname][0]]
                  +mod_comps[fname][0]+"("+mod_i_a_d[fname][0]+");";
      }
      else
      {
         meval += "y="+ftype_name[mod_types[fname][0]]
                  +mod_comps[fname][0]+"("+mod_i_a_d[fname][0]+");";
      }

      _for i (1,length(isrt)-1,1)
      {
         if(mod_subtract[fname][i])
         {
            meval += "y-=minus("+mod_i_a_d[fname][i]+")*"+ftype_name[mod_types[fname][i]]
                     +mod_comps[fname][i]+"("+mod_i_a_d[fname][i]+");";
         }
         else
         {
           meval += "y+="+ftype_name[mod_types[fname][i]]
                    +mod_comps[fname][i]+"("+mod_i_a_d[fname][i]+");";
         }
      }
      meval += "return y; }";
      eval(meval);
      return;
   }
   else
   {
      args = __pop_list(_NARGS);
      () = fprintf(fp_stde, "%s\n", %{{{
`
  add_line(line_id, function_name, line_type;
              id=string, eorder=#, subtract);

  Create or add to the fit function function_name() (a model that
  returns a sum of line components) a line component identified by the
  line_id string. The line_id must first have been created by the
  init_line function.

  The added component must be one of the following ISIS or XSPEC
  models: gauss, egauss, Lorentz, voigt, gaussian, agauss, zgauss,
  zagauss, as identified by the line_type string.

  The added component will have the prefix: g_, eg_, L_, v_, xg_, ag_,
  zg_, or zag_, respectively, coupled with line_id(id). (Default
  prefixes can be changed with line_model_prefix function.)

  Qualifiers:

   id:       String to identify the model instance, e.g., "1", "2",
             "Isis_Active_Dataset" (default "1")
   eorder:   if=0, the line components will be arranged in wavelength order
             (default is last used value, or 0 or 1, based upon whether 
             the first added model is naturally wavelength or energy 
             based, respectively)
   subtract: if present, subtract, not add, the line component
             (indicated by minus(id) function, which is just an
             aliased constant function, before the line component)
`  ); %}}}
      return;
   }
}

public define delete_line()
{
   variable args;
   if(_NARGS==2)
   {
      args=__pop_list(_NARGS);
      variable lname=args[0], fname=args[1];

      if(typeof(lname) != String_Type || 
         typeof(fname) != String_Type    )
      { message("Input component and model type values as strings"); return; }

      if(length(where(line_name==lname))==0)
      { message("Line component not initialized"); return; }

      ifnot(assoc_key_exists(mod_comps,fname))
      { message("Summed line function not initialized"); return; }

      variable i, iw=where(mod_comps[fname]!=lname);

      mod_comps[fname] = mod_comps[fname][iw];
      mod_values[fname] = mod_values[fname][iw];
      mod_types[fname] = mod_types[fname][iw];
      mod_subtract[fname] = mod_subtract[fname][iw];
      mod_i_a_d[fname] = mod_i_a_d[fname][iw];

      variable meval="public define "+fname+"(){ variable y;";

      if(mod_subtract[fname][0])
      {
         meval += "y=-minus("+mod_i_a_d[fname][0]+")*"+ftype_name[mod_types[fname][0]]
                  +mod_comps[fname][0]+"("+mod_i_a_d[fname][0]+");";
      }
      else
      {
         meval += "y="+ftype_name[mod_types[fname][0]]
                  +mod_comps[fname][0]+"("+mod_i_a_d[fname][0]+");";
      }

      _for i (1,length(mod_comps[fname])-1,1)
      {
         if(mod_subtract[fname][i])
         {
            meval += "y-=minus("+mod_i_a_d[fname][i]+")*"+ftype_name[mod_types[fname][i]]
                     +mod_comps[fname][i]+"("+mod_i_a_d[fname][i]+");";
         }
         else
         {
           meval += "y+="+ftype_name[mod_types[fname][i]]
                    +mod_comps[fname][i]+"("+mod_i_a_d[fname][i]+");";
         }
      }
      meval += "return y; }";
      eval(meval);
      return;
   }
   else
   {
      args=__pop_list(_NARGS);
      () = fprintf(fp_stde, "%s\n", %{{{
`
  delete_line(line_id, function_name);

  Delete the line component, identified by the string line_id
  (previously initialized by the init_line function), from the summed
  fit function (previously created by the funtion add_line) given by
  the string, function_name.
`  ); %}}}
      return;
   }
}

public define find_line()
{
   variable args, lo_in, hi_in, lo_tru, hi_tru, e_lo, e_hi;
   if(_NARGS==2)
   {
      args = __pop_list(_NARGS);
      lo_in=args[0], hi_in=args[1];

      if( typeof(lo_in)!=Char_Type && typeof(lo_in)!=Integer_Type && 
          typeof(lo_in)!=Float_Type && typeof(lo_in)!=Double_Type && 
          typeof(hi_in)!=Char_Type && typeof(hi_in)!=Integer_Type && 
          typeof(hi_in)!=Float_Type && typeof(hi_in)!=Double_Type         )
       { message("Inputs need to be numbers"); return; }

      if(lo_in<hi_in)
      {
         lo_tru = lo_in;
         hi_tru = hi_in;
      }
      else if(lo_in>hi_in)
      {
         lo_tru = hi_in;
         hi_tru = lo_in;
      }
      else
      { message("Inputs identical"); return; } 

      variable u_info = unit_info(qualifier("unit","kev")); 
  
      if(u_info.is_energy)
      {
         e_lo = lo_in*u_info.scale;
         e_hi = hi_in*u_info.scale;
      }
      else
      {
         e_lo = _A(hi_in*u_info.scale);
         e_hi = _A(lo_in*u_info.scale);
      }

      variable iw = where(e_lo <= line_energy <= e_hi);
      if(length(iw) == 0)
      {
         ifnot(qualifier_exists("noprint"))
	 { message("No lines found"); }
         return NULL;
      }
      else
      {
         variable isrt=array_sort(line_energy[iw]);
	 ifnot(qualifier_exists("noprint"))
         {
            variable i;
            _for i (0,length(isrt)-1,1)
            {
               if(u_info.name == "keV" || u_info.name == "A" || u_info.name == "Angstrom")
               {
                  () = fprintf(fp_stde," %-12S   %14.4g keV   %14.4g A\n",
                  line_name[iw[i]], line_energy[iw[i]], _A(line_energy[iw[i]]));
               }
               else
               {
                  variable le;
                  if(u_info.is_energy)
                  {
                     le = line_energy[iw[i]]/u_info.scale;
                  }
                  else
                  {
                     le = _A(line_energy[iw[i]])/u_info.scale;
                  }
                  () = fprintf(fp_stde," %-12S   %14.4g keV   %14.4g A   %14.4g   "
                               +u_info.name+"\n",
                  line_name[iw[i]], line_energy[iw[i]], _A(line_energy[iw[i]]), le);
               }
	    }      
	 }
         return line_name[iw[isrt]];
      }   
   }
   else
   {
      args = __pop_list(_NARGS);
      () = fprintf(fp_stde, "%s\n", %{{{
`
  line_ids = find_line(a,b; unit=string, noprint)
  
   Return an array of line_ids from the database, originally
   initialized with init_line, with default centers between bounds
   (a,b), and further print this list to the screen.

  Qualifiers:

   unit:    Units of the bounds (default "keV")
   noprint: If present, don't print the list to the screen
`  ); %}}}
      return;
   }
}

public define save_line_models()
{
   if(_NARGS==1)
   {
      variable i, file=();
      if(typeof(file)!=String_Type)
       { message("Input filename needs to be a string"); return; }

      variable fps = fopen(file,"w");

      () = fprintf(fps,"%% Line Database: \n");
      _for i (0,length(line_name)-1,1)
      {
         () = fprintf(fps,"init_line(;line_id=\"%s\", center=%g, min=%g, max=%g,\n",
                      line_name[i],line_energy[i],line_energy_min[i],line_energy_max[i]);
         () = fprintf(fps,"           norm=%g, norm_min=%g, norm_max=%g,\n",
                      line_norm[i],line_norm_min[i],line_norm_max[i]);
         () = fprintf(fps,"           sigma=%g, sigma_min=%g, sigma_max=%g,\n",
                      line_sigma[i],line_sigma_min[i],line_sigma_max[i]);
         () = fprintf(fps,"           vtherm=%g, vtherm_min=%g, vtherm_max=%g,\n",
                      line_vtherm[i],line_vtherm_min[i],line_vtherm_max[i]);
         () = fprintf(fps,"           unit=\"keV\");\n");
      }
      () = fprintf(fps,"\n");

      variable mod_def, lmkeys = assoc_get_keys(mod_comps);

      foreach mod_def (lmkeys)
      {
         () = fprintf(fps,"%% Line Model: \"%s\" \n",mod_def);
         _for i (0,length(mod_comps[mod_def])-1,1)
         {
            if(mod_subtract[mod_def][i])
            {
               () = fprintf(fps,"add_line(\"%s\",\"%s\",\"%s\"; id=\"%s\", eorder=%i, subtract);\n",
                            mod_comps[mod_def][i],mod_def,mod_types[mod_def][i],
                            mod_i_a_d[mod_def][i],mod_eorder[mod_def]);
            }
            else
            {
               () = fprintf(fps,"add_line(\"%s\",\"%s\",\"%s\"; id=\"%s\", eorder=%i);\n",
                            mod_comps[mod_def][i],mod_def,mod_types[mod_def][i],
                            mod_i_a_d[mod_def][i],mod_eorder[mod_def]);
            }
         }
         () = fprintf(fps,"\n");
      }
      () = fclose(fps);
   }
   else
   {
      variable args = __pop_list(_NARGS);
      () = fprintf(fp_stde, "%s\n", %{{{
`
  save_line_models(file_name);
  
   Create a S-lang script in file_name that when executed initializes
   all lines and models, as they currently exist, from the init_line
   and add_line/delete_line functions.
`  ); %}}}
      return;
   }
}


#iftrue
public define rolling_fit()
{
   if(_NARGS==1)
   {
      variable i=0, comp, mod_name=();
      if(typeof(mod_name)!=String_Type)
       { message("Input model name needs to be a string"); return; }

      ifnot(assoc_key_exists(mod_comps,mod_name))
       { message("Model does not exist"); return; }

      variable fv_hold = Fit_Verbose;
      Fit_Verbose = -1;
      variable nloop = qualifier("nloop",1);
      variable tol = qualifier("tol",0.);

      variable line_mods=ftype_name[mod_types[mod_name]]+
                         mod_comps[mod_name]+"("+
                         mod_i_a_d[mod_name]+")";

      variable mod_pars, mod_par_num, 
               mod_pars_thaw = Array_Type[length(mod_comps[mod_name])],
               unfrz_line_pars = String_Type[0];

      foreach comp (line_mods)
      {
         mod_pars_thaw[i] = String_Type[0];
         foreach mod_par_num (get_fun_params(comp))
         {
            variable gp = get_params[mod_par_num];
            variable ptype = strlow(strtok(gp.name,".")[-1]);

            % As long as the parameter is not tied or frozen, add it
            % to the global list of line parameters that will be
            % frozen on each loop
            if( gp.freeze==0 && gp.tie==0 )
            {
               unfrz_line_pars = [unfrz_line_pars,gp.name];

               % But only if it is in a category of fit parameters
               % that we want to fit, add it to the list of parameters
               % for that component to be unfrozen for the local fit.
               if( (((ptype=="norm") && qualifier_exists("nonorm")) != 1) && 
                   (((ptype=="sigma") && qualifier_exists("nosigma")) != 1) && 
                   (((ptype=="fwhm") && qualifier_exists("nosigma")) != 1) && 
                   (((ptype=="vtherm") && qualifier_exists("novtherm")) != 1)  )
               {
                  mod_pars_thaw[i] = [mod_pars_thaw[i],get_params[mod_par_num].name];
               }
            }
	 }
         i++;
      }

      variable itot=i-2, info;

      () = eval_counts(&info);
      variable delta_stat=1.e16, start_stat = info.statistic;
      variable looped = 0;

      while(looped < nloop && delta_stat > tol)
      {
         _for i (0,itot,1)
         {
            freeze(unfrz_line_pars);
            if(length(mod_pars_thaw[i]))
            {
               thaw(mod_pars_thaw[i]);
               () = fit_counts;
            }
         }
         thaw(unfrz_line_pars);
         () = eval_counts(&info);
         delta_stat = start_stat - info.statistic;
         start_stat = info.statistic;
         looped++;
      }
      Fit_Verbose = fv_hold;
   }
   else
   {
      variable args = __pop_list(_NARGS);
      () = fprintf(fp_stde, "%s\n", %{{{
`
  rolling_fit(line_model_name);
  
   For a line model created with the init_line/add_line/delete_line
   functions and identified by the string line_model_name, perform a
   fit where the continuum+one line component at a time is left
   unfrozen.  Serially loop through a fit of all of the line
   components a specified number of times, or until the fit statistic
   stops changing (comparing full loop to full loop) within a
   specified tolerance range.

  Qualifiers:

   nloop =    Number of fit loops through the line components. 
              (Default nloop=1)
   tol =      Tolerance on changes in fit statistic changes.  If the
              fit statistic has changed by less than this value since
              the beginning of the loop, stop looping regardless of the 
              nloop parameter value. (Default tol=0.)
   nonorm =   Do not fit line normalizations, regardless of whether or
              not they are unfrozen parameters.
   nosigma =  Do not fit line widths (Sigma or fwhm), regardless of 
              whether or not they are unfrozen parameters.
   novtherm = Do not fit line therm widths, regardless of whether or
              not they are unfrozen parameters.
`  ); %}}}
      return;
   }
}  
#endif

define query_user(string_ref)
{
   variable buf, status;
 
   forever {
      if ( fprintf(stdout, "  Enter line name: ") < 0 ) return -1;
      status = fgets(&buf, stdin);

      if(status>1)
      {
         @string_ref = strtrim(buf,"\n");
         return 0;
      }

      if (fprintf(stdout, "  Come again??\n")<0) return -1;
  }
}

public define add_cursor_line()
{
   variable args;
   if(_NARGS==2)
   {
      args = __pop_list(_NARGS);
      variable fun_name = args[0], line_type = args[1];
   }
   else
   {
      () = fprintf(fp_stde, "%s\n", %{{{
`
  add_cursor_line(fun_name, line_type [; qualifiers])

  Initialize (via the init_line function) and add (via the add_line
  function) lines of type line_type to the line model named fun_name
  using the cursor clicking on a plot.  Lines will be given default
  names based upon their centroid value.

  The user can either add only the line centroid values (with line
  lower/upper limits automatically added), or click on three points to
  correspond to line limits and centroid.  Allowed line widths will be
  determined from the lower/upper limits.

  Default keyboard values for lower/centroid/upper values are mapped
  to keyboard triplets: x/c/v ; s/d/f ; w/e/r; 1/2/3; n/m/, ; j/k/l ;
  i/o/p ; 9/0/- with the spacebar or mouse click always being the
  centroid. q quits the session (and cannot be overwritten).

  Qualifiers:

   Any from init_line or add_line will be passed through and retain
   their usual default values, except that center, center_min,
   center_max, sigma, sigma_min, sigma_max will be generated from the
   plot clicks.  Thus, reuse of those qualifiers will generate an
   error.

   res             : Fraction resolution of detector (default=1.e-3),
                     used to guess lower/upper limits [=line center X
                     (1+/-res*res_factor)] and line width [=line
                     center*res*sigma_scale] and line width limits
                     [=line width*res*sigma_factor_lo/_hi]
   res_factor      : Used to determine line limits (default=2)
   sigma_scale     : Used to determine line widths (default=0.25)
   sigma_factor_hi : Used to determine line width upper limit 
                     (default=8)
   sigma_factor_lo : Used to determine line width lower limit
                     (default=0)
   limits          : If exists, determine limits/widths from cursor
                     clicks
   lo_limit        : Change default keys for lower limit clicks (string 
                     array)
   hi_limit        : Change default keys for upper limit clicks
                     (string array)
   center          : Change default keys for centroid clicks (string
                     array)
   prompt_name     : If exists, prompt for name of each line
   fit             : If exists, freeze all parameters except for newly
                     defined line, and perform a fit
 ` ); %}}} 
      return;
   }
 
   variable x, y, ch,line_id;
   variable res = qualifier("res",1.e-3);
   variable res_factor = qualifier("res_factor",2);
   variable sigma_scale = qualifier("sigma_scale",0.25);
   variable sigma_factor_hi = qualifier("sigma_factor_hi",8.);
   variable sigma_factor_lo = qualifier("sigma_factor_lo",0.);
   variable limits = 0;
   if( qualifier_exists("limits") ) limits=1;
   variable lo_limit = [qualifier("lo_limit",["x","s","w","1","n","j","i","9"])];
   variable hi_limit = [qualifier("hi_limit",["v","f","r","3",",","l","p","-"])];
   variable center = [qualifier("center",["c","d","e","2","m","k","o","0","A"," "])];
   variable n=1, j=0;
   if (limits) n=3;

   if ( length(where("q"==lo_limit)) || length(where("q"==hi_limit)) ||
      length(where("q"==center)) ) return;

   variable line_center, line_lo, line_hi;

   forever{
      line_center=-1.; line_lo=-1.; line_hi=-1;
      loop(n)
      {
         ifnot(j) () = printf("Enter line center, min, and max (any order): \n\n");
         if(j==2) { j=0; } else j++;
         
         cursor(&x,&y,&ch);
         if(get_plot_info.xlog) x = 10^x;
         if(ch=="q") break;
         if(length(where(ch==lo_limit)))
         {
            line_lo=x;
         }
         else if(length(where(ch==hi_limit)))
         {
            line_hi=x;
         }
         else if(length(where(ch==center)))
         {
            line_center=x;
         }
         if (n==1) line_center=x;
      }
      if (ch=="q" || line_center <=0) break;

      if (line_lo <= 0 || line_lo >= line_center) 
        line_lo = line_center*(1-res*res_factor);

      if (line_hi <= 0 || line_hi <= line_center) 
        line_hi = line_center*(1+res*res_factor);
      
      () = printf("Selected line value: %.4f + %.4f - %.4f \n\n",
           line_center,line_hi-line_center,line_center-line_lo);

      if(qualifier_exists("prompt_name"))
      {
         () = query_user(&line_id);
      }
      else
      {
         % Multiply wavelength or energy by 1000, truncate, and call
         % that the line name
         line_id = string(int(1.e3*x));
      }

      init_line( ;__qualifiers, line_id=line_id, center=line_center, 
        center_min=line_lo, center_max=line_hi, 
        sigma=line_center*res*sigma_scale, 
        sigma_min=line_center*res*sigma_scale*sigma_factor_lo, 
        sigma_max=line_center*res*sigma_scale*sigma_factor_hi );

      add_line(line_id, fun_name, line_type; __qualifiers);

      if(qualifier_exists("fit"))
      {
         () = eval_counts;
         freeze("*");
         thaw("*"+line_id+"*");
         () = fit_counts;
      }
   }
}





