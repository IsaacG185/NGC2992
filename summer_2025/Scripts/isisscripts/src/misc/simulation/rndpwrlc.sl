define rndpwrlc()
%!%+
%\function{rndpwrlc}
%\synopsis{simulates a light curve with a power law distributed power spectrum}
%\usage{(t, rate) = rndpwrlc(Integer_Type nt);}
%\qualifiers{
%\qualifier{beta}{[=1.5] power law index of the power spectrum}
%\qualifier{mean}{[=0] mean rate of the simulated light curve}
%\qualifier{sigma}{[=1] standard deviation of the simulated light curve}
%\qualifier{dt}{[=1] time resolution of the simulated light curve}
%}
%\description
%    \code{nt} is the number of bins of the simulated lightcurve.
%    It should be a power of two best performance of the fast Fourier transform.
%    See also Timmer & Koenig (1995): "On generating power law noise",
%    A&A 300, 707-710
%!%-
{
  variable nt;
  switch(_NARGS)
  { case 1: nt = (); }
  { help(_function_name()); return; }

  variable nt_2 = int(nt/2);
  if(2*nt_2 != nt)
  { vmessage("error (%s): nt must be even", _function_name()); return; }

  variable dt = qualifier("dt", 1);  % time resolution of the lc

  return dt*[0:int(nt)-1], powerlaw_noise(nt;; __qualifiers());
}
