define polint( xa, ya, x)
%!%+
% NAME:
%\function{polint}
%\synopsis{Polynomial Interpolation and Extrapolation with error estimation}
%\usage{ (Double_Type y, dy ) = polint (Double_Type[] xa, ya, Double_Type x);}
%\description
%    Returns an interpolated value \code{y} at the given point \code{x} and an
%    error estimate \code{dy} for the given arrays \code{xa} and \code{ya}.
%    If P(x) is the polynomial of degree n-1 such that P(xa_i) = ya_i, i=0,n-1,
%    then the retruned value y=P(x).
%    Adapted from algorithm in Numerical Recipes,
%    by Press et al. (1992, 2nd edition), Section 3.1. 
%
%\seealso{qromb}
%!%-
{
  variable n = length([xa]);
  
  variable c = @ya;
  variable d = @ya;

  variable dift = abs( x - xa );
  variable ns = where_min( dift );
  variable dif = dift[ns];
  
  variable y = ya[ns];
  ns -= 1;

  
  variable i,m;
  variable dy;
  variable den, ho, hp, w;
  
  _for m ( 1, n-1 ){
    i   = [0:n-m-1];
    ho  = xa[i] - x;
    hp  = xa[i+m] - x;
    w   = c[i+1] - d[i];
    den = ho-hp;
    if( length(where(den == 0.)) ){
      vmessage("<%s> : ERROR (Occurs only if xa[i]=xa[j], i!=j)",_function_name);
      return 0;
    }
    den = w/den;
    d[i] = hp*den;
    c[i] = ho*den;

    if( 2*(ns+1) < n-m ){
      dy = c[ns+1];
    }
    else{
      dy = d[ns];
      ns -= 1;
    }
    y += dy;
  }
  return ( y, dy );
}

define qromb()
%!%+
% NAME:
%\function{qromb}
%\synopsis{Integrate using Rombergs's rule to specified accuracy.}
%\usage{Double_Type int = qromb (Ref_Type function, Double_Type min, Double_Type max);}
%\description
%    Integrate a function between the limits \code{min} and \code{max} to specified
%    accuracy using the extended trapezoidal rule. Adapted from algorithm
%    in Numerical Recipes, by Press et al. (1992, 2nd edition), Section 4.3.
%    The precision and number of maximal iterations can be set via qualifiers.
%    Any other keywords are passed directly to the user-supplied function.
%    NOTE: Romberg is more efficient then Simpson. 
%\qualifiers{
%\qualifier{qromb_eps [=1e-6]}{:    Scalar specifying the fractional accuracy before
%                            ending the iteration.}
%\qualifier{qromb_max_iter [=16]}{: Integer specifying the total number iterations
%                            at which \code{qsimp} will terminate even if the
%                            specified accuracy has not yet been met.
%                            The maximum number of function evaluations is
%                            2^(qromb_max_iter-2)-1.}
%}
%\qualifier{k [=5]}{:    Integration is performed by Romberg’s method
%                       of order 2k, where, e.g., k=2 is Simpson’s rule.
%}
%\example
%    %  Compute the integral of sin(x) from 0 to PI/3.
%    %  The value obtained should be cos(PI/3) = 0.5
%    variable val = qromb( &sin, 0, PI/3);
%
%\seealso{integrate_trapez,polint,qsimp}
%!%-
{
  variable a,b,func;
  switch(_NARGS)
  { case 3: (func, a, b) = (); }
  { help(_function_name()); return; }
  
   
  variable eps   = qualifier("qromb_eps",1e-6);
  variable jmax  = qualifier("qromb_max_iter",16);
  variable k     = qualifier("k",5);

  variable ss, dss;
  variable h = Double_Type[jmax+1];
  variable s = Double_Type[jmax+1];

  h[0] = 1.0;

  variable j;
  _for j ( 0, jmax-1, 1 ){
    ifnot(j)
      s[j] = 0.5*(b-a)*(@func(a;; __qualifiers)+@func(b;; __qualifiers));
    else
      s[j] = integrate_trapez (func, a, b, s[j];;
			       struct_combine (__qualifiers, struct { steps=2^(j-1)} ) );
    if( j >= k ){
      (ss,dss) = polint( h[[j+1-k:j]], s[[j+1-k:j]], 0. );
      if( abs(dss) <= abs(eps*ss) ) return ss;
    }
    s[j+1] = s[j];
    h[j+1] = 0.25*h[j];
  }
  vmessage ("<%s>: WARNING - Sum did not converge to precision of %.2e after %d steps",
	    _function_name, eps,jmax);
  vmessage ("                Change in last step was: delta_int/int = %e", abs(dss)/ss);
  return ss;
}
