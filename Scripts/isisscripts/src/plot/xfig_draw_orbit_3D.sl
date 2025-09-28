require( "xfig" );

% function to shift, incline, and rotate orbit
private define _xfig_draw_orbit_3D_ellipse(x, foc, inc, omega) {
  x += vector(-foc, 0, 0);
  ifnot (qualifier_exists("noinc")) {
    x = vector_rotate(x, vector(1, 0, 0), inc * PI/180);
  }
  ifnot (qualifier_exists("noomega")) {
    x = vector_rotate(x, vector_rotate(vector(0, 0, 1), vector(1, 0, 0),
      inc * PI/180), omega * PI/180);
  }
  return x;
}

% projection of a 3D vector onto the camera field of view
private define _xfig_draw_orbit_3D_proj(r, cx, cy) {
  return (dotprod(r, cx), dotprod(r, cy));
}

%%%%%%%%%%%%%%%%%
define xfig_draw_orbit_3D()
%%%%%%%%%%%%%%%%%
%!%+
%\function{xfig_draw_orbit_3D}
%\synopsis{draws the orbit of a binary system in 3D}
%\usage{Xfig_Object xfig_draw_orbit([Xfig_Object xf,] Double_Type asini, i, ecc, omega);}
%\qualifiers{
%    \qualifier{caminc}{the camera inclination to the line of sight
%              (in degrees; default: 90-i)}
%    \qualifier{camroll}{the camera roll angle around the z-axis (along the
%              line of sight; in degress; default: 0)}
%}
%\description
%    Similar to 'xfig_draw_orbit' this function plots the orbit of a
%    binary, but seen from a user-defined direction and, thus, in 3D.
%    In order to draw the orbit the projected semi-major axis (asini),
%    inclination (i), eccentricity (ecc), and longitude of periastron
%    (omega) have to be provided.
%    
%    Additionally to the orbital plane the tangent plane of the sky
%    is drawn as well. This plane is defined to be perpendicular to
%    the line of sight and through the center of mass, i.e. the focal
%    point of the eccentric orbit nearest to the periastron (P).
%    Thereby, the observer is located below the tangent plane of the
%    sky, indicated by the arrow pointing to Earth.
%    All dashed lines are within the orbital plane, which are the
%    intersection of the orbital and tangent plane of the sky, the
%    semi-major and -minor axis (in red), and the line connecting the
%    orbit's center and the periastron. The projected semi-major axis
%    (asini) is drawn as dotted dashed line.
%    
%    The camera is controlled via qualifiers and by default the binary
%    is seen face-on.
%
%    Note that so far only basic functionallity have been implemented.
%\seealso{xfig_draw_orbit, ellipse}
%!%-
{
  variable pl = NULL, aSini, inc, ecc, omega;
  switch (_NARGS)
    { case 4: (aSini, inc, ecc, omega) = (); }
    { case 5: (pl, aSini, inc, ecc, omega) = (); }
    { help(_function_name()); return; }

  % camera
  variable cam  = qualifier("caminc", inc);   % inclination, 0 = onto tangent plane from above
  variable roll = qualifier("camroll", 0.); % rotation around z
  % camera unit vectors
  variable cx = vector(1, 0, 0);
  variable cy = vector(0, cos(cam*PI/180), sin(cam*PI/180));
  cx = vector_rotate(cx, vector(0,0,1), roll*PI/180);
  cy = vector_rotate(cy, vector(0,0,1), roll*PI/180);

  % orbit parameters
  variable a = aSini / sin(inc);
  % calculate focal point (center of mass)
  variable foc = sqrt(a^2 - (a*(1-ecc))^2);
  % calculate orbit
  variable phi = [0:2*PI:#200];
  variable r = vector(
    Double_Type[length(phi)], Double_Type[length(phi)], Double_Type[length(phi)]
  );
  (r.x, r.y) = ellipse(a, a*(1-ecc), 0, [0:2*PI:#200]);
  r = _xfig_draw_orbit_3D_ellipse(r, foc, inc, omega);

  %%% lines
  % intersection with tangent plane
  variable n = array_sort(abs(r.z))[[0,1]];
  variable ints = vector(r.x[n], r.y[n], [0,0]);
  % semi-* axes
  variable smaj = _xfig_draw_orbit_3D_ellipse(vector([0,-a], [0,0], [0,0]), foc, inc, omega);
  variable smin = _xfig_draw_orbit_3D_ellipse(vector([0,0], [0,a*(1-ecc)], [0,0]), foc, inc, omega);
  variable asini = vector(smaj.x[-1] * [1,1], smaj.y[-1] * [1,1], smaj.z);
  variable acosi = vector(smaj.x, smaj.y, smaj.z[0] * [1,1]);
  % position of periastron
  variable prast = _xfig_draw_orbit_3D_ellipse(vector(a, 0, 0), foc, inc, omega);
  % line from center of orbit to periastron
  variable cmpe = vector([smaj.x[0], prast.x], [smaj.y[0], prast.y], [smaj.z[0], prast.z]);
  % line from tg to apastron minus asini
  variable apast = vector(asini.x, asini.y, [0, asini.z[0]]);
  % line within the tg connecting the apastron and center of mass
  variable apcm = vector([apast.x[0], 0], [apast.y[0], 0], [0,0]);
  % center of mass
  variable cm = vector(0, 0, 0);

  % tangent plane
  variable wrld = a*(1+ecc);
  variable tp = vector([-1,-1,1,1,-1]*wrld, [-1,1,1,-1,-1]*wrld, [0,0,0,0,0]);

  %%% xfig plot
  if (pl == NULL) { pl = xfig_plot_new(12,12); }
  pl.world(-wrld, wrld, -wrld, wrld; padx = .1, pady = .1);
  pl.axes(; major = 0, minor = 0, color = "white");
  % orbit
  pl.plot(_xfig_draw_orbit_3D_proj(r, cx, cy));
  % tangent plane
  pl.plot(_xfig_draw_orbit_3D_proj(tp, cx, cy));
  % lines
  pl.plot(_xfig_draw_orbit_3D_proj(ints, cx, cy); line = 1);
  pl.plot(_xfig_draw_orbit_3D_proj(smaj, cx, cy); color = "red", line = 1);
  pl.plot(_xfig_draw_orbit_3D_proj(smin, cx, cy); color = "red", line = 1);
  pl.plot(_xfig_draw_orbit_3D_proj(asini, cx, cy); color = "red", line = 2);
  pl.plot(_xfig_draw_orbit_3D_proj(cmpe, cx, cy); line = 1);
  pl.plot(_xfig_draw_orbit_3D_proj(acosi, cx, cy); line = 2);
  pl.plot(_xfig_draw_orbit_3D_proj(apast, cx, cy); line = 2);
  pl.plot(_xfig_draw_orbit_3D_proj(apcm, cx, cy); line = 2);
  pl.plot(_xfig_draw_orbit_3D_proj(cm, cx, cy); sym = "x");
  % to Earth
  variable Earth = vector([1,1]*.8*wrld, -[1,1]*.8*wrld, -[.1,.25]*wrld);
  pl.plot(_xfig_draw_orbit_3D_proj(vector(Earth.x, Earth.y, [0, Earth.z[0]]), cx, cy); line = 2);
  pl.plot(_xfig_draw_orbit_3D_proj(Earth, cx, cy); forward_arrow);
  pl.xylabel(
    _xfig_draw_orbit_3D_proj(vector(Earth.x[1], Earth.y[1], Earth.z[1]), cx, cy), "to Earth",
    0, .7; size = "scriptsize"
  );
  % labels
  pl.xylabel(_xfig_draw_orbit_3D_proj(wrld*vector(0,1.05,.05), cx, cy), "tangent plane of the sky"R;
             size = "scriptsize");
  pl.xylabel(_xfig_draw_orbit_3D_proj(vector(prast.x*1.4, prast.y*1.4, prast.z), cx, cy), "P"; size = "scriptsize");
  pl.xylabel(_xfig_draw_orbit_3D_proj(vector(smaj.x[1]*1.05, smaj.y[1]*1.05, smaj.z[1]), cx, cy), "A";
	     size = "scriptsize");

  return pl;
}

