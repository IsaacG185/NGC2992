require("gsl", "gsl");

define plummer_interaction_kernel()
%!%+
%\function{plummer_interaction_kernel}
%\synopsis{Evaluate equations of motion or potential energy from a number of Plummer spheres}
%\usage{Double_Type eom[3,n] = plummer_interaction_kernel(Double_Types t, m[6,n], Struct_Type ps; qualifiers)}
%\altusage{Double_Type energy[n] = plummer_interaction_kernel(Double_Types t, m[6,n], Struct_Type ps; qualifiers)}
%\qualifiers{
%\qualifier{coords}{[\code{="cyl"}] Use cylindrical ("cyl") or cartesian ("cart") coordinates.}
%\qualifier{eomecd}{[\code{="eom"}] Return equations of motion ("eom") or potential energy ("energy").}
%}
%\description
%    This function computes the equations of motion or potential energy of n test particles
%    at time 't' caused by the interaction with a number of moving Plummer spheres. Depending
%    on whether cylindrical coordinates (r,phi,z) and their canonical momenta (vr,Lz,vz) or
%    cartesian coordinates (x,y,z,vx,vy,vz; see qualifier 'coords') are used, the second
%    input parameter 'm' is a [6,n]-matrix with
%    (qualifier("coords")=="cyl")                       or (qualifier("coords")=="cart")
%       m[0,*] = r;                                        m[0,*] = x;
%       m[1,*] = phi;                                      m[1,*] = y;
%       m[2,*] = z;                                        m[2,*] = z;
%       m[3,*] = vr;                                       m[3,*] = vx;
%       m[4,*] = Lz;                                       m[4,*] = vy;
%       m[5,*] = vz;                                       m[5,*] = vz;
%    If the qualifier 'eomecd' is set to "eom", the function returns a [3,n]-matrix 'delta' with
%       delta[0,*] = -d/dr Phi(r,phi,z);                   delta[0,*] = -d/dx Phi(x,y,z);
%       delta[1,*] = -d/dphi Phi(r,phi,z);                 delta[1,*] = -d/dy Phi(x,y,z);
%       delta[2,*] = -d/dz Phi(r,phi,z);                   delta[2,*] = -d/dz Phi(x,y,z);
%    whereby Phi is the sum over all Plummer potentials.
%    If the qualifier 'eomecd' is set to "energy", the function returns an array of length n
%    storing the potential energy for each orbit:
%       E(r,phi,z) = Double_Type[n] = Phi(r,phi,z)
%    or
%       E(x,y,z) = Double_Type[n] = Phi(x,y,z)
%
%    For each Plummer sphere, the third input parameter 'ps', which is a structure, contains
%    a field which is again a structure with fields 't', 'x', 'y', and 'z' (all are arrays of
%    the same length) that list the time-dependent positions of the sphere. Additionally, the
%    shape of the respective sphere (see notes below) is given by the two fields 'psa' and
%    'psb' (both scalars).
%\notes
%    The potential of a Plummer sphere at distance r is
%       Phi(r) = -psa*(psb+r^2)^(-1/2)
%    The resulting acceleration in radial direction is
%       d^2/dt^2 r = -d/dr Phi = -psa*(psb+r^2)^(-3/2)*r
%
%    Cubic spline interpolation is used to determine the positions of the Plummer spheres
%    at time 't' if the GSL-module is available. Otherwise, linear interpolation is applied.
%    Extrapolation is not allowed. Always make sure that the tabulated times '.t[*]' are in
%    monotonic increasing order if '.t[-1]' is positive or in monotonic decreasing order if
%    '.t[-1]' is negative.
%\example
%    ps = struct{ o0, o1 };
%    ps.o0 = struct{ t=[0,1,2], x=[-1,0,1], y=[0,1,2], z=[0,1,2], psa=1, psb=4 };
%    ps.o1 = struct{ t=[0,1,2], x=[1,0,-1], y=[0,1,2], z=[0,1,2], psa=1, psb=4 };
%    m = Double_Type[6,1];
%    m[0,0] = 0; m[1,0] = 2; m[2,0] = 0; m[3,0] = 0; m[4,0] = 0; m[5,0] = 0;
%    r = plummer_interaction_kernel(0,m,ps; coords="cart");
%    r = plummer_interaction_kernel(0,m,ps; eomecd="energy");
%\seealso{N_body_simulation_std_kernel, plummer_MW}
%!%-
{
  if(_NARGS!=3)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': Wrong number of arguments.", _function_name());
  }
  variable t, m, ps;
  (t, m, ps) = ();
  if(_is_struct_type(ps)!=1)
    throw UsageError, sprintf("Usage error in '%s': Third input parameter has to be Struct_Type.", _function_name());
  variable eomecd = qualifier("eomecd", "eom");
  variable coords = qualifier("coords", "cyl");
  %
  variable cols = get_struct_field_names(ps);
  variable N = length(m[0,*]);
  variable r;
  if(eomecd == "eom")
    r = Double_Type[3,N]; % equations of motion
  else if(eomecd == "energy")
    r = Double_Type[N]; % energy
  else
    throw UsageError, sprintf("Usage error in '%s': Invalid value for qualifier 'eomecd'.", _function_name());
  %
  variable intpolfunc = &interpol;
