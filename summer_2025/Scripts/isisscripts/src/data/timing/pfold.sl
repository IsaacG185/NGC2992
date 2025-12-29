% -*- mode: slang; mode: fold; -*- %

define phaseOfTime (time, p, dp, ddp) %{{{
%!%+
%\function{phaseOfTime}
%\synopsis{Compute the phase corresponding to given time}
%\usage{Double_Type[] phaseOfTime(Double_Type[] time, Double_Type, p, dp, ddp);}
%\description
%  Given a time and a period evolution by the period P \code{p},
%  first, and second derivative of P, \code{dp} and \code{ddp},
%  respectively, calculate the phase.
%
%  Note: This function does a simple taylor expansion of the phase
%  dphi = 1./P(t)dt. Time zero correpsonds to phase zero. For
%  long time arrays this function suffers from precision errors.
%
%  Since it is expected that the period changes monotonically, this
%  function throws an error if the given time is outside of the extrema
%  (if any). This only applies to non-zero \code{ddp}.
%\seealso{timeOfPhase}
%!%-
{
  variable a1 = 1./double(p);

  if (abs(dp)<1e-16 && abs(ddp)<1e-16)
    return time*a1;

  variable a2 = -0.5*a1*a1*dp;

  if (abs(ddp)<1e-16)
    return (time*a2+a1)*time;

  variable a3 = dp*dp*a1*a1*a1/3.-ddp*a1*a1/6.;

  if ((a2*a2-3*a3*a1>0) &&
      not all((-a2-sqrt(a2*a2-3*a3*a1))/3./a3 < time < (-a2+sqrt(a2*a2-3*a3*a1))/3./a3))
    throw DomainError, "Period evolution is invalid for the given time frame";

  return ((time*a3+a2)*time+a1)*time;
}
%}}}

define timeOfPhase (phase, p, dp, ddp) %{{{
%!%+
%\function{timeOfPhase}
%\synopsis{Compute the time corresponding to given phase}
%\usage{Double_Type[] timeOfPhase(Double_Type[] phase, Double_Type, p, dp, ddp);}
%\description
%  Given a phase and a period evolution by the period P \code{p},
%  first, and second derivative of P, \code{dp} and \code{ddp},
%  respectively, calculate the time.
%
%  Note: This function is essentially the inverse of \code{timeOfPhase}.
%  For non-zero \code{ddp} the inverse is only approximated through
%  series inversion!
%\seealso{phaseOfTime}
%!%-
{
  variable b1 = p;

  if (abs(dp)<1e-16 && abs(ddp)<1e-16)
    return phase*b1;

  if (abs(ddp)<1e-16)
    return p*(1.-sqrt(1.-2*dp*phase))/dp;

  % through series inversion
  variable b2 = 0.5*b1*dp;
  variable b3 = (p*dp*dp+p*p*ddp)/6.;

  if ((b2*b2-3*b3*b1>0) &&
      not all((-b2-sqrt(b2*b2-3*b3*b1))/3./b3 < time < (-b2+sqrt(b2*b2-3*b3*b1))/3./b3))
    throw DomainError, "Period evolution is invalid for the given period frame";

  return ((b3*phase+b2)*phase+b1)*phase;
}
%}}}

