define integrateRK45_adaptive()
%!%+
%\function{integrateRK45_adaptive}
%\synopsis{Integrate an ODE with an adaptive 4th/5th order Runge-Kutta algorithm}
%\usage{(t, x(t)) = integrateRK45_adaptive(&f, t0, t, [, x0]);}
%\description
%    Given an ordinary differential equation of the form\n
%      dx/dt = f(t, x(t))
%    (with \code{x} either a scalar or an array)\n
%    this function numerically computes the solution\n
%      x(t) = int_{t0}^{t} f(t', x(t')) dt' [ + x0 ]\n
%    by means of a 4th/5th order Runge-Kutta (RK) algorithm.
%
%    \code{&f} is a reference to a function with two arguments:\n
%       \code{define f(t, x)}\n
%       \code{\{}\n
%       \code{  return ...;}\n
%       \code{\}}
%
%    If x is an array, the adaptive stepsize is chosen according\n
%    to the needs of the "worst-offender" equation implying that\n
%    the desired accuracy is reached by each individual component.
%
%    Note: All qualifiers are also passed to the function f.
%\qualifiers{
%\qualifier{eps}{[\code{=1e-12}] absolut error control tolerance; lower limit: 1e-15}
%\qualifier{method}{[\code{="RKCK"}] choose among three different RK45 methods:
%      "RKF": RK-Fehlberg, "RKCK": RK-Cash-Karp, "RKDP": RK-Dormand-Prince}
%\qualifier{path}{return the entire path and not only the final result}
%\qualifier{verbose}{show intermediate "times" \code{t}}
%\qualifier{plus all qualifiers of the function f}{}
%}
%\example
%    % d/dt x(t) = -sin (t^2)*2t; -> analytical solution: x(t) = cos(t^2) for x(0)=1
%    define f(t,x)
%    {
%      return -sin(t^2)*2*t;
%    };
%    (t, x) = integrateRK45_adaptive(&f, 0, 10, 1; path);
%    plot(t,x-cos(t^2));
%
%    % d/dt [x1(t),x2(t)] = [x2(t),-x1(t)]; -> analytical solution: x1(t) = cos(t) for x1(0)=1, x2(0)=0
%    define f(t,x)
%    {
%      [x[1],-x[0]];
%    }
%    (t, x) = integrateRK45_adaptive(&f, 0, PI, [1,0]; path);
%    plot(t,x[*,0]-cos(t));
%    
%\seealso{integrateRKF45, integrateRK4, integrateAB5}
%!%-
{
  variable f, t0, t, x=0;
  switch(_NARGS)
  { case 3: (f, t0, t) = (); }
  { case 4: (f, t0, t, x) = (); }
  { help(_function_name()); return; }

  variable eps = _max( qualifier("eps", 1e-12), 1e-15 );
  variable method = qualifier("method", "RKCK");
  variable verbose = qualifier_exists("verbose");
  variable path = qualifier_exists("path");

  variable k1, k2, k3, k4, k5, k6, k7, dx_c, dx_e; % dx_c = dx continue, dx_e = dx error estimation
  variable coef = Double_Type[7,7]; % modified Butcher tableau
  if(method == "RKF")
  {
    coef[0,0]= 1./4;   coef[0,1]=  1./4;
    coef[1,0]= 3./8;   coef[1,1]=  3./32;      coef[1,2]=  9./32;
    coef[2,0]= 12./13; coef[2,1]=  1932./2197; coef[2,2]= -7200./2197;  coef[2,3]=  7296./2197;
    coef[3,0]= 1.;     coef[3,1]=  439./216;   coef[3,2]= -8.;          coef[3,3]=  3680./513;    coef[3,4]= -845./4104;
    coef[4,0]= 1./2;   coef[4,1]= -8./27;      coef[4,2]=  2.;          coef[4,3]= -3544./2565;   coef[4,4]=  1859./4104;   coef[4,5]= -11./40;
    coef[5,0]= 0;      coef[5,1]=  25./216;    coef[5,2]=  1408./2565;  coef[5,3]=  2197./4104;   coef[5,4]= -1./5;         coef[5,5]= 0; % fourth order solution
    coef[6,0]= 0;      coef[6,1]=  16./135;    coef[6,2]=  6656./12825; coef[6,3]=  28561./56430; coef[6,4]= -9./50;        coef[6,5]= 2./55; % fifth order solution
  }
  else if(method == "RKDP")
  {
    coef[0,0]= 1./5;  coef[0,1]= 1./5; 
    coef[1,0]= 3./10; coef[1,1]= 3./40;       coef[1,2]=  9./40;
    coef[2,0]= 4./5;  coef[2,1]= 44./45;      coef[2,2]= -56./15;      coef[2,3]= 32./9;
    coef[3,0]= 8./9;  coef[3,1]= 19372./6561; coef[3,2]= -25360./2187; coef[3,3]= 64448./6561; coef[3,4]= -212./729;
    coef[4,0]= 1.;    coef[4,1]= 9017./3168;  coef[4,2]= -355./33;     coef[4,3]= 46732./5247; coef[4,4]=  49./176;       coef[4,5]= -5103./18656;
    coef[5,0]= 1.;    coef[5,1]= 35./384;     coef[5,2]= 500./1113;    coef[5,3]=  125./192;   coef[5,4]= -2187./6784;    coef[5,5]= 11./84; % fourth order solution
    coef[6,0]= 0;     coef[6,1]= 5179./57600; coef[6,2]= 7571./16695;  coef[6,3]=  393./640;   coef[6,4]= -92097./339200; coef[6,5]= 187./2100;    coef[6,6]= 1./40; % fitfh order solution
  }
  else % use RKCK if method is none of the two above methods
  {
    coef[0,0]= 1./5;  coef[0,1]= 1./5;
    coef[1,0]= 3./10; coef[1,1]= 3./40;       coef[1,2]= 9./40;
    coef[2,0]= 3./5;  coef[2,1]= 3./10;       coef[2,2]= -9./10;       coef[2,3]= 6./5;
    coef[3,0]= 1.;    coef[3,1]= -11./54;     coef[3,2]= 5./2;         coef[3,3]= -70./27;       coef[3,4]= 35./27;
    coef[4,0]= 7./8;  coef[4,1]= 1631./55296; coef[4,2]= 175./512;     coef[4,3]= 575./13824;    coef[4,4]= 44275./110592; coef[4,5]= 253./4096;
    coef[5,0]= 0;     coef[5,1]= 2825./27648; coef[5,2]= 18575./48384; coef[5,3]= 13525./55296;  coef[5,4]= 277./14336;    coef[5,5]= 1./4; % fourth order solution
    coef[6,0]= 0;     coef[6,1]= 37./378;     coef[6,2]= 250./621;     coef[6,3]= 125./594;      coef[6,4]= 0;             coef[6,5]= 512./1771; % fitfh order solution    
  }
  % solving the ODEs:
  variable s = 1.*sign(t-t0); % for t<t0 make transformation: t->-t, t0->-t0, dt->-dt
  if(s==0) s=1.; % to account for t-t0==0
  t *= s; t0 *= s;
  variable dt = 1e-12*(t-t0); % intialize stepsize with arbitrary value as it is adjusted anyway
  if(path)
  {
    variable trajectory = struct{ t, x };
    trajectory.t = { s*t0 };
    trajectory.x = { x };
  }
  while(t0 < t0+dt <= t)
  {
    k1 = s * dt * @f(s*t0, x;; __qualifiers);
    k2 = s * dt * @f(s*(t0 + coef[0,0]*dt), x + coef[0,1]*k1;; __qualifiers);
    k3 = s * dt * @f(s*(t0 + coef[1,0]*dt), x + coef[1,1]*k1 + coef[1,2]*k2;; __qualifiers);
    k4 = s * dt * @f(s*(t0 + coef[2,0]*dt), x + coef[2,1]*k1 + coef[2,2]*k2 + coef[2,3]*k3;; __qualifiers);
    k5 = s * dt * @f(s*(t0 + coef[3,0]*dt), x + coef[3,1]*k1 + coef[3,2]*k2 + coef[3,3]*k3 + coef[3,4]*k4;; __qualifiers);
    k6 = s * dt * @f(s*(t0 + coef[4,0]*dt), x + coef[4,1]*k1 + coef[4,2]*k2 + coef[4,3]*k3 + coef[4,4]*k4 + coef[4,5]*k5;; __qualifiers);
    if(method == "RKDP") % for RKPD use fifth order solution to continue integration
    {
      dx_e = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
      k7 = s * dt * @f(s*(t0 + coef[5,0]*dt), x + dx_e;; __qualifiers);
      dx_c = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6 + coef[6,6]*k7; % fifth order solution
    }
    else % for RKF, RKCK use fourth order solution to continue integration
    {
      dx_c = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
      dx_e = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6; % fifth order solution
    }
    variable scale = 0.9*(eps/max(abs(dx_c-dx_e)))^(0.2); % 0.9 is safety factor; derivation see Numerical Recipes, Section "Adaptive Stepsize Control for Runge-Kutta"
    % variable scale = ( 0.5*eps*dt/max(abs(dx_c-dx_e)) )^0.25;  % "derivation of this formula can be found in advanced books on numerical analysis", statement in Numerical Methods Using Matlab, 4th Edition, 2004
    if(scale>1 or dt<=1e-15*t) % scale>1: accept stepsize only if correction factor is larger than 1
    {                          % dt<=abs(1e-15*t) in order to avoid infinite loops due to Double_Type precision limit at dt=1e-16*t
      x += dx_c;
      t0 += dt;
      if(path)
      {
	list_append(trajectory.t, s*t0);
	list_append(trajectory.x, x);
      }
      if(verbose) vmessage("t=%g", s*t0);
    }
    dt = _max(dt*scale, t*1e-15); % abs(1e-15*t) in order to avoid infinite loops due to Double_Type precision limit at dt=1e-16*t
    if(t0+dt > t) dt = t-t0;
  }
  if(path)
  {
    trajectory.t = list_to_array(trajectory.t);
    t0 = trajectory.t;
    variable len1 = length(x);
    if(len1==1)
    {
      trajectory.x = list_to_array(trajectory.x);
      x = trajectory.x;
    }
    else
    {
      variable i;
      variable len2 = length(trajectory.t);
      x = Double_Type[len2, len1];
      _for i(0,len2-1,1)
      {
	x[i,*] = trajectory.x[i];
      }
    }
  }
  return t0, x;
}
