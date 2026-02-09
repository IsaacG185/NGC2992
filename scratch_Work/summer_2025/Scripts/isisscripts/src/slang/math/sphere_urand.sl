require( "rand" );

%%%%%%%%%%%%%%%%%%%
define sphere_urand()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{sphere_urand}
%\synopsis{generate spherical coordinates uniformly distributed on a sphere}
%\usage{(Double_Type theta, phi) = sphere_urand();
%\altusage{(Double_Type theta[], phi[]) = sphere_urand(Integer_Type n);}
%}
%\description
%    The function generates \code{n} (default: \code{1}) pairs \code{(theta[i], phi[i])}
%    of spherical coordinates -- such that the points
%     \code{[ sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta) ]}
%    are uniformly distributed on the surface of the unit sphere.
%!%-
{
  variable n;
  switch(_NARGS)
  { case 0: n = 1; }
  { case 1: n = (); }
  { help(_function_name()); return; }

  variable theta = acos(rand_flat(-1, 1, n)),
           phi = rand_flat(0, 2*PI, n);

  if(n==1)
    return (theta[0], phi[0]);
  else
    return (theta, phi);
}
