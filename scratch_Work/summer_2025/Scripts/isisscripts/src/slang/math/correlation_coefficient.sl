define correlation_coefficient()
%!%+
%\function{correlation_coefficient}
%\synopsis{calculates the [weighted] linear correlation coefficient between two arrays}
%\usage{Double_Type rho = correlation_coefficient(Double_Type x[], Double_Type y[] [ , Double_Type w[] ]);}
%\description
%
%   The function of the unweighted correlation coefficient reads:
%
%   \code{                     n * sum(x*y)  -  sum(x) * sum(y)          }
%   \code{rho  =  -------------------------------------------------------}
%   \code{         sqrt(n*sum(x^2)-sum(x)^2) * sqrt(n*sum(y^2)-sum(y)^2) }
%   
%   w defines the weight of each point. By default it is set to w = 1.
%   
%\seealso{find_correlations}
%!%-
{
   variable x, y, w;
   switch(_NARGS)
     
   { case 2: 
       (x, y) = (); 
     variable n = length(x);
     variable sumX = sum(x);
     variable sumY = sum(y);
     return (n*sum(x*y)-sumX*sumY)/sqrt(n*sum(x^2)-sumX^2)/sqrt(n*sum(y^2)-sumY^2);
  }
   
   { case 3: 
	(x, y, w) = ();
      
      variable mx = sum(w*x)/sum(w);
      variable my = sum(w*y)/sum(w);
      
      variable covxy = sum( w* (x-mx) * (y-my))   / sum(w);
      variable covxx = sum( w* (x-mx) * (x-mx))   / sum(w);
      variable covyy = sum( w* (y-my) * (y-my))   / sum(w);
      
      return covxy/sqrt(covxx*covyy);
      }
      
   { help(_function_name()); return; }
   
}