private define pulseGridFromPhasebins (phaseLo, phaseHi, grid) %{{{
{
  variable nStart = int(floor(phaseLo));
  variable nStop = int(floor(phaseHi));
  variable nbins = length(grid)-1;

  variable pulses, i, cover;

  variable iStart, iStop, iLast;

  iStart = nStart[0];
  iStop = nStop[0];
  cover = 0;
  _for i (0, length(nStart)-1)
  {
    if (iStart <= nStart[i] <= iStop || iStart <= nStop[i] <= iStop)
    {
      if (nStart[i] < iStart)
	iStart = nStart[i];

      if (nStop[i] > iStart)
	iStop = nStop[i];
    }
    else
    {
      cover += iStop-iStart+1;
      iStart = nStart[i];
      iStop = nStop[i];
    }
  }

  % last interval
  cover += iStop-iStart+1;

  pulses = Int_Type[cover];

  % second pass to count
  iStart = nStart[0];
  iStop = nStop[0];
  iLast = 0;
  _for i (0, length(nStart)-1)
  {
    if (iStart <= nStart[i] <= iStop || iStart <= nStop[i] <= iStop)
    {
      if (nStart[i] < iStart)
	iStart = nStart[i];

      if (nStop[i] > iStart)
	iStop = nStop[i];
    }
    else
    {
      pulses[[0:iStop-iStart]+iLast] = [iStart:iStop];
      iLast += iStop-iStart+1;
      iStart = nStart[i];
      iStop = nStop[i];
    }
  }

  pulses[[0:iStop-iStart]+iLast] = [iStart:iStop];

  variable phase_lo = Double_Type[nbins*length(pulses)];
  variable phase_hi = Double_Type[length(phase_lo)];

  _for i (0, length(pulses)-1)
  {
    phase_lo[i*nbins+[0:nbins-1]] = grid[[0:nbins-1]]+pulses[i];
    phase_hi[i*nbins+[0:nbins-1]] = grid[[1:nbins]]+pulses[i];
  }

  return phase_lo, phase_hi, pulses;
}
%}}}

