%%%%%%%%%%%%%%%%%%
define spearmanrho()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{spearmanrho}
%\synopsis{Timing Tools: Spearman's Rank Correlation Coefficient}
%\usage{(rho) = spearmanrho (a,b);}
%\description
% rho = 1 - frac {6 sum d_i^2} {n(n^2 -1)}
%
% d_i = a_i - b_i :  difference between the ranks of corresponding values
%               n :  number of values
%
% Alternative: The statistics module (\code{require("stats");}) includes
% several functions for determining (rank) correlations coefficients,
% such as \code{spearman_r}, which provides the p-value (as well as the
% correlation coefficient \code{rho}).
%!%-
{
  variable a,b;
  switch(_NARGS)
  { case 2: (a,b) = (); }
  { help(_function_name());
    throw UsageError, sprintf("%s Usage Error: wrong number of arguments", _function_name() );
  }
  
   if (length(a) != length(b))
	 {
	   throw UsageError, sprintf("%s Usage Error: array lengths differ!", _function_name() );
	 }
   

   if(length(a)!=length(unique(a)) or length(b)!=length(unique(b)))
	 {
		%message ("Warning: arrays not unique!");
		variable rgx, rgy,dx,dy, sa,sb;
		sa = array_sort(a);
		sb = array_sort(b);
		rgx = a[sa];
		rgy = b[sb];
		variable tmp = Double_Type[length(rgx)];
		variable i,ndx,u = unique(rgx);
		_for i (0,length(u)-1,1)
		  {
			 ndx = where( rgx==rgx[u[i]]);
			 tmp[ndx] = mean(ndx+1);
		  }		
		dx = tmp[array_sort(sa)] - mean(tmp);
		u = unique(rgy);
		tmp[*] = 0.;
		_for i (0,length(u)-1,1)
		  {
			 ndx = where( rgy==rgy[u[i]]);
			 tmp[ndx] = mean(ndx+1);
		  }
		dy = tmp[array_sort(sb)] - mean(tmp);
		return sum(dx*dy)/sqrt(sum(sqr(dx))*sum(sqr(dy)));
	 }

   return 1-(6*sum(sqr(array_sort(array_sort(a))-array_sort(array_sort(b))))/(length(a)*(sqr(length(a))-1)));
}
