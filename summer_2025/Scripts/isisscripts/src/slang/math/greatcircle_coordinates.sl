%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define greatcircle_coordinates()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{greatcircle_coordinates}
%\synopsis{calculates the coordinates of the greatcircle between two points on a sphere}
%\usage{(Double_Type lambda[], phi[]) = greatcircle_coordinates(lambda1, phi1, lambda2, phi2);}
%\qualifiers{
%\qualifier{unit}{[\code{="deg"}] unit of the angular coordinates}
%\qualifier{delta}{[\code{=0.5}] angular step in degrees}
%}
%\description
%    (\code{lambda}i, \code{phi}i) are the spherical coordinates of point i.\n
%    \code{unit="deg"}: \code{lambda}i and \code{phi}i are in degrees.\n
%                They can be scalar values or arrays of the form
%                \code{[deg, arcmin]}, \code{[deg, arcmin, arcsec]} or \code{[sign, deg, arcmin, arcsec]}.
%    \code{unit="rad"}: \code{lambda}i and \code{phi}i are scalars in radian.\n
%    \code{unit="hms"}: code{lambda}i are scalars hour angles (24h = 360deg)
%                or arrays in h:m:s format, i.e., \code{[h, m]} or \code{[h, m, s]}.
%                The \code{phi}i are nevertheless in degrees as above.
%\seealso{greatcircle_distance}
%!%-
{
  variable l1, p1, l2, p2;
  switch(_NARGS)
  { case 4: (l1, p1, l2, p2) = (); }
  { help(_function_name()); return; }
  
  variable q = __qualifiers();
  (l1, l2) = angle_to_rad(l1, l2;; q);
  if(qualifier("unit", "deg")=="hms")  q.unit = "deg";  % if RA is in HMS, delta is still in deg
  (p1, p2) = angle_to_rad(p1, p2;; q);

  variable x = cos(l2)*cos(p2);
  variable y = sin(l2)*cos(p2);
  variable z = sin(p2);
  variable cos_l1 = cos(l1);
  variable sin_l1 = sin(l1);
  (x, y) = (cos_l1*x+sin_l1*y, cos_l1*y-sin_l1*x);  % Rz(-l1)
  variable cos_p1 = cos(p1);
  variable sin_p1 = sin(p1);
  (x, z) = (cos_p1*x+sin_p1*z, cos_p1*z-sin_p1*x);  % Ry(-p1)
  variable inv_sqrt = 1./sqrt(y^2+z^2);
  variable cos_d = z*inv_sqrt;
  variable sin_d = y*inv_sqrt;
  (   z) = (  cos_d*z+sin_d*y);  % Rx(d)
  variable phi = atan2(z, x);
  phi = [0:phi:#(1+int(phi/(qualifier("delta", 0.5)*PI/180)))];
  (x, y, z) = (cos(phi), 0*phi, sin(phi));
  (y, z) = (cos_d*y+sin_d*z, cos_d*z-sin_d*y);  % Rx(-d)
  (x, z) = (cos_p1*x-sin_p1*z, cos_p1*z+sin_p1*x);  % Ry(p1)
  (x, y) = (cos_l1*x-sin_l1*y, cos_l1*y+sin_l1*x);  % Rz(l1)
  variable l = atan2(y, x);
  variable b = asin(z);
  
  switch(qualifier("unit", "deg"))
  { case "deg":  l *= 180/PI;  b *= 180/PI; }
  { case "HMS":  l *= 15/PI;   b *= 180/PI; }
  return (l, b);
}