private define periodFoldEvents (time, p) %{{{
{
% relatively easy task:
%   1) sort in the events to the phase histogram `value'
%   2) calculate exposure time for each phase bin `exposure'
%     => value/exposure is the pulse profile
  variable verbose = qualifier("chatty", qualifier("verbose", _Isisscripts_Verbose));

  % no gti given, assume all events are in a gti (edge are taken sharply)
  if (not qualifier_exists("gti") && verbose>=0)
    vmessage("*** Warning: No GTIs given, assuming full time between first and last event\n  This is likely not what you want");
  variable gti = qualifier("gti", struct {start=min(time),stop=max(time)});
  variable dp = qualifier("pdot", 0.); % P dot (for Taylor approximation)
  variable ddp = qualifier("pddot", 0.); % P dot dot (also for Taylor)
  variable nbins = qualifier("nbins", 30); % number of phase bins
  variable t0 = qualifier("t0", min(gti.start)); % zero point of period evolution

  variable grid = [0:1:#nbins+1]; % overflow bin does not matter here
  variable result, phaselc;

  % working variables
  variable phaseLo, phaseHi, pulses, k, j, startj, n, pStart, pStop, nStart,
    nStop, inStop, inStart, tTime, gtiStart, gtiStop,
    phase, eTime, bTime, gtiIdx, pulseStart, pulseStop, mapH;

  result = struct {
    bin_lo = grid[[:-2]],
    bin_hi = grid[[1:]],
    value, % count rate
    error = Double_Type[nbins], % count rate error
    counts =  UInt_Type[nbins], % counts
    npts, % how often a bin was hit by start time (not sure what this is used for)
    ttot = Double_Type[nbins], % per bin exposure
  };
  phaselc = NULL;

  phaseLo = phaseOfTime(gti.start-t0, p, dp, ddp);
  phaseHi = phaseOfTime(gti.stop-t0, p, dp, ddp);

  if (qualifier_exists("phaselc"))
  {
    phaselc = struct {
      phase_lo,
      phase_hi,
      counts,
      exposure,
    };

    (phaselc.phase_lo, phaselc.phase_hi, pulses) =
      pulseGridFromPhasebins (phaseLo, phaseHi, grid);
    phaselc.counts = UInt_Type[length(phaselc.phase_lo)];
    phaselc.exposure = Double_Type[length(phaselc.phase_lo)];
  }

  () = histogram(time, gti.start, gti.stop, &gtiIdx);

  pulseStart = 0;
  pulseStop = 0;
  _for k (0, length(gtiIdx)-1) {
    eTime = time[gtiIdx[k]]-t0;
    gtiStart = gti.start[k]-t0;
    gtiStop  = gti.stop[k]-t0;
    pStart = phaseLo[k];
    pStop = phaseHi[k];
    phase = phaseOfTime(eTime, p, dp, ddp);

    % get index in pulse profile of start and stop
    nStart = int(floor(pStart));
    nStop = int(floor(pStop));

    inStart = wherefirst(((pStart-nStart)-grid)<0.)-1;
    inStop = wherefirst(((pStop-nStop)-grid)<0.)-1;

    % need to go through each covered profile bin
    % and calculate the relative exposure. This is necessary
    % because if dp and ddp are non-zero, the coverage is
    % not linear.
    j = inStart;
    n = nStart;

    if (NULL != phaselc)
    {
      while (pulses[pulseStart] < nStart)
	pulseStart++;

      mapH = histogram(phase, phaselc.phase_lo, phaselc.phase_hi);

      if (NULL != mapH)
	phaselc.counts += mapH;

      pulseStop = pulseStart + nStop - nStart;
      bTime = [gtiStart, timeOfPhase([phaselc.phase_lo[[pulseStart*nbins+inStart+1:pulseStop*nbins+inStop]],
				      phaselc.phase_hi[[pulseStart*nbins+inStart:pulseStop*nbins+inStop-1]]],
				     p, dp, ddp), gtiStop];
      phaselc.exposure[[pulseStart*nbins+inStart:pulseStop*nbins+inStop]] +=
	bTime[[length(bTime)/2:length(bTime)-1]]-bTime[[0:length(bTime)/2-1]];

      pulseStart = pulseStop;
    }

    if ((inStart == inStop) && (nStart == nStop)) {
      % gti window is completely inside bin
      tTime = gtiStop-gtiStart;
      result.ttot[inStart] += tTime;
    }
    else if ((nStop - nStart) > 5)
    {
      % if many periods are covered in one interval it is better to loop
      % over the phase bins only once
      if (qualifier_exists("exact"))
      {
	n = [nStart+1:nStop-1]; %nStop-nStart+1;

	% endpoints
	bTime = timeOfPhase([grid[[inStart:nbins-1]]+nStart, grid[[inStart+1:nbins]]+nStart], p, dp, ddp);
	bTime[0] = gtiStart;
	result.ttot[[inStart:nbins-1]] += bTime[[length(bTime)/2:length(bTime)-1]]-bTime[[0:length(bTime)/2-1]];

	bTime = timeOfPhase([grid[[0:inStop]]+nStop, grid[[1:inStop+1]]+nStop], p, dp, ddp);
	bTime[-1] = gtiStop;
	result.ttot[[0:inStop]] += bTime[[length(bTime)/2:length(bTime)-1]]-bTime[[0:length(bTime)/2-1]];

	_for j (0, nbins-1)
	{
	  bTime = timeOfPhase([grid[j]+n, grid[j+1]+n], p, dp, ddp);

	  result.ttot[j] += sum(bTime[[length(bTime)/2:length(bTime)-1]]-bTime[[0:length(bTime)/2-1]]);
	}

      }
      else
      { % assume constant p over GTI such that there is a linear relation between dPhi and dT
	bTime = timeOfPhase([nStart+grid,nStop+grid], p, dp, ddp);
	tTime = (bTime[nbins+1]-bTime[nbins])/nbins;
	result.ttot += tTime;
	result.ttot[[inStart:nbins-1]] += (bTime[nbins]-gtiStart)/(nbins-inStart);
	result.ttot[[0:inStop]] += (gtiStop-bTime[nbins+1])/(inStop+1);
      }
    }
    else
    {
      bTime = timeOfPhase(n+grid, p, dp, ddp);
      startj = j;
      do {
	if (j==nbins) { % next period?
	  % phase grid change, so write it first
	  result.ttot[[startj:nbins-1]] += _min(gtiStop,bTime[[startj+1:nbins]])-_max(gtiStart,bTime[[startj:nbins-1]]);
	  n++;
	  bTime = timeOfPhase(n+grid, p, dp, ddp);
	  j = 0; startj = j;
	}
	j++;
      } while ((j <= inStop) || (n < nStop));
      % last partial period not covered yet, j==0 if last bin had been covered
      if (j!=0)
	result.ttot[[startj:j-1]] += _min(gtiStop,bTime[[startj+1:j]])-_max(gtiStart,bTime[[startj:j-1]]);
    }

    if (length(phase))
      result.counts += histogram(phase-floor(phase), grid)[[:-2]];
  }

  result.value = result.counts*1./result.ttot; % count rate
  result.error = sqrt(result.counts)/result.ttot; % count rate error
  result.npts = result.counts; % not sure what this is used for

  if ( NULL != phaselc )
    phaselc = struct { phaselc = phaselc };

  return struct { @result, @phaselc };
}
%}}}

