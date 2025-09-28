define checkrwlc()
%!%+
%\function{checkrwlc [ff]}
%\usage{Struct_Type checkrwlc(time, value, error, bin_lo, bin_hi)
%\altusage{Struct_Type checkrwlc (time, value, bin_lo, bin_hi) % in which case resu.erro will be zero}
%}
%\description
%    This script implements the alogrithm proposed by M. de Kool et al. (1993)
%    to check for random walk in a pulse period evolution.
%    In principle, everything containing time and value information
%    can be checked for random walk with this script (i.e. a lightcurve).
%    The output of the script is a structure containing the fields\n
%      - bin_lo = lower delta t bin\n
%      - bin_hi = upper delta t bin\n
%      - value  = delta omega value\n
%      - erro = uncertainties calculated from the given uncertainties of the values\n
%      - dist  = not normalized delta omega value\n
%      - len = normalization facotr for delta omega (value = dist/len)
%
%    Care should be taken that, when using for period evolution, the period and the
%    time array should be given in the same units.
%
%    The code might not be perfectly optimized
%    and is getting slow for large arrays of time and value (>500).
%
%    To estimate the true errors of the result, a Monte Carlo simulation should be used.
%\qualifiers{
%\qualifier{grp_r}{[Double]: grouping parameter as defined in Eq. 5, de Kool (1993) (default 0.1)}
%\qualifier{verbose}{[Boolean]: print progress in form of current working timebin (default: false)}
%}
%\seealso{M. de Kool and U. Anzer, 1993, MNRAS, 262, 726}
%!%-
{
  variable a, b, er, lo, hi;
  switch(_NARGS)
  { case 4: (a, b, lo, hi) = (); er = 0*a ; }
  { case 5: (a, b, er, lo, hi) = (); }
  { help(_function_name()); return; }

  variable R = qualifier("grp_r", 0.1);  % group definition parameter (Eq. 5)
  variable chatty = qualifier_exists("verbose"); % print out progress or not?
  
  variable length_a = length(a);
  variable length_lo = length(lo);
  variable lenarr = Double_Type[length_lo];
  variable erroarr = Double_Type[length_lo];
  variable distarr = Double_Type[length_lo];
  variable i, j;
  _for j (0, length_lo-1, 1)
  {
    % j = 2 ;
    variable tmpres = Struct_Type[length_a];
    variable groupe = Double_Type[length_a] + 1;  % at least one point belongs to each group
    variable len = 0 ;
    _for i (1, length_a-1, 1)
    {
      % message("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-") ;
      variable dt = a - shift(a,-i);  % what is the difference between two times in the distance i?
      % print(dt) ;
      % message("--") ;
      % print(lo[j]) ;
      % print(hi[j]) ;
      variable pairs = where(lo[j] <= dt <= hi[j]);  % check which differences in time lay in the regarded timebin
      % print(pairs) ;
      groupe[ where(abs(dt) <= R*lo[j]) ]++ ; % count how many other points belong to the point's group
% print(where(abs(dt) <= R*lo[j]) );
	% print((dt)) ;
      % message("----") ;
      
      tmpres[i-1] = struct {
	dist = abs(b[pairs-i]-b[pairs]),
	erro = sqrt((er[pairs-i])^2+(er[pairs])^2),
	pairs = pairs,
	shift = i };
      
      % dist += sum(abs(b[pairs-i]-b[pairs]));  % calculate the distance for all the pairs having the correct difference in time
      len += length(pairs);  % save the number of values going into dist to calc the average
      % print(tmpres[i-1].erro) ;
      % message("_------------------------_") ;
    }
    if(chatty)  vmessage("Iteration %d, dt = %f - %f", j, lo[j], hi[j]);
    % print(tmpres[1]) ;
    % message("-----" ) ;
    % print(groupe) ;
    % message("-=--=" );

    variable tmpdist = 0.0;
    variable tmperro = 0.0;
    variable reno = 0.0;
    variable nopairs = 0;

      % print(groupe[tmpres[0].pairs]) ;

    _for i (0, length_a-2, 1)
    { % applying the weight of the indivdual pairs to the respective pair in the sum
      variable w = 1. / groupe[tmpres[i].pairs] / groupe[tmpres[i].pairs-tmpres[i].shift];
      tmpdist += sum( w * tmpres[i].dist );
      tmperro += sqrt(sum( w * tmpres[i].erro^2 ));
	% print(w) ;
	% print(tmperro) ;
	% message("-------") ;
      reno += sum(w);
      nopairs += length(tmpres[i].pairs);
    }
    % message(",.,.,.,.,.,.,.,..,.,.") ;

    % renormalizing the weighted average
    % print(reno) ;
    % message("*****") ;
    % print(nopairs) ;
    % message("===========" );
    lenarr[j] = len;  % save the mean for each (lo,hi) bin in an array
    distarr[j] = tmpdist/reno*nopairs;
    erroarr[j] = tmperro/reno*nopairs;
  }

  return struct {
    bin_lo = lo,
    bin_hi = hi,
    value = distarr/lenarr,
    err = erroarr/lenarr,
    dist = distarr,
    len = lenarr
  };
}
