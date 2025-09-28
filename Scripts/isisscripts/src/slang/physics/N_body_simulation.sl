define N_body_simulation_std_kernel()
%!%+
%\function{N_body_simulation_std_kernel}
%\synopsis{Default interaction kernel for the function 'N_body_simulation'}
%\usage{Double_Type r[6,N] = N_body_simulation_std_kernel(Double_Types t, m[6,N]; qualifiers)}
%\description
%   This function is the default interaction kernel of the function 'N_body_simulation'.
%   It computes the equations of motion of N interacting particles at time t.
%   The input parameter 'm' is a [6,N]-matrix with
%      m[0,j] = x_j;
%      m[1,j] = y_j;
%      m[2,j] = z_j;
%      m[3,j] = vx_j;
%      m[4,j] = vy_j;
%      m[5,j] = vz_j;
%
%   For each particle, the potential of particle i (at position (x_i,y_i,z_i)) exerted
%   on particle j (at position (x_j,y_j,z_j)) is a Plummer sphere of the form
%      Phi(x_i,y_i,z_i,x_j,y_j,z_j) = -psa_i*(psb_i+dis^2)^(-1/2)
%   with
%      dis^2 = (x_i-x_j)^2+(y_i-y_j)^2+(z_i-z_j)^2
%   and psa_i and psb_i model constants (see qualifiers).
%   The resulting acceleration of particle j is then
%      d^2/dt^2 x_j = -d/dx_j Phi = sum( psa_i*(psb_i+dis^2)^(-3/2)*(x_i-x_j), i!=j)
%      d^2/dt^2 y_j = -d/dy_j Phi = sum( psa_i*(psb_i+dis^2)^(-3/2)*(y_i-y_j), i!=j)
%      d^2/dt^2 z_j = -d/dz_j Phi = sum( psa_i*(psb_i+dis^2)^(-3/2)*(z_i-z_j), i!=j)
%   yielding the following system of first-order differential equations, which are the
%   equations of motion of this system and which are returned as a [6,N]-matrix 'r'
%      d/dt x_j  = r[0,j] = vx_j
%      d/dt y_j  = r[1,j] = vy_j
%      d/dt z_j  = r[2,j] = vz_j
%      d/dt vx_j = r[3,j] = -d/dx_j Phi = sum( psa_i*(psb_i+dis^2)^(-3/2)*(x_i-x_j), i!=j)
%      d/dt vy_j = r[4,j] = -d/dy_j Phi = sum( psa_i*(psb_i+dis^2)^(-3/2)*(y_i-y_j), i!=j)
%      d/dt vz_j = r[5,j] = -d/dz_j Phi = sum( psa_i*(psb_i+dis^2)^(-3/2)*(z_i-z_j), i!=j)
%\qualifiers{
%\qualifier{psa}{[\code{=Double_Type[N]+1}] Parameter used to parametrize the interaction potential.}
%\qualifier{psb}{[\code{=Double_Type[N]+0}] Parameter used to parametrize the interaction potential.}
%}
%\example
%    N = 4;
%    m = Double_Type[6,N];
%    r = N_body_simulation_std_kernel(0,m; psa=Double_Type[N]+1, psb=Double_Type[N]+1);
%\seealso{N_body_simulation}
%!%-
{
  if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': Wrong number of arguments.", _function_name());
  }
  variable t, m;
  (t, m)= ();
  variable N = length(m[0,*]);
  variable psa = qualifier("psa", Double_Type[N]+1);
  if(length(psa)!=N)
    throw UsageError, sprintf("Usage error in '%s': Qualifier 'psa' invalid. It is supposed to be an array of length %d.", _function_name(), N);
  variable psb = qualifier("psb", Double_Type[N]+0);
  if(length(psb)!=N)
    throw UsageError, sprintf("Usage error in '%s': Qualifier 'psb' invalid. It is supposed to be an array of length %d.", _function_name(), N);
  %
  variable r = Double_Type[6,N];
  r[0,*] = m[3,*];
  r[1,*] = m[4,*];
  r[2,*] = m[5,*];
  variable i, j;
  _for i(0,N-2,1)
  {
    _for j(i+1,N-1,1)
    {
      variable dx = m[0,j]-m[0,i];
      variable dy = m[1,j]-m[1,i];
      variable dz = m[2,j]-m[2,i];
      variable dis2 = dx^2 + dy^2 + dz^2;
      variable interaction_ij = psa[j] * (psb[j]+dis2)^(-1.5);
      variable interaction_ji = psa[i] * (psb[i]+dis2)^(-1.5);
      r[3,i] += interaction_ij*dx;
      r[3,j] -= interaction_ji*dx;
      r[4,i] += interaction_ij*dy;
      r[4,j] -= interaction_ji*dy;
      r[5,i] += interaction_ij*dz;
      r[5,j] -= interaction_ji*dz;
    }
  }
  return r;
}

