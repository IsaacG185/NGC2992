define powerlaw_noise()
%!%+
%\function{powerlaw_noise}
%\synopsis{simulates a light curve with a power law distributed power spectrum}
%\usage{Double_Type rate[] = powerlaw_noise(Integer_Type n);}
%\qualifiers{
%\qualifier{beta}{[= 1.5]: power law index of the power spectrum}
%\qualifier{mean}{[= 0]: mean rate of the simulated light curve}
%\qualifier{sigma}{[= 1]: standard deviation of the simulated light curve}
%}
%\description
%    \code{n} is the number of bins of the simulated lightcurve.
%    It should be a power of two best performance of the fast Fourier transform.
%\seealso{Timmer & Koenig (1995): "On generating power law noise", A&A 300, 707-710}
%!%-
{
  variable n;
  switch(_NARGS)
  { case 1: n = (); }
  { help(_function_name()); return; }

  variable n_2 = int(n/2);
  if(2*n_2 != n)
  { vmessage("error (%s): nt must be even", _function_name()); return; }

  variable betaph = qualifier("beta", 1.5);  % power law index of periodogram
  variable mean   = qualifier("mean",   0);  % mean count rate of the simulated lightcurve
  variable sigma  = qualifier("sigma",  1);  % standard deviation of the lightcurve to be simulated

  % calculating powerlaw distributed periodogram
  variable fac = (1.*[1:n_2]/n)^(-betaph/2.);  % 1/T, ..., 1/dt
  variable pos_real = grand(n_2)*fac;
  variable pos_imag = grand(n_2)*fac;
  pos_imag[n_2-1] = 0;
  variable real = [ 0., pos_real,  pos_real[[n_2-2:0:-1]] ];
  variable imag = [ 0., pos_imag, -pos_imag[[n_2-2:0:-1]] ];

  % simulate lc from its Fourier transform
  variable rate = Real(fft(real + imag*1i, 1));

  % normalize to desired mean count rate and variance
  variable m = moment(rate);
  return mean + (rate-m.ave)/m.sdev * sigma;
}
