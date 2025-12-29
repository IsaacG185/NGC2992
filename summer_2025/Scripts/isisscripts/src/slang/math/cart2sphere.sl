define cart2sphere()
%!%+
%\function{cart2sphere}
%\synopsis{Convert Cartesian to spherical coordinates}
%\usage{cart2sphere(Double_Types x[], y[], z[], vx[], vy[], vz[]);}
%\description
%    Convert Cartesian (x,y,z,vx,vy,vz) to spherical (r,phi,theta,vr,vphi,vtheta)
%    coordinates with polar angle phi rotating counter-clockwise from the positive
%    x-axis and azimuth angle theta being zero for the positive z-axis.
%\example
%    (r,phi,theta,vr,vphi,vtheta) = cart2sphere(0,0,0,1,2,3);
%    (r,phi,theta,vr,vphi,vtheta) = cart2sphere(0,0,1,1,2,3);
%    (r,phi,theta,vr,vphi,vtheta) = cart2sphere(1,1,1,3,3,3);
%    (r,phi,theta,vr,vphi,vtheta) = cart2sphere(1,0,0,0,2,1);
%    (r,phi,theta,vr,vphi,vtheta) = cart2sphere([0,1],[0,0],[0,0],[1,0],[2,2],[3,1]);
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
    variable x, y, z, vx, vy, vz;
    (x ,y, z, vx, vy, vz) = ();
    x = [1.*x]; y = [1.*y]; z = [1.*z]; vx = [1.*vx]; vy = [1.*vy]; vz = [1.*vz];
    variable len = length(x);
    % radius:
    variable r, ind1, ind2;
    r = sqrt(x^2 + y^2 + z^2); % radius
    ind1 = where( r!=0, &ind2 ); % ind1 -> r!=0; ind2 -> r==0
    variable vr = Double_Type[len]; % initialize vr = radial velocity
    vr[ind1] = ( x[ind1] * vx[ind1] + y[ind1] * vy[ind1] + z[ind1] * vz[ind1]) / r[ind1];
    vr[ind2] = sqrt( (vx[ind2])^2 + (vy[ind2])^2 + (vz[ind2])^2 );
    %
    variable ind3, ind4;
    ind3 = where( x^2+y^2!=0, &ind4 ); % ind3 -> x^2+y^2!=0; ind4 -> x^2+y^2==0
    % azimuth angle theta:
    variable theta = Double_Type[len]; % initialize theta
    theta[ind1] = acos( z[ind1]/r[ind1] );
    theta[ind2] = 0.*theta[ind2]; % in principle, this line is not necessary as already done in initialization
    variable vtheta = Double_Type[len]; % initialize vtheta
    vtheta[ind3] = ( z[ind3]*vr[ind3]/r[ind3] - vz[ind3] ) / sqrt( (x[ind3])^2 + (y[ind3])^2 );
    vtheta[ind4] = sqrt( (vx[ind4])^2 + (vy[ind4])^2 ) / z[ind4]; % on the z-axis: vr=vz, vphi=0 -> vtheta*z=sqrt(vx^2+vy^2)
    vtheta[ind2] = 0.*theta[ind2]; % in origin, vtheta is zero as the entire velocity is assigned to vr; NOTE: 0.*theta[ind2] and not 0.*vtheta[ind2] as vtheta[ind2] might be nan due to previous line
    % polar angle phi:
    variable vphi = Double_Type[len]; % initialize vphi
    vphi[ind3] = (vy[ind3] * x[ind3] - vx[ind3] * y[ind3] ) / ( (x[ind3])^2 + (y[ind3])^2 );
    vphi[ind4] = 0.*vphi[ind4]; % in principle, this line is not necessary as already done in initialization
    variable phi = Double_Type[len]; % initialize phi
    variable ind = where(x==0 and y==0); % to determine phi for points on the z-axis use velocities instead of coordinates
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
    %
    if(length(x)==1) {return (r[0], phi[0], theta[0], vr[0], vphi[0], vtheta[0]);}
    else return (r, phi, theta, vr, vphi, vtheta);
  }
}
