% -*- mode: slang; mode: fold -*-

private define filterFouQuantForFrequencyRange(fouquant, fmin, fmax) {
  %{{{
  variable idx = where(fmin <= fouquant.freq <= fmax);
  variable idxmin = min(idx);
  variable idxmax = max(idx);
  variable df = fouquant.freq[[idxmin+1:idxmax]] - fouquant.freq[[idxmin:idxmax-1]];
  
  if (length(idx) == 0) vmessage("ERROR (lag_energy_spectrum): No frequency bins between %g-%g in Fourier products!", fmin, fmax);
  if (qualifier("verbose", 0) > 1){
    vmessage("  ***(lag_energy_spectrum): Minimal frequency bin %d at %g Hz", idxmin, fouquant.freq[idxmin]);
    vmessage("  ***(lag_energy_spectrum): Maximal frequency bin %d at %g Hz", idxmax, fouquant.freq[idxmax]);
    vmessage("  ***(lag_energy_spectrum): Number of frequency bins: %d", length(idx));
  }
  variable ret = struct_filter(fouquant, idx; copy);
  return struct_combine(ret, struct{df = df, idxmin = idxmin, idxmax = idxmax, n_freqs = length(idx)});
} %}}}

private define verifyLightcurveTime(lc1, lc2){ 
  %{{{
  %% Test whether the time interval of reference and energy-resolved lightcurve is the same
  if (length(lc1.time)!=length(lc2.time) or (lc1.time[0]!=lc2.time[0]) or (lc1.time[-1]!=lc2.time[-1])){
    throw DataError, "ERROR: The time arrays of the reference and small band lightcurve seem to be different!";
  }
} %}}}

private define getLightcurve(lc, dt, dimseg){ 
  %{{{

  variable data = typeof(lc) == String_Type ? fits_read_table(lc) : lc;

  if (struct_field_exists(data, "time") * struct_field_exists(data, "rate") != 1) {
    throw UsageError, sprintf("ERROR (%s): %s does not have a time and rate column! Exiting...", _function_name(), lc);
  }
  
  return segment_lc_for_psd(data, dt, dimseg;; __qualifiers);
} %}}}

private define calculateSummedReferenceLightcurve(lc_list, index, dt, dimseg){ 
  %{{{
  % Calculate the reference lightcurve as sum of all
  % energy-resolved lightcurves but the current channel-of-interest.
  % This way there is no correlation of the Poisson noise between the
  % subject and reference bands (see also Uttley+14 Sect 3.2).

  %% todo: clean up this horrible if-else mess!
  
  variable channel_of_interest = typeof(lc_list[index]) == String_Type ? fits_read_table(lc_list[index]) : lc_list[index];

  variable jj, lc;
  variable summed_rate = Double_Type[length(channel_of_interest.rate)];
  
  if (qualifier_exists("elo") * qualifier_exists("ehi") * qualifier_exists("elo_ref") * qualifier_exists("ehi_ref") == 1) {
    %% If we have energy information about the ref LC we want to
    %% only subtract the COI in case it's within the ref LC borders.
    variable elo_ref = qualifier("elo_ref");
    variable ehi_ref = qualifier("ehi_ref");
    variable elo = qualifier("elo");
    variable ehi = qualifier("ehi");
    
    variable idx_lo = wherefirst(elo >= elo_ref);
    variable idx_hi = wherelast(ehi <= ehi_ref);

    _for jj (idx_lo, idx_hi, 1) {
      if ((elo[index] >= elo[jj]) and (ehi[index] <= ehi[jj])) {
	if (qualifier("verbose", 0) > 1) vmessage("  ***(%s): COI LC (index %d, %g-%g keV) is within Ref. LC (%g-%g keV). Not adding COI lightcurve to Ref. LC.",
						  _function_name(), index, elo[index], ehi[index], elo_ref, ehi_ref);
	continue;
      } else {
	lc = typeof(lc_list[jj]) == String_Type ? fits_read_table(lc_list[jj]) : lc_list[jj];
	verifyLightcurveTime(channel_of_interest, lc);
	if (qualifier("verbose", 0) > 1) vmessage("  ***(%s): Summing LC (index %d, %g-%g keV) to Ref. LC (%g-%g keV).",
						  _function_name(), jj, elo[jj], ehi[jj], elo_ref, ehi_ref);
	summed_rate += lc.rate;
      }
    }	     
  } else {
    %% If no energy information about the reference lightcurve is
    %% provided, we assume that it spans the full energy range.
    _for jj (0, length(lc_list)-1, 1){
      if (jj == index){
	if (qualifier("verbose", 0) > 1) vmessage("  ***(%s): Not adding COI LC (index %d) to Ref. LC, assuming that the Ref. LC goes over all energies.",
						  _function_name(), index);
	continue;
      } else {
	lc = typeof(lc_list[jj]) == String_Type ? fits_read_table(lc_list[jj]) : lc_list[jj];
	verifyLightcurveTime(channel_of_interest, lc);
	summed_rate += lc.rate;
      }
    }
  }
  
  return segment_lc_for_psd(struct{time = channel_of_interest.time, rate = summed_rate},
			    dt, dimseg;; __qualifiers);
} %}}}

