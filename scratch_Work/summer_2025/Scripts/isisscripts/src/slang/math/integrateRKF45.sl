define integrateRKF45()
%!%+
%\function{integrateRKF45}
%\synopsis{integrates an ODE with the adaptive 4th/5th order Runge-Kutta-Fehlberg algorithm}
%\usage{x = integrateRKF45(&f, t1, t2, dt[, x0]);}
%\qualifiers{
%\qualifier{eps}{[\code{=1e-12}] error control tolerance}
%\qualifier{verbose}{show intermediate "times" \code{t}}
%}
%\description
%    This implementation of the adaptive Runge-Kutta-Fehlberg algorithm
%    is still considered EXPERIMENTAL and MAY REQUIRE FURTHER TESTING!
%
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
%\seealso{integrateRK4, integrateAB5}
%!%-
{
  variable f, t, t2, dt, x=0;
  switch(_NARGS)
  { case 4: (f, t, t2, dt) = (); }
  { case 5: (f, t, t2, dt, x) = (); }
  { help(_function_name()); return; }

  variable eps = qualifier("eps", 1e-12);
  variable verbose = qualifier_exists("verbose");

  % http://www.springerlink.com/content/f69256402h71w8m8/
  % http://math.fullerton.edu/mathews/n2003/RungeKuttaFehlbergMod.html
  % http://en.wikipedia.org/wiki/Runge%E2%80%93Kutta%E2%80%93Fehlberg_method

  while(t < t+dt <= t2)
  {
    if(verbose)  vmessage("t=%g", t);
    variable k1 = dt * @f(x,  t;; __qualifiers);
    variable k2 = dt * @f(x + 0.25*k1,  t + 0.25*dt;; __qualifiers);
    variable k3 = dt * @f(x + 0.09375*k1 + 0.28125*k2,  t + 0.375*dt;; __qualifiers);
    variable k4 = dt * @f(x + 1932./2197*k1 - 7200./2197*k2 + 7296./2197*k3,  t + 12./13*dt;; __qualifiers);
    variable k5 = dt * @f(x + 439./216*k1 - 8*k2 + 3680./513*k3 - 845./4104*k4,  t + dt;; __qualifiers);
    variable k6 = dt * @f(x - 8./27*k1 + 2*k2 - 3544./2565*k3 + 1859./4104*k4 - 0.275*k5,  t + 0.5*dt;; __qualifiers);
    variable dx4 = 25./216*k1 + 1408./2565*k3 + 2197./4104*k4 - 0.2*k5;
%   variable dx5 = 16./135*k1 + 6656./12825*k3 + 28561./56430*k4 - 0.18*k5 + 2./55*k6;
    variable dx4_dx5 = 1./360*k1 - 128./4275*k3 - 2197./75240*k4 + 0.02*k5 + 2./55*k6;  % dx4 - dx5
%    variable s = (eps*dt/2/abs(       dx4_dx5)  )^0.25;  % doesn't work for array-valued x
    variable s = ( eps*dt/2/sqrt(sumsq(dx4_dx5)) )^0.25;  % just a hack to make it work for array-valued x;
                                                          % remains to be seen whether it makes sense or not
    if(s>0.1)  % <- This condition was invented by Manfred and should probably be replaced by something more clever.
    {
      x += dx4;
      t += dt;
    }
    dt *= _max(0.1, _min(s, 4));
    if(t+dt>t2)  dt = t2-t;
  }
  if(verbose)  vmessage("t=%g", t);
  return x;
}