private define periodFoldLCfast (input) %{{{
{
  variable phaseLo = input.phaseLo;
  variable grid = input.grid;
  variable dt = input.dt;
  variable fracexp = input.fracexp;
  variable rate = input.rate;
  variable rateerr = input.rateerr;
  variable nbins = input.nbins;

  variable verbose = qualifier("chatty", qualifier("verbose", _Isisscripts_Verbose));

  % Fast approximation, assumes that light curve bins are point measurements
  % (i.e., bin_hi-bin_lo is short compared to a phase bin)
  variable fastP, npts, fastIdx, cDt, cFracExp, result,
    phaselc, nStart, j, tTime;

  fastP = phaseLo-floor(phaseLo);
  npts = histogram(fastP, grid, ,&fastIdx)[[:-2]];

  result = struct {
    bin_lo = grid[[:-2]],
    bin_hi = grid[[1:]],
    value, % count rate
    error = Double_Type[length(fastIdx)], % count rate error
    counts =  Double_Type[length(fastIdx)], % counts
    npts = npts, % how often a bin was hit by start time (not sure what this is used for)
    ttot = Double_Type[length(fastIdx)], % per bin exposure
  };
  phaselc = NULL;

  _for j (0, length(fastIdx)-2) {
    if (verbose>=2) vmessage("Interval [%d/%d]", j+1, length(fastIdx)-1);
    cDt = (length(dt) == 1) ? dt : dt[fastIdx[j]];
    cFracExp = (length(fracexp) == 1) ? fracexp*cDt : fracexp[fastIdx[j]]*cDt;
    result.counts[j] = sum((rate[fastIdx[j]])*cFracExp);
    result.ttot[j] = sum(cFracExp);
    result.error[j] = (NULL != rateerr) ? sum(sqr((rateerr[fastIdx[j]])*cFracExp)) : result.counts[j];
  }

  if (qualifier_exists("phaselc"))
  {
    phaselc = struct {
      phase_lo,
      phase_hi,
      counts,
      exposure,
    };

    nStart = int(floor(phaseLo));
    nStart = nStart[unique(nStart)];
    phaselc.phase_lo = Double_Type[nbins*length(nStart)];
    phaselc.phase_hi = Double_Type[nbins*length(nStart)];
    phaselc.counts = Double_Type[nbins*length(nStart)];
    phaselc.exposure = Double_Type[nbins*length(nStart)];

    _for j (0, length(nStart)-1)
    {
      phaselc.phase_lo[[0:nbins-1]+j*nbins] = nStart[j]+grid[[0:nbins-1]];
      phaselc.phase_hi[[0:nbins-1]+j*nbins] = nStart[j]+grid[[1:nbins]];
    }

    npts = histogram(phaseLo, phaselc.phase_lo, phaselc.phase_hi, &fastIdx);
    _for j (0, length(fastIdx)-1)
    {
      cDt = (length(dt) == 1) ? dt : dt[fastIdx[j]];
      cFracExp = (length(fracexp) == 1) ? fracexp*cDt : fracexp[fastIdx[j]]*cDt;
      tTime = sum(cFracExp);
      phaselc.counts[j] = sum(cFracExp*rate[fastIdx[j]]);
      phaselc.exposure[j] = tTime;
    }

    phaselc = struct { phaselc = phaselc };
  }

  result.counts = result.counts[[:-2]];
  result.ttot = result.ttot[[:-2]];
  result.value = result.counts/result.ttot;
  result.error = sqrt(result.error[[:-2]])/result.ttot;

  return struct { @result, @phaselc };
}
%}}}

