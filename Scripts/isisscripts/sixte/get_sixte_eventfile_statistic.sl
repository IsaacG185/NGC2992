private define calc_pattern_fractions_of_grid(evt, lo, hi, field){
  variable grid = array_struct_field(evt, field);
  variable ret = struct{
    nsings = Double_Type[length(lo)],
    ndoubs = Double_Type[length(lo)],
    ntrips = Double_Type[length(lo)],
    nquads = Double_Type[length(lo)],
    nvalids = Double_Type[length(lo)],
    sfracs = Double_Type[length(lo)],
    dfracs = Double_Type[length(lo)],
    tfracs = Double_Type[length(lo)],
    qfracs = Double_Type[length(lo)],
    sfrac_errs = Double_Type[length(lo)],
    dfrac_errs = Double_Type[length(lo)],
    tfrac_errs = Double_Type[length(lo)],
    qfrac_errs = Double_Type[length(lo)]
  };

  variable ii;
  _for ii (0, length(lo)-1, 1){
    variable evt_filtered = struct_filter(evt, where(lo[ii] <= grid < hi[ii]) ; copy);
    % Note that currently the pile-up events and non-pileup events
    % are NOT distinguished for the energy/channel sorted patterns.
    ret.nsings[ii] = length(where(evt_filtered.type == 0));
    ret.ndoubs[ii] = length(where(evt_filtered.type == 1)) + length(where(evt_filtered.type == 2)) + length(where(evt_filtered.type == 3)) + length(where(evt_filtered.type == 4));
    ret.ntrips[ii] = length(where(evt_filtered.type == 5)) + length(where(evt_filtered.type == 6)) + length(where(evt_filtered.type == 7)) + length(where(evt_filtered.type == 8));
    ret.nquads[ii] = length(where(evt_filtered.type == 9)) + length(where(evt_filtered.type == 10)) + length(where(evt_filtered.type == 11)) + length(where(evt_filtered.type == 12));
    ret.nvalids[ii] = length(where(evt_filtered.type >= 0));
    
    if (ret.nsings[ii]>0) (ret.sfracs[ii], ret.sfrac_errs[ii]) = ratio_error_prop(1.*ret.nsings[ii], 1.*ret.nvalids[ii] ; Poisson);
    if (ret.ndoubs[ii]>0) (ret.dfracs[ii], ret.dfrac_errs[ii]) = ratio_error_prop(1.*ret.ndoubs[ii], 1.*ret.nvalids[ii] ; Poisson);
    if (ret.ntrips[ii]>0) (ret.tfracs[ii], ret.tfrac_errs[ii]) = ratio_error_prop(1.*ret.ntrips[ii], 1.*ret.nvalids[ii] ; Poisson);
    if (ret.nquads[ii]>0) (ret.qfracs[ii], ret.qfrac_errs[ii]) = ratio_error_prop(1.*ret.nquads[ii], 1.*ret.nvalids[ii] ; Poisson);
  }
  
  return ret;
}

