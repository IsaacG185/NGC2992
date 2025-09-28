define cart2cyl()
%!%+
%\function{cart2cyl}
%\synopsis{Convert Cartesian to cylindrical coordinates}
%\usage{cart2cyl(Double_Types x[], y[], z[], vx[], vy[], vz[]);}
%\description
%    Convert Cartesian (x,y,z,vx,vy,vz) to cylindrical (r,phi,z,vr,vphi,vz)
%    coordinates with phi rotating counter-clockwise from the positive x-axis.
%\example
%    (r,phi,z,vr,vphi,vz) = cart2cyl(1,1,1,2,3,4);
%    (r,phi,z,vr,vphi,vz) = cart2cyl([1,0],[1,0],[1,0],[2,0],[3,0],[4,0]);
%    (r,phi,z,vr,vphi,vz) = cart2cyl( cyl2cart(1,PI/2,1,2,3,4) );
%\seealso{cart2sphere, cyl2cart}
%!%-
{
  if(_NARGS!=6)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable x, y, z, vx, vy, vz;
    (x ,y, z, vx, vy, vz) = ();
    x = [1.*x]; y = [1.*y]; z = [1.*z]; vx = [1.*vx]; vy = [1.*vy]; vz = [1.*vz];
    variable len = length(x);
    variable r, ind1, ind2;
    % radius:
    r = sqrt(x^2 + y^2); % radius
    ind1 = where( r!=0, &ind2 ); % ind1 -> r!=0; ind2 -> r==0
    variable vr = Double_Type[len]; % initialize vr = radial velocity
    vr[ind1] = ( x[ind1] * vx[ind1] + y[ind1] * vy[ind1] ) / r[ind1];
    vr[ind2] = sqrt( (vx[ind2])^2 + (vy[ind2])^2 );
    % polar angle phi:
    variable phi = Double_Type[len]; % initialize phi
    variable vphi = Double_Type[len]; % initialize vphi
    vphi[ind1] = (vy[ind1] * x[ind1] - vx[ind1] * y[ind1] ) / (r[ind1])^2;
    vphi[ind2] = 0.*vphi[ind2]; % in principle, this line is not necessary as already done in initialization
    variable ind = where(x==0 and y==0); % to determine phi for points at the origin use velocities instead of coordinates
    x[ind] = vx[ind];
    y[ind] = vy[ind];
    variable i;
    _for i(0, len-1, 1)
    {
      if (x[i]==0)
      {
	if (y[i]==0) phi[i] = 0;
	else
	{
	  if (y[i]>0) phi[i] = PI/2.;
	  else phi[i] = 3./2*PI;
	}
      }
      else
      {
	if (x[i]>0)
	{
	  if (y[i]==0) phi[i] = 0;
	  else
	  {
	    if (y[i]>0) phi[i] = atan(y[i]/x[i]);
	    else phi[i] = atan(y[i]/x[i])+2.*PI;
	  }
	}
	else phi[i] = atan(y[i]/x[i])+PI;
      }
    }

    if(length(x)==1) {return (r[0], phi[0], z[0], vr[0], vphi[0], vz[0]);}
    else return (r, phi, z, vr, vphi, vz);
  }
}

define cyl2cart()
%!%+
%\function{cyl2cart}
%\synopsis{Convert cylindrical to Cartesian coordinates}
%\usage{cyl2cart(Double_Types r[], phi[], z[], vr[], vphi[], vz[]);}
%\description
%    Convert cylindrical (r,phi,z,vr,vphi,vz) to Cartesian (x,y,z,vx,vy,vz)
%    coordinates with phi rotating counter-clockwise from the positive x-axis.
%\example
%    (x,y,z,vx,vy,vz) = cyl2cart(1,PI/2,1,2,3,4);
%    (x,y,z,vx,vy,vz) = cyl2cart([1,0],[PI/2,0],[1,0],[2,0],[3,0],[4,0]);
%    (x,y,z,vx,vy,vz) = cyl2cart( cart2cyl(1,1,1,2,3,4) );
%\seealso{cart2cyl}
%!%-
{
  if(_NARGS!=6)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable r, phi, z, vr, vphi, vz;
    (r, phi, z, vr, vphi, vz) = ();
    r = 1.*r; phi = 1.*phi; z = 1.*z; vr = 1.*vr; vphi = 1.*vphi; vz = 1.*vz;
    variable x, y, vx, vy;
    x = r*cos(phi);
    y = r*sin(phi);
    vx = vr*cos(phi) - r*sin(phi)*vphi;
    vy = vr*sin(phi) + r*cos(phi)*vphi;
    return (x, y, z, vx, vy, vz);
  }
}
