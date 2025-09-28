%%%%%%%%%%%%%%
define colacal(freq, cpd, noicpd, lopsd, hipsd, noilopsd, noihipsd, siglopsd, sighipsd, alln)
%%%%%%%%%%%%%%
%!%+
%\function{colacal}
%\synopsis{Timing Tools: Coherence and Lag Calculation}
%\usage{ Struct_Type cola = colacal ([10 required inputs]);}
%\description
%    Input:
%      freq     - Fourier Frequency Array
%      cpd      - CPD Array
%      noicpd   - Poisson Noise Contribution to CPD
%      lopsd    - Non-noise-corrected PSD (low channel)
%      hipsd    - Non-noise-corrected PSD (high channel)
%      noilopsd - Noise-Contribution to low PSD
%      noihipsd - Noise-Contribution to high PSD
%      siglopsd - Noise-corrected PSD (low channel)
%      sighipsd - Noise-corrected PSD (high channel)
%      alln     - number of averaged segments in each frequency bin
%    Output: Struct containing
%      rawcof   - non-noise-corrected coherence function [Vaughan & Nowak, 1997, ApJ, 474, L43 (Eqn. 2)]
%      cof      - noise-corrected coherence function [Vaughan & Nowak, 1997, ApJ, 474, L43 (Eqn. 8, Part 1)]
%      errcof   - one-sigma uncertainty of cof [Vaughan & Nowak, 1997, ApJ, 474, L43 (Eqn. 8, Part 2)]
%      lag      - time lag [Nowak et al., 1999, ApJ, 510, 874 (Sect. 4)]
%      errlag   - one-sigma uncertainty of lag [Nowak et al., 1999, ApJ, 510, 874 (Eqn. 16)]
%      sigcpd   - noise-corrected cross-power-density [sigcpd = cpd - noicpd]
%!%-
{
  variable sigcpd = sqr(abs(cpd)) - noicpd;
  variable cof = sigcpd / (siglopsd * sighipsd);
  variable rawcof = (sigcpd + noicpd) / (lopsd * hipsd);
  variable dcof = (1.-cof) / sqrt(abs(cof)) * sqrt(2./alln);
  variable errcof = sqrt(  sqr(dcof/cof) + 2.*sqr(noicpd/sigcpd)
			 + (sqr(noilopsd/siglopsd) + sqr(noihipsd/sighipsd))/alln
			);
  variable lag = atan2(Imag(cpd), Real(cpd)) / (2.*PI*freq);
  variable errlag = sqrt( (1.-rawcof)/(2.*rawcof)/alln ) / (2.*PI*freq);
  return struct{rawcof=rawcof, cof=cof, errcof=errcof,
                lag=lag, errlag=errlag, sigcpd=sigcpd};
}
