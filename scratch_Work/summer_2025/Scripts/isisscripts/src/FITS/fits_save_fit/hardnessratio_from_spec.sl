%%%%%%%%%%%%%%%%%%%%%
define hardnessratio_from_spec()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{hardnessratio_from_spec}
%\synopsis{calculates hardness ratio from given spectrum}
%\usage{Struct_Type H = hardnessratio_from_spec(String_Type fits, freeze_model_comp)}
%\description
%    Calculates hardness ratio from a given spectrum using the model 'enflux'.
%    First argument is a fits file with data and model (from fits_save_fit).
%    Second argument is the model component of the continuum that has to be frozen (see enflux).
%    It first determines the soft and hard energy flux densities of two variable energy bands
%    and then derives the hardness ratio plus error.
%    For the hardness ratio two different definitions can be chosen (either h/s or
%    (h-s)/(h+s)).
%\qualifiers{
%\qualifier{hard_band}{Double_Type[2], hard energy band, default = [7.,10.]}
%\qualifier{soft_band}{Double_Type[2], soft energy band, default = [2.,4.]}
%\qualifier{hr_def}{Integer_Type, for hr=h/s choose 1, for hr=(h-s)/(h+s) choose 2, default = 1}
%\qualifier{roc}{Integer_Type, RMF OGIP compliance, default = 2}
%}
%\seealso{hardnessratio_error_prop,enflux,fits_save_fit}
%!%-
{
  variable fits,freeze_model_comp;
  switch(_NARGS)
  { case 2: (fits,freeze_model_comp) = (); }
  { help(_function_name()); return; }


  variable hard = qualifier("hard_band",[7.,10]);
  variable soft = qualifier("soft_band",[2.,4.]);
  variable roc = qualifier("roc",2);

  variable hr_def = qualifier("hr_def",1);

  ()=fits_load_fit(fits;ROC=roc);
  variable fun = get_fit_fun;
  fit_fun(sprintf("enflux(1,%s)",fun));
  set_par(freeze_model_comp,get_par(freeze_model_comp),1,0,1); % freeze continuum norm
  set_par("enflux(1).enflux",get_par("enflux(1).enflux"),0,0,1); % constrain enflux

  % hard energy range
  set_par("enflux(1).E_min",hard[0],1,0,100);
  set_par("enflux(1).E_max",hard[1],1,0,100);
  ()=fit_counts;
  variable h=fit_pars([get_par_info("enflux(1).enflux").index[0]]);

  % soft energy range
  set_par("enflux(1).E_min",soft[0],1,0,100);
  set_par("enflux(1).E_max",soft[1],1,0,100);
  ()=fit_counts;
  variable s=fit_pars([get_par_info("enflux(1).enflux").index[0]]);

  variable s_err = s.conf_max[0]-s.conf_min[0];
  variable h_err = h.conf_max[0]-h.conf_min[0];

  variable hr, err;
  (hr, err) = (hr_def==1)
            ? (h.value[0]/s.value[0], sqrt((1/s.value[0])^2*h_err^2+(h.value[0]/(s.value[0]^2))*s_err^2))
            : hardnessratio_error_prop(h.value[0],h_err,s.value[0],s_err);

  return struct{soft_flux=s.value[0],soft_flux_confmin=s.conf_min[0],soft_flux_confmax=s.conf_max[0],
    hard_flux=h.value[0],hard_flux_confmin=h.conf_min[0],hard_flux_conf_max=h.conf_max[0],hr=hr,hr_err=err};
}
