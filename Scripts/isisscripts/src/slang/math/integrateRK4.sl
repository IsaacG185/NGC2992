define integrateRK4()
%!%+
%\function{integrateRK4}
%\synopsis{integrates an ordinary differential equation with the 4th order Runge-Kutta algorithm}
%\usage{x = integrateRK4(&f, t1, t2, dt[, x0]);}
%\description
%    The integral of the ordinary differential equation\n
%      dx/dt = f(x(t), t)  with  x(t0) = x0\n
%    reads\n
%      x(t) = x0 + int_{t0}^{t} f(x(t'), t') dt'
%
%    \code{&f} is a reference to a function with two arguments:
%       \code{define f(x, t)}\n
%       \code{\{}\n
%       \code{  return ...;}\n
%       \code{\}}
%
%    \code{x} may be be a scalar as well as an array.
%\seealso{integrateAB5}
%!%-
{
  variable f, t1, t2, dt, x=0;
  switch(_NARGS)
  { case 4: (f, t1, t2, dt) = (); }
  { case 5: (f, t1, t2, dt, x) = (); }
  { help(_function_name()); return; }

  variable i, n = nint((t2-t1)*1./dt);
  dt = (t2-t1)*1./n;  % adjusting dt to have exactly n steps from t1 to t2
  _for i (0, n-1, 1)
  {
    variable t = t1 + i*dt;
    variable f1 = @f(x,           t       ;; __qualifiers);
    variable f2 = @f(x+0.5*dt*f1, t+0.5*dt;; __qualifiers);
    variable f3 = @f(x+0.5*dt*f2, t+0.5*dt;; __qualifiers);
    variable f4 = @f(x+    dt*f3, t+    dt;; __qualifiers);
    x += dt/6 * ( f1 + 2*f2 + 2*f3 + f4 );
  }
  return x;
}