private define write_cpd_to_ascii(realcpd, realcpd_err, imagcpd, imagcpd_err, fmin, fmax){
  %{{{
  % ASCII files of the cross-spectrum are needed for fitting with RELTRANS
  variable fptr_imag = fopen(sprintf("freq_cross_spec_imag_%f_%fHz.ascii", fmin, fmax), "w");
  variable fptr_real = fopen(sprintf("freq_cross_spec_real_%f_%fHz.ascii", fmin, fmax), "w");
  variable ii;
  _for ii (0, length(realcpd)-1, 1){
    () = fputs(sprintf("%i\t%f\t%f\n", ii+1, imagcpd[ii], imagcpd_err[ii]), fptr_imag);
    () = fputs(sprintf("%i\t%f\t%f\n", ii+1, realcpd[ii], realcpd_err[ii]), fptr_real);
  }
  () = fclose(fptr_imag);
  () = fclose(fptr_real);
} %}}}

private define verify_frequency_binning(dat){
  %{{{
  %% Check that the frequency binning of every energy-resolved
  %% lightcurve was the same for the individual frequency bins. If
  %% this is not the case this means that the energy-resolved
  %% lightcurves were extracted with different binning/time
  %% resolution.
  variable ii;
  variable N_energies = array_shape(dat.lag)[0];
  _for ii (1, N_energies-1, 1){
    if (_eqs(dat.n_segments[ii], dat.n_segments[0]) == 0 or
	_eqs(dat.n_frequencies[ii,*], dat.n_frequencies[0,*]) == 0 or
	_eqs(dat.f_min_dft[ii,*], dat.f_min_dft[0,*]) == 0 or
	_eqs(dat.f_max_dft[ii,*], dat.f_max_dft[0,*]) == 0){
      vmessage("WARNING (%s): The DFT binning of the energy-resolved lightcurves differs! Check the time resolutios of your individual lightcurves!",
	       _function_name());
    }
  }
} %}}}