#ifeval __get_reference("gsl->interp_cspline")!=NULL; % use cubic spline interpolation if GSL-module is available, otherwise linear interpolation
    intpolfunc = &gsl->interp_cspline;
#endif
  %
  variable col;
  foreach col (cols) % loop over all Plummer spheres
  {
    % --------------------------------------------------------
    % determine the position of the Plummer spheres at time t:
    variable temp1 = t;
    variable temp2 = @((get_struct_field(ps, col)).t);
    variable s = sign(temp2[-1]);
    if(s<0) % function 'intpolfunc' expects old_x to be in monotonic increasing order
    {
      temp1 *= s;
      temp2 *= s;
    }
    ifnot( temp2[0] <= temp1 <= temp2[-1] )
      throw UsageError, sprintf("Usage error in '%s': Orbit of Plummer sphere '%s' does not cover requested time t=%g.", _function_name(), col, t);
    variable x_ps = @intpolfunc(temp1, temp2, (get_struct_field(ps, col)).x);
    variable y_ps = @intpolfunc(temp1, temp2, (get_struct_field(ps, col)).y);
    variable z_ps = @intpolfunc(temp1, temp2, (get_struct_field(ps, col)).z);
    % --------------------------------------------------------
    % --------------------------------------
    % compute equations of motion or energy:
    variable psa = (get_struct_field(ps, col)).psa;
    variable psb = (get_struct_field(ps, col)).psb;
    variable dx, dy;
    if(coords=="cart")
    {
      dx = x_ps - m[0,*];
      dy = y_ps - m[1,*];
    }
    else % coords=="cyl"
    {
      variable cos_phi = cos(m[1,*]);
      variable sin_phi = sin(m[1,*]);
      dx = x_ps - m[0,*]*cos_phi;
      dy = y_ps - m[0,*]*sin_phi;
    }
    variable dz = z_ps - m[2,*];
    variable d2 = dx^2 + dy^2 + dz^2;
    if(eomecd == "eom")
    {
      variable interaction = psa*(psb+d2)^(-1.5);
      if(coords=="cart")
      {
	r[0,*] += interaction*dx;
	r[1,*] += interaction*dy;
	r[2,*] += interaction*dz;
      }
      else % coords=="cyl"
      {
	r[0,*] += interaction*(x_ps*cos_phi + y_ps*sin_phi - m[0,*]);
	r[1,*] += interaction*(y_ps*cos_phi - sin_phi*x_ps)*m[0,*];
	r[2,*] += interaction*dz;
      }
    }
    else if(eomecd == "energy")
    {
      r += -psa/sqrt(psb+d2); % potential energy of Plummer sphere is -a/sqrt(b+dx^2+dy^2+dz^2)
    }
    % --------------------------------------
  }
  return r;
}
