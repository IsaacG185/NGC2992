define ellipse ()
%!%+
%\function{ellipse}
%\synopsis{calculates points on an ellipse centered at the origin}
%\usage{(Double_Type X,Y) = ellipse(Double_Type smaj, smin, posang, phi)
%}
%\qualifiers{
%\qualifier{x}{[\code{=1}] compression/streching factor along the x-axis}
%\qualifier{y}{[\code{=1}] compression/streching factor along the y-axis}
%}
%\description
%    This function calculates the coordinates \code{X}, \code{Y} of an ellipse with
%    semimajor axis \code{smaj}, semiminor axis \code{smin}, and position angle \code{posang}
%    (measured in rad with respect to the x-axis) which is parameterized with \code{phi}.
%    The complete ellipse is covered when \code{phi} covers the values from 0 to 2*PI.
%\examples
%    variable phi=[0:2*PI:#200];
%    plot ( ellipse(5,3,0.2*PI,phi) );
%    oplot( ellipse(5,3,0.2*PI,phi ; x=0.5) );
%\seealso{enclosing_ellipse}
%!%-
{
  variable a,b,p,t;
  switch(_NARGS)
  { case 4: (a,b,p,t) = (); }
  { help(_function_name()); return; }
  
  variable x=qualifier("x",1.);
  variable y=qualifier("y",1.);
  return (
	  x*a*cos(t)*cos(p)-x*b*sin(t)*sin(p),
	  y*a*cos(t)*sin(p)+y*b*sin(t)*cos(p)
	 );
  
}
