% -*- mode: slang; mode: fold -*-

require("gsl","gsl");

% There are also plot function which uses the
% xfig module to create eps-files
require("xfig");


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_det()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_det}
%\synopsis{Determines the arrival times from a lightcurve using a pulse pattern}
%\usage{Struct_Type atime_det(Struct_Type lc, Struct_Type[] pattern, Double_Type t0, Struct_Type ephemeris[, Struct_Type orbit]);
% or Struct_Type atime_det(String_Type lc, Struct_Type[] pattern, Double_Type t0, Double_Type[] period[, Struct_Type orbit]);}
%\qualifiers{
%    \qualifier{time}{name of the time field in the FITS-file,
%             see fits_read_lc for details}
%    \qualifier{indiv}{determine individual pulses. If no value
%             is assigned, all arrival times are re-
%             turned. Otherwise a given integer sets
%             the number of pulses to average}
%    \qualifier{movem}{if 'indiv' is greater one, so it is averaged
%             over a number of arrival times, a
%             moving mean is used to get all individual
%             pulses. Note that the pulses are then not
%             statistically independent!}
%    \qualifier{ccfint}{interpolates the cross correlation of the
%             pulse pattern and the actual analyzed
%             pulse to increase the accuracy. Only works
%             well for clear signals! The number of
%             interpolated bins between each original
%             bin is set to the assigned number
%             (default = 4)}
%    \qualifier{varerr}{estimates the error by a local standard
%             deviation. Therefore the variation of the
%             given number of arrival times is used
%             (default = 10)}
%    \qualifier{mcerr}{estimates the error of each arrival time
%             by performing Monte Carlo simulations. If
%             an integer is assigned it sets the number
%             of runs (default = 10000). Has a higher
%             priority than 'varerr'}
%    \qualifier{mcgaus}{fit a gaussian to the Monte Carlo distri-
%             bution, if used for error estimation}
%    \qualifier{getpat}{if multiple patterns are given, the index
%             of the used one is stored in this variable,
%             which has to be given as a reference (@var)}
%    \qualifier{match}{reference to a variable (&var) where the
%             matching pulses are saved as structures
%             similar to the reference profile}
%    \qualifier{ccflim}{matches below the given cross-correlation
%             values are skipped (default = 0), allowed
%             range is -1 to 1.}
%    \qualifier{chatty}{boolean value for output messages
%             (default = 1). If set to 2, also echo
%             result of Monte Carlo error estimation}
%    \qualifier{debug}{plot the cross correlation and the matching
%             pulse, echo the found phase shift and
%             sleep the given seconds (default = 1) or,
%             if set to 'user' wait until a key is
%             pressed}
%}
%\description
%    Using one or more pulse pattern the arrival times
%    of pulses in a lightcurve are determined using
%    phase connection. The pattern must be given as a
%    structure with the fields
%      Double_Type bin_lo
%      Double Type bin_hi
%      Double_Type value
%      Double_Type error,
%    as, for example, returned by the 'epfold' function.
%    The lightcurve can be passed by a structure with
%    the fields 'time', 'rate', 'error' and 'fracexp',
%    or by the filename to a FITS-file.
%    To transform the phase shift to time, the pulse
%    period at the actual position in the lightcurve is
%    needed. For a first guess this may be a constant
%    value (in seconds) or an array of two elements
%    defining a range of periods (min/max values, in
%    seconds). In the latter case the pulse period is
%    searched by using the 'getVarPeriod' function and
%    additional qualifiers are passed. However, the
%    correct way is to pass the pulse ephemeris and
%    additional orbital parameters to calculate the
%    pulse poriod more precisely. The corresponding
%    structures are described in the 'check_pulseperiod_orbit_struct'
%    function. The values may be found by a fit to the
%    arrival times using a constant pulse period. This
%    leads to slightly different results, hence the
%    determination of the arrival times and their
%    analysis is an iterative procedure.
%    If the 'indiv' qualifier is omitted the given
%    lightcurve is folded and the returned arrival
%    time corresponds to the phase shift of the given
%    pattern to the resulting profile.
%    If the method for estimating the uncertainty of
%    the arrival times is not specified by qualifiers,
%    the default uncertainty is set to one phase bin.
%    The number of bins are derived from the given
%    pulse pattern.
%    The returned structure has the following fields:
%    arrtimes - array of determined arrival times (MJD)
%    error    - their uncertainties (days)
%    arrnum   - relative pulse number of each arrival
%               time to a specific pulse. Dramatically
%               increases the speed of a fit.
%    numref   - index of the reference pulse, should be
%               zero. Is updated if arrival times are
%               merged.
%    reft0    - the given reference time t0
%\seealso{atime_merge, save_atime, define_atime, arrtimes, pfold}
%!%-
{
 variable lcF, refprof, reft0, per, orb = NULL;
 switch(_NARGS)
   { case 4: (lcF,refprof,reft0,per) = (); }
   { case 5: (lcF,refprof,reft0,per,orb) = (); }
   { help(_function_name()); return; }

 variable t0found = 0;
 variable timefield = qualifier("time","time");
 variable chatty = qualifier("chatty",1);
 if (chatty == NULL) chatty = 1;
 variable indiv = qualifier("indiv", 1);
 if (indiv == NULL) indiv = 1;
 indiv = [qualifier_exists("indiv"), indiv, qualifier_exists("movem") && indiv > 1];
 variable ccflim = qualifier("ccflim", 0.);
 ifnot (-1 <= ccflim <= 1) { vmessage("warning (%s): given ccf limit is outside the allowed range, using default value", _function_name); ccflim = 0.; }
 variable ccfint = qualifier("ccfint", 1);
 if (ccfint == NULL) ccfint = 10;
 variable mcerr = qualifier("mcerr", 0);
 if (mcerr == NULL) mcerr = 10000;
 variable varerr = qualifier("varerr", 0);
 if (varerr == NULL) varerr = 10;
 if (varerr != 0 && varerr < 2) { vmessage("warning (%s): need at least 2 datapoints to determine error by local variance", _function_name); varerr = 2; }
 if (varerr > 0 && mcerr > 0) varerr = 0;
 variable matchret = qualifier("match", NULL);
 if (typeof(matchret) == Ref_Type) % initialise return structure for matches
   @matchret = Struct_Type[0];
 else ifnot (typeof(matchret) == Null_Type) { vmessage("warning (%s): 'match' has to be of Ref_Type", _function_name); matchret = NULL; }
 variable getpat = qualifier("getpat", NULL), usedpat;
 ifnot (typeof(getpat) == Ref_Type or typeof(getpat) == Null_Type) { vmessage("warning (%s): 'getpat' has to be of Ref_Type", _function_name); getpat = NULL; }
 
 variable debug = qualifier("debug", -1);
 if (debug == NULL) debug = 1;
  
 % load lightcurve if not already given
 variable lc, lco;
 if (typeof(lcF) == String_Type)
 {
   lc = fits_read_lc(lcF;time=timefield);
   % convert fracexp to totalexp
   lc.fracexp = fits_lc_exposure(lcF)*lc.fracexp/86400.;
 } else lc = @lcF; % lc already given
 lco = @lc;

 % sort lc by time
 lc = sort_struct_arrays(lc, "time");

 % check if the period has to be estimated by Epoch Folding
 if (typeof(per) == Array_Type and length(per) == 2)
 {
   if (chatty) message("Determining pulse period of lightcurve");  
   per = getVarPeriod(lc, per[0]/86400, per[1]/86400;; struct_combine(__qualifiers, struct { dt=lc.fracexp }));
   if (chatty) vmessage("  p_lc  = %f s", per*86400);
   per = check_pulseperiod_orbit_struct(per*86400);
 }
 else if (typeof(per) == Double_Type) { per = struct { p0 = per, t0 = reft0 }; }
 else if (typeof(per) == Struct_Type && check_pulseperiod_orbit_struct(per) == 0) {
   vmessage("error (%s): pulse period structure not consistent with its definition", _function_name);
   return;
 }
 else { vmessage("error (%s): pulse period must be a single double type, a two element array or a structure", _function_name); }
 ifnot (orb == NULL || check_pulseperiod_orbit_struct(orb)) { vmessage("error (%s): orbit structure not given properly", _function_name); return; }
   
 % renorm reference profile(s)
 variable p;
 _for p (0, length(refprof)-1, 1)
 {
   refprof[p].error = refprof[p].error/(max(refprof[p].value)-min(refprof[p].value));
   refprof[p].value = (refprof[p].value-min(refprof[p].value))/(max(refprof[p].value)-min(refprof[p].value));
 }

 variable nums;
 variable nbins = length(refprof[0].value);
 if (indiv[0]) % prepare section to find individual pulses
 {
   % number of pulses in lc to look for
   nums = ceil((max(lc.time)-min(lc.time)) / per.p0 * 86400);
   ifnot (indiv[2]) nums = nums / indiv[1]; % reduced number by no moving mean
   nums = int(nums);
   % rebin lightcurve similar to profile if ALL pulses have to be found
   if (indiv[1] == 1) lc = rebin_lc(lc, per.p0 / 86400 / nbins);
 }
 else nums = 1;
 % loop over number of pulses (except if using profile only)
 % to get the pulse arrival times
 if (chatty) message("Getting pulse arrival times");
 variable i, f, t0, ccf, dphi, ddphi, ndx, j=0, lasttime = NULL, lastnum, acttime, actnum, ir = NULL;
 variable atimes = Double_Type[0], datimes = Double_Type[0], npuls = Integer_Type[0], refpuls = Integer_Type[0];
 _for i (0, nums-1, 1)
 {
   % determine arrival times of (each) individual pulses
   if (indiv[0])
   {
     % find actual pulse part of lc (attend moving mean, indiv[2]==1)
     if (indiv[2]) ndx = where(lc.time[0] + per.p0/86400*i <= lc.time < lc.time[0] + per.p0/86400*(i+indiv[1]));
     else ndx = where(lc.time[0] + per.p0/86400*i*indiv[1] <= lc.time < lc.time[0] + per.p0/86400*(i+1)*indiv[1]);
     % only use if number of bins are correct and ALL pulses have to be found
     if (length(ndx) == nbins && indiv[1] == 1)
     {
       t0 = lc.time[ndx[0]];
       % extract part
       f = struct { value = lc.rate[ndx], error = lc.error[ndx], bin_lo = (lc.time[ndx]-lc.time[ndx[0]]) * 86400 / per.p0, bin_hi = NULL };
       f.bin_hi = make_hi_grid(f.bin_lo);
       j++;
     }
     % average over given number of pulses by folding the lightcurve
     else if (length(ndx) >= nbins && indiv[1] > 1)
     {
       t0 = lc.time[ndx[0]];
       f = pfold(lc.time[ndx], lc.rate[ndx], per.p0/86400, lc.error[ndx];; struct_combine(__qualifiers, struct { nbins = nbins, dt=lc.fracexp[ndx], t0=t0 }));
       if (sum(isnan(f.value)) > 0) f = NULL;
       else j++;
     }
     else f = NULL;
   }
   % arrival time of the pulse profile
   else
   {
     if (chatty) message("  -> pulse profile");
     t0 = lc.time[0];
     % create profile
     f = pfold(lc.time, lc.rate, per.p0/86400, lc.error;; struct_combine(__qualifiers, struct { nbins = nbins, dt=lc.fracexp, t0=t0 }));
     ndx = [0,length(lc.time)-1];
   }

   ifnot (f == NULL)
   {
     % renorm profile / lc part
     f.error = f.error/(max(f.value)-min(f.value));
     f.value = (f.value-min(f.value))/(max(f.value)-min(f.value));
     % loop over all given pattern
     variable ccfmax = -2.;
     _for p (0, length(refprof)-1, 1)
     {
       variable tempccf = CCF_1d(refprof[p].value, f.value);
       % assign cross-correlation in case of a better match
       if (max(tempccf) > ccfmax)
       {
	 ccf = @tempccf;
	 ccfmax = max(tempccf);
	 usedpat = p;
         if (typeof(getpat) == Ref_Type) @getpat = usedpat;
       }
     }
     if (chatty == 2)
     {
       vmessage("  -> cross-correlation is %.3f", max(ccf));
       if (length(refprof) > 1) vmessage("     with pulse pattern no. %d", usedpat);
     }
     % check on ccf limit
     if (max(ccf) < ccflim)
     {
       ccf[0] = _NaN;
       message("  -> below the given limit and SKIPPED");
     }
     ifnot (isnan(ccf[0]))
     {
       % calculate the actual pulse period
       variable pact = pulseperiod(t0, per, orb);

       % get reference pulse number, if not set
       % (is needed if pulse number 0 had less nbins than required)
       if (ir == NULL) ir = i;

       %%% PULSE ARRIVAL TIME DETERMINATION %%%
       variable tstart = lc.time[ndx[0]], tstop = lc.time[ndx[-1]];
       ndx = 0;
       % periodic borders
       ccf = [ccf, ccf[0]];
       if (qualifier_exists("debug"))
       {
	 xrange; xlabel("Phase Shift"); title("Result of Cross Correlation");
	 yrange(-1,1); ylabel("Correlation");
	 connect_points(0);
	 point_style(4);
	 color(1);
	 plot(1.*[0:nbins]/nbins, ccf);
       }
#ifexists gsl->interp_cspline
       if (ccfint > 1)% && t0 != reft0) % interpolate the ccf result to get the position more properly
       {
	 % interpolate
         ccf = gsl->interp_cspline_periodic([0:length(ccf)-1:1./ccfint], [0:length(ccf)-1], ccf);
	 if (qualifier_exists("debug"))
	 {
	   color(4); point_style(-1);
	   connect_points(1);
	   oplot(1.*[0:length(ccf)-1] / (length(ccf) - 1), ccf);
	 }
       }
#endif
       % calculate phase shift
       dphi  = 1.*where_max(ccf) / (length(ccf)-1);
       if (length(dphi) > 1) dphi = min(dphi);
       if (dphi == 1.) dphi = 0.;
       if (qualifier_exists("debug"))
       {
	 vmessage("  phase shift: %.3f", dphi);
	 color(2); connect_points(1); point_style(-1);
	 oplot([dphi,dphi],[-1,1]);
	 if (typeof(debug) == String_Type && debug == "user") ()=keyinput(;silent, nchr=1);
	 else sleep(debug);
	 color(1); xlabel("Pulse Phase"); xrange;
	 ylabel("Normalized Count Rate"); title("Aligned Pulse and Reference");
	 yrange(min([f.value-f.error,refprof[usedpat].value-refprof[usedpat].error]),
		max([f.value+f.error,refprof[usedpat].value+refprof[usedpat].error]));
         hplot_with_err(f.bin_lo, f.bin_hi, shift(f.value, -int(dphi*nbins)), shift(f.error, -int(dphi*nbins)));
	 ohplot_with_err(refprof[usedpat]);
	 if (typeof(debug) == String_Type && debug == "user") ()=keyinput(;silent, nchr=1);
	 else sleep(debug);
       }
       % set relative pulse number
       if (indiv[2]) actnum = i-ir;
       else actnum = (i-ir) * indiv[1];
       % add match to returning structure array (if set)
       if (typeof(matchret) == Ref_Type) 
         @matchret = [@matchret, struct { bin_lo = f.bin_lo, bin_hi = f.bin_hi, value = shift(f.value, -int(dphi*nbins)),
	                                  error = shift(f.error, -int(dphi*nbins)), ccf = max(ccf), tstart = tstart, tstop = tstop }];
       % transform phase shift into arrival time
       acttime = t0 + (1.-dphi)*pact/86400;
       % check if arrival times does not match the pulse number
       ifnot (lasttime == NULL)
       {
	 variable is = (acttime-lasttime)*86400/pact;
	 variable should = actnum-lastnum;
       	 if (abs(is - should) > qualifier("phidif", .2))
       	 {
       	   if (qualifier_exists("debug")) vmessage("  phidif is %.3f, should be %.3f -> shifting time", is, should);
       	   acttime = acttime - round(is-should) * pact/86400;
       	 }
	 else if (qualifier_exists("debug")) vmessage("  phidif is %.3f, should be %.3f", (acttime-lasttime)*86400/pact, actnum-lastnum);
       }
       lasttime = acttime;
       lastnum = actnum;
       atimes = [atimes, acttime];
       npuls = [npuls, actnum];
       refpuls = [refpuls, 0];

       %%% ERROR ESTIMATION %%%
       ddphi = NULL;
#ifexists gsl->interp_cspline
       if (mcerr > 1 && ccfint > 1) % estimate error using Monte Carlo techniques
       {
	 variable mc, lo, hi, dphis = Double_Type[mcerr], mphi, lphi = NULL;
	 variable fm = Double_Type[length(f.value)];
	 variable refm = Double_Type[length(refprof[usedpat].value)];
	 _for mc (0, mcerr-1, 1) % MC loop
	 {
	   % random noisy profile
	   fm = f.value + grand(length(fm)) * f.error;
	   refm = refprof[usedpat].value + grand(length(refm)) * refprof[usedpat].error;
           % cross correlate
           ccf = CCF_1d(refm,fm);
	   % periodic borders
	   ccf = [ccf, ccf[0]];
	   ccf = gsl->interp_cspline_periodic([0:length(ccf)-1:1./ccfint], [0:length(ccf)-1], ccf);
	   % get shift
	   mphi = 1.*where_max(ccf) / (length(ccf)-1);
           if (length(mphi) > 1) mphi = min(mphi);
           if (mphi == 1.) mphi = 0.;
	   % check on phase shifts greater 1
%	   ifnot (lphi == NULL) if (abs(lphi - mphi) > 2.*qualifier("phidif", .2)) mphi = mphi + 1.*sign(lphi-mphi);
	   lphi = mphi;
	   dphis[mc] = mphi;
	 }
	 % do a gaussian fit to the distribution
	 if (qualifier_exists("mcgaus"))
	 {
	   variable x_lo = [0.:2.-1./sqrt(mcerr):1./sqrt(mcerr)];
           variable x_hi = x_lo + x_lo[1];
           variable h = histogram(dphis, x_lo, x_hi);
   	   ddphi = array_fit_gauss(x_lo, h,, x_lo[where_max(h)[0]], moment(dphis).sdev, 1000; frz=[0,0,0,1]).sigma;
	   ddphi = ddphi * pact / 86400;
	 }
	 else ddphi = moment(dphis).sdev * pact / 86400;

	 if (chatty == 2) vmessage("  -> estimated error = %f phases", ddphi/pact*86400);
	 if (qualifier_exists("debug") && qualifier_exists("mcgaus"))
	 {
	   xrange(0,2); yrange(0,1.1*max(h)/sum(h));
	   xlabel("Phase Shift"); ylabel("Number Density");
	   color(1);
	   hplot(x_lo, x_hi, h/sum(h));
           if (typeof(debug) == String_Type && debug == "user") ()=keyinput(;silent, nchr=1);
	   else sleep(debug);
	 }
	 
         datimes = [datimes,ddphi];
       }
       else if (varerr > 0)
#else
       if (varerr > 0) % estimate error by a local mean
#endif
       {
	 % calculate local variance
	 ndx = [((length(atimes) - 1) / varerr) * varerr: length(atimes) - 1]; % indices of last #varerr-1 number of datapoints
	 ddphi = moment((atimes[ndx] - atimes[ndx-1]) / (npuls[ndx] - npuls[ndx-1])).sdev;
	 if (length(ndx) == varerr)
	 {
           if (chatty == 2) vmessage("  -> estimated error = %f phases", ddphi/pact*86400);
           datimes = [datimes, ddphi * ones(length(ndx))];
	 }
       }
       else datimes = [datimes, pact/86400/nbins]; % if no error was estimated: error = 1 phase bin
     }
   }
 }
 % set remaining errors for local variance
 if (varerr > 0 && length(datimes) < length(atimes))
 {
   if (length(ndx) == 1 || ddphi == 0.0) ddphi = pact/86400/nbins;
   else if (length(ndx) < varerr/2 && length(datimes) > 0) ddphi = datimes[length(datimes)-1];
   datimes = [datimes, ddphi * ones(length(atimes)-length(datimes))];
   if (chatty == 2) vmessage("  -> estimated error = %f phases", ddphi/pact*86400);
 }
 if (indiv[0] and chatty) vmessage("  -> individual pulses (%d/%d)", j, int(nums));

 return struct { arrtimes = atimes, error = datimes, arrnum = npuls, numref = refpuls, reft0 = reft0 };
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_merge()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_merge}
%\synopsis{merges two or more structures of arrival times into one}
%\usage{Struct_Type atime_merge(Struct_Type atime1, Struct_Type atime2);
% or Struct_Type atime_merge(Struct_Type[] atime);}
%\qualifiers{
%    \qualifier{nosort}{do not sort the merged arrival times}
%}
%\description
%    Either both given structures or an array of
%    structures containing arrival times are merged.
%    The fields of the structures must be equal to
%    the ones described in 'atime_det'.
%    The relative pulse numbers and their references
%    are updated to the indices of the new array of
%    arrival times. In addition the arrival times are
%    sorted by time unless the 'nosort' qualifier is
%    given.
%\seealso{atime_det}
%!%-
{
 variable a1, a2 = NULL;
 switch(_NARGS)
   { case 1: (a1) = (); }
   { case 2: (a1,a2) = (); }
   { help(_function_name()); return; }
 if (__is_initialized(&a1)) a1 = @a1;
 ifnot (a2 == NULL) a2 = @a2; 

 % check on correct parameters
 if (a2 == NULL && _typeof(a1) != Struct_Type)
   throw RunTimeError, sprintf("error (%s): need an array of structures", _function_name);
 if (a2 != NULL && (length(a1)+length(a2) > 2 || (typeof(a1) != Struct_Type && _typeof(a2) != Struct_Type)))
   throw RunTimeError, sprintf("error (%s): need two single structures", _function_name);
 
 % merge structures
 variable merg, i, reft0 = NULL;
 if (a2 == NULL) % array given
 {
   if (length(a1) > 1)
   {
     _for i (1, length(a1)-1, 1)
     {
       a1[i].numref += length(a1[i-1].numref); % shift reference numbers
       if (reft0 == NULL) reft0 = a1[i-1].reft0;
       else ifnot (reft0 == a1[i-1].reft0) vmessage("warning (%s): reference times of matching profile are not equal", _function_name);
     }
     merg = merge_struct_arrays(a1);
     merg.reft0 = reft0;
   }
   else merg = a1;
 }
 else % two structures given
 {
   ifnot (__is_initialized(&a1)) merg = a2;
   else ifnot (__is_initialized(&a2)) merg = a1;
   else
   {
     % a2.arrtimes = a2.arrtimes - shift; % correct arrival times
     a2.numref += length(a1.numref); % shift reference numbers
     if (a1.reft0 == a2.reft0) reft0 = a1.reft0;
     else vmessage("warning (%s): reference times of matching profile are not equal", _function_name);
     merg = merge_struct_arrays([a1,a2]);
     merg.reft0 = reft0;
   }
 }
 
 % sort by time
 ifnot (qualifier_exists("nosort"))
 {
   variable ndx = array_sort(merg.arrtimes), nr = @(merg.numref);
   merg.arrtimes = merg.arrtimes[ndx];
   merg.error = merg.error[ndx];
   merg.arrnum = merg.arrnum[ndx];
   _for i (0, length(nr)-1, 1) merg.numref[i] = wherefirst(ndx == nr[ndx[i]]); % update reference numbers
 }

 return merg;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define save_atime()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{save_atime}
%\synopsis{saves a structure of arrival times into a FITS-file}
%\usage{save_atime(String_Type filename, Struct_Type atime, String_Type extname[, String_Type[] comments]);}
%\qualifiers{
%    \qualifier{obj}{observed object, written into FITS header}
%    \qualifier{sat}{used satellite, written into extension header}
%    \qualifier{nfold}{number of arrival times, which were merged
%              during the determination. Corresponds to the
%              'indiv' qualifier for the 'atime_det' function.
%              Written into extension header}
%    \qualifier{hfits}{structure for additional FITS-header fields}
%    \qualifier{hext}{structure for additional extension-header fields}
%    \qualifier{newfile}{if the given filename exists a new file is
%              created instead of updating the existing one}
%    \qualifier{newext}{if the given extension already exists in the
%              FITS-file a further one with the same name is
%              added instead of updating the existing one}
%}
%\description
%    A structure of arrival times, e.g. as returned by the
%    'atime_det' function, is save into the given FITS-file
%    creating or updating the extension of the geiven name.
%    Most of the qualifiers allow to store addiotional
%    informations into the header of the FITS-file or the
%    extension. The optional fourth parameter can be used
%    to write additional comments into the FITS-file.
%\seealso{atime_det, atime_merge, load_atime}
%!%-
{
 variable file, atimes, ext, comm;
 switch(_NARGS)
   { case 3: (file,atimes,ext) = (); comm = NULL; }
   { case 4: (file,atimes,ext,comm) = (); }
   { help(_function_name()); return; }
 variable object = qualifier("obj", NULL);
 variable sat = qualifier("sat", NULL);
 variable nfold = qualifier("nfold", NULL);
 variable hfits = qualifier("hfits", NULL);
 variable htabl = qualifier("hext", NULL);
 variable doup = not qualifier_exists("newfile");
 variable doov = not qualifier_exists("newext");

 % store pulse index of matching profile (dphi != 0)
 variable reft0 = atimes.reft0;
 
 % create fits file, if it does not exist
 variable fp, i;
 if (access(file, F_OK)==0 && doup) fp = fits_open_file(file,"w");
 else { fp = fits_open_file(file,"c"); doup = 0; }
  
 % fits header
 ifnot (doup)
 {
   fits_create_image_hdu(fp, NULL, 0, 0);
   if (object != NULL) fits_update_key(fp, "OBJECT", object, "observed OBJECT");
   % additional fits header informations
   if (typeof(hfits) == Struct_Type)
     _for i (0, length(get_struct_field_names(hfits))-1, 1)
       fits_update_key(fp, get_struct_field_names(hfits)[i], get_struct_field(hfits, get_struct_field_names(hfits)[i]));
 }
  
 % eventually delete existing table of same extension
 if (doov && _fits_movnam_hdu(fp, -1, ext, 0)==0) ()=_fits_delete_hdu(fp);  
 % create table of arrival times
 fits_write_binary_table(fp, ext, reduce_struct(atimes,"reft0"));
 % table header
 if (sat != NULL) fits_update_key(fp, "SATELLIT", sat, "used SATELLITE(S)");
 fits_update_key(fp, "TUNIT1", "MJD", "physical unit of field 1");
 fits_update_key(fp, "TUNIT2", "MJD", "physical unit of field 2");
 fits_update_key(fp, "TUNIT3", "rel. pulse number", "physical unit of field 3");
 fits_update_key(fp, "TUNIT4", "reference index", "physical unit of field 4");
 fits_update_key(fp, "REFT0", reft0, "reference time of matching profile");
 if (nfold != NULL) fits_update_key(fp, "NFOLD", nfold, "number of pulses used for folding");
 % additional table header informations
 variable htn, htk;
 if (typeof(htabl) == Struct_Type)
 {
   htn = get_struct_field_names(htabl);
   _for i (0, length(htn)-1, 1)
   {
     htk = get_struct_field(htabl, htn[i]);
     if (length(htk)==1) fits_update_key(fp, htn[i], htk);
     else fits_update_key(fp, htn[i], htk[0], htk[1]);
   }
 }
 % comments
 if (typeof(comm) != Array_Type) comm = [comm];
 if (_typeof(comm) == String_Type)
   _for i (0, length(comm)-1, 1) fits_write_comment(fp, comm[i]);
 fits_close_file(fp);
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define load_atime()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{load_atime}
%\synopsis{loads a structure containing arrival times from a FITS-file}
%\usage{Struct_Type load_atime(String_Type filename, String_Type extname);}
%\description
%    The arrival times, which were stored previously by
%    'save_atime', are loaded and returned as a structure.
%    This structure has the fields described in the
%    'atime_det' function. The extension table containing
%    the arrival times must be specified as well as the
%    FITS-file itself.
%\seealso{save_atime, atime_det}
%!%-
{
 variable file, ext;
 switch(_NARGS)
   { case 2: (file,ext) = (); }
   { help(_function_name()); return; }

 variable fp = fits_open_file(file, "r");
 variable atimes, reft0;
 % move to extension and load table
 if (_fits_movnam_hdu(fp, _FITS_BINARY_TBL, ext, 0)==0) atimes = fits_read_table(fp); else atimes = NULL;
 ifnot (atimes == NULL)
 {
   reft0 = fits_read_key(fp, "REFT0");
   atimes = struct_combine(atimes, struct { reft0 = reft0 });
 }
 else vmessage("error (%s): extension '%s' not found in binary table", _function_name, ext);

 fits_close_file(fp);
 return atimes;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_metavalid(ind)
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_metavalid}
%\synopsis{checks if a given dataset of arrival times contains valid metadata}
%\usage{Integer_Type[] atime_metavalid(Integer_Type index);}
%\description
%    If a dataset of arrival times is defined using the
%    'define_atime' function, there are also a lot of
%    addiotional needed informations defined in the
%    metadata. These are used by fitting the data by the
%    'arrtimes' fit function. This function can be used
%    to find all defined data containing arrival times,
%    which is implemented in 'atime_dataind'.
%\seealso{define_atime, arrtimes, get_dataset_metadata, atime_dataind}
%!%-
{
  ifnot (typeof(ind) == Array_Type) ind = [ind];
  variable i, ok = 0;
  foreach i (ind)
  {
    variable metadata = struct_copy(get_dataset_metadata(i));
    if (typeof(metadata) == Struct_Type)
    {
      if (
           struct_field_exists(metadata, "datapnum")
        && struct_field_exists(metadata, "refpnum")
        && struct_field_exists(metadata, "reft0")
        && struct_field_exists(metadata, "modelpnum")
        && struct_field_exists(metadata, "notice")
        && struct_field_exists(metadata, "id")
        && struct_field_exists(metadata, "useref")
        && struct_field_exists(metadata, "shiftref")
        && struct_field_exists(metadata, "freeparams")
      ) ok += 1;
    }
  }
  if (length(ind) == ok) return 1;
  else return 0;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_dataind()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_dataind}
%\synopsis{returns the datasets, which contain arrival times}
%\usage{Integer_Type[] atime_dataind();}
%\description
%    Loops over all defined datasets and checks, which
%    are containing arrival times. Therefore the function
%    'atime_metavalid' is used. If no dataset is found,
%    the function returns NULL.
%\seealso{atime_metavalid, define_atime}
%!%-
{
 variable i, ind = Integer_Type[0];

 foreach i (all_data)
   if (atime_metavalid(i)) ind = [ind, i];
 
 return length(ind) == 0 ? NULL : ind;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define xnotice_atime()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{xnotice_atime}
%\synopsis{notices a range of defined arrival times}
%\usage{xnotice_atime(Integer_Type index[, Double_Type time_lo, Double_Type time_hi]);
% or xnotice_atime(Integer_Type index, Double_Type time);
% or xnotice_atime(Double_Type time);}
%\description
%    There are three different ways to notice the time
%    range of arrival times defined in a dataset:
%    1. Like 'xnotice' set the time range of dataset
%       'index' explicitly from 'time_lo' to 'time_hi'.
%    2. Find the border of the time range of dataset
%       'index' nearest to the given time. Then set
%       the found border to this time. The border of
%       a possible adjacent dataset is changed respect-
%       ively.
%    3. Find that dataset, which time range has the
%       nearest border to the given time and proceed
%       like option two.
%    If the dataset only is given, then the full time
%    range is used.
%\seealso{define_atime, xnotice}
%!%-
{
 variable ind = NULL, cut = NULL, mn = NULL, mx;
 switch(_NARGS)
   { case 1: (cut) = (); }
   { case 2: (ind,cut) = (); }
   { case 3: (ind,mn,mx) = (); }
   { help(_function_name()); return; }

 variable meta, dc, nind = atime_dataind;
 if (typeof(nind) == Null_Type) { vmessage("warning (%s): no datasets containing arrival times defined", _function_name); return; }
 % check if the full range of a specific dataset should be used
 if (typeof(cut) == Integer_Type && ind == NULL)
 {
   ifnot (wherefirst(nind == cut) == NULL) % dataset found
   {
     dc = get_data_counts(cut);
     meta = struct_copy(get_dataset_metadata(cut));
     meta.notice = [dc.value[0],dc.value[length(dc.value)-1]];
     set_dataset_metadata(cut, meta);
     xnotice(cut, dc.bin_lo[0], dc.bin_hi[length(dc.bin_hi)-1]);
     return;
   }
   else { vmessage("error (%s): dataset %d not found or does not contain arrival times", _function_name, cut); return; }
 }
 % if only one dataset exists skip ind parameter (for option 2)
 if (length(nind) == 1 && ind != NULL && cut != NULL) { mn = ind; mx = cut; ind = nind[0]; }
 % cut adjacent segments at given time (only 'cut' given)
 % or cut given segment and adjacent one
 if (ind == NULL || (ind != NULL && mn == NULL))
 {
   variable noti, dif, ndx, i;
   dif = Double_Type[length(nind),2]; % [distance to given time, left/right border]
   _for i (0, length(nind)-1, 1)
   {
     noti = struct_copy(get_dataset_metadata(nind[i])).notice;
     dif[i,*] = [min(abs(noti - cut)), where_min(abs(noti - cut))];
   }
  
   if (ind == NULL) % find the two datasets closest to given time
   {   
     if (length(nind) > 1) ndx = array_sort(dif[*,0])[[0,1]]; % select two closests one
     else ndx = 0; % only one dataset given
     dif = dif[ndx,*];
     nind = nind[ndx];
   }
   else % find adjacent dateset to given one
   {
     ndx = array_sort(dif[*,0]);
     if (length(ndx)>2) { dif[1,*] = dif[ndx[2],*]; nind[1] = nind[ndx[2]]; } % select third closest one (-> adjacent dataset)
     else nind = Integer_Type[1];
     % select border of given dataset
     dif[0,*] = [0.0, where_max(abs(noti - cut))];
     nind[0] = ind;
     % check if given time is inside interval of given dataset
     noti = struct_copy(get_dataset_metadata(ind)).notice;
     ifnot (noti[0] < cut < noti[1]) { vmessage("warning (%s): given time outside of dataset", _function_name); return; }
   }
   % set new borders and notice
   % first check if given time is enclosed by dataset (left border smaller cut)
   meta = struct_copy(get_dataset_metadata(nind[0]));
   if (meta.notice[0] < cut)
   {
     meta.notice[int(dif[0,1])] = double(cut);
     xnotice(nind[0], meta.notice[0], meta.notice[1]);
     set_dataset_metadata(nind[0], meta);
     dc = get_data_counts(nind[0]);
     ndx = where(meta.notice[0] <= dc.value <= meta.notice[1]);
     xnotice(nind[0], dc.bin_lo[ndx[0]], dc.bin_hi[ndx[length(ndx)-1]]);
   }
   if (length(nind) > 1)
   {
     meta = struct_copy(get_dataset_metadata(nind[1]));
     meta.notice[int(dif[1,1])] = double(cut);
     set_dataset_metadata(nind[1], meta);
     dc = get_data_counts(nind[1]);
     ndx = where(meta.notice[0] <= dc.value <= meta.notice[1]);
     if (length(ndx) > 0) xnotice(nind[1], dc.bin_lo[ndx[0]], dc.bin_hi[ndx[length(ndx)-1]]);
     else xnotice(nind[1], 0, 0);
   }
 }
  
 % notice by given borders
 if (mn != NULL)
 {
   if (typeof(ind) != Array_Type) ind = [ind];
   _for i (0, length(ind)-1, 1)
   {
     meta = struct_copy(get_dataset_metadata(ind[i]));
     meta.notice = double([mn, mx]);
     set_dataset_metadata(ind[i], meta);
     dc = get_data_counts(ind[i]);
     ndx = where(mn <= dc.value <= mx);
     if (length(ndx) > 0) xnotice(ind[i], dc.bin_lo[ndx[0]], dc.bin_hi[ndx[length(ndx)-1]]);
     else xnotice(nind[i], 0, 0);
   }
 }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_useref()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_useref}
%\synopsis{switches the use of a reference pulse number}
%\usage{atime_useref(Integer_Type[] dataid[, Integer_Type boolean]);}
%\description
%    While fitting pulse arrival times the pulse number
%    of each pulse must be determined. By using the
%    atime_det function to determine the arrival times
%    each pulse gets a pulse number relative to the
%    first pulse found in the input lightcurve. Once
%    the pulse number of this reference pulse is deter-
%    mined during a fit, the numbers of all other pulses
%    are also set. Using this function the use of rela-
%    tive pulse numbers during a fit can be turned off
%    (boolean=0) or on (boolean=1, default).
%\seealso{arrtimes, atime_det, atime_shiftref}
%!%-
{
 variable i, id, st, meta;
 switch(_NARGS)
   { case 1: (id) = (); st = NULL; }
   { case 2: (id,st) = (); }
   { help(_function_name()); return; }

 if (typeof(id) != Array_Type) id = [id];
 % loop over ids
 _for i (0, length(id)-1, 1)
 {
   if (atime_metavalid(id[i]))
   {
     meta = struct_copy(get_dataset_metadata(id[i]));
     if (st == NULL) meta.useref = 0;
     else meta.useref = (st == 1);
     set_dataset_metadata(id[i], meta);
   }
 }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_shiftref()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_shiftref}
%\synopsis{switches the shift of the reference pulse number}
%\usage{atime_shiftref(Integer_Type[] dataid[, Integer_Type boolean]);}
%\description
%    While fitting pulse arrival times a reference pulse
%    number may be used. The reference pulse is the
%    first one of the dataset, but while fitting it is
%    by default shifted to the pulse nearest to the
%    fixed reference time 'tpuls0' of the pulse ephe-
%    meris. With this function this shift can be turned
%    off (boolean=0) or on (boolean=1, default).
%\seealso{arrtimes, atime_useref, atime_det}
%!%-
{
 variable i, id, st, meta;
 switch(_NARGS)
   { case 1: (id) = (); st = NULL; }
   { case 2: (id,st) = (); }
   { help(_function_name()); return; }

 if (typeof(id) != Array_Type) id = [id];
 % loop over ids
 _for i (0, length(id)-1, 1)
 {
   if (atime_metavalid(id[i]))
   {
     meta = struct_copy(get_dataset_metadata(id[i]));
     if (st == NULL) meta.shiftref = 1;
     else meta.shiftref = (st == 1);
     set_dataset_metadata(id[i], meta);
   }
 }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_xinclude()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_xinclude}
%\synopsis{Specifies the datasets, which should be taken into account in the fit}
%\usage{atime_xinclude(Integer_Type[] index);}
%\description
%    During the fit only the given datasets containing
%    arrival times are taken into account. The remain-
%    ing ones are noticed such that no bins are used.
%    Hence the fit function and parameters are not
%    affected by changed dataset indices.
%\seealso{xnotice_atime, define_atime}
%!%-
{
 variable id, nind = atime_dataind;
 switch(_NARGS)
   { case 0: id = nind; }
   { case 1: (id) = (); }
   { help(_function_name()); return; }
 variable i, meta, fp, fr;
 ifnot (typeof(id) == Array_Type) id = [id];

 % include dataset
 _for i (0, length(id)-1, 1)
 { 
   if (wherefirst(nind == id[i]) == NULL) vmessage("warning (%s): given dataset does not exist or does not contain arrival times",_function_name);
   else
   {
     meta = struct_copy(get_dataset_metadata(id[i]));
     xnotice_atime(id[i],meta.notice[0],meta.notice[1]);
     thaw(meta.freeparams);
   }
 }
 % loop over datasets and exclude
 _for i (0, length(nind)-1, 1)
 {
   if (wherefirst(id == nind[i]) == NULL)
   {
     meta = struct_copy(get_dataset_metadata(nind[i]));
     xnotice(nind[i],0,0);
     % store free parameters
     fp = get_params(sprintf("arrtimes(%d).*", nind[i]));
     fr = wherenot(array_struct_field(fp, "freeze"));
     ifnot (fr == NULL)
     {
       fp = array_struct_field(fp, "index")[wherenot(array_struct_field(fp, "freeze"))];
       meta.freeparams = fp;
       set_dataset_metadata(nind[i], meta);
     }
     % freeze free parameters
     freeze(fp);
   }
 }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define define_atime()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{define_atime}
%\synopsis{defines a dataset of arrival times}
%\usage{Integer_Type define_atime(Struct_Type atime[, Integer_Type divide]);}
%\qualifiers{
%    \qualifier{modnum}{a reference to a variable, where to store
%             the pulse numbers found by the model}
%    \qualifier{noff}{do not add 'arrtimes' to the actual fit-
%             function correspondig to the dataset}
%}
%\description
%    Takes the given arrival times structure to define
%    an ISIS dataset. This structure may be created by
%    'atime_det' or loaded by 'load_atime'. Accordingly
%    all usual ISIS routines, which operate on datasets,
%    e.g. fitting, can be used. The fit function
%    'arrtimes' handle arrival times including orbital
%    motion and pulse ephemeris. If not disabled by the
%    'noff' qualifier the actual fit function is auto-
%    matically extended by the resulting dataset using
%    the 'arrtimes' model. It also takes the qualifier
%    'modnum' into account to return the pulse numbers
%    determined by the model. The reference to the
%    pulse numbers is stored into the metadata of the
%    dataset.
%    If the second parameter 'divide' is given the
%    dataset is defined several times accordingly to
%    the given integer. The datasets are then noticed
%    automatically such that the whole data is divided
%    into the given number of parts of equal length.
%    Each part may be then fitted individually.
%    The returned integer corresponds to ISIS dataset
%    index.
%\seealso{arrtimes, atimes_det, load_atime, atime_metavalid, xnotice_atime}
%!%-
{
 variable s, cut;
 switch(_NARGS)
   { case 1: (s) = (); cut = Double_Type[0]; }
   { case 2: (s,cut) = (); }
   { help(_function_name()); return; }

 message("\nNOTE: there was a change in the definition of the ephemeris structure!");
 message("      If you encounter any problems or your previous fit doesn't work anymore");
 message("      please write an email to matthias.kuehnel@sternwarte.uni-erlangen.de\n");
 variable modnum = qualifier("modnum",NULL);
 if (typeof(modnum) != Ref_Type && modnum != NULL) { vmessage("warning (%s): qualifier modnum must be a reference",_function_name); modnum = NULL; }

 % if no cutting times are given, but number of segments,
 % create segments with equal length in time
 variable arrtimeshig = make_hi_grid(s.arrtimes);
 if (typeof(cut) == Integer_Type)
 {
   if (cut == 1) cut = Double_Type[0];
   else cut = 1.*min(s.arrtimes) + 1.*(max(arrtimeshig)-min(s.arrtimes)) * [1:cut-1] / cut;
 }
 % insert border of segments
 cut = [min(s.arrtimes),cut,max(arrtimeshig)];
 
 % check if smallest error allowed is small enough
 if (Minimum_Stat_Err < 0 or Minimum_Stat_Err > min(s.error))
 {
   Minimum_Stat_Err = 0.9*min(s.error);
   vmessage("warning (%s): Minimum_Stat_Err too large, changed to describe errors",_function_name);
 }

 variable seg = length(cut) - 1; % number of segments
 variable tmin, tmax;
 variable i, ind = Integer_Type[0];
 if (modnum != NULL) @modnum = Integer_Type[seg,length(s.arrnum)];
 % loop over segments
 _for i (0, seg-1, 1)
 {
   % define data
   ind = [ind, define_counts(s.arrtimes,arrtimeshig,s.arrtimes,s.error)];
   % store relative pulse numbers and used time interval (via metadata)
   set_dataset_metadata(ind[i], struct { datapnum = s.arrnum,
                                         refpnum = s.numref,
                                         reft0 = s.reft0,
                                         notice = [cut[i],cut[i+1]],
                                         modelpnum = modnum,
                                         id = i,
                                         useref = 1,
                                         shiftref = 1,
                                         freeparams = Integer_Type[0] });
   % xnotice
   xnotice_atime(ind[i],cut[i],cut[i+1]);
 }

 % define fit function, except if qualifier set
 ifnot (qualifier_exists("noff")) fit_fun("arrtimes(Isis_Active_Dataset)");
 
 return ind;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_get_t0()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_get_t0}
%\synopsis{returns the reference time of the arrival times}
%\usage{Double_Type atime_get_t0(Integer_Type[] dataid);}
%\description
%    This function returns the emitting time of the pulse
%    of number 0 as used in the polynomial to calculate
%    pulse arrival times.
%\seealso{arrtimes, pulse_time}
%!%-
{
 variable id, i;
 switch(_NARGS)
   { case 1: (id) = (); }
   { help(_function_name()); return; }
 if (typeof(id) == Integer_Type) id = [id];
 variable t0 = Double_Type[length(id)];
 _for i (0, length(id)-1, 1) t0[i] = struct_copy(get_dataset_metadata(id[i])).reft0;

 if (length(t0) == 1) t0 = t0[0];
 return t0;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define pulse_time()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulse_time}
%\synopsis{returns the pulse arrival time of the given pulse number with
%    respect to the pulse ephemeris and orbit}
%\usage{Double_Type pulse_time(Integer_Type[] number, Struct_Type ephemeris[, Struct_Type orbit]);
% or Double_Type pulse_time(Integer_Type[] number, Double_Type pulseperiod[, Struct_Type orbit]);}
%\qualifiers{
%    \qualifier{MJD}{the values of the pulse ephemeris are given
%           in days (default: seconds)}
%    \qualifier{eph}{may be set to the pulse ephemeris structure}
%    \qualifier{orb}{may be set to the orbital structure}
%    \qualifier{dphi}{an additive constant phase shift}
%}
%\description
%    Calculates the expected pulse arrival time of the
%    given pulse number, which may be a single value
%    or an array. The structures containing the pulse
%    ephemeris and the orbital parameters must follow
%    the conditions decribed in 'check_pulseperiod_orbit_struct'.
%    Instead of the pulse ephemeris the pulse period
%    may be given only. These structures may be also
%    passed to the function by qualifiers, hence the
%    structure parameters can be omitted.
%    The equation to calculate the arrival time is
%    similar to Hilditch eq. 3.53, including the terms
%    of the fourth order (p3dot). The numerical calcu-
%    lation is optimized using the Horner schema. For
%    details see 'arrtimes'.
%\seealso{check_pulseperiod_orbit_struct, pulseperiod, arrtimes}
%!%-
{
 variable n, eph, orb = NULL;
 switch(_NARGS)
   { case 1: (n) = (); eph = qualifier("eph", NULL); orb = qualifier("orb", NULL); }
   { case 2: (n,eph) = (); }
   { case 3: (n,eph,orb) = ();}
   { help(_function_name()); return; }

 variable dphi = qualifier("dphi",0);

 % backwards compatibility
 if (orb != NULL) {
   ifnot (struct_field_exists(orb, "torb0")) { orb = struct_combine(orb, struct { torb0 = orb.tau }); }
   ifnot (struct_field_exists(orb, "tau")) { orb = struct_combine(orb, struct { tau = orb.torb0 }); }
 }
 if (not struct_field_exists(eph, "tpuls0")) { eph = struct_combine(eph, struct { tpuls0 = eph.t0, ppuls = eph.p0 }); }
 if (not struct_field_exists(eph, "t0")) { eph = struct_combine(eph, struct { t0 = eph.tpuls0, p0 = eph.ppuls }); }
 ifnot (check_pulseperiod_orbit_struct(eph)) { vmessage("error (%s): pulse period structure not given properly", _function_name); return; }
 if (orb != NULL && check_pulseperiod_orbit_struct(orb) == 0) { vmessage("error (%s): orbit structure not given properly", _function_name); return; }

 variable t0 = eph.t0;
 variable p0 = eph.p0;
 variable pdot = eph.pdot;
 variable p2dot = eph.p2dot;
 variable p3dot = eph.p3dot;
 % transform into days if values are given in seconds (standard)
 ifnot (qualifier_exists("MJD"))
 {
   p0 /= 86400.;
   p2dot *= 86400.;
   p3dot *= 86400. * 86400.;
 }
 % pulse emitted time
 variable tn = ((((((pdot*pdot + 4.*p2dot*p0)*pdot + p0*p0*p3dot) * p0 * n / 24. + ((p0*p2dot + pdot*pdot)*p0)) * n / 6. + p0 * pdot / 2.) * n) + p0) * n + t0;
 % phase shift of pattern
 if (-1 < dphi < 1) tn += dphi * pulseperiod(tn, eph) / 86400;
 % take orbit into account
 variable z = 0.;
 if (orb != NULL && orb.asini > 0. && orb.porb > 0) z = BinaryPos(tn; porb=orb.porb, eccentricity=orb.ecc, omega=orb.omega,
					     asini=orb.asini, t0=orb.torb0, pporb=orb.pporb);
 return tn + z / 86400.;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define arrtimes_fit(lo,hi,pars)
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{arrtimes}
%\synopsis{fit function for modelling arrival times}
%\usage{arrtimes(id)}
%\description
%    This model can bes used in arrival time fits. The
%    pulse arrival times are calculated using the
%    'pulse_time' function, including orbital motion
%    and up to the third derivative of the pulse
%    period. The observed pulse arrival time t_obs(n)
%    is calculated by
%
%      t_obs(n) = t0 + A*n + B*n^2 + C*n^3 + D*n^4
%                 + z(t_emit(n))/c
%                 
%    where A to D are coefficients depending on the
%    pulse period and its higher derivatives, z/c is
%    the Doppler Shift due to orbital motion (see
%    'BinaryPos' for details) and t_emit(n) is the
%    time, when the nth pulse is emitted in the bary-
%    centre of the binary. This time is found solving
%    the above equation:
%    
%      t_emit(n) = t_obs(n) - z/c
%      
%    However, this can not be solved since the
%    observed arrival times include the Doppler
%    Shift. Hence the emission time must be found
%    iteratively, starting at t_emit(n) = t_obs(n).
%    The found pulse numbers are stored in a reference
%    variable, if set by 'define_atime'.
%    The model parameters are
%      ppuls - pulse period (s)
%      pdot  - first derivative (s/s)
%      p2dot - second derivative (s/s^2)
%      p3dot - third derivative (s/s^3)
%      dphi  - constant additive phase shift
%      porb  - orbital period (d)
%      torb0 - time of periastron passage (MJD)
%      asini - projected semi major axis (lts)
%      ecc   - eccentricity
%      omega - angle of periastron (degrees)
%      pporb - change of orbital period (d/d)
%    The reference time of the pulse ephemeris,
%    called tpuls0 in 'atime_get_ephemeris' for
%    example, is fix and set by 'define_atime'.
%    If you know what you are doing you can
%    change this time using 'atime_set_ephemeris'.
%\seealso{pulse_time, atime_set_ephemeris, define_atime, BinaryPos}
%!%-
{
 variable p0 = pars[0]/86400.;    % pulse period in reference frame of the binary [d]
 variable pdot = pars[1];         % first derivative of the pulse period [d/d]
 variable p2dot = pars[2]*86400.; % second derivative of the pulse period [d/d^2]
 variable p3dot = pars[3]*86400.*86400.; % third derivative of the pulse period [d/d^2]
 variable dphi = pars[4];         % phase shift of search pattern
 variable porb = pars[5];         % orbial period [days]
 variable ecc = pars[6];          % eccentricity of the orbit
 variable omega = pars[7];        % angle of periastron [degrees]
 variable asini = pars[8];        % projected major axis [lts]
 variable t0 = pars[9];           % time of periastron
 variable pporb = pars[10];       % first derivative of the orbital period [s/s]
 variable maxiter = 50;
 variable limit = 1e-12;
 variable chatty = 0;
 
 % check on valid metadata
 ifnot (atime_metavalid(Isis_Active_Dataset)) throw RunTimeError, "given dataset does not contain arrival times";
 % relative puls numbers as determined by getArrivalTimes
 variable meta = struct_copy(get_dataset_metadata(Isis_Active_Dataset));
 variable noti = @ (get_data_info(Isis_Active_Dataset).notice_list); % indices of used data
 variable pnum, z, tobs, temit, i, m, temit_new, dt;
 pnum = Double_Type[length(lo)];
 tobs = Double_Type[length(lo)]; tobs[*] = lo[*];
 temit = Double_Type[length(lo)];
 temit_new = Double_Type[length(lo)]; temit_new[*] = lo[*];
 
 % correct doppler shift of reference time to get pulse emission time for n=0
 variable tn0;
 variable tn0o = meta.reft0;
 variable tn0_new = tn0o;
 % correct this time for orbit (if orbit given)
 m=0;
 do
 {
   tn0 = tn0_new;
   if (asini>0 && porb>0)
   {
     z = BinaryPos(tn0; porb=porb, eccentricity=ecc, omega=omega, asini=asini, t0=t0, pporb=pporb);
     z = z / 86400.;
   } else z = 0.;
   tn0_new = tn0o - z;
   m++;
 } while (abs(tn0_new - tn0) > limit && m<maxiter);
 tn0 = tn0_new;
 % because tn0 != given reference time for pulse period, the pulse
 % ephemeris at tn0 must be calculated now
 variable neph = pulseperiod_transform(tn0, struct { p0 = p0*86400, pdot = pdot, p2dot = p2dot/86400, p3dot = p3dot/86400/86400, t0 = tn0o});
 p0 = neph.p0/86400; pdot = neph.pdot; p2dot = neph.p2dot*86400; p3dot = neph.p3dot*86400*86400;
 % shift reference pulse number if not disabled
 if (meta.shiftref)
 {
   variable ni = where_min(abs(lo-tn0));
   variable nr = meta.refpnum[noti[ni]];
   variable sndx = where(meta.refpnum == nr);
   meta.datapnum[sndx] -= meta.datapnum[noti[ni]];
   meta.refpnum[sndx] = noti[ni];
 }
 % get indices of all pulse numbers to determine
 variable ndx_det, ndx_ref;
 if (meta.useref) ndx_det = where(meta.datapnum[noti] == 0 | meta.refpnum[noti] < noti[0] | meta.refpnum[noti] > noti[length(noti)-1], &ndx_ref);
 else { ndx_det = [0:length(noti)-1]; ndx_ref = Integer_Type[0]; }

 dt = max(lo)-min(lo);
 % determine pulse numbers by orbit correct the arrival time and solve t(n)
 % this must be done iteratively
 variable n, refi;
 _for i (0, length(ndx_det)-1, 1)
 {
   m = 0; n = ndx_det[i];
   do
   {
     temit[n] = temit_new[n];
     % get z component of neutron star at emitted time (in lts) (if orbit given)
     if (porb>0 && asini>0)
     {
       z = BinaryPos(temit[n]; porb=porb, eccentricity=ecc, omega=omega, asini=asini, t0=t0, pporb=pporb);
       z = z / 86400.;
     } else z = 0;
     % find pulse number, solve Hilditch 3.53 for given t
     if (pdot == 0.0 && p2dot == 0.0 && p3dot == 0.0) pnum[n] = (lo[n] - z - tn0) / p0 - dphi;
     else pnum[n] = find_function_value(&pulse_time, lo[n]-z, (min(lo)-.5*dt-tn0)/p0, (max(lo)+.5*dt-tn0)/p0;
                    eps=1e-12, qualifiers = struct { dphi = dphi, eph = struct { tpuls0=tn0, ppuls=p0, pdot=pdot, p2dot=p2dot, p3dot=p3dot }, MJD }); % MJD qualifier important!
     % pulse number must be an integer
     pnum[n]=round(pnum[n]);
     % calculate new pulse arrival time
     temit_new[n] = pulse_time(int(pnum[n]), struct { tpuls0=tn0, ppuls=p0, pdot=pdot, p2dot=p2dot, p3dot=p3dot }; dphi = dphi, MJD);
     m++;
   } while (abs(temit_new[n] - temit[n]) > limit && m < maxiter);
   temit[n] = temit_new[n];
   if (porb>0 && asini>0)
   {
     z = BinaryPos(temit[n]; porb=porb, eccentricity=ecc, omega=omega, asini=asini, t0=t0, pporb=pporb);
     z = z / 86400.;
   } else z = 0;
   tobs[n] = temit[n] + z;
 }
 % set reference pulse numbers and calculate arrival times
 _for i (0, length(ndx_ref)-1, 1)
 {
   n = ndx_ref[i];
   refi = where(noti == meta.refpnum[noti[n]])[0];
   pnum[n] = pnum[refi] + meta.datapnum[noti[n]];
   % calculate arrival time
   temit[n] = pulse_time(int(pnum[n]), struct { tpuls0=tn0, ppuls=p0, pdot=pdot, p2dot=p2dot, p3dot=p3dot }; dphi = dphi, MJD);
   if (porb>0 && asini>0)
   {
     z = BinaryPos(temit[n]; porb=porb, eccentricity=ecc, omega=omega, asini=asini, t0=t0, pporb=pporb);
     z = z / 86400.;
   } else z = 0;
   tobs[n] = temit[n] + z;
 }
 % store derived pulse numbers if reference to variable is given
 if (meta.modelpnum != NULL) (@meta.modelpnum)[meta.id,noti] = int(pnum);
 return tobs;
} %}}}

% set default values and limits
add_slang_function("arrtimes",["ppuls [s]","pdot [s/s]","p2dot [s/s^2]","p3dot [s/s^3]","dphi","porb [days]","ecc","omega [degrees]","asini [lts]","torb0 [MJD]","pporb [s/s]"]);
define arrtimes_default_hook(i)
{
  variable defs = [
    struct { value = 1.0, freeze = 0, hard_min = 0.0, hard_max = 1e10, min = 0, max = 0, step = 1e-3, relstep = 1e-5 },
    struct { value = 0.0, freeze = 0, hard_min = -1.0, hard_max = 1.0, min = -1e-6, max = 1e-6, step = 1e-11, relstep = 1e-13 },
    struct { value = 0.0, freeze = 0, hard_min = -1.0, hard_max = 1.0, min = -1e-11, max = 1e-11, step = 1e-13, relstep = 1e-15 },
    struct { value = 0.0, freeze = 0, hard_min = -1.0, hard_max = 1.0, min = -1e-18, max = 1e-18, step = 1e-20, relstep = 1e-22 },
    struct { value = 0.0, freeze = 1, hard_min = -1.0, hard_max = 1.0, min = -1.0, max = 1.0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = 0.0, hard_max = 1000, min = 0, max = 1000, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = 0.0, hard_max = 1.0, min = 0.0, max = 1.0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = -360, hard_max = 360.0, min = 0, max = 0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = 0.0, hard_max = 1e10, min = 0, max = 0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 0, hard_min = 0.0, hard_max = 1e10, min = 0, max = 0, step = 1e-2, relstep = 1e-4 },
    struct { value = 0.0, freeze = 1, hard_min = -1.0, hard_max = 1.0, min = -1e-4, max = 1e-4, step = 1e-6, relstep = 1e-8 }
  ];
  return defs[i];
}
set_param_default_hook("arrtimes", &arrtimes_default_hook);


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_set_ephemeris()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_set_ephemeris}
%\synopsis{sets the actual model parameters of a given
%    dataset of pulse arrival times}
%\usage{atime_set_ephemeris(Integer_Type[] idx, Struct_Type eph[, Struct_Type orb]);}
%\altusage{atime_set_ephemeris(Integer_Type[] idx, Double_Type eph[, Struct_Type orb]);}
%\qualifiers{
%    \qualifier{sett0}{also set the reference time of the pulse
%               ephemeris, which is used internally}
%}
%\description
%    The given structure(s) containing the pulse ephemeris
%    and the orbital parameters are used to set the model
%    parameters of dataset 'idx'. Instead of the pulse
%    ephemeris the pulse period may be given only. Other-
%    wise the structure has to contain:
%      ppuls  - pulse period (s)
%      pdot   - first derivative (s/s)
%      p2dot  - second derivative (s/s^2)
%      p3dot  - third derivative (s/s^3)
%      tpuls0 - reference time (MJD)
%    The orbital parameters are stored in the second
%    structure:
%      porb   - orbital period (d)
%      torb0  - time of periastron passage (MJD)
%      asini  - projected semi major axis (lts)
%      ecc    - eccentricity
%      omega  - angle of periastron (degrees)
%    By default the reference time of the pulse ephemeris
%    is NOT set, because this should be fixed and set to
%    the same time as used for the pulse pattern. This
%    time therefore defines the arrival time of the pulse
%    of number n=0. Only change this time if you know what
%    effects will result (see arrtimes function)!    
%\seealso{arrtimes, atime_get_ephemeris}
%!%-
{
  variable id, eph, orb = NULL;
  switch(_NARGS)
    { case 2: (id,eph) = (); }
    { case 3: (id,eph,orb) = (); }
    { help(_function_name()); return; }
  ifnot (typeof(id) == Array_Type) id = [id];
  % check on valid metadata
  ifnot (atime_metavalid(id)) throw RunTimeError, "given dataset does not contain arrival times";
  % check given structures
  ifnot (check_pulseperiod_orbit_struct(eph)) { vmessage("error (%s): pulse period structure not given properly", _function_name); return; }
  ifnot (orb != NULL && check_pulseperiod_orbit_struct(orb)) { vmessage("error (%s): orbit structure not given properly", _function_name); return; }
  % backwards compatibility
  if (orb != NULL && not struct_field_exists(orb, "torb0")) {
    orb = struct_combine(orb, struct { torb0 = orb.tau });
  }
  if (not struct_field_exists(eph, "tpuls0")) {
    eph = struct_combine(eph, struct { tpuls0 = eph.t0, ppuls = eph.p0 });
  }
  % set model values
  variable f, meta, i;
  foreach i (id)
  {
    foreach f (get_struct_field_names(eph))
    {
      if (f == "tpuls0" && qualifier_exists("sett0"))
      {
        meta = struct_copy(get_dataset_metadata(i));
        meta.reft0 = eph.tpuls0;
        set_dataset_metadata(i, meta);
      }
      else ifnot (f == "tpuls0") set_par(sprintf("arrtimes(%d).%s",i,f), @get_struct_field(eph,f));
    }
    if (orb != NULL && orb.asini > 0 && orb.porb > 0)
      foreach f (get_struct_field_names(orb)) set_par(sprintf("arrtimes(%d).%s",i,f), @get_struct_field(orb,f));
    else {
      set_par(sprintf("arrtimes(%d).porb",i), 0, 1, 0, 0);
      set_par(sprintf("arrtimes(%d).ecc",i), 0, 1, 0, 0);
      set_par(sprintf("arrtimes(%d).omega",i), 0, 1, 0, 0);
      set_par(sprintf("arrtimes(%d).asini",i), 0, 1, 0, 0);
      set_par(sprintf("arrtimes(%d).torb0",i), 0, 1, 0, 0);
      set_par(sprintf("arrtimes(%d).pporb",i), 0, 1, 0, 0);
    }
  }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_get_ephemeris()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_get_ephemeris}
%\synopsis{retrieves the actual model parameters of a given
%    dataset of pulse arrival times}
%\usage{(Struct_Type, Struct_Type) atime_get_ephemeris(Integer_Type idx);}
%\description
%    Returnes two structures containing the model parameters
%    of a dataset, which contains pulse arrival times. The
%    first structure describes the pulse ephemeris:
%      ppuls  - pulse period (s)
%      pdot   - first derivative (s/s)
%      p2dot  - second derivative (s/s^2)
%      p3dot  - third derivative (s/s^3)
%      tpuls0 - reference time (MJD)
%    The orbital parameters are stored in the second
%    structure:
%      porb   - orbital period (d)
%      torb0  - time of periastron passage (MJD)
%      asini  - projected semi major axis (lts)
%      ecc    - eccentricity
%      omega  - angle of periastron (degrees)
%    If porb or asini is zero, the returned orbital
%    structure will be set to NULL.
%\seealso{arrtimes, check_pulseperiod_orbit_struct}
%!%-
{
  variable id;
  switch(_NARGS)
    { case 1: (id) = (); }
    { help(_function_name()); return; }
  % check on valid metadata
  ifnot (atime_metavalid(Isis_Active_Dataset)) throw RunTimeError, "given dataset does not contain arrival times";
  % build structures
  variable eph = struct {
    p0  = get_par(sprintf("arrtimes(%d).ppuls",id)),
    pdot   = get_par(sprintf("arrtimes(%d).pdot",id)),
    p2dot  = get_par(sprintf("arrtimes(%d).p2dot",id)),
    p3dot  = get_par(sprintf("arrtimes(%d).p3dot",id)),
    t0 = struct_copy(get_dataset_metadata(id)).reft0
  };
  if (get_par(sprintf("arrtimes(%d).porb",id)) > 0 && get_par(sprintf("arrtimes(%d).asini",id)) > 0)
    return (eph, struct {
      porb   = get_par(sprintf("arrtimes(%d).porb",id)),
      tau  = get_par(sprintf("arrtimes(%d).torb0",id)),
      asini  = get_par(sprintf("arrtimes(%d).asini",id)),
      ecc    = get_par(sprintf("arrtimes(%d).ecc",id)),
      omega  = get_par(sprintf("arrtimes(%d).omega",id)),
      pporb  = get_par(sprintf("arrtimes(%d).pporb",id)) });
  else return (eph, NULL);
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_save_ephemeris()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_save_ephemeris}
%\synopsis{saves pulse ephemeris and orbital parameters into as an S-lang script}
%\usage{atime_save_ephemeris(Integer_Type idx, String_Type filename);
% or atime_save_ephemeris(Struct_Type eph[, Struct_Type orb], String_Type filename)}
%\description
%    The fitted pulse ephemeris and orbital paramters
%    of the given dataset or the structures themself
%    are saved into a file. This file is an S-lang
%    script and can be called directly or loaded by
%    using 'atime_load_ephemeris'.
%\seealso{atime_load_ephemeris, atime_get_ephemeris}
%!%-
{
 % process arguments
 variable id, filename, eph, orb = NULL;
 switch(_NARGS)
   { case 2:
     (id, filename) = ();
     if (typeof(id) == Struct_Type) eph = id;
     else
     {
       if (length(id) > 1) { vmessage("error (%s): only one dataset is allowed", _function_name); return; }
       (eph,orb) = atime_get_ephemeris(id);
     }
   }
   { case 3: (eph, orb, filename) = (); }
   { help(_function_name()); return; }

 % write S-lang file
 variable f, fp = fopen(filename, "w+");
 ()=fprintf(fp, "(\n  struct {\n");
 foreach f (get_struct_field_names(eph)) ()=fprintf(fp, "    %s = %S,\n", f, get_struct_field(eph, f));
 ()=fprintf(fp, "  },\n");
 if (orb != NULL && orb.asini > 0 && orb.porb > 0)
 {
   ()=fprintf(fp, "  struct {\n");
   foreach f (get_struct_field_names(orb)) ()=fprintf(fp, "    %s = %S,\n", f, get_struct_field(orb, f));
   ()=fprintf(fp, "  }\n");
 } else ()=fprintf(fp, "  NULL\n");
 ()=fprintf(fp, ")\n");
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_load_ephemeris()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_load_ephemeris}
%\synopsis{returns previously ssaved pulse ephemeris and orbital parameters}
%\usage{atime_load_ephemeris(Integer_Type idx, String_Type filename);
% or (Struct_Type, Struct_Type) atime_load_ephemeris(String_Type filename);}
%\description
%    The pulse ephemeris and orbital parameters, which
%    have been previously saved by using the function
%    'atime_save_ephemeris', are either assigned to the
%    given dataset 'idx' or returned as structures.
%    The first one defines the pulse ephemeris and the
%    second one the orbit.
%    The following commands are equal:
%      (eph, orb) = atime_load_ephemeris(filename);
%      (eph, orb, ) = evalfile(filename);
%\seealso{atime_save_ephemeris, atime_get_ephemeris, evalfile}
%!%-
{
 variable eph, orb, idx, filename;
 switch(_NARGS)
   { case 1: filename = (); (eph, orb, ) = evalfile(filename); return (eph, orb); }
   { case 2: (idx, filename) = (); (eph, orb, ) = evalfile(filename); atime_set_ephemeris(idx, eph, orb); }
   { help(_function_name()); return; }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define plot_atime()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{plot_atime}
%\synopsis{plots the residuals of a pulse arrival times fit}
%\usage{plot_atime([Integer_Type[] index]);}
%\qualifiers{
%    \qualifier{t0}{reference time of xticks}
%    \qualifier{col}{array of colors for datasets}
%    \qualifier{noerrbars}{do not plot errorbars}
%    \qualifier{connect_points}{see 'connect_points'}
%    \qualifier{style}{see 'point_style'}
%    \qualifier{xunit}{used time unit (d or s)}
%    \qualifier{yunit}{used residual unit (phi or s)}
%    \qualifier{xlunit}{label of xunit}
%    \qualifier{ylunit}{label of yunit}
%    \qualifier{xrng}{time range}
%    \qualifier{yrng}{residual range (default -0.5 to 0.5)}
%    \qualifier{ploteph}{overplot the pulse ephemeris}
%    \qualifier{plotorb}{overplot the orbital motion}
%    \qualifier{plotpnum}{overplot the modelled pulse numbers
%                     ('modnum' reference must be set,
%                     see 'define_atime')}
%    \qualifier{plotdif}{overplot the meassured pulse period
%                     ('modnum' reference must be set,
%                     see 'define_atime')}
%    \qualifier{y2rng}{yrange of overplot}
%    \qualifier{y2rel}{if pulse period tics are displayed
%                     wrong, you should switch to relative
%                     values and milliseconds}
%    \qualifier{extcol}{color of overplot}
%    \qualifier{extcolY}{yaxis color of overplot}
%    \qualifier{oplot}{do not erase plot window}
%    \qualifier{lshift}{if 'peph' and 'porb' set, shift the
%                     labels printed at the ephemeris by
%                     the given value in y-direction. May
%                     be a two value array [eph,orb].
%                     Values are interpreted as relative
%                     coordinates.}
%}
%\description
%    By default plots the residuals of all datasets
%    containing arrival times. The residuals are
%    calculated by
%      residuals = data - model
%    Using the optional
%    first parameter the indices of the datasets to
%    be plotted can be specified. Also works if
%    some datasets are excluded from the fit (see
%    'atime_xinclude').
%    The residuals in units of pulse phase or seconds
%    are plotted against the meassured pulse arrival
%    times in days or seconds. The units can be set
%    by using the accordant qualifiers. Further
%    informations can be overplotted, like the
%    pulse period in the binary barycentre.
%\seealso{arrtimes, atime_dataind, atime_xinclude, plot_data}
%!%-
{
 variable fn;
 switch(_NARGS)
   { case 0: fn = atime_dataind; }
   { case 1: fn = ();}
   { help(_function_name()); return; }

 % check if datasets containing arrival times exist
 if (typeof(fn) == Null_Type) { vmessage("warning (%s): no datasets containing arrival times defined",_function_name); return; }
 
 if (typeof(fn) != Array_Type) fn=[fn];
 % loop over datasets to get arrival times
 variable i, atimes = Double_Type[0], datimes = Double_Type[0], mtimes = Double_Type[0], ndx=0, noti;
 _for i (0, length(fn)-1, 1)
 {
  noti = @ (get_data_info(fn[i]).notice_list);
  % apply notice
  atimes = [atimes, get_data_counts(fn[i]).value[noti]];
  datimes = [datimes, get_data_counts(fn[i]).err[noti]];
  mtimes = [mtimes, get_model_counts(fn[i]).value[noti]];
  ndx = [ndx,ndx[length(ndx)-1]+length(noti)]; % indices belonging to different datasets
 }
 variable po = get_plot_options.yopt;
 variable p0, res, ndxu;

 variable eph, orb;

 variable nomod = not sum(mtimes); % model evaluated?

 % apply units
 variable xunit = qualifier("xunit","d");
 variable yunit = qualifier("yunit","phi");
 variable xlunit = "MJD";
 variable ylunit = "Pulse Phase";
 if (xunit == "d") xunit = 1.;
 else if (xunit == "s") { xunit = 86400; xlunit = "s"; }
 else { vmessage("warning (%s): x-axis unit '%s' not known, assuming days", _function_name, xunit); xunit = 1.; }
 if (yunit == "phi") yunit = 1.;
 else if (yunit == "s") ylunit = "s";
 else { vmessage("warning (%s): y-axis unit '%s' not known, assuming pulse phase", _function_name, yunit); yunit = 1.; }

 variable dnum = max(atimes)-min(atimes);
 variable t0 = qualifier("t0",round(mean(atimes)));
 if (typeof(t0) == Integer_Type) t0 = 1.*t0;
  
 variable xrng = qualifier("xrng",[min(atimes)-t0-0.1*dnum,max(atimes)-t0+0.1*dnum]);
 variable yrng = qualifier("yrng",NULL);
 if (yrng == NULL) % check on |residuals|>0.5
 {
   yrng = [-0.5,0.5];
   _for i (0, length(fn)-1, 1)
   {
     % calculate the actual pulse period
     (eph,orb) = atime_get_ephemeris(fn[i]);
     p0 = pulseperiod(atimes, eph, orb);
     if (ylunit == "s") yunit = max(p0);
     res = (atimes-mtimes)*86400./p0;
     res = res + sign(res)*datimes*86400./p0;
     if (min(res) < -0.5 && yrng[0] > min(res)) yrng[0] = min(res);
     if (max(res) > +0.5 && yrng[1] < max(res)) yrng[1] = max(res);
   }
 }
 if (nomod) { yrng = xrng; }
 % apply ranges
 yrng = yrng * yunit;
 xrng = xrng * xunit;
 if (qualifier("oplot",0) == 0)
 {
   yrange(yrng[0],yrng[1]);
   xrange(xrng[0],xrng[1]);
 }

 variable pper = qualifier_exists("ploteph");
 variable porb = qualifier_exists("plotorb");
 variable pnum = qualifier_exists("plotpnum");
 variable pdif = qualifier_exists("plotdiff");
 variable y2rng = qualifier("y2rng",NULL);
 % check on multiple plot qualifiers
 if (sum([pper || porb,pnum,pdif]) > 1)
 {
   vmessage("warning (%s): only one plot qualifier allowed, will ignore all plot qualifiers",_function_name);
   pper = 0; pnum = 0; pdif = 0; porb = 0;
 }
 % deactivate right border -> second axis
 else if ((pper || porb || pnum || pdif) && not nomod) ()=change_plot_options(;yopt="BNST");

 variable colData = qualifier("col",[1:length(fn)]+1);
 if (length(colData)!=length(fn)) colData=[colData,[max(colData):max(colData)+length(fn)-length(colData)-1]+1];
  
 if (qualifier("oplot",0) == 0)
 {
   xlabel(sprintf("Time (" + xlunit + " - %.2f MJD)",t0));
   if (nomod) ylabel(sprintf("Time (" + xlunit + " - %.2f MJD)",t0));
   else ylabel("Residuals (" + ylunit + ")");
   % "erase" plot window
   color(0); plot(xrng,[0,0]);
 }
 ifnot (nomod)
 {
   color(1);
   line_style(2);
   connect_points(1);
   point_style(-1);
   oplot(xrng,[0,0]);
   line_style(1);
   _pgsls(1);
 }

 variable colP = qualifier("extcol",15);
 variable colY2 = qualifier("extcolY",colP);
 variable lshift = qualifier("lshift",[0,0]);
 if (length(lshift) == 1) lshift = [lshift, lshift];
 % eventually plot pulse ephemeris
 if (pper && not nomod)
 {
  variable pulsper = Double_Type[0], pulst = Double_Type[0], pdot, p2dot, p3dot, t0p, nt, ex;
  ndxu = 0;
  _for i (0, length(fn)-1, 1)
  {
    ifnot (ndx[i] == ndx[i+1])
    {
      p0 = get_par(sprintf("arrtimes(%d).ppuls",fn[i])) / 86400;
      pdot = get_par(sprintf("arrtimes(%d).pdot",fn[i]));
      p2dot = get_par(sprintf("arrtimes(%d).p2dot",fn[i])) * 86400;
      p3dot = get_par(sprintf("arrtimes(%d).p3dot",fn[i])) * 86400 * 86400;
      t0p = struct_copy(get_dataset_metadata(fn[i])).reft0;
      nt = [mtimes[ndx[i]], mtimes[ndx[i+1]-1]];
      nt = [nt[0]:nt[1]:(nt[1]-nt[0])/100];
      pulst = [pulst,nt];
      pulsper = [pulsper,p0 + pdot * (nt-t0p) + 1./2. * p2dot * sqr(nt-t0p) + 1./6. * p3dot * sqr(nt-t0p)*(nt-t0p)];
      ndxu = [ndxu,ndxu[length(ndxu)-1]+length(nt)];
    } else ndxu = [ndxu, ndxu[length(ndxu)-1]];
  }
  pulsper = pulsper*86400;
  dnum = max(pulsper)-min(pulsper);
  if (dnum == 0.0) ex=1.0; else ex=0.0;
  line_style(1);
  if (y2rng == NULL) y2rng=[min(pulsper)-0.1*dnum-ex,max(pulsper)+0.1*dnum+ex];
  if (qualifier_exists("y2rel")) % _pgaxis has problems with small numbers
  { % so this qualifier switches to a relative pulse period and milliseconds
    variable sw = y2rng[0] > 0 ? 1. : 1e3;
    variable rel = round(floor(y2rng[0]*sw))/sw;
    y2label(sprintf("Pulse Period (ms - %d %s)", int(rel*sw), sw == 1 ? "s" : "ms"); color=colP, f=0.07);
    y2axis((y2rng[0]-rel)*1e3, (y2rng[1]-rel)*1e3; color=colY2);
  }
  else
  {
    y2label("Pulse Period (s)"; color=colP, f=0.07);
    y2axis(y2rng[0], y2rng[1]; color=colY2);
  }
  _for i (0, length(fn)-1, 1)
  {
    ifnot (ndx[i] == ndx[i+1])
    {
      nt = [ndxu[i]:ndxu[i+1]-1];
      color(colP);
      if (dnum == 0.0) oplot(xrng, [0,0]);
      else oplot((pulst[nt]-t0)*xunit,(pulsper[nt]-y2rng[0])/(y2rng[1]-y2rng[0])*sum(abs(yrng))/yunit + yrng[0]/yunit);
    }
  }
  if (pper && porb)
  {
    color(colP);
    ex = where_min(pulst);
    xylabel_in_box((pulst[ex]-xrng[0]-t0)/(xrng[1]-xrng[0]), (pulsper[ex]-y2rng[0])/(y2rng[1]-y2rng[0]) + lshift[0], "P\\deph\\u(t)");
  }
  ()=change_plot_options(;yopt=po); % restore plot options
 }

 % eventually plot orbital motion
 if (porb && not nomod)
 {
  pulsper = Double_Type[0]; pulst = Double_Type[0];
  variable asini, ecc, omega, torb0, period;
  ndxu = 0;
  _for i (0, length(fn)-1, 1)
  {
    ifnot (ndx[i] == ndx[i+1])
    {
      p0 = get_par(sprintf("arrtimes(%d).ppuls",fn[i]));
      asini = get_par(sprintf("arrtimes(%d).asini",fn[i]));
      ecc = get_par(sprintf("arrtimes(%d).ecc",fn[i]));
      omega = get_par(sprintf("arrtimes(%d).omega",fn[i]));
      torb0 = get_par(sprintf("arrtimes(%d).torb0",fn[i]));
      period = get_par(sprintf("arrtimes(%d).porb",fn[i]));
      nt = [mtimes[ndx[i]], mtimes[ndx[i+1]-1]];
      nt = [nt[0]:nt[1]:(nt[1]-nt[0])/100];
      pulst = [pulst,nt];
      pulsper = [pulsper,pulseperiod(nt, p0, struct { asini = asini, omega = omega, ecc = ecc, tau = torb0, porb = period })];
      ndxu = [ndxu,ndxu[length(ndxu)-1]+length(nt)];
    } else ndxu = [ndxu, ndxu[length(ndxu)-1]];
  }
  ifnot (pper)
  {
    dnum = max(pulsper)-min(pulsper);
    if (dnum == 0.0) ex=1.0; else ex=0.0;
    line_style(1);
    if (y2rng == NULL) y2rng=[min(pulsper)-0.1*dnum-ex,max(pulsper)+0.1*dnum+ex];
    y2axis(y2rng[0],y2rng[1];color=colY2);
    y2label("Pulse Period (s)";color=colP,f=0.07);
  }
  _for i (0, length(fn)-1, 1)
  {
    ifnot (ndx[i] == ndx[i+1])
    {
      nt = [ndxu[i]:ndxu[i+1]-1];
      color(colP);
      if (pper && dnum == 0.0) oplot(xrng, [0,0]);
      else oplot((pulst[nt]-t0)*xunit,(pulsper[nt]-y2rng[0])/(y2rng[1]-y2rng[0])*sum(abs(yrng))/yunit + yrng[0]/yunit);
    }
  }
  if (pper && porb)
  {
    color(colP);
    ex = where_min(pulst);
    xylabel_in_box((pulst[ex]-xrng[0]-t0)/(xrng[1]-xrng[0]), (pulsper[ex]-y2rng[0])/(y2rng[1]-y2rng[0]) + lshift[1], "P\\dorb\\u(t)");
  }
  ()=change_plot_options(;yopt=po); % restore plot options
 }

 % eventually plot model pulse numbers
 if (pnum && not nomod)
 {
  pnum = qualifier("plotpnum");
  if (typeof(pnum) == Ref_Type && length(@pnum[0,*]) == length(mtimes))
  {
   pnum = @pnum;
   dnum = max(pnum)-min(pnum);
   line_style(1);
   if (y2rng == NULL) y2rng=[min(pnum)-0.1*dnum,max(pnum)+0.1*dnum];
   y2axis(y2rng[0],y2rng[1];color=colY2);
   y2label("Pulse Number";color=colP,f=0.07);
   color(colP);
   connect_points(0);
   point_style(5);
   oplot((mtimes-t0)*xunit,(pnum-y2rng[0])/(y2rng[1]-y2rng[0])*sum(abs(yrng))/yunit + yrng[0]/yunit);
   connect_points(1);
   point_style(-1);
  }
  else vmessage("warning (%s): qualifier 'plotpnum' must be a reference to the pulse number array",_function_name);
  ()=change_plot_options(;yopt=po); % restore plot options
 }

 % eventually plot 'measured' pulse period
 if (pdif && not nomod)
 {
  pdif = qualifier("plotdiff");
  if (typeof(pdif) == Ref_Type)
  {
   pdif = @pdif;
   variable mn, mx, pdife, ftimes;
   ndxu = wherenot(isinf(pdif));
   pdif = pdif[ndxu];
   pdife = pdife[ndxu];
   ftimes = ftimes[ndxu];
   dnum = max(pdif)-min(pdif);
   line_style(1);
   if (y2rng == NULL) y2rng=[min(pdif)-0.1*dnum,max(pdif)+0.1*dnum];
   y2axis(y2rng[0],y2rng[1];color=colY2);
   y2label("Arrival Times Difference (s)";color=colP,f=0.07);
   color(colP);
   connect_points(0);
   point_style(5);
   _for i (0, length(fn)-1, 1)
   {
     ifnot (ndx[i] == ndx[i+1])
     {
       mx = [ndx[i]+1:ndx[i+1]];
       mn = [ndx[i]:ndx[i+1]-1];
       pdife = sqrt(sqr(datimes[mx])+sqr(datimes[mn])) / (pdif[mx] - pdif[mn]) * 86400;
       pdif = (atimes[mx] - atimes[mn]) / (pdif[mx] - pdif[mn]) * 86400;
       ftimes = (mtimes[mx] + mtimes[mn]) / 2.;
       oplot_with_err((ftimes-t0)*xunit,(pdif-y2rng[0])/(y2rng[1]-y2rng[0])*sum(abs(yrng))/yunit + yrng[0]/yunit);
     }
   }
   connect_points(1);
   point_style(-1);
  }
  else vmessage("warning (%s): qualifier 'plotdiff' must be a reference to the pulse number array",_function_name);
  ()=change_plot_options(;yopt=po); % restore plot options
 }

 % style
 variable style = qualifier("style", 4);
 point_style(style);
 if (qualifier_exists("noerrbars")) connect_points(qualifier_exists("connect_points"));
 % plot arrival times
 _for i (0, length(fn)-1, 1)
 {
   (eph,orb) = atime_get_ephemeris(fn[i]);
   if (ndx[i]<ndx[i+1]) % check on ignored datasets
   {
     color(colData[i]);
     ndxu = [ndx[i]:ndx[i+1]-1]; % indices to use
     % calculate residuals (with respect to the actual pulse period)
     res = (atimes[ndxu] - mtimes[ndxu])*86400.;
     ifnot (ylunit == "s") p0 = pulseperiod(atimes[ndxu], eph, orb);
     else p0 = 1.;
     % if no model exists plot arrtimes also in y-direction
     if (nomod) { res = atimes[ndxu]-t0; p0 = 86400.; }
     if (qualifier_exists("noerrbars")) oplot((atimes[ndxu]-t0)*xunit,res/p0);
     else oplot_with_err((atimes[ndxu]-t0)*xunit,res/p0,datimes[ndxu]*86400./p0;;__qualifiers);
   }
 }
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_sim()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_sim}
%\synopsis{simulates pulse arrival times}
%\usage{Struct_Type atime_sim([Integer_Type n,] Double_Type tmin, tmax, Struct_Type eph[, orb]);}
%\qualifiers{
%    \qualifier{scramble}{1 sigma noise of the simulated arrival
%               times in seconds (default = 0)}
%    \qualifier{dn}{the increment of the arrival times if
%               they are not randomly generated
%               (default = 1)}
%}
%\description
%    Simulates the orbit and the pulsation of a pulsar
%    and returns the pulse arrival times in the time
%    range given by 'tmin' and 'tmax'. If the number
%    of arrival times 'n' is given, then n randomly
%    selected arrival times are returned. The returned
%    structure is equal to the atime_det function.
%    The uncertainties of the simulated arrival times
%    are calculated using the 'scramble' value. If no
%    value is given, the uncertainties are set to 0.1%
%    of the pulse period to avoid ISIS from treating
%    the arrival times as counts, resulting in poisson
%    errors.
%    The structures describing the pulse ephemeris and
%    the orbit must fullfil the conditions described
%    in the function check_pulseperiod_orbit_struct.
%
% NOTE
%    Due to speed reasons the returned arrival times
%    might be beyond the given time interval or not
%    all pulses in this interval are returned.
%\seealso{atime_det, check_pulseperiod_orbit_struct, arrtimes}
%!%-
{
 variable n = NULL, tmin, tmax, eph, orb = NULL;
 switch(_NARGS)
   { case 3: (tmin,tmax,eph) = (); }
   { case 4: (n,tmin,tmax,eph) = (); if (typeof(n) != Integer_Type) { orb = @eph; eph = @tmax; tmax = tmin; tmin = n; n = NULL; }}
   { case 5: (n,tmin,tmax,eph,orb) = (); }
   { help(_function_name()); return; }

 ifnot (check_pulseperiod_orbit_struct(eph)) { vmessage("error (%s): pulse period structure not given properly", _function_name); return; }
 ifnot (orb != NULL && check_pulseperiod_orbit_struct(orb)) { vmessage("error (%s): orbit structure not given properly", _function_name); return; }

 % backwards compatibility
 if (orb != NULL && not struct_field_exists(orb, "torb0")) {
   orb = struct_combine(orb, struct { torb0 = orb.tau });
 }
 if (not struct_field_exists(eph, "tpuls0")) {
   eph = struct_combine(eph, struct { tpuls0 = eph.t0, ppuls = eph.p0 });
 }

 variable scramble = qualifier("scramble", 0.0);
 variable dn = qualifier("dn", 1);

 variable atimes, nums;

 % correct the reference time for orbit (if orbit given)
 variable maxiter = 50;
 variable limit = 1e-12;
 variable tn0, tn0_new = eph.tpuls0, tn0o;
 variable m=0, z;
 tn0o = tn0_new;
 do
 {
   tn0 = tn0_new;
   if (orb != NULL && orb.asini>0 && orb.porb>0)
   {
     z = BinaryPos(eph.tpuls0; porb=orb.porb, eccentricity=orb.ecc, omega=orb.omega, asini=orb.asini, t0=orb.tau, pporb=orb.pporb);
     z = z / 86400.;
   } else z = 0.;
   tn0_new = tn0o - z;
   m++;
 } while (abs(tn0_new - tn0) > limit && m<maxiter);
 tn0_new = tn0;
 % because tn0 != given reference time for pulse period, the pulse
 % ephemeris at tn0 must be calculated now
 eph = pulseperiod_transform(tn0, eph);
  
 % calculate the pulse numbers roughly
 variable ndx;
 if (n == NULL)
 {
   nums = round([(tmin-eph.tpuls0) / (eph.p0/86400.):(tmax-eph.t0) / (eph.p0/86400.):dn]); % all pulse numbers
   ndx = [0:length(nums)-1];
 }
 else
 {
   nums = round((urand(n)*(tmax-tmin)+(tmin-eph.tpuls0)) / (eph.p0/86400.)); % random pulse numbers
   nums = nums[array_sort(nums)]; % sort pulse numbers
   % check on multiple equal pulse numbers
   ndx = wherenot(nums[[1:length(nums)-1]] - nums[[0:length(nums)-2]] == 0); % difference to next pulse number = 0 -> equal
   % only use not equal numbers
   ndx = [ndx,length(nums)-1]; % also include last number
   nums = nums[ndx];
 }
 % apply ephemeris and orbit
 atimes = pulse_time(nums, struct_combine(eph, struct { ppuls = eph.p0, tpuls0 = eph.t0 }), orb);

 % scramble arrival times and calculate the error
 atimes += grand(length(ndx))*scramble/86400.;
 variable atimes_err;
 if (scramble == 0) atimes_err = 1e-3 * eph.p0 * ones(length(atimes)) / 86400.;
 else atimes_err = ones(length(atimes))*scramble/86400.;

 return struct { arrtimes = atimes, error = atimes_err, arrnum = nums - nums[0], numref = ones(length(atimes))*0, reft0 = tn0o };
} %}}}


