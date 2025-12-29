
% -*- mode: slang; mode: fold -*-

%%%%%%%%%%%%%%%%%%%%%%%%
define atime_det_beta()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_det_beta}
%\synopsis{Determines the arrival times from a lightcurve using a pulse pattern}
%\usage{Struct_Type atime_det_beta(Struct_Type lc, Struct_Type[] pattern, Double_Type t0[, Double_Type period]);
% or Struct_Type atime_det_beta(String_Type lc, Struct_Type[] pattern, Double_Type t0[, Double_Type period]);}
%\qualifiers{
%    \qualifier{time}{name of the time field in the FITS-file,
%             see fits_read_lc for details}
%    \qualifier{indiv}{determine individual pulses. If no value
%             is assigned, all arrival times are re-
%             turned. Otherwise a given integer sets
%             the number of pulses to average}
%    \qualifier{movem}{if 'indiv' is greater one, so it is aver-
%             aged over a number of arrival times, a
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
%    \qualifier{mcgaus}{fit a gaussian to the Monte Carlo distribution, if
%             used for error estimation}
%    \qualifier{ccflim}{matches below the given cross-correlation
%             values are skipped (default = 0), allowed
%             range is -1 to 1.}
%    \qualifier{numdif}{maximum allowed deviation from expected
%             pulse number (default = 0.5 phases)}
%    \qualifier{match}{reference to a variable (&var) where the
%             matching pulses are saved as structures
%             similar to the reference profile}
%    \qualifier{slope}{reference to a variable (&var) where the
%             slope of the lightcurve is saved, which
%             is calculated by an interpolation of
%             the mean count rate in the single pulses}
%    \qualifier{skipsl}{do not take the slope of the lightcurve
%             into account}
%    \qualifier{mmnorm}{by default the pulse pattern and the
%             pulses are renormalized by
%               f = (f - mean(f)) / sdev(f)
%             If this qualifier is set, the min/max-
%             normalizaton is used instead
%               f = (f - max(f)) / (max(f) - min(f))}
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
%    phase connection. The patterns must be given as a
%    structure with the fields
%      Double_Type bin_lo
%      Double Type bin_hi
%      Double_Type value
%      Double_Type error,
%    as, for example, returned by the 'epfold' function.
%    If multiple patterns are given, the best matching
%    one is used to determine the arrival times.
%    The lightcurve can be passed by a structure with
%    the fields 'time', 'rate', 'error' and 'fracexp',
%    or by the filename to a FITS-file.
%    To determine individual pulses as enabled by the
%    'indiv' qualifier an approximate pulse period must
%    be given (in seconds) to cut the lightcurve into
%    segments were the pulses are searches. Instead of
%    the pulse period an array of two elements defining
%    a range of periods (min/max values, in seconds)
%    may also be given. In that case the 'getVarPeriod'
%    function is used to determine the pulse period and
%    additional qualifiers are passed.
%    If the 'indiv' qualifier is omitted the given
%    lightcurve is folded and the returned phase shift
%    corresponds to the phase shift of the used pattern
%    to the resulting profile.
%    If the method for estimating the uncertainty of
%    the phase shifts is not specified by qualifiers,
%    the default uncertainty is set to one phase bin.
%    The number of bins are derived from the given
%    pulse pattern.
%    The returned structure has the following fields:
%    t0       - array of first time bins of the pulses
%               determined from the lightcurve (MJD)
%    phi      - array of phase shifts of the pulses
%               with respect to the used pattern
%    error    - uncertainties of 'phi'
%    arrnum   - relative pulse number of each arrival
%               time to a specific pulse. Dramatically
%               increases the speed of a fit.
%    numref   - index of the reference pulse, should be
%               zero. Is updated if arrival times are
%               merged.
%    reft0    - the given reference time t0
%    p0       - the given pulse period
%    usedpat  - index of the used pulse pattern in case
%               of multiple ones given
%    The arrival times can be calculated by
%      t = t0 + phi * p0
%    as a first guess, since p0 is a function of time.
%    This fact is handled properly by the fit function
%    'arrtimes'. The function 'atime_calc' calculates
%    the arrival times according to the above equation
%    with respect to a given pulse ephemeris and
%    orbital  parameters.
%\seealso{atime_calc, atime_merge, save_atime, define_atime, arrtimes, pfold}
%!%-
{
 variable lcF, refprof, reft0, per;
 switch(_NARGS)
   { case 4: (lcF,refprof,reft0,per) = (); }
   { help(_function_name()); return; }

 % qualifiers and initialization of variables
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
 variable dummy, slope = qualifier("slope", &dummy);
 ifnot (typeof(slope) == Ref_Type || typeof(slope) == Null_Type) { vmessage("warning (%s): 'slope' has to be of Ref_Type", _function_name); slope = &dummy; }
  
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
 }
 else ifnot (typeof(per) == Double_Type || per > 0)
   throw RunTimeError, "pulse period must be a single positive double type, a two element array or a structure";

 % renorm reference profile(s)
 variable p;
 _for p (0, length(refprof)-1, 1)
 {
   if (qualifier_exists("mmnorm"))
   {
     refprof[p].error = refprof[p].error/(max(refprof[p].value)-min(refprof[p].value));
     refprof[p].value = (refprof[p].value-min(refprof[p].value))/(max(refprof[p].value)-min(refprof[p].value));
   }
   else
   {
     variable mom = moment(refprof[p].value);
     refprof[p].error = refprof[p].error / mom.sdev;
     refprof[p].value = (refprof[p].value - mom.ave) / mom.sdev;
   }
 }

 % substract the slope from the lightcurve
 ifnot (qualifier_exists("skipsl"))
 {
   @slope = pulse2pulse_flux_lc(lc, per);
   lc.rate -= (@slope).rate;
 }
  
 variable nums;
 variable nbins = length(refprof[0].value);
 if (indiv[0]) % prepare section to find individual pulses
 {
   % number of pulses in lc to look for
   nums = ceil((max(lc.time)-min(lc.time)) / per * 86400);
   ifnot (indiv[2]) nums = nums / indiv[1]; % reduced number by no moving mean
   nums = int(nums);
   % rebin lightcurve similar to profile if ALL pulses have to be found
   if (indiv[1] == 1) lc = rebin_lc(lc, per / 86400 / nbins);
 }
 else nums = 1;

 % loop over number of pulses (except if using profile only)
 % to get the pulse arrival times
 if (chatty) message(nums == 1 ? "Matching profiles" : "Looking for matches in lightcurve");
 variable i, f, ccf, ndx, j=0, lastphi = NULL, lastnum, ir = NULL;
 variable t0 = Double_Type[0], phi = Double_Type[0], dphi = Double_Type[0];
 variable npuls = Integer_Type[0], refpuls = Integer_Type[0];
 variable usedpat = Integer_Type[0], errdx;
 _for i (0, nums-1, 1)
 {
   % determine arrival times of (each) individual pulses
   if (indiv[0])
   {
     % find actual pulse part of lc (attend moving mean, indiv[2]==1)
     if (indiv[2]) ndx = where(lc.time[0] + per/86400*i <= lc.time < lc.time[0] + per/86400*(i+indiv[1]));
     else ndx = where(lc.time[0] + per/86400*i*indiv[1] <= lc.time < lc.time[0] + per/86400*(i+1)*indiv[1]);
     % only use if number of bins are correct and ALL pulses have to be found
     if (length(ndx) == nbins && indiv[1] == 1)
     {
       t0 = [t0, lc.time[ndx[0]]];
       % extract part
       f = struct { value = lc.rate[ndx], error = lc.error[ndx], bin_lo = lc.time[ndx]-lc.time[ndx[0]], bin_hi = NULL };
       f.bin_hi = make_hi_grid(f.bin_lo);
       j++;
     }
     % average over given number of pulses by folding the lightcurve
     else if (length(ndx) >= nbins && indiv[1] > 1)
     {
       t0 = [t0, lc.time[ndx[0]]];
       f = pfold(lc.time[ndx], lc.rate[ndx], per/86400, lc.error[ndx];; struct_combine(__qualifiers, struct { nbins = nbins, dt=lc.fracexp[ndx], t0=t0[-1] }));
       if (sum(isnan(f.value)) > 0) f = NULL;
       else j++;
     }
     else f = NULL;
   }
   % arrival time of the pulse profile
   else
   {
     t0 = [t0, lc.time[0]];
     % create profile
     f = pfold(lc.time, lc.rate, per/86400, lc.error;; struct_combine(__qualifiers, struct { nbins = nbins, dt=lc.fracexp, t0=t0[-1] }));
   }

   ifnot (f == NULL)
   {
     % renorm profile / lc part
     if (qualifier_exists("mmnorm"))
     {
       f.error = f.error/(max(f.value)-min(f.value));
       f.value = (f.value-min(f.value))/(max(f.value)-min(f.value));
     }
     else
     {
       mom = moment(f.value);
       f.error = f.error / mom.sdev;
       f.value = (f.value - mom.ave) / mom.sdev;
     }
     % loop over all given pattern
     variable ccfmax = -2., newusedpat;
     _for p (0, length(refprof)-1, 1)
     {
       variable tempccf = CCF_1d(refprof[p].value, f.value);
       % assign cross-correlation in case of a better match
       if (max(tempccf) > ccfmax)
       {
	 ccf = @tempccf;
	 ccfmax = max(tempccf);
	 newusedpat = p;
       }
     }
     usedpat = [usedpat, newusedpat];
     if (chatty == 2)
     {
       vmessage("  -> cross-correlation is %.3f", max(ccf));
       if (length(refprof) > 1) vmessage("     with pulse pattern no. %d", usedpat[-1]);
     }
     % check on ccf limit
     if (max(ccf) < ccflim)
     {
       ccf[0] = _NaN;
       message("  -> below the given limit and SKIPPED");
     }
     ifnot (isnan(ccf[0]))
     {
       % get reference pulse number, if not set
       % (is needed if pulse number 0 had less nbins than required)
       if (ir == NULL) ir = i;

       %%% PHASE SHIFT DETERMINATION %%%
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
       variable actphi = 1.*where_max(ccf) / (length(ccf)-1);
       if (length(actphi) > 1) actphi = min(actphi);
       if (actphi == 1.) actphi = 0.;
       if (qualifier_exists("debug"))
       {
	 vmessage("  phase shift: %.3f", actphi);
	 color(2); connect_points(1); point_style(-1);
	 oplot([actphi,actphi],[-1,1]);
	 if (typeof(debug) == String_Type && debug == "user") ()=keyinput(;silent, nchr=1);
	 else sleep(debug);
	 color(1); xlabel("Pulse Phase"); xrange;
	 ylabel("Normalized Count Rate"); title("Aligned Pulse and Reference");
	 yrange(min([f.value-f.error,refprof[usedpat[-1]].value-refprof[usedpat[-1]].error]),
		max([f.value+f.error,refprof[usedpat[-1]].value+refprof[usedpat[-1]].error]));
         hplot_with_err(f.bin_lo, f.bin_hi, shift(f.value, -int(actphi*nbins)), f.error);
	 ohplot_with_err(refprof[usedpat[-1]]);
	 if (typeof(debug) == String_Type && debug == "user") ()=keyinput(;silent, nchr=1);
	 else sleep(debug);
       }
       % set relative pulse number
       variable actnum;
       if (indiv[2]) actnum = i-ir;
       else actnum = (i-ir) * indiv[1];
       % add match to returning structure array (if set)
       if (typeof(matchret) == Ref_Type)
         @matchret = [@matchret, struct { bin_lo = f.bin_lo, bin_hi = f.bin_hi, value = shift(f.value, -int(actphi*nbins)),
                                          error = shift(f.error, -int(actphi*nbins)), ccf = max(ccf), tstart = lc.time[ndx[0]], tstop = lc.time[ndx[-1]] }];

       % check if phase shift does not match the pulse number
       ifnot (lastphi == NULL)
       {
	 variable is = actphi - lastphi;
	 variable should = actnum - lastnum;
       	 if (abs(is - should) > qualifier("numdif", .5))
       	 {
       	   if (qualifier_exists("debug")) vmessage("  numdif is %.3f, should be %.3f -> shifting phase", is, should);
       	   actphi = actphi - round(is-should);
       	 }
	 else if (qualifier_exists("debug")) vmessage("  numdif is %.3f, should be %.3f", actphi - lastphi, actnum - lastnum);
       }
       lastphi = actphi;
       lastnum = actnum;
       phi = [phi, actphi];
       npuls = [npuls, actnum];
       refpuls = [refpuls, 0];

       %%% ERROR ESTIMATION %%%
#ifexists gsl->interp_cspline
       if (mcerr > 1 && ccfint > 1) % estimate error using Monte Carlo techniques
       {
	 variable mc, dphis = Double_Type[mcerr];
	 _for mc (0, mcerr-1, 1) % MC loop
	 {
	   % random noisy profile
	   variable fm = f.value + grand(length(f.value)) * f.error;
	   variable refm = refprof[usedpat[-1]].value + grand(length(refprof[usedpat[-1]].value)) * refprof[usedpat[-1]].error;
           % cross correlate
           ccf = CCF_1d(refm,fm);
	   % periodic borders
	   ccf = [ccf, ccf[0]];
	   ccf = gsl->interp_cspline_periodic([0:length(ccf)-1:1./ccfint], [0:length(ccf)-1], ccf);
	   % get shift
	   variable mphi = 1.*where_max(ccf) / (length(ccf)-1);
           if (length(mphi) > 1) mphi = min(mphi);
           if (mphi == 1.) mphi = 0.;
	   dphis[mc] = mphi;
	 }
	 % do a gaussian fit to the distribution
	 if (qualifier_exists("mcgaus"))
	 {
	   variable x_lo = [0.:2.-1./sqrt(mcerr):1./sqrt(mcerr)];
           variable x_hi = x_lo + x_lo[1];
           variable h = histogram(dphis, x_lo, x_hi);
   	   dphi = [dphi, array_fit_gauss(x_lo, h,, x_lo[where_max(h)[0]], moment(dphis).sdev, 1000; frz=[0,0,0,1]).sigma];
	 }
	 else dphi = [dphi, moment(dphis).sdev];

	 if (chatty == 2) vmessage("  -> estimated error = %f phases", dphi[-1]);
	 if (qualifier_exists("debug") && qualifier_exists("mcgaus"))
	 {
	   xrange(0,2); yrange(0,1.1*max(h)/sum(h));
	   xlabel("Phase Shift"); ylabel("Number Density");
	   color(1);
	   hplot(x_lo, x_hi, h/sum(h));
           if (typeof(debug) == String_Type && debug == "user") ()=keyinput(;silent, nchr=1);
	   else sleep(debug);
	 }
       }
       else if (varerr > 0)
#else
       if (varerr > 0) % estimate error by a local mean
#endif
       {
	 % calculate local variance
	 errdx = [((length(phi) - 1) / varerr) * varerr: length(phi) - 1]; % indices of last #varerr-1 number of datapoints
	 if (length(errdx) == varerr)
	 {
 	   dphi = [dphi, moment((phi[errdx] - phi[errdx-1]) / (npuls[errdx] - npuls[errdx-1])).sdev * ones(length(errdx))];
           if (chatty == 2) vmessage("  -> estimated error = %f phases", dphi[-1]);
	 }
       }
       % if no error was estimated: error = 1 phase bin       
       else dphi = [dphi, 1./nbins];
     }
   }
 }
 % set remaining errors for local variance
 if (varerr > 0 && length(dphi) < length(phi))
 {
   variable adphi;
   if (length(errdx) == 1 || length(dphi) == 0) adphi = 1./nbins;
   else if (length(errdx) < varerr/2 && length(dphi) > 0) adphi = dphi[-1];
   dphi = [dphi, adphi * ones(length(phi)-length(dphi))];
   if (chatty == 2) vmessage("  -> estimated error = %f phases", adphi);
 }
 if (indiv[0] and chatty) vmessage("  -> individual pulses (%d/%d)", j, int(nums));

 return struct { t0 = t0, phi = phi, error = dphi, arrnum = npuls, numref = refpuls, reft0 = reft0, p0 = per, usedpat = usedpat };
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_merge_beta()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_merge_beta}
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
       else ifnot (reft0 == a1[i-1].reft0) { vmessage("error (%s): reference times of matching profile are not equal", _function_name); return; }
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
   variable ndx = array_sort(merg.t0), nr = @(merg.numref);
   merg.t0 = merg.t0[ndx];
   merg.phi = merg.phi[ndx];
   merg.error = merg.error[ndx];
   merg.arrnum = merg.arrnum[ndx];
   merg.usedpat = merg.usedpat[ndx];
   _for i (0, length(nr)-1, 1) merg.numref[i] = wherefirst(ndx == nr[ndx[i]]); % update reference numbers
 }

 return merg;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define atime_calc_beta()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{atime_calc_beta}
