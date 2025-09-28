%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_simple_gpile_info()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_simple_gpile_info}
%\synopsis{retrieves pileup information within a simple_gpile2 model}
%\usage{Struct_Type info = get_simple_gpile_info(Integer_Type id);}
%!%-
{
  variable id;
  switch(_NARGS)
  { case 1: id = (); }
  { help(_function_name()); return; }

  variable info = struct { bin_lo, bin_hi, flux, arf, countrate, arf2, countrate2, arf3, countrate3, pileup, index_max_pileup };
  info.bin_lo = get_data_counts(id).bin_lo;
  info.bin_hi = get_data_counts(id).bin_hi;
  variable piled_fit_fun = get_fit_fun();
  fit_fun( get_unpiled_fit_fun() );
  info.flux = eval_fun(info.bin_lo, info.bin_hi);
  fit_fun( piled_fit_fun );

  variable model = "simple_gpile2("+string(id)+").";
  variable beta = get_par(model+"beta");
  variable indx = typecast(get_par(model+"data_indx"), Integer_Type);
  if(indx == 0 or beta == 0.)  return info;

  variable arf_indx = get_data_info(indx).arfs[0];
  variable arf = get_arf( arf_indx );
  variable fracexpo = get_arf_info(arf_indx[0]).fracexpo;
  if(length(fracexpo)>1)  fracexpo[where(fracexpo==0)] = 1.;  else  { if(fracexpo==0)  fracexpo = 1.; }

  info.arf = rebin(info.bin_lo, info.bin_hi, arf.bin_lo, arf.bin_hi, arf.value/fracexpo * (arf.bin_hi-arf.bin_lo) ) / (info.bin_hi-info.bin_lo);
  info.countrate = info.flux * info.arf / (info.bin_hi-info.bin_lo);

  variable mod_ord;
  variable arf2_indx = typecast(get_par(model+"arf2_indx"), Integer_Type);
  if(arf2_indx > 0)
  {
    arf = get_arf(arf2_indx);
    fracexpo = get_arf_info(arf2_indx).fracexpo;
    if(length(fracexpo)>1) { fracexpo[where(fracexpo==0)] = 1.; } else { if(fracexpo==0) { fracexpo = 1.; } }
    info.arf2 = rebin(info.bin_lo, info.bin_hi, 2*arf.bin_lo, 2*arf.bin_hi, arf.value/fracexpo * (arf.bin_hi-arf.bin_lo) ) / (info.bin_hi-info.bin_lo);
    info.countrate2 = rebin(info.bin_lo, info.bin_hi, 2*arf.bin_lo, 2*arf.bin_hi, arf.value/fracexpo * rebin(arf.bin_lo, arf.bin_hi, info.bin_lo, info.bin_hi, info.flux) )/(info.bin_hi-info.bin_lo);
  }
  else
    info.countrate2 = 0*info.countrate;

  variable arf3_indx = typecast(get_par(model+"arf3_indx"), Integer_Type);
  if(arf3_indx > 0)
  {
    arf = get_arf(arf3_indx);
    fracexpo = get_arf_info(arf3_indx).fracexpo;
    if(length(fracexpo)>1) { fracexpo[where(fracexpo==0)] = 1.; } else { if(fracexpo==0) { fracexpo = 1.; } }
    info.arf3 = rebin(info.bin_lo, info.bin_hi, 3*arf.bin_lo, 3*arf.bin_hi, arf.value/fracexpo * (arf.bin_hi-arf.bin_lo) ) / (info.bin_hi-info.bin_lo);
    info.countrate3 = rebin(info.bin_lo, info.bin_hi, 3*arf.bin_lo, 3*arf.bin_hi, arf.value/fracexpo * rebin(arf.bin_lo, arf.bin_hi, info.bin_lo, info.bin_hi, info.flux) )/(info.bin_hi-info.bin_lo);
  }
  else
    info.countrate3 = 0*info.countrate;

  info.pileup = 1 - exp(-beta*(info.countrate+info.countrate2+info.countrate3));

  info.index_max_pileup = where(info.pileup == min(info.pileup))[0];

  return info;
}
