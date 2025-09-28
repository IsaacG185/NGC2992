private define cross_power_density(rate1, rate2, numseg, dimseg){
%!%+
%\function{cross_power_density}
%\synopsis{Timing Tools: Cross Power Density (aka. Cross-Spectrum)}
%\usage{(cpd, errcpd) = cross_power_density(rate1, rate2, numseg, dimseg)}
%\description
%    Calculates the CPD, averaged over all segments, as
%    Conj(DFT(rate1))*DFT(rate2)
%    using the dorDFT function. The return values are of Complex_Type.
%    The error is the standard error on the mean of the averaged CPD.
%\seealso{dorDFT}
%!%-
  variable startbin = 0;
  variable endbin = dimseg-1;
  
  variable cpd = Complex_Type[dimseg/2];  % = 0 + 0i
  variable cpds = Complex_Type[numseg, dimseg/2];  % Record of CPDs of all segments for error calculation

  variable seg=0;
  loop(numseg)
  {
    variable cpd_of_segment = Conj(dorDFT(rate1[[startbin:endbin]])) * dorDFT(rate2[[startbin:endbin]]);

    cpd += cpd_of_segment;
    startbin += dimseg;
    endbin += dimseg;

    % Divide by dimseg because dorDFT has normalization sqrt(N) and is
    % applied twice: once for DFT(rate1), once for DFT(rate2).
    cpds[seg,*] = cpd_of_segment / dimseg;
    seg++;
  }
  
  cpd /= (numseg * dimseg);  % Average over all segments
  
  % ====== Error calculation ========================================
  variable errcpd = Complex_Type[dimseg/2];
  variable freq;
  _for freq (0, dimseg/2-1, 1){
    errcpd[freq] = moment(Real(cpds[*,freq])).sdom + moment(Imag(cpds[*,freq])).sdom*1i;
  }

  return cpd, errcpd;
}