private define periodFoldLCexact (input) %{{{
{
  variable phaseLo = input.phaseLo;
  variable phaseHi = input.phaseHi;
  variable grid = input.grid;
  variable dt = input.dt;
  variable fracexp = input.fracexp;
  variable t0 = input.t0;
  variable time = input.time;
  variable rate = input.rate;
  variable rateerr = input.rateerr;
  variable nbins = input.nbins;

  variable verbose = qualifier("chatty", qualifier("verbose", _Isisscripts_Verbose));

  variable npts, tStart, tStop, pStart, pStop, nStart, nStop,
    inStart, inStop, cFracExp, n, j, k, tTime, tVal, result,
    bTime, startj, phaselc, pulses, pulseStart, pulseStop;

  result = struct {
    bin_lo = grid[[:-2]],
    bin_hi = grid[[1:]],
    value, % count rate
    error = Double_Type[nbins], % count rate error
    counts =  Double_Type[nbins], % counts
    npts = Int_Type[nbins], % how often a bin was hit by start time (not sure what this is used for)
    ttot = Double_Type[nbins], % per bin exposure
  };
  phaselc = NULL;

  if (qualifier_exists("phaselc"))
  {
    phaselc = struct {
      phase_lo,
      phase_hi,
      counts,
      exposure,
    };

    (phaselc.phase_lo, phaselc.phase_hi, pulses) =
      pulseGridFromPhasebins (phaseLo, phaseHi, grid);
    phaselc.counts = Double_Type[length(phaselc.phase_lo)];
    phaselc.exposure = Double_Type[length(phaselc.phase_lo)];
  }

  pulseStart = 0;
  pulseStop = 0;
  _for k (0, length(phaseLo)-1) {
    if (verbose>2) { vmessage("Phase interval [%d/%d]", k+1, length(phaseLo)); }
    tStart = time[k]-t0;
    % nummerical issue here, large timestamps + dt creates deviations
    tStop = tStart + ((length(dt)==1) ? dt : dt[k]);
    pStart = phaseLo[k];
    pStop = phaseHi[k];
    nStart = int(floor(pStart));
    nStop = int(floor(pStop));

    % phase bins lc bins fall into
    inStart = wherefirst(((pStart-nStart)-grid)<0)-1;
    inStop = wherefirst(((pStop-nStop)-grid)<0)-1;

    if (NULL == inStart || NULL == inStop)
      continue;

    result.npts[inStart]++;

    n = nStart;
    j = inStart;

    cFracExp = (length(fracexp)==1) ? fracexp : fracexp[k];

    if (NULL != phaselc)
    {
      while (pulses[pulseStart] < nStart)
	pulseStart++;
    }

    if ((inStart == inStop) && (nStart == nStop)) {
      tTime = (tStop-tStart)*cFracExp;
      tVal = rate[k]*tTime;
      result.counts[j] += tVal;
      result.ttot[j] += tTime;
      result.error[j] += (NULL != rateerr) ? sqr(rateerr[k]*tTime) : tVal;

      if (NULL != phaselc)
      {
	phaselc.counts[pulseStart*nbins+j] += tVal;
	phaselc.exposure[pulseStart*nbins+j] += tTime;
      }
    } else if ((nStop - nStart) > 5) {
      % if many periods are covered in one interval it is better to loop over the phase bins only once
      % and for the LC it is safe to assume the period does not change significantly over one bin
      bTime = timeOfPhase([nStart+grid,nStop+grid], input.P[0], input.P[1], input.P[2]);
      tTime = (bTime[nbins+1]-bTime[nbins])/nbins*cFracExp;
      result.counts += rate[k]*tTime;
      result.ttot += tTime;

      pulseStop = pulseStart + nStop-nStart;
      if (NULL != phaselc)
      {
	phaselc.counts[[(pulseStart+1)*nbins:(pulseStop-1)*nbins]] += rate[k]*tTime;
	phaselc.exposure[[(pulseStart+1)*nbins:(pulseStop-1)*nbins]] += tTime;
      }

      tTime = (bTime[nbins]-tStart)/(nbins-inStart)*cFracExp;
      result.ttot[[inStart:nbins-1]] += tTime;
      result.counts[[inStart:nbins-1]] += rate[k]*tTime;

      if (NULL != phaselc)
      {
	phaselc.counts[[inStart:nbins-1] + nbins*pulseStart] += rate[k]*tTime;
	phaselc.exposure[[inStart:nbins-1] + nbins*pulseStart] += tTime;
      }

      tTime = (tStop-bTime[nbins+1])/(inStop+1)*cFracExp;
      result.ttot[[0:inStop]] += tTime;
      result.counts[[0:inStop]] += rate[k]*tTime;

      if (NULL != phaselc)
      {
	phaselc.counts[[0:inStop] + nbins*pulseStop] += rate[k]*tTime;
	phaselc.exposure[[0:inStop] + nbins*pulseStop] += tTime;
      }

      pulseStart = pulseStop;
    } else {
      % otherwise we loop through the phases until we hit the interval limit
      bTime = timeOfPhase(n+grid, input.P[0], input.P[1], input.P[2]);
      startj = j;

      do {
	if (j == nbins) {
	  tTime = (_min(tStop,bTime[[startj+1:nbins]])-_max(tStart,bTime[[startj:nbins-1]]))*cFracExp;
	  tVal = rate[k]*tTime;
	  result.ttot[[startj:nbins-1]] += tTime;
	  result.counts[[startj:nbins-1]] += tVal;
	  result.error[[startj:nbins-1]] += (NULL != rateerr) ? rateerr[k]*tTime : tVal;

	  if (NULL != phaselc)
	  {
	    phaselc.counts[[startj:nbins-1] + nbins*pulseStart] += tVal;
	    phaselc.exposure[[startj:nbins-1] + nbins*pulseStart] += tTime;
	  }

	  n++;
	  bTime = timeOfPhase(n+grid, input.P[0], input.P[1], input.P[2]);
	  j=0; startj = j;
	  pulseStart++;
	}
	j++;
      } while ((j <= inStop) || (n < nStop));
      % last coverage might not be handled
      pulseStop = pulseStart;
      if (j!=0) {
	tTime = (_min(tStop,bTime[[startj+1:j]])-_max(tStart,bTime[[startj:j-1]]))*cFracExp;
	tVal = rate[k]*tTime;
	result.ttot[[startj:j-1]] += tTime;
	result.counts[[startj:j-1]] += tVal;
	result.error[[startj:j-1]] += (NULL != rateerr) ? sqr(rateerr[k]*tTime) : tVal;

	if (NULL != phaselc)
	{
	  phaselc.counts[[startj:j-1] + nbins*pulseStart] += tVal;
	  phaselc.exposure[[startj:j-1] + nbins*pulseStart] += tTime;
	}
      }
    }
  }

  if (NULL != phaselc)
    phaselc = struct { phaselc = phaselc };

  result.value = result.counts/result.ttot;
  result.error = sqrt(result.error)/result.ttot;

  return struct { @result, @phaselc };
}
%}}}

