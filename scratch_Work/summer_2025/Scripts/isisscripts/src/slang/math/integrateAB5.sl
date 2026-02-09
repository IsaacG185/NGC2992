
define integrateAB5()
%!%+
%\function{integrateAB5}
%\synopsis{integrates an ordinary differential equation with the 5th order Adams-Bashforth algorithm}
%\usage{x = integrateAB5(&f, t1, t2, dt[, x0]);}
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
%\seealso{integrateRK4}
%!%-
{
  variable f, t1, t2, dt, x0=0.;
  switch(_NARGS)
  { case 4: (f, t1, t2, dt    ) = (); }
  { case 5: (f, t1, t2, dt, x0) = (); }
  { help(_function_name()); return; }

  variable i, n = nint((t2-t1)*1./dt);
  if(n<5)  n = 5;
  dt = (t2-t1)*1./n;  % adjusting dt to have exactly n steps from t1 to t2

  if(__is_numeric(x0)==1)  x0 *= 1.;   % Integer_Type => Double_Type
  variable x = typeof(x0)[5]; x[0] = x0;
  _for i (0, 3, 1)
    x[i+1] = integrateRK4(f, t1+i*dt, t1+(i+1)*dt, dt, x[i];; __qualifiers);
  variable i0=0, i1=1, i2=2, i3=3, i4=4;

  _for i (0, n-5, 1)
  {
    x[i0] = x[i4]                                                     % i0 = (i+5) mod 5
            + dt*( 1901/720. * @f(x[i4], t1+(i+4)*dt;; __qualifiers)  % i4 = (i+4) mod 5
                  -1387/360. * @f(x[i3], t1+(i+3)*dt;; __qualifiers)  % i3 = (i+3) mod 5
                  + 109/ 30. * @f(x[i2], t1+(i+2)*dt;; __qualifiers)  % i2 = (i+2) mod 5
                  - 637/360. * @f(x[i1], t1+(i+1)*dt;; __qualifiers)  % i1 = (i+1) mod 5
                  + 251/720. * @f(x[i0], t1+ i   *dt;; __qualifiers)  % i0 =  i    mod 5
	         );
    (i0, i1, i2, i3, i4) = (i1, i2, i3, i4, i0);                      % i++
  }
  return x[i4];  % == x[(i+5) mod 5]  % (The i's have already been rotated.)
}