%\synopsis{converts a pulse phaseshift into arrival times}
%\usage{(Double_Type[] arrtimes, errors) = atime_calc(Struct_Type atime, eph[, orb]);
% or (Double_Type[] arrtimes, errors) = atime_calc(Double_Type[] t0, phi, error, Struct_Type eph[, orb]);}
%\description
%    Takes the structure determined by 'atime_det'
%    or an array of times, phase shifts and their
%    errors and returns the pulse arrival times
%      t = t0 + phi * p(t0) [+ z(t0)/c]
%    To calculate the pulse period at each time
%    a pulse ephemeris structure is needed (see
%    'check_pulseperiod_orbit_struct'). If an
%    optional structure containing orbital
%    parameters is given, the Doppler shift delay
%    is included as well.
%\seealso{atime_det, check_pulseperiod_orbit_struct, pulseperiod}
%!%-
{
 variable atime, t0, phi, error, eph, orb = NULL;
 switch(_NARGS)
   { case 2: (atime,eph) = (); }
   { case 3: (atime,eph,orb) = (); }
   { case 4: (t0,phi,error,eph) = (); }
   { case 5: (t0,phi,error,eph,orb) = (); }
   { help(_function_name()); return; }
 if (typeof(atime) == Struct_Type) { t0 = atime.t0; phi = atime.phi; error = atime.error; }
 ifnot (length(t0) == length(phi) == length(error)) { vmessage("%s: t0, phi and error must be of same length", _function_name); return; }

 % backwards compatibility
 if (not struct_field_exists(eph, "p0")) {
   eph = struct_combine(eph, struct { p0 = eph.ppuls, t0 = eph.tpuls0 });
 }
 if (orb != NULL && not struct_field_exists(orb, "tau")) {
   orb = struct_combine(orb, struct { tau = orb.torb0 });
 }
 if (not check_pulseperiod_orbit_struct(eph)) {
   vmessage("error (%s): pulse period is not given properly", _function_name);
 }
 if (orb != NULL && not check_pulseperiod_orbit_struct(orb)) {
   vmessage("error (%s): pulse period is not given properly", _function_name);
 }

 return t0 + phi * pulseperiod(t0, eph, orb)/86400;
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%
define save_atime_beta()
%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{save_atime_beta}
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

 message("not implemented yet");
 return 0;
}
