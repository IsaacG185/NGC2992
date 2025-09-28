define integrate_trapez()
%!%+
%\function{integrate_trapez}
%\synopsis{numerical integration with the trapezoidal rule}
%\usage{Double_Type int = integrate_trapez(Double_Type x[], Double_Type y[]);
%    alternative:
%    Double_Type int = integrate_trapez(Ref_Type function, Double_Type min, Double_Type max);}
%\description
%    If two arguments (\code{x[]} and \code{y[] = function(x[])}) are given the integral is calculated via:
%    \code{int = sum_i (y[i-1] + y[i])/2 * (x[i]-x[i-1])}
%    An alternative usage with three arguments requires a reference to
%    the function and the integration limits. The function is evaluated
%    on an equidistant grid. The number of steps can be set with a qualifier.
%    The second case allows a forth argument specifying a previous result
%    with a smaller number of steps, which is meant for iterative usage by
%    the function \code{qsimp}.
%\qualifiers{
%\qualifier{steps [=100]}{:    number of equidistant grid points,
%                       on which the function is evaluated}
%}
%\example
%    % Integration of the sin function from 0 to PI/3
%    % The result should be 0.5
%    variable x = [0:PI/3:#100];
%
%    % The first method: providing grid and corresponding function values
%    integrate_trapez (x, sin(x));
%
%    % Alternative method using reference to the function and integration limits
%    integrate_trapez (&sin, 0, PI/3);
%    integrate_trapez (&sin, 0, PI/3; steps = 5000);    
%\seealso{integrateRK4, qsimp}
%!%-
{
  variable x, y;
  variable func, A, B;
  variable fac   = 1.0;
  variable R     = NULL;
  variable steps = nint(qualifier("steps", 100));
  
  switch(_NARGS)
  { case 2: (x, y) = ();
    if(length(x) != length(y) or length(x)<2)
      message("error ("+_function_name()+"): x and y have to be arrays of same length >1");
    else
      return sum( 0.5*(y[[:-2]]+y[[1:]]) * (x[[1:]]-x[[:-2]]) );
  }
  { case 3: (func, A, B)    = (); }
  { case 4: (func, A, B, R) = (); if (R != NULL) {fac = 0.5;} }
  { help(_function_name()); return;     }
  if (R == NULL) R = 0.;
  variable tnm = double( steps );
  variable del = ( B - A ) / tnm;                     %Spacing of the points to add
  variable xgrid = A + 0.5*del + [0:steps-1] * del;  %Grid of points @ compute function
  variable val = array_map_qualifiers( Double_Type, func, xgrid ;; __qualifiers );
  R = fac * ( R + (double(B)-A) * sum(val)/tnm );
  return R;
}
