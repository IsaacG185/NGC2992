%%%%%%%%%%%%%%%%%%%%%%%%
define solveODEbyIntegrate()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{solveODEbyIntegrate}
%\synopsis{solves an ordinary differential equation on a grid by integration}
%\usage{x = solveODEbyIntegrate(&f, tgrid);}
%\qualifiers{
%    \qualifier{rdt}{integration step size relative to 'tgrid' binsize (default: 0.1)}
%    \qualifier{x0}{integration constant (default: 0)}
%    \qualifier{t0}{time reference for x0 (default: first 'tgrid' bin)}
%    \qualifier{method}{integratipn method (default: &integrateRK4)}
%}
%\description
%    The integral of the ordinary differential equation (ODE)\n
%      dx/dt = f(x(t), t)  with  x(t0) = x0\n
%    reads\n
%      x(t) = x0 + int_{t0}^{t} f(x(t'), t') dt'
%
%    \code{&f} is a reference to a function with two arguments:
%       \code{define f(x, t)}\n
%       \code{\{}\n
%       \code{  return ...;}\n
%       \code{\}}
%\seealso{integrateRK4}
%!%-
{
  variable f, tgrid;
  switch(_NARGS)
    { case 2: (f, tgrid) = (); }
    { help(_function_name()); return; }

  % step size and integration constant
  variable rdt = qualifier("rdt", .1);
  variable t0 = qualifier("t0", tgrid[0]);
  variable x0 = qualifier("x0", 0);
  variable method = qualifier("method", &integrateRK4);
  variable qual = qualifier("qualifiers", NULL);
    
  % index of reference time, t0, in time grid, tgrid
  if (tgrid[0] > t0 || tgrid[-1] < t0) {
    vmessage("error (%s): t0 (%.2f) not within tgrid (%.2f - %.2f)", _function_name, t0, tgrid[0], tgrid[-1]);
    return;
  }
  variable i0 = wherefirstmin(abs(tgrid - t0));

  % set-up solution: calculate starting point
  variable fx = Double_Type[length(tgrid)]; % will be the solution f(x)
  variable dt = abs(t0 - tgrid[i0]) * rdt;
  if (dt < 1e-3*rdt) {
    fx[i0] = x0;
  } else if (t0 < tgrid[i0]) {
    fx[i0] = (@method)(f, t0, tgrid[i0], dt, x0;; qual);
  } else {
    fx[i0] = (@method)(f, tgrid[i0], t0, -dt, x0;; qual);
  }

  % solve remaining bins
  variable i;
  % forward integration
  _for i (i0+1, length(tgrid)-1, 1) {
    dt = (tgrid[i] - tgrid[i-1]) * rdt;
    fx[i] = (@method)(f, tgrid[i-1], tgrid[i], dt, fx[i-1];; qual);
  }
  % backward integration
  _for i (i0-1, 0, -1) {
    dt = (tgrid[i+1] - tgrid[i]) * rdt;
    fx[i] = (@method)(f, tgrid[i+1], tgrid[i], -dt, fx[i+1];; qual);
  }

  return fx;
}
