%%%%%%%%%%%%%%%%%%%%%%%%
define epfoldpdot ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{epfoldpdot}
%\synopsis{peforms epoch folding on a lightcurve in a given period
%interval}
%\usage{(Struct_Type res) = epfoldpdot(Double_Type t, r, pstart, pstop);
%or (Struct_Type res) = epfoldpdot(Double_Type t, pstart, pstop) ; (event data)}
%
%\qualifiers{
%\qualifier{nbins}{number of bins for the pulse profile}
%\qualifier{exact}{calculate the pulse profile in a more exact way, see description of pfold (not recommed as it takes a very long time!).}
%\qualifier{dt}{exposure of every lightcurve time bin, should be given to ensure correct results.}
%\qualifier{sampling}{how many periods per peak to use (default=10)}
%\qualifier{nsrch}{how many periods to search in a linear grid (default not set)}
%\qualifier{dp}{delta period of linear period grid (default  not set)}
%\qualifier{lstat}{use L-statistics instead of chi^2 statistics}
%\qualifier{chatty}{set the verbosity, chatty-1 is piped to pfold (default=0)}
%\qualifier{gti}{GTIs for event data, given as struct{start=Double_Type, stop=Double_Type}}
%\qualifier{pdstart}{start p-dot for grid search (default=0)}
%\qualifier{pdstop}{stop p-dot for grid search (default=0)}
%\qualifier{pdnsrch}{search point for p-dot grid, (default = nsrch
%(if defined, otherwise 10))}
%}
%
%
%\description
%   Performs epoch folding on a given lightcurve between the periods
%   pstart and pstop and period derivatives (p-dot) pdstart and pdstop.
%   The function was adopted from
%   the IDL routine of the same name. GTI correction only implemented
%   for event-data yet.
%
%   By default, periods are sampled according to the triangular rule
%   for estimating the period error, using "sampling" periods per peak.
%   If a linear grid is to be used, either "dp" for a given distance
%   between two consecutive periods or "nsrch" for a given number of
%   periods can be given. These qualifiers are mutually exclusive.
%
%   P-dot is always sampled on a linear grid with  pdnsrch points.
%
%   The routine uses the S-lang function 'parallel_map' to use
%   Isis_Slaves.num_slaves cores on your machine for parallel
%   computing. On a MacBook Pro with quadcorse i7 this gives a speed
%   improvement of a factor ~>2 over single core calculations.
%
%   The returned structure "res" contains five fields: "p" for the
%   evaluated period, pd for the evaluated period derviates,
%   and "stat" for the value of the statistic used. "stat" is a 2D
%   array of dimnesion (np, npd).
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
%   NOTE: "exact" qualifier is currenlty untested and may lead to
%   erronoeus results!
%
%   If "exact" is not given, the script is ~10% slower than
%   sitar_epfold_rate.
%
%   The script is still in the develepment phase, please report any
%   bugs or missing features to Felix
%   (felix.fuerst@fau.de).
%
%   NOTE: Please read
%          Davies, S.R., 1990, MNRAS 244, 93 (L-statistics!)
%          Larsson, S., 1996, A&AS 117, 197
%          Leahy, D.A., Darbro, W., Elsner, R.F., et al.,1983, ApJ 266, 160-170
%          Schwarzenberg-Czerny, A., 1989, MNRAS 241, 153
%
%!%-
{
  variable t,r,pstart, pstop ;

  variable eventdata = 0;
  % disable chatty if not set
  variable chatty = qualifier("chatty",qualifier("verbose",_Isisscripts_Verbose)) ;

  switch(_NARGS)
  { case 3: (t,  pstart, pstop) = ();
    eventdata = 1 ;
    if (chatty) { vmessage("using event data"); }
  }
  { case 4: (t,r,pstart, pstop) = (); }
  { help(_function_name()); return; }

  variable t0 = qualifier ("t0", t[0]);
  variable nbins = qualifier ("nbins", 20) ;
  variable sampl = qualifier("sampling", 10)  ; %periods per peak
  variable dp = qualifier("dp", -10) ; %delta p for linear period sampling
  variable nsrch = qualifier("nsrch", -10) ; %number of periods in linear period grid

  nsrch = int(nsrch) ;

  variable pdstart=0;
  variable pdstop ;

  variable pd=0;

  variable pdnsrch=1 ;

  if (qualifier_exists("pdstart") and qualifier_exists("pdstop"))
  {
    pdnsrch= qualifier("pdnsrch", qualifier("nsrch", 10));
    pdstart = qualifier("pdstart");
    pdstop = qualifier("pdstop");
    pd = [pdstart:pdstop:#pdnsrch];
  }

  ifnot(qualifier_exists("dt") or eventdata==1) {
    vmessage("WARNING (epfoldpdot): no dt qualifier given, creating differential grid! Might lead to unexpected results!");
  }
  variable dt = qualifier("dt" , make_hi_grid(t)-t) ; %exposure times

  ifnot (qualifier_exists("gti") or eventdata==0) {
    vmessage("WARNING (epfoldpdot): using eventdata without gti qualifier, taking time of first and last event. This is most likely NOT what you want!") ;
  }
  variable gti = qualifier("gti", struct{ start=min(t), stop=max(t) });

  variable tges = sum(dt) ; %effective observation time

  if (tges < 0) {
    throw UsageError, "provided lightcurve not continously increasing (tges was < 0).";
  }

  if (chatty) { vmessage(">> Starting data analysis <<"); }

  if (chatty) {
    vmessage("Determining number of trial periods between %f and %f.", pstart, pstop);
  }

  if (eventdata and qualifier_exists("lstat")) {
    vmessage("WARNING (epfoldpdot): using eventdata, lstat qualifier not sensible! Reverting to use of chi^2 statistic.");
  }

  variable ergdim=1;
  variable p = pstart;
  variable j, i = 1;

  if (dp > 0 && nsrch == -10)
  {
    if (chatty) { vmessage("Making linear period grid with delta P = %f.", dp); }
    p = [pstart:pstop:dp];
    ergdim = length(p);
  }
  else if (dp == -10  && nsrch > 0)
  {
    if (chatty) { vmessage("Making linear period grid with %dx%d entries.", nsrch, pdnsrch); }
    p = [pstart:pstop:#nsrch];
    ergdim = nsrch;
  }
  else if (dp > 0 && nsrch > 0)
  {
    throw UsageError, "Unable to create search grid, provide either 'dp' or 'nsrch'";
  }
  else {
    if (chatty) vmessage("Making intelligent grid!") ;
    while (p[-1] <= pstop)
    {
      ergdim++;
      p=[p, p[i-1]+p[i-1]*p[i-1]/(tges*sampl) ];
      i++;
    }
  }

  if (chatty) { vmessage("number of periods = %d\n....done ",ergdim*pdnsrch); }

  if (chatty) { variable tstart = _time(); variable tlast = _time(); }

  variable ptest = pstart;
  variable pdtest = pdstart;
  variable pp,pparr, ndx;

  % variable parr = Double_Type[ergdim] ;
  variable chierg = Double_Type[ergdim,pdnsrch];

  variable perc, titer, remain;

  variable factor  =  (1.* (length(t)-nbins)) / (nbins -1.); % (N-M)/(M-1) as in Davies Eq. 11

  variable finitepp, faulty = Integer_Type[0];

  %susbstract mean from rate, as we need only the
  %difference for the statistics and it does not change
  %the generality
  ifnot(eventdata) {
    variable rm = moment(r);
    r -= rm.ave;

    if (chatty) {
      vmessage("mean = %f", rm.ave);
      vmessage("effective observation time: %f", tges);
    }
  }
  _for j (0, pdnsrch-1, 1)
  {
    pdtest = pd[j];

    if (chatty>1) vmessage("Entry %d,%d: P=%.4f, Pdot=%.4e", i,j, ptest, pdtest);

    if(eventdata) {
      pparr = parallel_map(Struct_Type, &pfold, p;
			   t=t, pdot=pdtest, nbins=nbins,chatty=chatty, t0=t0,gti=gti);
    }
    else if(qualifier_exists("exact")) {
      pp = parallel_map(Struct_Type, &pfold, p ;
			t=t, p=p, nbins = nbins, dt = dt, chatty=chatty, t0=t0, exact);
    }
    else {
      pparr = parallel_map(Struct_Type, &pfold, p  ;
			   t=t,r=r, pdot=pdtest, nbins = nbins, dt = dt, chatty=chatty, t0=t0);
    }

    _for i (0, ergdim-1, 1)
    {
      pp = pparr[i];
      ptest = p[i];

      finitepp = wherenot(isnan(pp.value) or isinf(pp.value));

      if (length(finitepp) < nbins) {
	vmessage("WARNING: period %f has faulty phase bins! Ignoring those phase bins, but please check!", ptest);
	faulty = [faulty, i];
	struct_filter(pp, finitepp);
      };

      if (eventdata) chierg[i,j] =  sum((pp.value-mean(pp.value))^2. / mean(pp.value));
      else if (qualifier_exists("lstat"))
      {
	% see Davies Eq. 11
	chierg[i,j] = factor * ( sum(pp.npts*pp.value^2))/(sum (pp.error*(pp.npts-1.)));
      }
      else
      {
	% see Davies Eq. 4 or Larsson Eq. 1
	chierg[i,j] =  sum(pp.npts*pp.value^2.)/rm.var;
      }

      if (chatty)
      {
	if (_time()-tlast > 10)
	{
	  tlast=_time();
	  titer = (tlast-tstart)/double(j);
	  remain=(ergdim-j)*titer;

	  vmessage("%.2f%% done", j*100./ergdim );
	  vmessage("its taking %.2fsec per iteration", titer);

	  if (remain <= 600) vmessage("%.2f sec remaining...", remain);
	  else if (remain <= 7200) vmessage("%.2f min remaining...", remain/60.);
	  else vmessage("%.2f h remaining...", remain/3600.);
	}
      }
    }

  }

  %structure containing searched periods, statistics value,
  %phasebins used and indices of periods with gaps in the pulse profile
  return struct{ p=p,pd=pd, stat=chierg, nbins=nbins, badp = faulty };
}