private define periodFoldLC (time, rate, rateerr, p) %{{{
{
  variable verbose = qualifier("chatty", qualifier("verbose", _Isisscripts_Verbose));

  variable dp  = qualifier("pdot", 0.);
  variable ddp = qualifier("pddot", 0.);
  variable nbins = qualifier("nbins", 30);

  if (not qualifier_exists("dt") && verbose>=0)
    vmessage("*** Warning: Grid spacing not given, assuming dt=diff(time).\n This is likely not what you want.");
  variable fast = not qualifier_exists("exact");

  variable input = struct {
    phaseLo, phaseHi, grid,
    dt, t0, fracexp, 
    time, rate, rateerr,
    nbins, P,
  };

  input.time = time;
  input.rate = rate;
  input.rateerr = rateerr;
  input.P = [p, dp, ddp];
  input.dt = qualifier("dt", mean(time[[1:]]-time[[:-2]])); % if not given, dt is t_k+1-t_k, can be single value
  input.fracexp = qualifier("fracexp", 1.); % if not given, full time coverage of dt is assumed
  input.t0 = qualifier("t0", min(time)); % zero point of period evolution

  input.phaseLo = phaseOfTime(time-input.t0, p, dp, ddp);
  input.grid = [0:1:#nbins+1];
  input.nbins = nbins;

  % we can speed up the calculation by alot when we ignore
  % that lc bins are finite
  if (fast) {
    return periodFoldLCfast(input;; __qualifiers());
  } else {
    input.phaseHi = phaseOfTime(time-input.t0+input.dt, p, dp, ddp);
    return periodFoldLCexact(input;; __qualifiers());
  }
}
%}}}

define pfold () %{{{
%!%+
%\function{pfold}
%\synopsis{folds a lightcurve or event list on a given period}
%\usage{Struct_Type pp = pfold(Double_Type t, r, p);
%\altusage{Struct_Type pp = pfold(Double_Type t, r, p, e);}
%\altusage{Struct_Type pp = pfold(Double_Type t, p);}}
%\qualifiers{
%\qualifier{nbins}{[=30] number of bins for the pulse profile}
%\qualifier{exact}{take finite lightcurve bins into account (LC case).
%             take differantial phase grid into account (Events case).}
%\qualifier{dt}{lightcurve bin size.}
%\qualifier{fracexp}{fractional exposure per lightcurve bin.}
%\qualifier{t0}{set reference time.}
%\qualifier{pdot}{[=0] first derivative of pulse period p.}
%\qualifier{pddot}{[=0] second derivative of pulse period p.}
%\qualifier{gti}{GTIs for event data, given as struct{start=Double_Type, stop=Double_Type}}
%}
%\description
%   Calculates the pulse profile of a given lightcurve or event list
%   for times \code{t} and rate \code{r}. In case of an event list
%   normally the use of GTIs is necessary to ensure correct results.
%
%   If the qualifiers \code{pdot} or \code{pddot} are given and not
%   zero a taylor expansion of the period evolution is used to
%   calculate the mapping to phase (from \code{t0}). If \code{pddot}
%   is non-zero the result is only approximately correct. See
%   \code{phaseOfTime}.
%
%   The input arrays \code{t}, \code{r}, and \code{e} can also be
%   given as qualifiers.
%
%   If the \code{exact} qualifier is given the finite size of lightcurve
%   bins is taken into account by linear interpolation. However, the
%   computation time is increased. For event lists, the code will take the
%   differentail phase grid change into account. Otherwise the exposure
%   time is approximated assuming a constant period over one GTI frame.
%
%   The returned structure contains the fields bin_lo, bin_hi, value
%   and err, ready for plotting the pulse profile (as rate). For further
%   diagnostics the \code{counts} (counts) and \code{ttot} (per-bin exposure)
%   are given. The field \code{npts} contains the number of lightcurve bins
%   starting in each bin.
%\seealso{phaseOfTime, timeOfPhase}
%!%-
{
  variable verbose = qualifier("chatty",qualifier("verbose", _Isisscripts_Verbose)) ;
  variable t,r = NULL,e = NULL,p;

  switch(_NARGS)
  {case 1:
    p = ();
    (t,r,e) = (qualifier("t", NULL), qualifier("r",r), qualifier("e", e));
  }
  {case 2:
    (t,p) = ();
    (r,e) = (qualifier("r", r), qualifier("e", e));
  }
  {case 3:
    (t,r,p) = ();
    e = qualifier("e", e);
  }
  {case 4:
    (t,r,p,e) = ();
  }
  {() = (); help(_function_name()); return; }

  if (NULL == t)
    throw UsageError, "No time array given (neither as parameter nor qualifier 't')";

  if (verbose>0)
  {
    vmessage(`Period folding parameters for array of length %d:
  p    : %g
  pdot : %g
  pddot: %g
  interpreted as %s data`, length(t), p, qualifier("pdot", 0.0), qualifier("pddot", 0.0),
			  (NULL == r) ? "event" : "light-curve");
  }

  if (NULL == r) {
    % event data
    return periodFoldEvents(t, p;; __qualifiers);
  } else {
    % lightcurve
    if (length(t) != length(r) || (e != NULL && length(t)!=length(e)))
      throw UsageError, "Time and rate (or error) arrays are not of equal length";
    return periodFoldLC(t, r, e, p;; __qualifiers);
  }
}
%}}}

define pfold_map () %{{{
%!%+
%\function{pfold_map}
%\synopsis{folds a lightcurve or event list on a given period map}
%\usage{Struct_Type ppmap = pfold_map(Double_Type t, r, p);
%\altusage{Struct_Type ppmap = pfold_map(Double_Type t, r, p, e);}
%\altusage{Struct_Type ppmap = pfold_map(Double_Type t, p);}}
%\qualifiers{
%\qualifier{nbins}{[=30] number of bins for the pulse profile}
%\qualifier{exact}{take finite lightcurve bins into account (LC case).
%             take differantial phase grid into account (Events case).}
%\qualifier{dt}{lightcurve bin size.}
%\qualifier{fracexp}{fractional exposure per lightcurve bin.}
%\qualifier{t0}{set reference time.}
%\qualifier{pdot}{[=0] first derivative of pulse period p.}
%\qualifier{pddot}{[=0] second derivative of pulse period p.}
%\qualifier{gti}{GTIs for event data, given as struct{start=Double_Type, stop=Double_Type}}
%}
%\description
%   This function acts identical to \code{pfold} except that a two
%   dimensional array is calculated, where the first dimension runs
%   over the cycles and the second over the period.
%   
%   The returned structure has the following fields
%     bin_lo, bin_hi  Phase grid of pulses (from 0 to 1)
%     phase_lo, phase_hi  Cycle grid, continuously
%     counts  2D map of counts
%     exposure  2D map of exposure time
%     rate  2D map of rate
%     p  struct returned by pfold
%
%   For illustration: The returned map can be collapsed to the pulse
%   profile via \code{sum(ppmap.counts, 0)} or \code{mean(ppmap.rate, 0)}.
%\seealso{pfold, phaseOfTime, timeOfPhase}
%!%-
{
  variable chatty = qualifier("chatty",qualifier("verbose", _Isisscripts_Verbose)) ;
  variable t,r = NULL,e = NULL,p;
  variable plc, counts, exposure, rate, i;

  switch(_NARGS)
  {case 2:
    (t,p) = ();
    (r,e) = (qualifier("r", r), qualifier("e", e));
  }
  {case 3:
    (t,r,p) = ();
    e = qualifier("e", e);
  }
  {case 4:
    (t,r,p,e) = ();
  }
  {() = (); help(_function_name()); return; }

  if (NULL == r) {
    % event data
    %throw NotImplementedError, "Currently not implemented for event data";
    plc = periodFoldEvents(t, p;; struct { phaselc, @__qualifiers});
  } else {
    % lightcurve
    if (length(t) != length(r) || (e != NULL && length(t)!=length(e)))
      throw UsageError, "Time and rate (or error) arrays are not of equal length";
    plc = periodFoldLC(t, r, e, p;; struct { phaselc, @__qualifiers});
  }

  counts = _reshape(plc.phaselc.counts, [length(plc.phaselc.phase_lo)/length(plc.bin_lo), length(plc.bin_lo)]);
  exposure = _reshape(plc.phaselc.exposure, [length(plc.phaselc.phase_lo)/length(plc.bin_lo), length(plc.bin_lo)]);
  rate = counts*1./exposure;
  i = where(exposure<=0);
  rate[i] = 0.0;

  return struct {
    bin_lo = plc.bin_lo,
    bin_hi = plc.bin_hi,
    phase_lo = plc.phaselc.phase_lo[[::length(plc.bin_lo)]],
    phase_hi = plc.phaselc.phase_hi[[::length(plc.bin_hi)]],
    counts = counts,
    exposure = exposure,
    rate = rate,
    p = plc,
  };
}
%}}}