private define write_to_outfile(dat, f_lo, f_hi, keywords, lc_list){
  %{{{
  variable fp = fits_open_file(qualifier("outfile"), "c");

  variable N_energies, N_les;
  (N_energies, N_les) = array_shape(dat.lag)[0], array_shape(dat.lag)[1];
  
  variable jj;
  _for jj (0, N_les-1, 1){
    % write_cpd_to_ascii(dat.mean_realcpds[*,jj], dat.mean_realcpd_errs[*,jj], 
    % 		     dat.mean_imagcpds[*,jj], dat.mean_imagcpd_errs[*,jj], 
    % 		     f_lo[jj], f_hi[jj]);  
    
    variable extname = sprintf("BAND_%f_%fHz", f_lo[jj], f_hi[jj]);
    variable sdata = struct{
      "ENERGY_LO"         = qualifier("elo", Double_Type[N_energies]),
      "ENERGY_HI"         = qualifier("ehi", Double_Type[N_energies]),
      "LAG"               = dat.lag[*,jj], 
      "LAG_ERR"           = dat.errlag[*,jj], 
      "MEAN_IMAG_CPD"     = dat.mean_imagcpds[*,jj],
      "MEAN_IMAG_CPD_ERR" = dat.mean_imagcpd_errs[*,jj],
      "MEAN_REAL_CPD"     = dat.mean_realcpds[*,jj],
      "MEAN_REAL_CPD_ERR" = dat.mean_realcpd_errs[*,jj],
      "MEAN_PHASE"        = dat.mean_phases[*,jj],
      "RMS"               = dat.rms[*,jj],
      "RMS_ERR"           = dat.rms_err[*,jj],
    };
    
    variable keys = struct_combine(struct{
      F_MIN = f_lo[jj], F_MAX=f_hi[jj], N_SEGS = dat.n_segments[0],
      N_FREQS = dat.n_frequencies[0,jj], FMIN_DFT = dat.f_min_dft[0,jj], 
      FMAX_DFT = dat.f_max_dft[0,jj]}, keywords);
    variable hist = struct{
      history = [sprintf("Wrote lag-energy spectrum in frequency range %f-%fHz", f_lo[jj], f_hi[jj])],
      comment = ["Time unit is seconds, energy unit is keV, frequency unit is Hertz", 
		 "Analyzed lightcurves:", lc_list]
    };
    
    fits_write_binary_table(fp, extname, sdata, keys, hist);
  }
  
  %% Write power spectrum and coherence into "COHERENCE" & "PSD" extension
  variable psd_colnames = String_Type[N_energies+1];
  variable cof_colnames = String_Type[2*N_energies+1];
  variable lag_colnames = String_Type[2*N_energies+1];
  (psd_colnames[0], cof_colnames[0], lag_colnames[0]) = "freq", "freq", "freq";

  variable ii;
  _for ii (0, N_energies-1, 1){
    psd_colnames[ii+1] = sprintf("psd%i", ii);
    cof_colnames[ii+1] = sprintf("cof%i", ii);
    cof_colnames[N_energies+ii+1] = sprintf("errcof%i", ii);
    lag_colnames[ii+1] = sprintf("lag%i", ii);
    lag_colnames[N_energies+ii+1] = sprintf("errlag%i", ii);
  }
    
  variable psd_data = @Struct_Type(psd_colnames);
  variable cof_data = @Struct_Type(cof_colnames);
  variable lag_data = @Struct_Type(lag_colnames);
  
  %% Frequency grids are all the same (because LCs have same binning)
  set_struct_field(psd_data, "freq", dat.freq[0]);
  set_struct_field(cof_data, "freq", dat.freq[0]);
  set_struct_field(lag_data, "freq", dat.freq[0]);
  
  _for ii (0, N_energies-1, 1){
    set_struct_field(psd_data, psd_colnames[ii+1], dat.psd[ii]);
    set_struct_field(cof_data, cof_colnames[ii+1], dat.cof[ii]);
    set_struct_field(cof_data, cof_colnames[N_energies+ii+1], dat.errcof[ii]);
    set_struct_field(lag_data, lag_colnames[ii+1], dat.freqres_lags[ii]);
    set_struct_field(lag_data, lag_colnames[N_energies+ii+1], dat.freqres_errlags[ii]);
  }
  
  fits_write_binary_table(fp, "PSD", psd_data, struct{"N_SEGS"=dat.n_segments[0]});
  fits_write_binary_table(fp, "COHERENCE", cof_data, struct{"N_SEGS"=dat.n_segments[0]});
  fits_write_binary_table(fp, "LAGS", lag_data, struct{"N_SEGS"=dat.n_segments[0]});
  
  fits_close_file(fp);
  () = system(sprintf("fthedit %s\[0] keyword=N_LES operation=add value=%i comment=\"Number of frequency-resolved lag-energy spectra\"",
		      qualifier("outfile"), N_les));
  vmessage("Wrote lag-energy spectrum data to %s", qualifier("outfile"));
} %}}}


