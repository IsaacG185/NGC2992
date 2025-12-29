private define dorDFT(rate)
%!%+
%\function{dorDFT}
%\synopsis{Timing Tools: Discrete Fourier Transform}
%\usage{dft = dorDFT(rate);}
%\description
%    Performs a Fast Fourier Transform on a given rate array with the
%    same properties as IDL FFT:
%    * Normalization = sqrt(length(rate))
%    * renormalize rate around 0 by subtracting mean such that
%      variability is calculated wrt. mean rate
%    * return only meaningful bins for PSD calculations, i.e. first
%      bin up to Nyquist frequency
%!%-
{
  variable l = length(rate);
  return fft(rate-mean(rate), 1)[[1:l/2]]*l; %%% IDL Correction Factor;
}
