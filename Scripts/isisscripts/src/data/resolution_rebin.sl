%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Marco Fink
% Mail: marco.fink@fau.de


%%%%%%%%%%%%%%%%%%%%%%%%
define energy_resolution(E_keV, instrument){
%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function that returns Spectral resolution in keV at a given
% point in keV. Second argument is a string specifying the instrument.

    variable dE_eV = 0;

    switch(instrument)
    % approximate Energy resolution for NuStar FPM,
    % linear interpolation of values given on:
    % https://heasarc.gsfc.nasa.gov/docs/nustar/nustar_tech_desc.html
      {case "fpm": dE_eV = 8.6*E_keV + 310; }

    % approximate Energy resolution for XMM-Newton, assuming:
    % linear interpolation of values given on:
    % https://xmm-tools.cosmos.esa.int/external/xmm_user_support/documentation/uhb/epic_specres.html
      {case "epn": dE_eV = 8.9*E_keV + 91; }

    % approximate Energy resolution for Suzaku XIS, 
    % linear interpolation of values given on:
    % http://space.mit.edu/XIS/about/  
      {case "xis": dE_eV = 13.3*E_keV + 47; }
      { return -1; }

    % catch negative cases and convert to keV
    if(dE_eV <= 0){
      dE_eV = 0.1;
    }

    return 0.001*dE_eV;
}


%%%%%%%%%%%%%%%%%%%%%%%%
define resolution_rebin(id, instrument) {
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{resolution_rebin}
%\synopsis{Rebin spectra based on approximated detector resolution.}
%\usage{Array_Type resolution_rebin(dataset_id, instrument; oversampling, min_counts);}
%\qualifiers{
%\qualifier{sampling}{Float_Type, oversampling factor of detector resolution/bin width, default: 3}
%\qualifier{min_sn}{Float_Type, minimum signal-to-noise ratio, default: 5}
%}
%\description
%    This function rebins a dataset to fulfill the following two criteria:\n
%    1: Each bin contains enough counts so that - assuming Poissonian noise -
%       Signal-to-Noise is larger than the given minimum.\n
%    2: If criterion 1 is fulfilled, the bin size is chosen as a fraction of the 
%       detector resolution, an oversampling of 3 is recommended (Kaastra 2016).\n
%
%    Required arguments are the dataset ID and a string that specifies the used 
%    instrument. Supported are:\n
%      XMM EPICpn: "epn"\n
%      Suzaku XIS: "xis"\n
%      NuSTAR FPM: "fpm"\n
%
%\examples
%     Load and plot EPICpn data with a histogram oversampling detector resolution by 5:\n
%     variable EPN_data = load_data("src_s.pha");\n
%     resolution_rebin(EPN_data,"epn"; sampling = 5);\n
%     plot_data(EPN_data; dsym=0);\n
%
%\seealso{rebin_data, group}
%!%-

  % check for detector support
  if(energy_resolution(0, instrument) == -1){
    vmessage("Detector not supported");
    return [0];
  }

  variable sampling = qualifier("sampling", 3);
  variable signal_noise = qualifier("min_sn", 5);
  
  rebin_data(id,0);

  % assuming Poissonian distribution for signal-to-noise
  variable min_counts = signal_noise^2;
  variable data = get_data(id);

  variable E_min = _A(data).bin_lo[0];
  variable E_max = _A(data).bin_hi[-1];
  
  % calculate the rebin grid from the energy resolution
  variable res_bin_lo = [E_min]; 
  variable next_bin = 0;
    
  while(res_bin_lo[-1] < E_max){
    next_bin = res_bin_lo[-1] + (1.0/sampling)*energy_resolution(res_bin_lo[-1], instrument);
    res_bin_lo = array_insert(res_bin_lo, next_bin, length(res_bin_lo));
  };
  
  % go to Angstrom space
  res_bin_lo = _A(res_bin_lo);
  
  variable index_array = Integer_Type[length(data.bin_lo)];
  variable i;
  variable flag = 1;
  variable j = 0;
  variable counts = 0;

  % fill the index array for later use by rebin_data
  for(i=0; i < length(index_array)-1; i++){
    if(data.bin_lo[i] > res_bin_lo[j]){
      if(counts >= min_counts){
	counts = 0;
	flag *= -1;
      }
      j += 1;
    }else{
      counts += data.value[i];
    }
    
    index_array[i] = flag;
  };
  
  rebin_data(id, index_array);
  return index_array;
}
