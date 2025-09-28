define Aitoff_projection()
%!%+
%\function{Aitoff_projection}
%\synopsis{computes an Aitoff projection}
%\usage{(Double_Type x, y) = Aitoff_projection(Double_Type l, b);}
%\qualifiers{
%\qualifier{deg}{\code{l} and \code{b} are in degrees, not in radian}
%\qualifier{normalized}{\code{x} and \code{y} are normalized (by \code{PI/2})
%                 such that \code{abs(x) <= 2} and \code{abs(y) <= 1}.}
%}
%\description
%    NOTE: for astronomical purposes you probably want to use the
%    equal area Hammer-Aitoff projection rather than an Aitoff-projection.
%    Erroneously many astronomers call the Hammer-Aitoff projection an
%    Aitoff projection
%
%    \code{x = 2 * cos(b) * sin(l/2) / sinc(alpha);}\n
%    \code{y = sin(b) / sinc(alpha);}\n
%    where
%      \code{cos(alpha) = cos(b) * cos(l/2)}\n
%    and
%      \code{sinc(alpha) = sin(alpha)/alpha}
%\seealso{Hammer_projection, Lambert_Equal_Area_projection}
%!%-
{
  variable l, b;
  switch(_NARGS)
  { case 2: (l, b) = (); }
  { help(_function_name()); return; }

  vmessage("WARNING: Aitoff_projection is a map projection that is very rarely used");
  vmessage("   You probably want to use the Hammer-Aitoff projection, which is");
  vmessage("   implemented in the function Hammer_projection!");

  if(qualifier_exists("inverse")) {
      throw RunTimeError, "Error: inverse of Aitoff_projection is not yet implemented";
  }

  if(qualifier_exists("deg")) { 
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



  variable alpha = acos(cos(b)*cos(l/2.));
  variable inv_sinc_alpha = alpha/sin(alpha);
  if(typeof(alpha)==Array_Type) {
    inv_sinc_alpha[where(alpha==0)] = 1.;
  } else {
    if(alpha==0)  inv_sinc_alpha = 1;
  }
  if(qualifier_exists("normalized"))  inv_sinc_alpha /= PI/2;

  variable sig=+2.;
  if(qualifier_exists("astronomical")) {
      sig=-2.;
  }

  return sig*cos(b)*sin(l/2.)*inv_sinc_alpha,
         sin(b)*inv_sinc_alpha;
}