%%%%%%%%%%%%%%%%%%%%%%%
define get_sixte_eventfile_statistic(){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_sixte_eventfile_statistic}
%\synopsis{Get the top-level information of a SIXTE event file}
%\usage{Struct_Type ret = get_sixte_eventfile_statistic(String_Type filename[, Double_Type flux]);}
%\description
%       This function returns the valid, invalid, fractional and
%       piled-up pattern numbers of the event file, together with the 
%       exposure and a possible flux entry (the argument is passed
%       directly into the struct). This information is based on the
%       event file keywords NVALID/NGRAD1 etc., written by SIXTE. 
%       
%       The pattern fraction errors are calculated assuming Poisson error.
%       Furthermore, it is possible to calculate (energy-)resolved
%       pattern fractions by giving the lo, hi, and field qualifiers.
%       Hereby, currently no distinction between non-piled up and
%       piled-up patterns is made (nvalids = TYPE>=0).
%       
%       If the given event file is an already loaded FITS file
%       (Struct_Type), the reading of the relevant header keywords is
%       skipped and only the energy/channel resolved patterns are
%       returned (requires lo, hi, and field qualifiers).
%\qualifiers{
%\qualifier{lo}{low grid for calculation of pattern fractions (in
%      unit of fields}
%\qualifier{hi}{high grid}
%\qualifier{field}{Name of event file column for filtering (for
%      example "signal" or "pha")}
%\qualifier{nphot}{Adds an additional struct field with number of
%      photons in the SIXTE event file}
%}
%\seealso{ratio_error_prop}
%!%-
  variable file, flux;
  switch(_NARGS)
  { case 2: (file, flux) = (); }
  { case 1: (file) = (); }
  { return help(_function_name()); }

  if (typeof(file) == Struct_Type){
    return calc_pattern_fractions_of_grid(file, qualifier("lo"), qualifier("hi"), qualifier("field"));
  }
  
  variable sr = fits_read_key_struct(file+"[1]", %{{{
				     "EXPOSURE",
				     "NVALID",
				     "NPVALID",
				     "NINVALID",
				     "NPINVALI",
				     "NGRAD0",
				     "NPGRA0",
				     "NGRAD1",
				     "NPGRA1",
				     "NGRAD2",
				     "NPGRA2",
				     "NGRAD3",
				     "NPGRA3",
				     "NGRAD4",
				     "NPGRA4",
				     "NGRAD5",
				     "NPGRA5",
				     "NGRAD6",
				     "NPGRA6",
				     "NGRAD7",
				     "NPGRA7",
				     "NGRAD8",
				     "NPGRA8",
				     "NGRAD9",
				     "NPGRA9",
				     "NGRAD10",
				     "NPGRA10",
				     "NGRAD11",
				     "NPGRA11",
				     "NGRAD12", 
				     "NPGRA12"
				    ); %}}}

  variable ret = struct {
    flux           = flux,
    exposure       = sr.exposure,
    nvalid         = sr.nvalid,
    nvalid_piled   = sr.npvalid,
    ninvalid       = sr.ninvalid,
    ninvalid_piled = sr.npinvali,
    nsing          = sr.ngrad0,
    nsing_piled    = sr.npgra0,
    ndoub          = sr.ngrad1+sr.ngrad2+sr.ngrad3+sr.ngrad4,
    ndoub_piled    = sr.npgra1+sr.npgra2+sr.npgra3+sr.npgra4,
    ntrip          = sr.ngrad5+sr.ngrad6+sr.ngrad7+sr.ngrad8,
    ntrip_piled    = sr.npgra5+sr.npgra6+sr.npgra7+sr.npgra8,
    nquad          = sr.ngrad9+sr.ngrad10+sr.ngrad11+sr.ngrad12,
    nquad_piled    = sr.npgra9+sr.npgra10+sr.npgra11+sr.npgra12,
    sfrac, sfrac_err, dfrac, dfrac_err, tfrac, tfrac_err, qfrac, qfrac_err
  };

  if (qualifier_exists("nphot")){
    ret = struct_combine(ret, struct{npho_sim=max(fits_read_table(file+"[1]").ph_id)});      
  }
  
  if (qualifier_exists("lo") and qualifier_exists("hi") and qualifier_exists("field")){
    % Calculate pattern fractions on a given (energy or channel) grid
    variable evt = fits_read_table(file);
    variable patfrac_ret = calc_pattern_fractions_of_grid(evt, qualifier("lo"), 
							  qualifier("hi"), qualifier("field"));
    ret = struct_combine(ret, patfrac_ret);
  }
  
  (ret.sfrac, ret.sfrac_err) = ratio_error_prop(1.*ret.nsing, 1.*ret.nvalid ; Poisson);
  (ret.dfrac, ret.dfrac_err) = ratio_error_prop(1.*ret.ndoub, 1.*ret.nvalid ; Poisson);
  (ret.tfrac, ret.tfrac_err) = ratio_error_prop(1.*ret.ntrip, 1.*ret.nvalid ; Poisson);
  (ret.qfrac, ret.qfrac_err) = ratio_error_prop(1.*ret.nquad, 1.*ret.nvalid ; Poisson);

  return ret;
}
