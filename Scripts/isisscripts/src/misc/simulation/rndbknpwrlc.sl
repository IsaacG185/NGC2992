define rndbknpwrlc()
%!%+
%\function{rndbknpwrlc}
%\synopsis{simulates a light curve with a broken power law distributed power spectrum}
%\usage{(t, rate) = rndbknpwrlc(Integer_Type nt);}
%\qualifiers{
%\qualifier{beta1}{[=1.5]: first power law index of the power spectrum}
%\qualifier{beta1}{[=1.0]: second power law index of the power spectrum}
%\qualifier{perc}{[]}
%\qualifier{mean}{[=0]: mean rate of the simulated light curve}
%\qualifier{sigma}{[=1]: standard deviation of the simulated light curve}
%\qualifier{dt}{[=1]: time resolution of the simulated light curve}
%}
%\description
%    \code{nt} is the number of bins of the simulated lightcurve.
%    It should be a power of two best performance of the fast Fourier transform.
%!%-
{
  variable nt;
  switch(_NARGS)
  { case 1: nt = (); }
  { help(_function_name()); return; }

  % nt must be even and should also be a power of 2 for calculation speed reasons
  if(nt mod 2 != 0)
  { vmessage("error (%s): nt must be even", _function_name()); return; }

  variable betaph1 = qualifier("beta1", 1.5); % power law index of periodogram
  variable betaph2 = qualifier("beta2", 1.0); % power law index of periodogram
  variable perc = qualifier("perc", 0.8); % Percent of PSD after which break occurs
  variable mean = qualifier("mean", 0); %  Mean count rate of the simulated lightcurve
  variable sigma = qualifier("sigma", 1); % Standard deviation of the lightcurve to be simulated
  variable dt = qualifier("dt", 1); %  Time resolution of the lc

  variable minin = min((([0:(nt/2.)*perc]+1.)/(dt*nt))^(-(betaph1/2.)) );
  variable maxin = max((([0:(nt/2.)*(1.-perc)]+floor(nt/2.*perc)+2.)/(dt*nt))^(-(betaph2/2.)));

  %calculating powerlaw distributed periodogram
  variable   fac = [(([0:(nt/2.)*perc]+1.)/(dt*nt))^(-(betaph1/2.)),
		    ((([0:(nt/2.)*(1.-perc)]+floor(nt/2.*perc)+2.)/(dt*nt))^(-(betaph2/2.)))/maxin*minin ]; % 1/T,...,1/dt
  variable pos_real = grand(nt/2)*fac;
  variable pos_imag = grand(nt/2)*fac;
  pos_imag[nt/2-1] = 0;
  variable neg_real = pos_real[[0:nt/2-2]];
  variable neg_imag = -(pos_imag[[0:nt/2-2]]);
  variable real = [0., pos_real, reverse(neg_real)];
  variable imag = [0., pos_imag, reverse(neg_imag)];

  % simulate lc from its Fourier transform
  variable rate = Real(fft((real+(imag)*1i),1));

  % normalize to desired mean count rate and variance
  variable m = moment(rate);
  variable t = dt*[0:nt-1];
  rate = mean + (rate-m.ave)/m.sdev*sigma;

  return (t, rate);
}
