%%%%%%%%%%%%%%%%%%%%%%%%
define Hammer_projection()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Hammer_projection}
%\synopsis{Computes the Hammer-Aitoff projection}
%\usage{(Double_Type x, y) = Hammer_projection(Double_Type l, b);}
%\qualifiers{
%\qualifier{deg}{\code{l} and \code{b} are in degrees, not in radian}
%\qualifier{normalized}{\code{x} and \code{y} are normalized (by \code{sqrt(2)})
%                 such that \code{abs(x) <= 2} and \code{abs(y) <= 1}.}
%\qualifier{astronomical}{flip x-axis for astronomical maps, where east is
%                 to the left}
%\qualifier{inverse}{calculate the inverse projection, interpreting l as the x- and
%               b as the y-coordinate; all other qualifiers are 
%               also interpreted as expected.}
%}
%\description
% This is the projection erroneously called the Aitoff projection by many
% astronomers. It is an equal area projection. The projection equations are
%
%    \code{x = 2 * sqrt(2) * cos(b) * sin(l/2) / sqrt(1 + cos(b)*cos(l/2));}\n
%    \code{y = sqrt(2) * sin(b) / sqrt(1 + cos(b)*cos(l/2));}\n
%
% The inverse function returns nan if the arguments given are not possible.
%
%\seealso{Aitoff_projection, Lambert_Equal_Area_projection}
%!%-
{
  variable l, b;
  switch(_NARGS)
  { case 2: (l, b) = (); }
  { help(_function_name()); return; }

  if (qualifier_exists("inverse")) {

      % inverse projection
      variable x=l; 
      variable y=b;
      if (qualifier_exists("astronomical")) {
	  x=-x;
      }
      if (qualifier_exists("normalized")) {
	  x*=sqrt(2.0);
	  y*=sqrt(2.0);
      }

      variable z2=1.-(x/4.)^2.-(y/2.)^2.;
      variable z = sqrt(z2);

      l=2.*atan2(z*x/2.0, 2.*z*z-1.);
      b=asin(y*z);

      if (qualifier_exists("astronomical")) {
       	  if(typeof(l)==Array_Type) {
       	      l[where(l<0)] += 2*PI;
       	  } else { 
	      if (l<0.0) {
		  l+=2*PI;
	      }
	  }
      }

      if (qualifier_exists("deg")) {
	  l*=180./PI;
	  b*=180./PI;
      }

      return l,b;
  }

  if (qualifier_exists("deg") ) {
      l *= PI/180;
      b *= PI/180;
  }

  if(typeof(l)==Array_Type) {
      while(any(abs(l)>PI)) {
   	  l[where(l> PI)] -= 2*PI;
   	  l[where(l<-PI)] += 2*PI;
      }
  } else { 
      while(l> PI)  l-= 2*PI;
      while(l<-PI)  l+= 2*PI;
  }

  variable sinb,cosb;
  (sinb,cosb)=sincos(b);

  variable sinl2,cosl2;
  (sinl2,cosl2)=sincos(l/2.0);

  variable w = 1./sqrt(0.5+0.5*cosb*cosl2);
  if (qualifier_exists("normalized"))  {
      w = w/sqrt(2.0);
  }

  variable astro=2.;
  if (qualifier_exists("astronomical")) {
      astro=-2.;
  }

  return (astro*cosb*sinl2*w,sinb*w);

}