private define atime_sim_residuals_maxdif(x) %{{{
% Determine the maximum of the residuals of the
% parameter given by the necessary qualifier 'par'
% and its value 'x'. Use in the atime_sim_residuals
% to find the maximum variation of a parameter to
% produce nice plots.
{
  variable par = qualifier("par", NULL);
  variable id = qualifier("id", 1);
  if (par == NULL) return NULL;
  % set parameter and evaluate
  set_par(par,x);
  ()=eval_counts(;fit_verbose=-2);
  % return maximum residuals
  variable res = max(abs(get_data_counts(id).value-get_model_counts(id).value))*86400/get_par(sprintf("arrtimes(%d).ppuls",id));
  return res;
} %}}}

%%%%%%%%%%%%%%%%%%%%%%%%
define atime_sim_residuals()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_sim_residuals}
%\synopsis{simulates arrival times to calculate how the
%  residuals depend on parameter variations}
%\usage{atime_sim_residuals(Double_Type tmin, tmax, Struct_Type eph, orb, String_Type psfile);}
%\qualifiers{
%    \qualifier{n}{number of variations for each parameter
%           and sign (-> 2*n variatons, default: 3)}
%    \qualifier{tpd}{number of simulated arrival times per day
%           (default: 10)}
%    \qualifier{mres}{maximum allowed residuals (=yrange) in
%           units of pulse phase (default: 0.45),
%           must be in the range of 0.0-0.45}
%    \qualifier{minr}{smallest allowed relative variation of a
%           parameter, used to determine the overall
%           variation of this parameter to produce
%           nice plots (default: 1e-10)}
%    \qualifier{pars}{only simulate this given parameters
%           (default: all except tpuls0 and pporb)}
%}
%\description
%    This function determines the dependency of the
%    residuals on the given orbit and pulse ephemeris.
%    Therefore pulse arrival times are simulated and
%    the fit parameters are variied in the way, that
%    the shape of the resulting residuals can be seen
%    well. The resulting plots are stored in a Post-
%    Script file specified by the filename 'psfile'.
%    The labels show the absolute variation of the
%    the parameter.
%    The simulated times will be in the range of
%    'tmin' to 'tmax' (in MJD). The orbital parameter
%    and the pulse ephemeris structure must be in the
%    same form described in the function
%    check_pulseperiod_orbit_struct.
%\seealso{atime_sim, check_pulseperiod_orbit_struct, arrtimes}
%!%-
{
 variable tmin, tmax, eph, orb, psfile;
 switch(_NARGS)
   { case 5: (tmin,tmax,eph,orb,psfile) = (); }
   { help(_function_name()); return; }

 ifnot (check_pulseperiod_orbit_struct(eph)) { vmessage("error (%s): pulse period structure not given properly", _function_name); return; }
 if (orb == NULL) { vmessage("error (%s): orbit structure not given!", _function_name); return; }
 ifnot (check_pulseperiod_orbit_struct(orb)) { vmessage("error (%s): orbit structure not given properly", _function_name); return; }
 
 % backwards compatibility
 if (orb != NULL && not struct_field_exists(orb, "torb0")) {
   orb = struct_combine(orb, struct { torb0 = orb.tau });
 }
 if (not struct_field_exists(eph, "tpuls0")) {
   eph = struct_combine(eph, struct { tpuls0 = eph.t0, ppuls = eph.p0 });
 }

 variable n = qualifier("n",3);
 variable mres = qualifier("mres",0.45);
 variable minr = qualifier("minr",1e-10);
 variable tpd = qualifier("tpd",10);
#ifexists xfig_plot_new
 variable uxfig = qualifier_exists("xfig");
#else
 variable uxfig = 0;
#endif
 variable simpars = qualifier("pars",["ppuls","pdot","p2dot","p3dot","porb","ecc","omega","asini","torb0"]);
 ifnot (0.0 <= mres <= 0.45) { vmessage("warning (%s): given residual range must be between 0.0 and 0.45, using the maximum range", _function_name); mres=0.45; }

 % simulate arrival times
 variable s = atime_sim(tmin-1, tmax+1, eph, orb; dn = int(round((tmax-tmin+2)*tpd)));

 % define arrival times and set parameters
 variable id = define_atime(s)[0];

 variable tpl = int(round(0.5*(tmax + tmin)));
 ifnot (uxfig) ()=open_plot(sprintf("%s/cps",psfile));
 variable v;

 % loop over all model parameters
 variable pars = struct_combine(eph, orb);
 foreach (simpars)
 {
   if (uxfig)
   {
#ifexists xfig_plot_new
     variable pl = xfig_plot_new(10,7);
     pl.world(tmin-tpl, tmax-tpl, -mres, mres);
     pl.xlabel(sprintf("Time (MJD - %.2f)", tpl));
     pl.ylabel("Residuals (Pulse Phase)");
     pl.plot([tmin-tpl, tmax-tpl], [0,0]; line=2);
#else
     variable pl = NULL;
     vmessage("%s: xfig module not loaded", _function_name); return;
#endif
   }
   variable par = ();
   ifnot (struct_field_exists(pars,par)) { vmessage("warning (%s): unknown parameter %s", _function_name, par); return; }
   variable value = get_struct_field(pars, par);
   variable parstr = sprintf("arrtimes(%d).%s",id,par);
   % find maximum variation to get the given phase shift 'mres'
   atime_set_ephemeris(id, eph, orb);
   variable maxvar = NULL, minvar = NULL, mm = minr;
   while (maxvar == NULL && minvar == NULL)
   {
     variable nvmn = value*(1.-mm);
     variable nvmx = value*(1.+mm);
     % check on hard limits
     while (get_par_info(parstr).hard_min > nvmn)
     {
%       sprintf("warning (%s): residual range for parameter %s not reached due to its hard limit",_function_name,par);
       minvar = value*(1.-mm/10.);
       nvmn = value*(1.-mm/10.);
     }
     while (get_par_info(parstr).hard_max < nvmx)
     {
%       sprintf("warning (%s): residual range for parameter %s not reached due to its hard limit",_function_name,par);
       maxvar = value*(1.+mm/10.);
       nvmx = value*(1.+mm/10.);
     }
     % check on soft limits
     variable vmin = get_par_info(parstr).min; if (vmin > nvmn) vmin = nvmn - 1e-26;
     variable vmax = get_par_info(parstr).max; if (vmax < nvmx) vmax = nvmx + 1e-26;
     set_par(parstr, value, 0, vmin, vmax);
     % find values
     if (maxvar == NULL) maxvar = find_function_value(&atime_sim_residuals_maxdif, mres, value, nvmx; qualifiers = struct { par = parstr, id = id }, quiet, eps=1e-3);
     if (minvar == NULL) minvar = find_function_value(&atime_sim_residuals_maxdif, mres, nvmn, value; qualifiers = struct { par = parstr, id = id }, quiet, eps=1e-3);
     mm *= 2.0;
   }
   ifnot (maxvar == NULL || minvar == NULL) mm = min(([maxvar,minvar] / value - 1.) * [1., -1.]);
   else if (minvar == NULL) mm = maxvar / value - 1.;
   else mm = 1. + minvar / value;
   atime_set_ephemeris(id,eph,orb);
   ifnot (uxfig) title(sprintf("%s = %e %s",par,value,get_par_info(parstr).units));
   % loop over variations
   _for v (-n, n, 1)
   {
     ifnot (v==0)
     {
       % define color
       variable cs = .19 + abs(v)*(.8/n);
       ifnot (uxfig)
       {
         if (v>0) _pgscr(16+v+n,0,0,cs);
         else _pgscr(16+v+n,cs,0,0);
       }
       % set variation and evaluate the model
       variable newv = value*(1. + mm*v/n);
       vmin = get_par_info(parstr).min; if (vmin > newv) vmin = newv - 1e-26;
       vmax = get_par_info(parstr).max; if (vmax < newv) vmax = newv + 1e-26;
       set_par(parstr, newv, 0, vmin, vmax);
       ()=eval_counts(;fit_verbose=-2);
       % define the label
       variable data = get_data_counts(id);
       variable model = get_model_counts(id);
       variable teph, torb;
       (teph, torb) = atime_get_ephemeris(id);
       variable me = round(mean(data.value));
       variable in = where(model.bin_lo > me + .95*(tmax-tmin) - abs(tmin - tpl))[0];
       variable lx = data.bin_lo[in] - me;
       variable ly = (data.value[in] - model.value[in])*86400 / pulseperiod(data.value[in], teph, torb);
       if (ly<-mres) ly = -0.9*mres;
       if (ly>mres) ly = 0.9*mres;
       % plot residuals
       ifnot (uxfig)
       {
         plot_atime(;style=-1,col=16+v+n,oplot=(v>-n),xrng=[tmin,tmax]-tpl,yrng=[-mres,mres],connect_points,noerrbars);
         color(16+v+n); xylabel(lx,ly,sprintf("%.2e",value*mm*v/n),0.,0.5);
       }
       else
       {
	 variable res = (data.value - model.value)*86400 / pulseperiod(data.value, teph, torb);
	 pl.plot(data.value - tpl, res; color = "#"+rgb2hex(v<0 ? cs : 0, 0, v<0 ? 0 : cs; string));
	 pl.xylabel(0, .8*mres*v/n, sprintf("%.2e",value*mm*v/n), 0, 0; color = rgb2hex(v<0 ? cs : 0, 0, v<0 ? 0 : cs; str));
       }
     }
   }
   if (uxfig) pl.render(sprintf("%s_%s.eps", psfile, par));
 }

 ifnot (uxfig) close_plot;
 delete_data(id);
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_sim_orbitimpact()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_sim_orbitimpact}
%\synopsis{determines the impact of uncertainties of orbital
%  parameters on the pulse ephemeris}
%\usage{atime_sim_orbitimpact(Double_Type tmin, tmax, Struct_Type eph, orb, dorb);}
%\qualifiers{
%    \qualifier{tpd}{number of simulated arrival times per day
%            (default: 10)}
%    \qualifier{pars}{parameters of the pulse ephemeris which
%            are used to fit the simulated data
%            (default: ["ppuls", "pdot", "p2dot",
%                       "p3dot"])}
%    \qualifier{range}{allowed fitting ranges of the parameters
%            given by the 'pars' qualifier in accordant
%            units. The ranges have to be given as an
%            array of alternate min/max values for each
%            parameter in 'pars'}
%}
%\description
%    An uncertainty of an orbital parameter may lead
%    to a wrong pulse ephemeris after a successful
%    fit of pulse arrival times. This function deter-
%    mines the impact of uncertainties on the pulse
%    ephemeris by simulating arrival times in the
%    range 'tmin' and 'tmax' and fitting them within
%    the given orbital uncertainties. The returned
%    structure itself contains structures for each
%    orbital parameter, which contain the fitted
%    pulse ephemeris and therefore the impact of this
%    parameter. The highest phase shift left in the
%    residuals is also returned for each orbital
%    parameter.
%    The given orbital and pulse ephemeris structure
%    must fullfil the conditions described in the
%    check_pulseperiod_orbit_struct function. The uncertainties of
%    the parameters are itself given by a structure,
%    which may either contain double types for the
%    errors or arrays with two elements for the lower
%    and upper errors.
%\seealso{atime_sim, check_pulseperiod_orbit_struct, arrtimes}
%!%-
{
 variable tmin, tmax, eph, orb, dorb;
 switch(_NARGS)
   { case 5: (tmin,tmax,eph,orb,dorb) = (); }
   { help(_function_name()); return; }

 % backwards compatibility
 if (orb != NULL && not struct_field_exists(orb, "torb0")) {
   orb = struct_combine(orb, struct { torb0 = orb.tau });
 }
 if (not struct_field_exists(eph, "tpuls0")) {
   eph = struct_combine(eph, struct { tpuls0 = eph.t0, ppuls = eph.p0 });
 }

 ifnot (check_pulseperiod_orbit_struct(eph)) { vmessage("error (%s): pulse period structure not given properly", _function_name); return; }
 if (orb == NULL) { vmessage("error (%s): orbit structure not given!", _function_name); return; }
 ifnot (check_pulseperiod_orbit_struct(orb)) { vmessage("error (%s): orbit structure not given properly", _function_name); return; }
  
 % check uncertainty structure
 ifnot (typeof(dorb) == Struct_Type) throw RunTimeError, "given uncertainties must be a structure";
 else ifnot (struct_field_exists(dorb, "porb")
          && struct_field_exists(dorb, "torb0")
          && struct_field_exists(dorb, "asini")
          && struct_field_exists(dorb, "ecc")
          && struct_field_exists(dorb, "omega")) throw RunTimeError, "uncertainties are not defined properly";
 ifnot (struct_field_exists(dorb, "pporb")) dorb = struct_combine(dorb, struct { pporb = 0. });

 variable tpd = qualifier("tpd", 10);
 variable fpars = qualifier("pars", ["ppuls", "pdot", "p2dot","p3dot"]);
 variable range = qualifier("range", NULL);

 % simulate arrival times
 variable s = atime_sim(tmin-1, tmax+1, eph, orb; dn = int(round((tmax-tmin+2)*tpd)));
 % define arrival times and set parameters
 variable id = define_atime(s)[0];
 ifnot (range == NULL)
 {
   ifnot (2*length(fpars) == length(range)) throw RunTimeError, "'range' array must be of double length as 'pars' array";
   variable i;
   _for i (0, length(fpars)-1, 1)
     set_par(sprintf("arrtimes(%d).%s", id, fpars[i]), get_struct_field(eph, fpars[i]), 0, range[2*i], range[2*i+1]);
 }

 % loop over all model parameters
 variable impact = struct { porb, torb0, asini, ecc, omega, pporb };
 foreach (get_struct_field_names(orb))
 {
   variable p, stat, par = ();
   variable value = get_struct_field(orb, par);
   variable error = get_struct_field(dorb, par);
   ifnot (typeof(error) == Array_Type) error = [error,error];
   if (length(error) > 2) { vmessage("warning (%s): length of array of uncertainty %s wrong, trimming...", _function_name, par); error = error[[0,1]]; }

   % prepare resulting structure
   set_struct_field(impact, par, struct { ppuls, pdot, p2dot, p3dot, maxshift });
   % freeze all parameters
   freeze(freeParameters);
   _for i (-1, 1, 2)
   {
     atime_set_ephemeris(id, eph, orb);
     if (error[(i+1)/2] > 0.)
     {
       set_par(sprintf("arrtimes(%d).%s", id, par), value + sign(i)*error[(i+1)/2]); % set uncertain parameter
       % thaw pulse ephemeris and fit
       foreach (fpars)
       {
         p = ();
         thaw(sprintf("arrtimes(%d).%s", id, p));
         ()=fit_counts(&stat; fit_verbose=-2);
       }
     }
     % store fitted parameters
     foreach (fpars)
     {
       p = ();
       set_struct_field(get_struct_field(impact, par), p, get_par(sprintf("arrtimes(%d).%s",id,p)));
     }
     % store highest phase shift left
     get_struct_field(impact, par).maxshift = max(abs(get_data_counts(id).value-get_model_counts(id).value))*86400/get_par(sprintf("arrtimes(%d).ppuls", id));
   }
 }

 delete_data(id);
 return impact;
} %}}}