define lag_energy_spectrum(lc_list, dimseg) {
%!%+
%\function{lag_energy_spectrum}
%\synopsis{Calculates the time lag of energy-resolved lightcurves}
%\usage{Struct_Type les = lag_energy_spectrum(String_Type[lcs], dimseg)}
%\description
%    * lc_list: Array of file names of the energy-resolved
%               lightcurves (must have same length and time binning)
%    * dimseg:  Segmentation length in bins, needed to segment the
%               lightcurve and do the Fourier calculation
%    
%    returns: lag-energy-spectrum as a struct with fields lag, errlag
%\qualifiers{
%    \qualifier{dt}{Time resolution of the lightcurve in seconds
%                [default: TIMEDEL keyword]}
%    \qualifier{deadtime}{Detector deadtime in seconds [default: 0.0s]}
%    \qualifier{f_lo}{Array_Type. For frequency-resolved lag-energy
%                spectra. Default: lowest sampled frequency [an array
%                containing only fmin=1/(dt*dimseg)]. Unit: Hz}
%    \qualifier{f_hi}{See f_lo. Default: Nyquist frequency [1/(2*dt)]. Unit: Hz}
%    \qualifier{verbose}{Increase verbosity [default=0]}
%    \qualifier{outfile}{String_Type. If set, write various timing products
%                into a FITS file.}
%    \qualifier{elo, ehi}{Double_Type: Energy grid}
%    \qualifier{elo_ref, ehi_ref}{Boundaries of reference lightcurve}
%}
%\notes
%    * The default error computation is Nowak et al., 1999, ApJ, 510,
%      874 (Sect. 4).
%    * All input lightcurves are accounted for their gaps and segmented
%      by segment_lc_for_psd. 
%    * The cross-spectrum (CPD) and lags are calculated with foucalc.
%    * The PSD normalization is fixed to Miyamoto.
%    * The average time lag in the frequency interval is calculated by
%      the normal mean on the imaginary and real part of the
%      cross-spectrum: 
%      atan2(mean(Imag(CPD)), mean(Real(CPD)))/(PI*(fmin+fmax))
%    * Reference lightcurve: For each energy bin, the function takes the
%      summed lightcurves of all but the current energy bands (always
%      excluding the lightcurve for the cross-spectrum).
%    * The function does *not* use any information about the energy
%      grid. This has to be created by yourself (and must be the same as
%      the lightcurves in lc_list)! The elo, ehi qualifiers are only
%      for the records in the output file
%    
%    If you want to add energy information to the output FITS file,
%    you can pass two Double_Type arrays (same length as lc_list) via
%    the elo, ehi qualifiers. The columns of the created extension,
%    called BAND_<f_lo>_<f_hi>Hz, are:
%  
%    ENERGY_LO           - Energy channel (keV), taken from elo qualifier
%    ENERGY_HI           - Energy channel (keV), taken from ehi qualifier
%    MEAN_PHASE          - Phase (radians), computed as atan2(mean(Im(CPD)), mean(Re(CPD)))
%    LAG                 - Time lag (s), computed as phase/(PI*(fmin+fmax))
%    LAG_ERR             - Error computed as in Nowak et al., 1999, ApJ, 510, 874 Eq. 16
%    LAG_ERR_PROPERR     - Error computed from Gaussian error propagation
%    MEAN_REAL/IMAG_CPD  - real/imaginary part of the mean of the
%                          segment-averaged cross-spectrum
%    MEAN_REAL/IMAG_CPD_ERR - standard error on the mean of the
%                          real/imaginary segment-averaged cross-spectrum 
%    RMS/RMS_ERR         - Root Mean Squared variability of the channel-of-interest 
%                          lightcurve. The error is calculated using
%                          Vaughan et al., MNRAS 345, 1271, 2003 Eq. 11.
%                          
%    Following keywords are written into each extension:
%    
%    N_SEGS              - Number of segments averaged over (foucalc.numavgall)
%    N_FREQS             - Number of frequencies averaged over (as in
%                          "mean of the CPD")
%    F_MIN/F_MAX         - Minimum and maximum frequency as given by
%                          f_lo, f_hi qualifiers
%    FMIN_DFT/FMAX_DFT   - Minimal/Maximal frequency of the frequency-filtered
%                          Fourier products - this can be different from
%                          F_MIN/F_MAX due to the discretization of the
%                          *Discrete* Fourier Transform
%                         
%    If you find any bugs or have questions, please contact ole.koenig@fau.de
%
%    The function also accepts all qualifiers of segment_lc_for_psd.
%
%\example
%    %% Example for frequency-resolved lag-energy spectrum
%    (f_lo, f_hi) = log_grid(1, 50, n_freqs);  % (Hz)
%    % Energy grid must be the same as extracted lightcurves
%    (elo, ehi) = log_grid(0.5, 10, n_energies);  % (keV)
%    variable les = lag_energy_spectrum(lc_names, dimseg
%                                       ; f_lo = f_lo, f_hi=f_hi,
%                                       verbose=2, outfile="test.fits", elo=elo, ehi=ehi);
%    _for ii (0, n_freqs-1, 1) {
%      ohplot_with_err(elo, ehi, les.lag[*,ii], les.errlag[*,ii]);   
%    }
%\seealso{segment_lc_for_psd, foucalc, colacal}
%!%-
  try {
    variable dt = qualifier_exists("dt") ? qualifier("dt") : fits_read_key(lc_list[0], "TIMEDEL");
  } catch TypeMismatchError:
  {
    return vmessage("ERROR (%s): Couldn't receive the time resolution from TIMEDEL, need dt qualifier!", _function_name());
  }
  
  variable f_lo = qualifier("f_lo", [1/(dt*dimseg)]);
  variable f_hi = qualifier("f_hi", [1/(2*dt)]);  % Nyquist frequency
  variable verbose = qualifier("verbose", 0);
  variable deadtime = qualifier("deadtime", 0.0);
  variable normtype = "Miyamoto";

  variable N_energies = length(lc_list);
  variable N_les = length(f_lo);

  variable dat = struct{
    %% Fields for frequency-averaged data
    lag               = Double_Type[N_energies, N_les],
    errlag            = Double_Type[N_energies, N_les],
    rms               = Double_Type[N_energies, N_les],
    rms_err           = Double_Type[N_energies, N_les],
    min_freqs         = Double_Type[N_energies, N_les],
    max_freqs         = Double_Type[N_energies, N_les],
    mean_realcpds     = Double_Type[N_energies, N_les],
    mean_realcpd_errs = Double_Type[N_energies, N_les],
    mean_imagcpds     = Double_Type[N_energies, N_les],
    mean_imagcpd_errs = Double_Type[N_energies, N_les],
    mean_phases       = Double_Type[N_energies, N_les],
    errlag_properr    = Double_Type[N_energies, N_les],
    f_min_dft         = Double_Type[N_energies, N_les],
    f_max_dft         = Double_Type[N_energies, N_les],
    n_frequencies     = Integer_Type[N_energies, N_les],

    %% Fields for frequency-resolved data
    n_segments        = Integer_Type[N_energies],
    freq              = Array_Type[N_energies],
    psd               = Array_Type[N_energies],
    cof               = Array_Type[N_energies],
    errcof            = Array_Type[N_energies],
    freqres_lags      = Array_Type[N_energies],
    freqres_errlags   = Array_Type[N_energies]
  };

  %% Loop through energy-resolved lightcurves (channel-of-interests)
  variable ii, jj;
  _for ii (0, N_energies-1, 1){
    
    if (verbose > 0) vmessage("  ***(%s): Calculate time lags for %s", _function_name(), lc_list[ii]);
    
    variable channel_of_interest = getLightcurve(lc_list[ii], dt, dimseg;; __qualifiers);

    variable lc_ref = calculateSummedReferenceLightcurve(lc_list, ii, dt, dimseg;; __qualifiers);     

    variable fouquant = foucalc(struct{time  = channel_of_interest.time,
                                       rate1 = lc_ref.rate,
                                       rate2 = channel_of_interest.rate},
				dimseg; normtype=normtype, deadtime=deadtime);

    variable numseg = fouquant.numavgall[0];
    
    dat.freq[ii] = fouquant.freq;
    dat.psd[ii] = fouquant.signormpsd2;
    dat.cof[ii] = fouquant.cof12;
    dat.errcof[ii] = fouquant.errcof12;
    dat.freqres_lags[ii] = fouquant.lag12;
    dat.freqres_errlags[ii] = fouquant.errlag12;
    dat.n_segments[ii] = numseg;

    %% Loop through frequency ranges
    _for jj (0, N_les-1, 1){
      if (verbose > 1) vmessage("  ***(%s): Calculating lag-energy spectrum in frequency range %g-%g Hz", 
				_function_name(), f_lo[jj], f_hi[jj]);

      variable fouquant_f = filterFouQuantForFrequencyRange(fouquant, f_lo[jj], f_hi[jj]; verbose=verbose);
      
      % RMS calculation (same as in foucalc but we want it for every
      % energy lightcurve and frequency range - running foucalc
      % everytime drastically increases the runtime due to the DFT, so
      % copy-paste the calculation here!)
      variable sigrms = sqrt( sum(fouquant.signormpsd2[[fouquant_f.idxmin:fouquant_f.idxmax-1]] * fouquant_f.df) );
      variable noirms = sqrt( sum(fouquant.noinormpsd2[[fouquant_f.idxmin:fouquant_f.idxmax-1]] * fouquant_f.df) );
      variable errrms = sqrt((4.*sigrms^2*noirms^2+2.*noirms^4)/(numseg*fouquant_f.n_freqs*sigrms^2));  % Vaughan+03 Eq. 11

      dat.rms[ii,jj] = sigrms;
      dat.rms_err[ii,jj] = errrms;
      
      %% Coherence and lag calculation on averaged cross-spectrum
      variable cola = colacal(0.5*(f_lo[jj]+f_hi[jj]),  % mid frequency
			      mean(fouquant_f.realcpd12)+mean(fouquant_f.imagcpd12)*1i,
			      mean(fouquant_f.noicpd12),
			      mean(fouquant_f.rawpsd1), mean(fouquant_f.rawpsd2), 
			      mean(fouquant_f.noipsd1), mean(fouquant_f.noipsd2),
			      mean(fouquant_f.sigpsd1), mean(fouquant_f.sigpsd2),
			      length(fouquant_f.freq)*numseg);  % K*M with M=number of frequencies averaged over and K=number of segments
      (dat.lag[ii,jj], dat.errlag[ii,jj]) = cola.lag, cola.errlag;
	  
      variable m_ReCPD = mean(fouquant_f.realcpd12);
      variable m_ReCPD_err = mean(fouquant_f.errrealcpd12);
      variable m_ImCPD = mean(fouquant_f.imagcpd12);
      variable m_ImCPD_err = mean(fouquant_f.errimagcpd12);
      
      %% Calculation from Gaussian error propagation
      variable m_phase = atan2(m_ImCPD, m_ReCPD);  % [radians]
      dat.errlag_properr[ii,jj]=1/(PI*(f_lo[jj]+f_hi[jj]))*
	sqrt((m_ReCPD/(m_ImCPD^2+m_ReCPD^2))^2*m_ImCPD_err^2 +
	     (m_ImCPD/(m_ImCPD^2+m_ReCPD^2))^2*m_ReCPD_err^2);
      
      dat.mean_realcpds[ii,jj]     = m_ReCPD;
      dat.mean_realcpd_errs[ii,jj] = m_ReCPD_err;
      dat.mean_imagcpds[ii,jj]     = m_ImCPD;
      dat.mean_imagcpd_errs[ii,jj] = m_ImCPD_err;
      dat.mean_phases[ii,jj]       = m_phase;
      dat.f_min_dft[ii,jj]         = min(fouquant_f.freq);
      dat.f_max_dft[ii,jj]         = max(fouquant_f.freq);
      dat.n_frequencies[ii,jj]     = length(fouquant_f.freq);
    }
  }

  verify_frequency_binning(dat);
  
  if (qualifier_exists("outfile")){
    variable keywords = struct{DIMSEG=dimseg, TIMEDEL=dt, NORMTYPE=normtype};
    write_to_outfile(dat, f_lo, f_hi, keywords, lc_list;; __qualifiers());
  }
  
  return dat;
}
