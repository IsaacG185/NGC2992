%%%%%%%%%%%%%%
define foucalc()
%%%%%%%%%%%%%%
%!%+
%\function{foucalc}
%\synopsis{calculates power-, cross power-, coherence- and timelag-spectra for timing analysis}
%\usage{Struct_Type foucalc(Struct_Type lc, Integer_Type dimseg)}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{normtype}{normalization type of PSD data, can be \code{"Miyamoto"} [default], \code{"Leahy"}, or \code{"Schlittgen"}}
%\qualifier{normindiv}{}
%\qualifier{avgbkg}{array of average background rates for each energy band}
%\qualifier{numinst}{[\code{=1}] number of activated PCUs on XTE, required for noise correction}
%\qualifier{deadtime}{[\code{=1e-5}] detector deadtime in seconds}
%\qualifier{nonparalyzable}{Set this qualifier if the deadtime is non-paralyzable}
%\qualifier{fmin}{minimum frequency used for RMS calculation}
%\qualifier{fmax}{maximum frequency used for RMS calculation}
%\qualifier{RMS}{DEPRECATED, use rms qualifier instead.}
%\qualifier{rms}{reference to a variable to store the signal, noise RMS and error
%           of each light curve in the [fmin, fmax] band. Can only be used with
%           normtype="Miyamoto". The error is calculated using Vaughan
%           et al., MNRAS 345, 1271, 2003 Eq. 11.}
%\qualifier{avgrate}{reference to a variable to store the average rate of each light curve}
%\qualifier{compact}{compact the output structure, only keep the most important quantities}
%\qualifier{noCPD}{do not calculate cross power densities and derived quantities}
%}
%\description
%    \code{lc} contains (properly segmented) light curves in several energy bands.
%    The best performance is achieved with a common structure of arrays,
%    \code{lc = struct { time=[t_1, t_2, ...], rate1=[r1_1, r1_2, ...], rate2=... };}.
%    [However, one can also use an array of structures (with an enormous overhead),
%    \code{lc = [ struct { time=t_1, rate1=r1_1, rate2=...}, struct { time=t_2, rate1=r1_2, rate2=... }, ... ];}.]
%    Also specifying "rate" instead of "rate1" is possible if no CPD
%    should be computed.
%
%    \code{dimseg} is the segment size used for the FFTs, which should therefore be a power of 2.
%
%    The returned structure contains the following fields:\n
%    - \code{freq}:
%        the frequency grid\n
%    - \code{numavgall}:
%        The bin \code{i} in all power spectra has been averaged over \code{numavgall[i]} original bins.
%        Here, \code{numavgall[i] = numseg}, as no frequency rebinning has been performed.\n
%    - Power spectra for each energy band:\n
%      * \code{rawpsd}, \code{errpsd = rawpsd/sqrt(numseg)}, \code{noipsd}:
%          the raw power spectrum (from \code{makepsd}),
%          its error from the average over segments,
%          and the noise level (from \code{psdcorr_zhang})\n
%      * \code{sigpsd = rawpsd - noipsd}:
%          the signal power spectrum\n
%      * \code{rawnormpsd}, \code{errnormpsd}, \code{noinormpsd}, \code{effnoinormpsd = noinormpsd / sqrt(numseg)}:
%          the normalized power spectrum,
%          its error, the noise level,
%          and the effective noise level in the normalized power spectrum\n
%      * \code{signormpsd = rawnormpsd - noinormpsd}:
%          the signal in the normalized power spectrum\n
%    - Cross power spectra, coherence and time lag functions for each pair of energy bands:\n
%      * \code{realcpd}, \code{imagcpd}:
%          real and imaginary part of the cross power density\n
%      * \code{errrealcpd}, \code{errimagcpd}:
%          standard error on the mean of the averaged cross power density\n
%      * \code{noicpd = ( sigpsd_lo * noipsd_hi + sigpsd_hi * noipsd_lo + noipsd_lo * noipsd_hi ) / numseg}\n
%      * \code{rawcof}, \code{cof}, \code{errcof}:
%          non-noise-corrected (raw) and noise-corrected coherence function and its one-sigma uncertainty\n
%      * \code{lag}, \code{errlag}:
%          time lag and its one-sigma uncertainty\n
%\seealso{makepsd, cross_power_density, colacal, psdcorr_zhang}
%!%-
{
  variable lc, dimseg;
  switch(_NARGS)
  { case 2: (lc, dimseg) = (); }
  { help(_function_name()); return; }

  variable verbose = qualifier_exists("verbose");

  % Lengths, times and channels
  variable t = array_struct_field(lc, "time");;
  variable bintime = t[1]-t[0];
  variable dimlc = length(t);
  variable numseg = int(dimlc/dimseg);
  variable tseg = bintime * dimseg;
  variable timelc = bintime * dimlc;
  variable str_fields = get_struct_field_names(lc[0]);  % lc[0]=lc, if lc is no array but struct
  variable numchan = length(str_fields[where(is_substr(str_fields, "rate"))]);  

  % Lightcurve parameters
  variable avgrate = Double_Type[numchan];
  variable rms_deprecated = Double_Type[numchan];  % used for deprecated RMS qualifier
  
  variable fieldnames = ["freq", "numavgall"];  % field names of output structure
  variable rms_fieldnames = String_Type[0];
  
  variable i, j;
  _for i (1, numchan, 1){
    fieldnames = [fieldnames, ["rawpsd", "errpsd", "normpsd", "errnormpsd", "noipsd", "sigpsd", "noinormpsd", "signormpsd", "effnoinormpsd"]+string(i)];
    rms_fieldnames = [rms_fieldnames, ["sigrms", "errrms", "noirms"]+string(i)];
  }
  
  _for i (1, numchan, 1)
    _for j (i+1, numchan, 1)
      fieldnames = [fieldnames, ["normrealcpd", "normimagcpd", "errnormrealcpd", "errnormimagcpd",
				 "realcpd", "imagcpd", "errrealcpd", "errimagcpd", "noicpd", 
				 "rawcof", "cof", "errcof", "lag", "errlag"]+string(i)+string(j)];  % assuming i < j < 100 ...
  variable fouquant = @Struct_Type(fieldnames);  % create structure
  variable rmsquant = @Struct_Type(rms_fieldnames);

  % Calculating Fourier Frequency Array
  fouquant.numavgall = ones(dimseg/2) * numseg;
  fouquant.freq = foufreq(t[[0:dimseg-1]]);
  if(verbose)
  {
    variable tgap = t[-1]-t[0] - (dimlc-1) * bintime;
    vmessage("  light curves: %g s with %d bins of %g s  (%g s gaps)", t[-1]-t[0], dimlc, bintime, tgap);
    if(tgap != 0.)
      message("POSSIBLE DETECTION OF GAPS IN THE LIGHTCURVE!\nIf the light curves contain gaps, one cannot rely on the Discrete Fourier Transformation.");
    vmessage("  segmentation: %d segments of %d bins", numseg, dimseg);
    vmessage("=> frequencies: %g-%g Hz.", fouquant.freq[0], fouquant.freq[-1]);
  }

  % Normalization Qualifiers
  variable normtype = qualifier("normtype", "Miyamoto");
  variable normindiv = qualifier_exists("normindiv");
  variable avgbkg = qualifier("avgbkg", Double_Type[numchan]);
  if(verbose)  vmessage("Power spectra will be calculated in %s-normalization.", normtype);
  
  if (not qualifier_exists("deadtime")){
    vmessage("warning (foucalc): Deadtime keyword not set. Using default for RXTE: 1e-05 s");
  }

  % RMS Qualifiers (see, e.g., Uttley et al., A&A Review 22, 72, 2014, Sect. 2.2.3)
  variable fmin = qualifier("fmin", min(fouquant.freq));
  variable fmax = qualifier("fmax", max(fouquant.freq));

  _for i (1, numchan, 1)
  {
    variable istr = string(i);
    if (verbose) ()=printf("Calculating power spectrum for rate%d.  ", i);

    % If "rate1" is not available in struct, use "rate"
    variable rate = struct_field_exists(lc, "rate"+istr) ? array_struct_field(lc, "rate"+istr) : array_struct_field(lc, "rate");
    avgrate[i-1] = mean(rate);

    % Calculating PSDs
    variable psd, nipsd;
    (psd, nipsd) = makepsd(rate, tseg, dimseg;; struct_combine(__qualifiers, struct { avgbkg=avgbkg[i-1] }));
    set_struct_field(fouquant, "rawpsd"+istr, psd);
    if(normindiv)
    { fouquant = struct_combine(fouquant, "normindivpsd"+istr);
      set_struct_field(fouquant, "normindivpsd"+istr, nipsd);
    }
    % No frequency rebinning at this point!

    % Calculating PSD errors! (errpsd)
    variable errpsd = psd/sqrt(numseg);
    set_struct_field(fouquant, "errpsd"+istr, errpsd);

    % Calculating normalized PSDs and their errors! (normpsd, errnormpsd)
    variable tempnormpsd, temperrnormpsd;
    if(normindiv)
    { tempnormpsd = nipsd;
      temperrnormpsd = tempnormpsd/sqrt(numseg);
    }
    else
    { tempnormpsd = normpsd(psd, normtype, avgrate[i-1], avgbkg[i-1], tseg, dimseg);
      temperrnormpsd = errpsd / psd[0] * tempnormpsd[0];
    }
    set_struct_field(fouquant, "normpsd"+istr, tempnormpsd);
    set_struct_field(fouquant, "errnormpsd"+istr, temperrnormpsd);
    temperrnormpsd = NULL;

    % Calculating observational noise with deadtime influence (noipsd, noinormpsd)
    variable noipsd, noinormpsd;
    (, noipsd, noinormpsd) = psdcorr_zhang(avgrate[i-1], tseg, dimseg;; struct_combine(__qualifiers(), struct { avgbkg=avgbkg[i-1] }));
    set_struct_field(fouquant, "noipsd"+istr, noipsd);
    set_struct_field(fouquant, "noinormpsd"+istr, noinormpsd);

    % effective noise level
    set_struct_field(fouquant, "effnoinormpsd"+istr, noinormpsd/sqrt(numseg));
    % calculate normalized signal psd
    variable signormpsd = tempnormpsd - noinormpsd;
    set_struct_field(fouquant, "signormpsd"+istr, signormpsd);

    if(normtype=="Miyamoto")
    {
      variable idx = where(fmin <= fouquant.freq <= fmax);
      variable idxmin = min(idx);
      variable idxmax = max(idx);
      variable df = fouquant.freq[[idxmin+1:idxmax]] - fouquant.freq[[idxmin:idxmax-1]];
      rms_deprecated[i-1] = sqrt( sum(signormpsd[[idxmin:idxmax-1]] * df) );
      
      variable sigrms = sqrt( sum(signormpsd[[idxmin:idxmax-1]] * df) );
      variable noirms = sqrt( sum(noinormpsd[[idxmin:idxmax-1]] * df) );
      variable errrms = sqrt((4.*sigrms^2*noirms^2+2.*noirms^4)/(numseg*length(idx)*sigrms^2));  % Vaughan+03 Eq. 11
      set_struct_field(rmsquant, "sigrms"+istr, sigrms);
      set_struct_field(rmsquant, "errrms"+istr, errrms);
      set_struct_field(rmsquant, "noirms"+istr, noirms);
      if(verbose)  vmessage("RMS(%g-%g Hz) = (%g +/- %g) %%", fmin, fmax, sigrms*100, errrms*100);
    }
    else
      if(verbose)  message("");  % to finish the earlier printf without "\n"

    % correct PSD for observational noise and deadtime
    set_struct_field(fouquant, "sigpsd"+istr, psd - noipsd);
    noipsd = NULL; noinormpsd = NULL; signormpsd = NULL;
  }

  if(qualifier_exists("noCPD"))
    vmessage("warning (%s): noCPD qualifier set => skipping calculation of cross power densities", _function_name());
  else
  {
  % CPD calculations
  variable lo, hi;
  _for lo (1, numchan-1, 1)
    _for hi (lo+1, numchan, 1)
    {
      variable lostr = string(lo);
      variable histr = string(hi);

      if (verbose) vmessage("Calculating cross power spectrum (=> coherence and timelags) for rate%d and rate%d.", lo, hi);

      variable cpd, errcpd;
      (cpd, errcpd) = cross_power_density(array_struct_field(lc, "rate"+lostr),
					  array_struct_field(lc, "rate"+histr),
					  numseg, dimseg);
      set_struct_field(fouquant, "realcpd"+lostr+histr, Real(cpd));
      set_struct_field(fouquant, "imagcpd"+lostr+histr, Imag(cpd));
      set_struct_field(fouquant, "errrealcpd"+lostr+histr, Real(errcpd));
      set_struct_field(fouquant, "errimagcpd"+lostr+histr, Imag(errcpd));

      variable tempnormcpd = normpsd(cpd, normtype, sqrt(avgrate[lo-1]*avgrate[hi-1]), sqrt(avgbkg[lo-1]*avgbkg[hi-1]), tseg, dimseg);
      variable temperrnormcpd = errcpd / cpd[0] * tempnormcpd[0];
      set_struct_field(fouquant, "normrealcpd"+lostr+histr, Real(tempnormcpd));
      set_struct_field(fouquant, "errnormrealcpd"+lostr+histr, Real(temperrnormcpd));
      set_struct_field(fouquant, "normimagcpd"+lostr+histr, Imag(tempnormcpd));
      set_struct_field(fouquant, "errnormimagcpd"+lostr+histr, Imag(temperrnormcpd));
      
      % use SIGPSD to calculate the cross power density noise
      variable sigpsd_lo = get_struct_field(fouquant, "sigpsd"+lostr);
      variable sigpsd_hi = get_struct_field(fouquant, "sigpsd"+histr);
      variable noipsd_lo = get_struct_field(fouquant, "noipsd"+lostr);
      variable noipsd_hi = get_struct_field(fouquant, "noipsd"+histr);
      variable noicpd = ( sigpsd_lo * noipsd_hi + sigpsd_hi * noipsd_lo + noipsd_lo * noipsd_hi ) / numseg;  % fouquant.numavgall;
      set_struct_field(fouquant, "noicpd"+lostr+histr, noicpd);

      variable psd_lo = get_struct_field(fouquant,"rawpsd"+lostr);
      variable psd_hi = get_struct_field(fouquant,"rawpsd"+histr);

      variable cola = colacal(fouquant.freq, cpd, noicpd, psd_lo, psd_hi, noipsd_lo, noipsd_hi, sigpsd_lo, sigpsd_hi, numseg);  % fouquant.numavgall
      set_struct_field(fouquant, "rawcof"+lostr+histr, cola.rawcof);
      set_struct_field(fouquant, "cof"   +lostr+histr, cola.cof);
      set_struct_field(fouquant, "errcof"+lostr+histr, cola.errcof);
      set_struct_field(fouquant, "lag"   +lostr+histr, cola.lag);
      set_struct_field(fouquant, "errlag"+lostr+histr, cola.errlag);
      cola= NULL;
      cpd = NULL; errcpd=NULL;
    }
  }

  variable rmsref = qualifier("rms");
  if(normtype=="Miyamoto" and rmsref!=NULL)
  {
    if(typeof(rmsref) == Ref_Type)
      (@rmsref) = rmsquant;
    else
      vmessage("warning (%s): rms qualifier has to be a reference", _function_name());
  }
  
  % Deprecated RMS qualifier (kept for backwards-compatibility)
  variable RMSref = qualifier("RMS");
  if(normtype=="Miyamoto" and RMSref!=NULL)
  {
    if(typeof(RMSref)==Ref_Type){
      vmessage("warning (%s): RMS qualifier is deprecated, please change to rms.", _function_name());
      (@RMSref) = rms_deprecated;
    } else {
      vmessage("warning (%s): RMS qualifier has to be a reference", _function_name());
    }
  }

  variable avgrateref = qualifier("avgrate");
  if(avgrateref!=NULL)
  {
    if(typeof(avgrateref)==Ref_Type)
      (@avgrateref) = avgrate;
    else
      vmessage("warning (%s): avgrate qualifier has to be a reference", _function_name());
  }

  if(qualifier_exists("compact"))
  {
    fieldnames = ["freq", "numavgall"];  % field names of output structure
    _for i (1, numchan, 1)
      fieldnames = [fieldnames, "signormpsd"+string(i)];
    _for i (1, numchan, 1)
      _for j (i+1, numchan, 1)
        fieldnames = [fieldnames, ["rawcof", "cof", "errcof", "lag", "errlag"]+string(i)+string(j)];
    variable compact_fouquant = @Struct_Type(fieldnames);  % create structure
    variable fieldname;
    foreach fieldname (fieldnames)
      set_struct_field(compact_fouquant, fieldname, get_struct_field(fouquant, fieldname));
    fouquant = compact_fouquant;
  }

  return fouquant;
}
