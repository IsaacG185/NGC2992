define qsimp()
%!%+
% NAME:
%\function{qsimp}
%\synopsis{Integrate using Simpson's rule to specified accuracy.}
%\usage{Double_Type int = qsimp (Ref_Type function, Double_Type min, Double_Type max);}
%\description
%    Integrate a function between the limits \code{min} and \code{max}to specified
%    accuracy using the extended trapezoidal rule. Adapted from algorithm
%    in Numerical Recipes, by Press et al. (1992, 2nd edition), Section 4.2.
%    The precision and number of maximal iterations can be set via qualifiers.
%    Any other keywords are passed directly to the user-supplied function.
%\qualifiers{
%\qualifier{qsimp_eps [=1e-6]}{:    Scalar specifying the fractional accuracy before
%                            ending the iteration.}
%\qualifier{qsimp_max_iter [=16]}{: Integer specifying the total number iterations
%                            at which \code{qsimp} will terminate even if the
%                            specified accuracy has not yet been met.
%                            The maximum number of function evaluations is
%                            2^(qsimp_max_iter+5)-1.}
%}
%\example
%    %  Compute the integral of sin(x) from 0 to PI/3.
%    %  The value obtained should be cos(PI/3) = 0.5
%    variable val = qsimp( &sin, 0, PI/3);
%       
%\seealso{integrate_trapez,qromb}
%!%-  
{
  variable A,B,func;
  switch(_NARGS)
  { case 3: (func, A, B) = (); }
  { help(_function_name()); return; }

  variable qsimp_max_iter = qualifier("qsimp_max_iter",  16);
  variable qsimp_eps      = qualifier("qsimp_eps",     1e-6);

  variable oldS  = -1e30;
  variable delta;
  variable i,S = NULL;
  _for i (0, qsimp_max_iter -1 ,1)
  {
    S = integrate_trapez (func, A, B, S;; struct_combine (__qualifiers, struct { steps = 2^(i+4)} ) );
    delta = abs (S - oldS);
    if ( delta <= abs(qsimp_eps*oldS) ) return S;
    oldS = S;
  }
  vmessage ("<%s>: WARNING - Sum did not converge to precision of %.2e after %d steps",
	    _function_name,qsimp_eps,qsimp_max_iter);
  vmessage ("                Change in last step was: delta_int/int = %e", delta/S);
  return S;
}
