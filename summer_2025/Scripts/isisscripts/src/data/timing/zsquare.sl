%%%%%%%%%%%%%%%%%%%%%%%
define zsquare ()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{zsquare}
%\synopsis{calculate Z^2 statistics for pulse period search}
%\usage{Double_Type Z2 = zsquare(Double_Type times, Double_Type testperiod}
%
%\description
%    Calculates the Z^2 statistics of an event list or light-curve for
%    a given period. By itself not very useful, but is used in z2fold
%    to search for periodicities using the Z^2 statistics.
%
%\qualifiers{
%\qualifier{lc}{=Double_Type rate; allows the use of a lightcurve instead of event files}
%\qualifier{m}{= Integer_Type; determines the highest order of summations (default 2)}
%}
%!%-
{
   variable t, P ; 
  
   switch(_NARGS)
    {case 2: (t, P) = ();}
    {help(_function_name()); return; }

   variable phis = (t mod P)/P ;
   
   variable j, k ;
   variable cossq, sinsq ;

   variable lc = qualifier("lc", 1) ; %% if not provided assume event data
   variable m = qualifier("m", 2) ; %% standard test should be Z^2_2

   variable norm = qualifier_exists("lc") ? sum(lc) : length(phis) ;
   
   variable zsqtmp = Double_Type[m] ;

   _for j (1, m, 1)
     {
	cossq = (sum(lc* cos(j*phis*2*PI)))^2. ;
	sinsq = (sum(lc* sin(j*phis*2*PI)))^2. ;
	zsqtmp[j-1] = cossq + sinsq ;
     }

   return sum(zsqtmp) * 2./norm ;
}