define N_body_simulation()
%!%+
%\function{N_body_simulation}
%\synopsis{Compute orbits for N interacting particles}
%\usage{Struct_Type ret = N_body_simulation(Struct_Type in, Double_Type t_end; qualifiers)}
%\description
%    By numerical integration and without any simplifying approximations, this function
%    directly solves the equations of motion of a system of N particles under the
%    influence of their mutual forces (The interaction is specified in a separate
%    function, see qualifier 'kernel'.) from time t=0 to time t=t_end. Negative values
%    for t_end imply backward integration. Cartesian coordinates are used throughout.
%
%    The input structure 'in' has to contain the fields "x", "y", "z", "vx", "vy", "vz".
%    Each of these fields has to be an array of length N. The corresponding index gives
%    the particle id, i.e., particle 0 refers to x[0], y[0], z[0], vx[0], vy[0], vz[0].
%    The return structure 'ret' contains for each particle a field, e.g., for particle 0
%    a field named "o0". This field is again a structure with fields "t", "x", "y", "z",
%    "vx", "vy", and "vz" giving the time-dependent coordinates of the respective particle.
%\notes
%    An adaptive Runge-Kutta-Fehlberg method of fourth/fifth order is applied to solve the
%    coupled system of first-order differential equations. The stepsize is hereby controlled
%    such that for each step an absolute accuracy in coordinates and velocity components is
%    achieved that is smaller than given by the qualifier 'tolerance'.
%\qualifiers{
%\qualifier{kernel}{[\code{="N_body_simulation_std_kernel"}] Name of the function which describes the
%      mutual interaction. Note that all qualifiers are passed to this function as well.}
%\qualifier{threshold}{[\code{=0}] Lower limit on the time difference of two consecutive moments of time
%      that will be saved.}
%\qualifier{tolerance}{[\code{=1e-10}] Absolut error control tolerance; lower limit: 1e-15.}
%\qualifier{verbose}{Show intermediate times t.}
%}
%\example
%    % Four interacting particles:
%    s = struct{x, y, z, vx, vy, vz};
%    s.x = [-10,0,10,0];
%    s.y = [0,10,0,-10];
%    s.z = [0,0,0,0];
%    s.vx = [0,-1,0,1];
%    s.vy = [-1,0,1,0];
%    s.vz = [0,0,0,0];
%    r = N_body_simulation(s, 50; kernel="N_body_simulation_std_kernel", psa=10*[1,1,1,1], psb=0.1*[1,1,1,1]);
%    xrange(min_max([r.o0.x,r.o1.x,r.o2.x,r.o3.x]));
%    yrange(min_max([r.o0.y,r.o1.y,r.o2.y,r.o3.y]));
%    plot(r.o0.x,r.o0.y); oplot(r.o1.x,r.o1.y); oplot(r.o2.x,r.o2.y); oplot(r.o3.x,r.o3.y);
%\seealso{N_body_simulation_std_kernel, N_body_simulation_MW_kernel}
%!%-
{
  if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': Wrong number of arguments.", _function_name());
  }
  variable in, t_end;
  (in, t_end) = ();
  if(_is_struct_type(in)!=1)
    throw UsageError, sprintf("Usage error in '%s': First input parameter has to be Struct_Type.", _function_name());
  if(struct_field_exists(in, "x")==0 or struct_field_exists(in, "y")==0 or struct_field_exists(in, "z")==0 or
     struct_field_exists(in, "vx")==0 or struct_field_exists(in, "vy")==0 or struct_field_exists(in, "vz")==0)
    throw UsageError, sprintf("Usage error in '%s': First input parameter has to be Struct_Type with fields 'x', 'y', 'z', 'vx', 'vy', and 'vz'.", _function_name());
  variable N = length(in.x);
  if(length(in.y)!=N or length(in.z)!=N or length(in.vx)!=N or length(in.vy)!=N or length(in.vz)!=N)
    throw UsageError, sprintf("Usage error in '%s': Fields of first input parameter have to be arrays of the same length.", _function_name());
  %
  variable kernel = __get_reference(qualifier("kernel"));
  variable eps = _max( qualifier("tolerance", 1e-10), 1e-15); % error control tolerance
  variable threshold = qualifier("threshold", 0);
  variable verbose = qualifier_exists("verbose");
  %
  variable s = sign(t_end);
  if(s==0) s=1; % to account for t_end==0
  t_end *= s; % for backward integration, i.e. t_end < 0, reverse t_end and the sign of the velocity components
  %
  variable m = Double_Type[6,N]; m[0,*] = in.x, m[1,*] = in.y, m[2,*] = in.z, m[3,*] = s*in.vx, m[4,*] = s*in.vy, m[5,*] = s*in.vz;
  variable cols = String_Type[N];
  variable i;
  _for i(0, N-1, 1)
    cols[i] = sprintf("o%d", i);
  variable ret = @Struct_Type(cols);
  variable temp = struct{ t, x, y, z, vx, vy, vz };
  _for i(0, N-1, 1)
  {
    temp.t = {0};
    temp.x = {m[0,i]};
    temp.y = {m[1,i]};
    temp.z = {m[2,i]};
    temp.vx = {m[3,i]};
    temp.vy = {m[3,i]};
    temp.vz = {m[5,i]};
    set_struct_field(ret, cols[i], @temp);
  }
  % ============================
  % initializing the ODE-solver:
  variable k1, k2, k3, k4, k5, k6, dx_c, dx_e; % dx_c = dx continue, dx_e = dx error estimation
  variable coef = Double_Type[7,7]; % modified Butcher tableau for Runge-Kutta-Fehlberg method
  coef[0,0]= 1./4;   coef[0,1]=  1./4;
  coef[1,0]= 3./8;   coef[1,1]=  3./32;      coef[1,2]=  9./32;
  coef[2,0]= 12./13; coef[2,1]=  1932./2197; coef[2,2]= -7200./2197;  coef[2,3]=  7296./2197;
  coef[3,0]= 1.;     coef[3,1]=  439./216;   coef[3,2]= -8.;          coef[3,3]=  3680./513;    coef[3,4]= -845./4104;
  coef[4,0]= 1./2;   coef[4,1]= -8./27;      coef[4,2]=  2.;          coef[4,3]= -3544./2565;   coef[4,4]=  1859./4104; coef[4,5]= -11./40;
  coef[5,0]= 0;      coef[5,1]=  25./216;    coef[5,2]=  1408./2565;  coef[5,3]=  2197./4104;   coef[5,4]= -1./5;       coef[5,5]= 0;       % fourth order solution
  coef[6,0]= 0;      coef[6,1]=  16./135;    coef[6,2]=  6656./12825; coef[6,3]=  28561./56430; coef[6,4]= -9./50;      coef[6,5]= 2./55;   % fifth order solution
  % ============================
  % =================================
  % solving the equations of motions:
  variable t = 0;
  variable t_last_save = 0;
  variable dt = 0.001;
  while(t < t+dt <= t_end)
  {
    k1 = dt * (@kernel)(s*t, m;; __qualifiers);
    k2 = dt * (@kernel)(s*(t + coef[0,0]*dt), m + coef[0,1]*k1;; __qualifiers);
    k3 = dt * (@kernel)(s*(t + coef[1,0]*dt), m + coef[1,1]*k1 + coef[1,2]*k2;; __qualifiers);
    k4 = dt * (@kernel)(s*(t + coef[2,0]*dt), m + coef[2,1]*k1 + coef[2,2]*k2 + coef[2,3]*k3;; __qualifiers);
    k5 = dt * (@kernel)(s*(t + coef[3,0]*dt), m + coef[3,1]*k1 + coef[3,2]*k2 + coef[3,3]*k3 + coef[3,4]*k4;; __qualifiers);
    k6 = dt * (@kernel)(s*(t + coef[4,0]*dt), m + coef[4,1]*k1 + coef[4,2]*k2 + coef[4,3]*k3 + coef[4,4]*k4 + coef[4,5]*k5;; __qualifiers);
    dx_c = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
    dx_e = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6; % fifth order solution
    variable scale = 0.9*(eps/max(abs(dx_c-dx_e)))^(0.2); % 0.9 is safety factor; derivation see Numerical Recipes, Section "Adaptive Stepsize Control for Runge-Kutta"
    if(scale>=1 or dt<=1e-14*t) % scale>1: accept stepsize only if correction factor is equal/larger than 1
    {
      m += dx_c;
      t += dt;
      if(verbose) vmessage("t=%g", s*t);
      if(t-t_last_save > threshold or t==t_end)
      {
	t_last_save = t;
	list_append((get_struct_field(ret, cols[0])).t, t);
	_for i(0, N-1, 1)
	{
	  list_append((get_struct_field(ret, cols[i])).x, m[0,i]);
	  list_append((get_struct_field(ret, cols[i])).y, m[1,i]);
	  list_append((get_struct_field(ret, cols[i])).z, m[2,i]);
	  list_append((get_struct_field(ret, cols[i])).vx, m[3,i]);
	  list_append((get_struct_field(ret, cols[i])).vy, m[4,i]);
	  list_append((get_struct_field(ret, cols[i])).vz, m[5,i]);
	}
      }
    }
    dt = _max(dt*scale, t*1e-15); % abs(1e-15*t) in order to avoid infinite loops due to Double_Type precision limit at dt=1e-16*t
    if(t+dt > t_end) dt = t_end-t;
  }
  % =================================
  temp = struct{ t, x, y, z, vx, vy, vz };
  temp.t = list_to_array((get_struct_field(ret, cols[0])).t, Double_Type);
  temp.t *= s; % for backward integration, i.e. t_end < 0, re-reverse t
  _for i(0, N-1, 1)
  {
    temp.x = list_to_array((get_struct_field(ret, cols[i])).x, Double_Type);
    temp.y = list_to_array((get_struct_field(ret, cols[i])).y, Double_Type);
    temp.z = list_to_array((get_struct_field(ret, cols[i])).z, Double_Type);
    temp.vx = list_to_array((get_struct_field(ret, cols[i])).vx, Double_Type);
    temp.vy = list_to_array((get_struct_field(ret, cols[i])).vy, Double_Type);
    temp.vz = list_to_array((get_struct_field(ret, cols[i])).vz, Double_Type);
    temp.vx *= s; temp.vy *= s; temp.vz *= s; % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
    set_struct_field(ret, cols[i], @temp);
  }
  return ret;
}
