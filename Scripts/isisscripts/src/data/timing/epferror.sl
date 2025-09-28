% used as default for the 'pget' qualifier: determine the maximum in
% the chi^2 landscape and return the corrsponding period
private define _epferror_pget(p, stat) {
  variable imax = where_max(stat);
  if (length(imax) != 1) { return -1; }
  return p[imax[0]];
}

%%%%%%%%%%%%%%%%%%%%%%%%
define epferror ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{epferror}
%\synopsis{Estimate epoch folding uncertainty with Monte-Carlo simulation
%    approach.}
%\usage{(Double_Type err) = epferror(Double_Type time, rate, period[, rate_error]);}
%\qualifiers{
%\qualifier{pstart}{start period for epoch folding period search.
%      (default: 0.5*period)}
%\qualifier{pstop}{stop period for epoch folding period search.
%      (default: 1.5*period)}
%\qualifier{ntrial}{number of MC iterations. (default: 20)}
%\qualifier{pget}{function reference to determine the period from the
%            chi^2 landscape. Arguments passed are
%              Double_Type[] p, stat
%            as returned by epfold. Has to return the period and -1
%            if the period could not be determined. (default: find
%            maximum, see below)}
%\qualifier{pdist}{set to a variable reference in order to retrieve
%             the simulated period distribution.}
%\qualifier{chatty}{chattiness of this function: If >0 print some debug
%              messages. If >1 plot the chi^2 landscape at each MC
%              iteration. (default: 0)}
%\qualifier{fchatty}{chattiness piped to epfold.}
%}
%\description
%    Note: All qualifiers are passed to pfold (for pulse profile
%    calculation) and epfold (for period search)! 
% 
%    This routine tries to estimate the uncertainty of a previously
%    received period using the epoche folding approach (see epfold).
%    It is adopted from the IDL script with the same name, but does
%    not yet allow for GTI or Poisson statistics. It implements the
%    following strategy:
%    1.) calculate a mean profile with given period. 
%    2.) compute the intensity for all times applying the
%        period multiplied profile.
%    3.) simulate an uncertainty for all times (assuming normal
%        distribution with sigma = error, or, if not given
%        sqrt(rate)).
%    4.) perform epoch folding for that simulated lightcurve.
%    5.) determine the maximum of the epoch folding chi^2 landscape
%        and remember the corresponding period. Use the 'pget'
%        qualifier in order to implement a user-defined approach!
%    6.) go to step 2.) Ntrial times, which results in a distribution
%        of determined periods.
%    7.) compute the standard deviation of the period distribution
%        obtained and return this as the uncertainty of the intial
%        epoch folding
% 
%    NOTE: The processing may last a long time (be prepared to wait  
%          hours to weeks)!
%
%    NOTE: Is is _important_ to use the same qualifiers used for
%          epfold previously for the actual data! That is epferror
%          has to search for the period in the same way as for the
%          data! This might further require to provide a function
%          for the determination of the best period from an epoch
%          folding result (see 'pget' qualifier).
%
%    References:
%       Davies, S.R., 1990, MNRAS 244, 93
%       Larsson, S., 1996, A&AS 117, 197
%       Leahy, D.A., Darbro, W., Elsner, R.F., et al., 1983,
%          ApJ 266, 160-170
%       Schwarzenberg-Czerny, A., 1989, MNRAS 241, 153
%
%!%-
{
  variable intime, inrate, period, rateerr = Double_Type[0] ;
  
  switch(_NARGS)
     {case 3: (intime,inrate,period) = ();}
     {case 4: (intime, inrate, period, rateerr) = (); }
     {help(_function_name()); return; }

 
   % qualifiers for epfold
   variable pstop = qualifier("pstop", 1.5*period) ;  
   variable pstart = qualifier("pstart", 0.5*period) ;
   variable pget = qualifier("pget", &_epferror_pget) ;
   if (pget != NULL && typeof(pget) != Ref_Type) {
     vmessage("error (%s): pget has to be a function reference!",
              _function_name);
   }

   %runs of the Monte Carlo loop
   variable ntrial = qualifier("ntrial", 20) ;
   
   %chattiness of the script: chatty != print progress
   %chatty > 1 : overplot chi^2 distribution
   variable chatty = qualifier("chatty", 0) ;
   variable fchatty = qualifier("fchatty", 0) ;
 
   if (chatty) {variable begin = _time ; message("Started MC loop..."); } 
  
   if (length(rateerr) == 0) {rateerr= sqrt(inrate);} 
  
   variable profile = pfold(intime, inrate, period ;; __qualifiers  ) ;

   variable simbaserate = interpol_points((intime mod period)/period, (profile.bin_lo+profile.bin_hi)/2., profile.value) ;

    variable simrate, epf, maxchierg = Double_Type[ntrial], i;

  variable bad = Integer_Type[ntrial] ;
  
  _for i (0, ntrial-1, 1) {
   
   % seed_random(qualifier("seed", _time)) ;

   % print(qualifier("seed", _time)) ;
    
   simrate = rateerr* grand(length(simbaserate)) + simbaserate ;

       % print(intime) ;
    
    % epf = epfold(intime, simrate, pstart, pstop; @__qualifiers(), chatty=fchatty ) ;  % requires S-Lang >= pre-2.2.3-39
    epf = epfold(intime, simrate, pstart, pstop;; struct_combine(__qualifiers(), struct { chatty=fchatty }));

    variable psim = @pget(epf.p, epf.stat);
    if (psim > -1) {
      maxchierg[i] = psim;
    } else {
      message("no unique maxium found, ignoring!");
      bad[i] = 1;
    }

    if (chatty) {
     ()=printf("Processed: %.2f%%  ---  Period %f\n", (100.*i)/ntrial, maxchierg[i]) ;
   }
  
   if (chatty > 1){ 
     color(2) ; oplot(epf.p, epf.stat) ;
   }
    
  }
  
  variable  err = moment(maxchierg[wherenot(bad)]).sdev ;
  
  if (chatty){
    ()=printf("Total runtime was %.2f sec.\n", _time-begin) ;
    ()=printf("%d failed period determinations.\n", length(where(bad)));
    ()=printf("Estimated uncertainty is %f.\n", err);
  }
  % return(struct{t = intime, r = simrate, pstart=pstart,p stop=pstop}) ;

  if (qualifier_exists("pdist")) {
    variable pdist = qualifier("pdist");
    if (typeof(pdist) != Ref_Type) {
      vmessage("error (%s): pdist has to be a variable reference!",
               _function_name);
      @pdist = NULL;
    } else {
      @pdist = maxchierg;
    }
  }
 return err ;
}
