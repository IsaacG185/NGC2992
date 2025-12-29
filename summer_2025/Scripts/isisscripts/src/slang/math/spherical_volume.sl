%%%%%%%%%%%%%%%%%%%%%%%
define spherical_volume()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{spherical_volume}
%\synopsis{computes the volume of an object parameterized in spherical coordinates}
%\usage{Double_Type vol = spherical_volume(Ref_Type &r);}
%\qualifiers{
%\qualifier{Ntheta}{[=180]}
%\qualifier{Nphi}{[=180]}
%\qualifier{logfile}{[=NULL]: If logfile is a filehandle, the function evaluations are logged.}
%}
%\description
%    \code{r} has to be a real function with two arguments (theta, phi).\n
%    \code{vol = int_0^2pi dphi  int_0^pi dtheta sin(theta)  int_0^r(theta, phi) dr r^2}\n
%    \code{    = int_0^2pi dphi  int_0^pi dtheta sin(theta)  r(theta, phi)^3/3}\n
%    The numerical integration of phi and theta is performed on the following grid:\n
%    \code{theta = [0 : Pi : #Ntheta];   phi = [0 : 2*Pi : #Nphi];}
%!%-
{
  variable r;
  switch(_NARGS)
  { case 1: r = (); }
  { help(_function_name()); return; }

  variable Ntheta = qualifier("Ntheta", 180);
  variable Nphi = qualifier("Nphi", 180);
  variable logfile = qualifier("logfile", NULL);

  variable dtheta = PI/Ntheta;
  variable dphi = 2*PI/Nphi;
  variable itheta, iphi, theta, phi, rr;
  variable volume = 0;
  _for itheta (0, Ntheta-1, 1)
  { theta = itheta * dtheta;
    _for iphi (0, Nphi-1, 1)
    { phi = iphi * dphi;
      rr = @r(theta, phi);
      if(logfile==NULL)
        ()=fprintf(logfile, "%g %g %g\n", theta, phi, rr);
      volume += rr^3/3. * sin(theta)*dtheta*dphi;
    }
    if(logfile==NULL)
      ()=fprintf(logfile, "\n");
  }
  return volume;
}
