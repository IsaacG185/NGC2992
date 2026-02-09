private define zhangfunction(acofidx, sumidx, deadtime, mincrate, bintime)
{
  variable tau = 1. / mincrate ;
  variable t = acofidx * bintime - sumidx * deadtime ;
  variable x = t / tau ;
  if(t >= 0.)
  {
    variable nsumidx = int(sumidx);
    variable g = 0.;
    variable i;
    _for i (0, nsumidx, 1)
      g += (double(nsumidx - i)/factorial(i)) * x^i;
    return (acofidx) - (sumidx * (deadtime + tau) / bintime) + ((tau * exp(-x) * g) / bintime);
  }
  return 0.;
}

%%%%%%%%%%%%%%%%%%%%
define psdcorr_zhang(totrate, tseg, dimseg)
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{psdcorr_zhang}
%\synopsis{Timing Tools: Poisson Noise and Deadtime Correction (Zhang)}
%\usage{(freq, psd) = psdcorr_zhang(totrate, tseg, dimseg);}
%\qualifiers{
%\qualifier{nonparalyzable}{Set this qualifier if the deadtime is non-paralyzable}
%}
%\description
%    The deadtime is assumed to be paralyzable by default.
%    
%    Inputs:
%      totrate - total countrate of all instruments
%      tseg    - realtime length of the lc segments used for psd calculation
%      dimseg  - bincount of the lc segments used for psd calculation
%
%    Outputs:
%      freq    - fourier frequency array
%      noipsd  - array of observational noise of the psd
%\seealso{Zhang et al. (1995), ApJ, 449, 930}
%!%-
{
  variable detrate = NULL;
  variable bintime = tseg / dimseg;
  variable timearray = [1:dimseg] * bintime;

  variable numinst = qualifier("numinst", 1.);
  variable deadtime = qualifier("deadtime", 1e-5);

  %%better not get avgrate values from the qualifier - the qualifier
  %%from fourcalc will be used, which is a reference and the whole thing
  %%will break down
  %variable avgrate = qualifier("avgrate", totrate);
  variable avgrate = @totrate;
  
  variable incrate = qualifier("incrate", NULL);
  variable normtype = qualifier("normtype", "Miyamoto");
  variable avgbkg = qualifier("avgbkg", 0.);

  if(incrate==NULL)
    detrate = totrate/numinst;
  else
    incrate = totrate/numinst;

  variable freq = foufreq(timearray);
  variable om = 2. * PI * bintime * freq;
  variable zhangpsd = Double_Type[dimseg/2];
  variable i, j;

  if(qualifier_exists("nonparalyzable"))
  {
    if(incrate!=NULL)
      detrate = incrate / (1. + incrate * deadtime);
    else
      incrate = detrate / (1. - detrate * deadtime);

    variable dim = int((dimseg * bintime / deadtime ) + 2.);
    variable h = Double_Type[dimseg+1, dim+1];
    _for i (0, dimseg, 1)
      _for j (1, dim, 1)
	h[i,j] = zhangfunction(double(i), double(j), deadtime, incrate, bintime);

    variable a = Double_Type[dimseg];
    variable sumdim = int(bintime/deadtime + 1.);
    a[0] = detrate * bintime * (1. + 2.*sum(h[1, [1:sumdim+1]]));
    _for i (1, dimseg-1, 1)
    {
      sumdim = int( (double(i) + 1.) * bintime / deadtime + 1.);
      a[i] = detrate * bintime * sum( h[i+1,[1:sumdim+1]] - 2.*h[i,[1:sumdim+1]] + h[i-1,[1:sumdim+1]] );
    }

    variable b = 4. * (a - detrate * detrate * bintime * bintime) / (detrate * bintime);
    b[0] = b[0] / 2.;

    _for i (1, dimseg-1, 1)
      zhangpsd += (double(dimseg-i) / double(dimseg)) * b[i] * cos(om*double(i));
    zhangpsd += b[0];
  }
  else
  {
    if(incrate!=NULL)
      detrate = incrate * exp(-incrate*deadtime);
    else
      incrate = detrate / (1. - detrate * deadtime);

    if(bintime >= deadtime)
      zhangpsd = 2. * (  1.
		       - 2. * detrate * deadtime * (1. - deadtime/(2.*bintime))
		       - ( (dimseg - 1.) / dimseg) * detrate * deadtime * (deadtime / bintime) * cos(om));
    else
    { variable m = 1.*int(deadtime/bintime);
      zhangpsd = 2. - 2 * detrate * bintime * (  1.
                                               - (dimseg-m)/dimseg * (m+1.-deadtime/bintime)^2 * cos(m*om)
                                               + (dimseg-m-1.)/dimseg *  (m-deadtime/bintime)^2 * cos((m+1.)*om)
                                               + 2. * cos((m+1.)/2.*om) * sin(m/2.*om)/sin(om/2.)
                                               - (m+1.)/dimseg * sin((2.*m+1.)/2.*om)/sin(om/2.)
                                               + 1./dimseg * (sin((m+1.)/2.*om)/sin(om/2.))^2.
		                              );
    }
  }

  % zhangpsd is Leahy-normalzed => unnormalized (raw) noipsd
  variable noipsd = (zhangpsd*dimseg*dimseg*avgrate)/(2.*tseg);

%  if(not qualifier_exists("unnormalized"))
%    noipsd = normpsd(noipsd, normtype, avgrate, avgbkg, tseg, dimseg);
%   return freq, noipsd;
  return freq, noipsd, normpsd(noipsd, normtype, avgrate, avgbkg, tseg, dimseg);
}
