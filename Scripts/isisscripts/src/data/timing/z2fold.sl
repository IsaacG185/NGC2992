% require("zsquare.sl");

%%%%%%%%%%%%%%%%%%%%%%%%
define z2fold ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{z2fold}
%\synopsis{peforms Z^2_m search on a lightcurve or event data in a given period
%interval}
%\usage{(Struct_Type res) = z2fold(Double_Type t, r, pstart, pstop);
%or (Struct_Type res) = z2fold(Double_Type t, pstart, pstop) ; (event data)}
%
%\qualifiers{
%\qualifier{sampling} {how many periods per peak to use (default=10)}
%\qualifier{nsrch} {how many periods to search in a linear grid (default not set)}
%\qualifier{dp} {delta period of linear period grid (default  not set)}
%\qualifier{m} {number of harmonics used (default =2)}
%\qualifier{chatty} {set the verbosity, (default=0)}
%\qualifier{gti}{GTIs for event data, given as struct{start=Double_Type, stop=Double_Type}} 
%}
%
%\description
%   Performs Z^2_m test  on a given lightcurve or event data between the periods
%   pstart and pstop. The function is based on epfold.sl.
%   GTI correction is implemented only  for event-data.
%
%   By default, periods are sampled according to the triangular rule
%   for estimating the period error, using "sampling" periods per peak.
%   If a linear grid is to be used, either "dp" for a given distance
%   between two consecutive periods or "nsrch" for a given number of
%   periods can be given. These qualifiers are mutually exclusive. 
%
%   The returned structure "res" contains four fields: "p" for the
%   evaluated period and "stat" for the value of the statistic used.
%
%   Please see Buccheri et al., 1983, Astron. Astrophys. 128, 245 for
%   more information on the Z-square statistics. 
%   
%\seealso{zsquare, epfold, pfold}   
%!%-
{
   variable t,r,pstart, pstop ;

  variable eventdata = 0;
  % disable chatty if not set
   variable chatty = qualifier("chatty",0) ;
  
    switch(_NARGS)
    {case 3: (t,  pstart, pstop) = ();
      eventdata = 1 ;
      if (chatty) {print("using event data"); } 
    }
    {case 4: (t,r,pstart, pstop) = (); }
    {help(_function_name()); return; }
  
   variable t0 = qualifier ("t0", t[0]);
   variable nbins = qualifier ("nbins", 20) ;
   variable sampl = qualifier("sampling", 10)  ; %periods per peak
   variable dp = qualifier("dp", -10) ; %delta p for linear period sampling
   variable nsrch = qualifier("nsrch", -10) ; %number of periods in linear period grid

   variable m = qualifier("m", 2) ; % using Z^2_2 as standard method
   if (chatty) {vmessage("Using Z^2_%d statistic\n", m) ; } ;
   
   nsrch = int(nsrch) ;

  % ifnot(qualifier_exists("dt") or eventdata==1){
  %   message("WARNING (epfold): no dt qualifier given, creating differential grid! Might lead to unexpected results!") ;
  % }
   variable dt = qualifier("dt" , make_hi_grid(t)-t) ; %exposure times

  % ifnot (qualifier_exists("gti") or eventdata==0){
  %   message("WARNING (epfold): using eventdata without gti qualifier, taking time of first and last event. This is most likely NOT what you want!") ;
  % }
  % variable gti = qualifier("gti", struct{start=min(t), stop=max(t)}) ;

   variable tges = sum(dt) ; %effective observation time
  
   % if (tges < 0) {message("ERROR (epfold): Please provide lightcurve with continously increasing time (tges was < 0)."); return;}
  
   if (chatty) {message(">> Starting data analysis <<") ;}
       
   if (chatty) {
      ()=printf("Determining number of trial periods between %f and %f.\n", pstart, pstop) ;
   }

   variable ergdim=1 ;
   variable p = pstart ;
   variable i = 1 ;
   
   if (dp > 0 && nsrch == -10)
     {	
	if (chatty) {()=printf("Making linear period grid with delta P = %f.\n", dp) ;}
	p = [pstart:pstop:dp] ;
	ergdim = length(p) ;
     }
   else if (dp == -10  && nsrch > 0)
     {
	if (chatty) {()=printf("Making linear period grid with %d entries.\n", nsrch) ;}
	p = [pstart:pstop:#nsrch] ;
	ergdim = nsrch ;
     }
   else if (dp > 0 && nsrch > 0)
     {
	()=printf("Please use either dp or nsrch!\n") ;
	return NULL ;
     }
   else { 
      if (chatty) ()=printf("Making intelligent grid!\n") ; 
      while (p[-1] <= pstop) 
	{
	   ergdim++ ;
	   p=[p, p[i-1]+p[i-1]*p[i-1]/(tges*sampl) ];
	   i++ ;
   	}
   }
 
   if (chatty) {()=printf("number of periods = %d\n....done\n",ergdim);}
   
   if (chatty) {variable tstart = _time(); variable tlast = _time() ; }
   
   variable ptest = pstart ;
   variable z2 = Double_Type[ergdim] ;
   
   variable chierg = Double_Type[ergdim] ;
   
   variable titer, remain ;

   % %susbstract mean from rate, as we need only the
   % %difference for the statistics and it does not change
   % %the generality
  % ifnot(eventdata){
  % variable rm = moment(r) ;
   % r -= rm.ave ;
      
   % if (chatty)  {
   %    ()=printf("mean = %f \n", rm.ave) ;
   %    % ()=printf("effective observation time: %f\n", tges  );
   % }
  % }
  
   _for i (0, length(p)-1, 1)
     {
	ptest = p[i] ;
        if(eventdata) {z2[i] = zsquare(t,ptest ; m=m) ;}
	else { z2[i] = zsquare(t,ptest  ; lc=r, m=m ) ;}

     if(chatty) 
	  {
	     if (_time()-tlast > 10)
	       {
		  tlast=_time() ;
		  titer = (tlast-tstart)/double(i) ;
		  remain=(ergdim-i)*titer ;
		  
		  ()=printf("%.2f%% done\n", i*100./ergdim ) ;
		  ()=printf("its taking %.2fsec per iteration\n", titer) ;
		  
		  if (remain <= 600)  ()=printf("%.2f sec remaining...\n", remain) ;
		  else if (remain <= 7200) ()=printf("%.2f min remaining...\n", remain/60.) ;
		  else ()=printf("%.2f h remaining...\n", remain/3600.) ;
	       }
	  }
     }

  %structure containing searched periods, statistics value,
  %phasebins used and indices of periods with gaps in the pulse profile
   return struct{p=p, stat=z2 } ;
   
}
