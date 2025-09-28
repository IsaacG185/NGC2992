%%%%%%%%%%%%%%%%%%%%%%%%
define epfold ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{epfold}
%\synopsis{peforms epoch folding on a lightcurve in a given period
%interval}
%\usage{(Struct_Type res) = epfold(Double_Type t, r, pstart, pstop);
%\altusage{(Struct_Type res) = epfold(Double_Type t, pstart, pstop) ; (event data)}}
%
%\qualifiers{
%\qualifier{nbins}{number of bins for the pulse profile (default=20)}
%\qualifier{exact}{calculate the pulse profile in a more exact way, see description of pfold (not recommended as it takes a very long time!).}
%\qualifier{dt}{exposure of every lightcurve time bin, should be given to ensure correct results.}
%\qualifier{sampling}{how many periods per peak to use (default=10)}
%\qualifier{nsrch}{how many periods to search in a linear grid (default not set)}
%\qualifier{dp}{delta period of linear period grid (default  not set)}
%\qualifier{lstat}{use L-statistics instead of chi^2 statistics}
%\qualifier{chatty}{set the verbosity, chatty-1 is piped to pfold (default=0)}
%\qualifier{gti}{GTIs for event data, given as struct{start=Double_Type, stop=Double_Type}} 
%}
%
%
%\description
%   Performs epoch folding on a given lightcurve between the periods
%   pstart and pstop. The function was adopted from
%   the IDL routine of the same name. GTI correction only implemented
%   for event-data yet.
%
%   By default, periods are sampled according to the triangular rule
%   for estimating the period error, using "sampling" periods per peak.
%   If a linear grid is to be used, either "dp" for a given distance
%   between two consecutive periods or "nsrch" for a given number of
%   periods can be given. These qualifiers are mutually exclusive. 
%
%   The returned structure "res" contains four fields: "p" for the
%   evaluated period and "stat" for the value of the statistic used.
%   Additionally the field "nbins" contains the number of phase bins
%   used and "badp" contains indices for res.p marking periods
%   where the pulse profile showd empty phase bins. Values of
%   res.stat[res.badp] should be taken with great care!
%        
%   Compared to the similar function sitar_epfold_rate, epfold.sl
%   uses the chi^2 statistic as a default and is based on pfold.sl,
%   which can take errors of the lightcurve into account.
%   If the qualifier "lstat" is given, the statistic is switched to
%   the l-stat statistic as in sitar_epfold_rate, but errors of the
%   lightcurve are no longer taken into account. lstat is not
%   available for event-data.
%
%   If the "exact" qualifier is given, the function takes the exposure
%   time of every time bin into account in the sense that, that a
%   given time bin may overlap over two phase bins. The corresponding
%   exposure time in every phase bin is reduced accordingly.
%
%   NOTE: the "exact" qualifiers slows the script considerably down,
%   depending on the length of the lightcurve and the number of bins
%   for up to a factor of >100!
%   
%   If "exact" is not given, the script is ~10% slower than
%   sitar_epfold_rate.
%   
%   The script is still in the develepment phase, please report any
%   bugs or missing features to Felix
%   (felix.fuerst@sternwarte.uni-erlangen.de).
%   
%   NOTE: Please read  
%          Davies, S.R., 1990, MNRAS 244, 93 (L-statistics!)
%          Larsson, S., 1996, A&AS 117, 197
%          Leahy, D.A., Darbro, W., Elsner, R.F., et al.,1983, ApJ 266, 160-170
%          Schwarzenberg-Czerny, A., 1989, MNRAS 241, 153
%   
%!%-
{
  variable t,r,pstart, pstop;

  variable eventdata = 0;
  % disable chatty if not set
  variable chatty = qualifier("chatty",qualifier("verbose",_Isisscripts_Verbose));

  switch(_NARGS)
  { case 3: (t,  pstart, pstop) = ();
    eventdata = 1 ;
    if (chatty>0) { vmessage("using event data"); }
  }
  { case 4: (t,r,pstart, pstop) = (); }
  { help(_function_name()); return; }

  variable t0 = qualifier ("t0", t[0]);
  variable nbins = qualifier ("nbins", 20);
  variable sampl = qualifier("sampling", 10); %periods per peak
  variable dp = qualifier("dp", -10) ; %delta p for linear period sampling
  variable nsrch = qualifier("nsrch", -10); %number of periods in linear period grid

  nsrch = int(nsrch);

  ifnot(qualifier_exists("dt") or eventdata==1) {
    message("WARNING (epfold): no dt qualifier given, creating differential grid! Might lead to unexpected results!") ;
  }
  variable dt = qualifier("dt" , make_hi_grid(t)-t); %exposure times

  ifnot (qualifier_exists("gti") or eventdata==0) {
    message("WARNING (epfold): using eventdata without gti qualifier, taking time of first and last event. This is most likely NOT what you want!") ;
  }
  variable gti = qualifier("gti", struct{ start=min(t), stop=max(t) });

  variable tges = sum(dt) ; %effective observation time

  if (tges<0) {
    throw UsageError, "Please provide lightcurve with continously increasing time (tges was < 0).";
  }

  if (chatty>0) { vmessage(">> Starting data analysis <<"); }

  if (chatty>0) {
    vmessage("Determining number of trial periods between %f and %f.", pstart, pstop);
  }

  if (eventdata and qualifier_exists("lstat")) {
    vmessage("WARNING (epfold): using eventdata, lstat qualifier not sensible! Reverting to use of chi^2 statistic.");
  }

  variable ergdim=1;
  variable p;
  variable i = 1;

  if (dp > 0 && nsrch == -10)
  {
    if (chatty>0) { vmessage("Making linear period grid with delta P = %f.", dp); }
    p = [pstart:pstop:dp];
    ergdim = length(p);
  }
  else if (dp == -10  && nsrch > 0)
  {
    if (chatty>0) { vmessage("Making linear period grid with %d entries.", nsrch); }
    p = [pstart:pstop:#nsrch];
    ergdim = nsrch;
  }
  else if (dp > 0 && nsrch > 0)
  {
    throw UsageError, "Unable to construct search grid, provide either 'dp' or 'nsrch'";
  }
  else {
    if (chatty>0) { vmessage("Making intelligent grid!"); }
    variable p_bin_hi = pstart;
    variable jj = 1;
    while (p_bin_hi  <= pstop) { % This may look pedestrian, but I determine first how much periods the grid will contain, because doing the period calculation twice will still be WAY faster than copying the arrays
      p_bin_hi = p_bin_hi + sqr(p_bin_hi)/(tges*sampl);
      jj++;
    };
    p  = Double_Type[jj]; % initialize array long enough for all test periods
    p[0] = pstart;
    while (p[i-1] <= pstop)
    {  ergdim++ ;
      p[i]= p[i-1]+p[i-1]*p[i-1]/(tges*sampl);
      i++ ;
    }
    p = p[[0:i-1]]; % cut the empty array entries
  }

  if (chatty>0) { vmessage("number of periods = %d .... done", ergdim); }

  if (chatty>0) { variable tstart = _time(); variable tlast = _time(); }

  variable ptest = pstart;
  variable pp, ndx ;
  variable parr = Double_Type[ergdim];
  variable chierg = Double_Type[ergdim];
  variable perc, titer, remain;

  variable factor = (1.* (length(t)-nbins)) / (nbins -1.); % (N-M)/(M-1) as in Davies Eq. 11
  variable finitepp, faulty = Integer_Type[0];

  %subtract mean from rate, as we need only the
  %difference for the statistics and it does not change
  %the generality
  ifnot(eventdata) {
    variable rm = moment(r);
    r -= rm.ave;

    if (chatty>0)  {
      vmessage("mean = %f", rm.ave);
      vmessage("effective observation time: %f", tges );
    }
  }

  _for i (0, length(parr)-1, 1)
  {
    ptest = p[i];
    if (eventdata) { pp = pfold(t,ptest ; nbins=nbins,chatty=chatty, t0=t0,gti=gti); }
    else if(qualifier_exists("exact")) { pp = pfold(t,r,ptest ; nbins = nbins, dt = dt, chatty=chatty, t0=t0, exact); }
    else { pp = pfold(t,r,ptest  ; nbins = nbins, dt = dt, chatty=chatty, t0=t0 ); }

    finitepp = wherenot(isnan(pp.value) or isinf(pp.value));

    if (length(finitepp) < nbins) {
      vmessage("WARNING: period %f has faulty phase bins! Ignoring those phase bins, but please check!", ptest);
      faulty = [faulty, i];
      struct_filter(pp, finitepp);
    }

    if (eventdata) {
      chierg[i] =  sum((pp.value[*]-mean(pp.value))^2. / (mean(pp.value)/pp.ttot[*]));
    } else {
      if (qualifier_exists("lstat"))
      {
	% see Davies Eq. 11
	chierg[i] = factor * ( sum(pp.npts*pp.value^2))/(sum (pp.error*(pp.npts-1.)));
      }
      else
      {
	% see Davies Eq. 4 or Larsson Eq. 1
	chierg[i] =  sum(pp.npts*pp.value^2.)/rm.var;
      }
    }

    if(chatty>0)
    {
      if (_time()-tlast > 10)
      {
	tlast=_time();
	titer = (tlast-tstart)/double(i);
	remain=(ergdim-i)*titer;

	vmessage("%.2f%% done", i*100./ergdim );
	vmessage("its taking %.2fsec per iteration", titer);

	if (remain <= 600)  vmessage("%.2f sec remaining...", remain);
	else if (remain <= 7200) vmessage("%.2f min remaining...", remain/60.);
	else vmessage("%.2f h remaining...", remain/3600.);
      }
    }
  }

  %structure containing searched periods, statistics value,
  %phasebins used and indices of periods with gaps in the pulse profile
  return struct{ p=p, stat=chierg, nbins=nbins, badp = faulty };
}
