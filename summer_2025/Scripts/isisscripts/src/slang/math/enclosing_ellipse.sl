private define r_e (a,b,p,t) % distance from the origin to the point on ellipse at phase t
{
  variable y=qualifier("y",1.);
  return sqrt(cos(t)^2*a^2*(cos(p)^2+y^2*sin(p)^2)+
	      sin(t)^2*b^2*(y^2*cos(p)^2+sin(p)^2)+
	      sin(t)*cos(t)*2*a*b*(y^2-1)*cos(p)*sin(p));
}

private define t_m (a,b,p,y) % phase parameter of ellipse where r_e is maximal (minimal?)
{
  return 0.5*atan( 2*a*b*cos(p)*sin(p)*(y^2-1.)/
		   (a^2*(cos(p)^2+y^2*sin(p)^2)-b^2*(y^2*cos(p)^2+sin(p)^2)));
}

%%%%%%%%%%%%%%%%%%%%%%%%%%
define enclosing_ellipse()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{enclosing_ellipse}
%\synopsis{calculates the smallest ellipse enclosing two ellipses centered at the origin}
%\usage{(Double_Type smaj,smin,posang) = enclosing_ellipse(Double_Type smaj1, smin1, posang1, smaj2, smin2, posang2)
%}
%\description
%    This function calculates the semimajor axis \code{smaj}, the semiminor axis \code{smin},
%    and the position angle \code{posang} of the smallest ellipse enclosing
%    two ellipses centered at the origin.
%\examples
%
%    smaj1 = 5.; smin1 = 2.; posang1 = 0.3;
%    smaj2 = 4.; smin2 = 1.; posang2 = 0.7*PI;
%    variable phi=[0:2*PI:#200];
%    
%    plot ( ellipse( enclosing_ellipse(smaj1, smin1, posang1, smaj2, smin2, posang2) ,phi) );
%    oplot( ellipse(smaj1, smin1, posang1 ,phi) );
%    oplot( ellipse(smaj2, smin2, posang2 ,phi) );
%\seealso{ellipse}
%!%-
{
  variable a1,b1,p1,a2,b2,p2;
  switch(_NARGS)
  { case 6: (a1,b1,p1,a2,b2,p2) = (); }
  { help(_function_name()); return; }
  
  (a1, b1,   a2, b2) = (abs(a1), abs(b1),    abs(a2),abs(b2)); % using only positive axes
  if (b1 > a1) (a1,b1,p1) = (b1,a1,p1+0.5*PI); % make sure that a1 is the semimajor axis
  if (b2 > a2) (a2,b2,p2) = (b2,a2,p2+0.5*PI); % make sure that a2 is the semimajor axis

  if ( a1 <= b2 ) return (a2,b2,p2);
  if ( a2 <= b1 ) return (a1,b1,p1);
  if ( a1==a2 && b1==b2 && ( (p1-p2) mod PI) == 0 ) return (a1,b1,p1);
  
   if (a2 < a1)  % make a2 the larger semimajor, check if necessary!
  {
    variable tmp = a2; a2 = a1; a1=tmp;
    tmp = b2; b2 = b1; b1 = tmp;
    tmp = p2; p2 = p1; p1 = tmp;
  }
  variable dp = p1;
  p1 -=dp;
  p2 -=dp;
  
  variable Y = a1/b1;
  
  variable A = r_e(a2,b2,p2,t_m(a2,b2,p2,Y);y=Y); % or: max(a1,r_e(a2,b2,p2,t_m(a2,b2,p2,Y);y=Y));
  variable B = max([r_e(a2,b2,p2,t_m(a2,b2,p2,Y)+0.5*PI;y=Y),a1]);
  
  variable mx,my;
  (mx,my)= ellipse (a2,b2,p2,t_m(a2,b2,p2,Y);y=Y);
  variable P = atan2(my,mx);
  
  variable a = r_e(A,B,P,t_m(A,B,P,1./Y);y=1./Y);
  variable b = r_e(A,B,P,t_m(A,B,P,1./Y)+0.5*PI;y=1./Y);
  (mx,my)= ellipse (A,B,P,t_m(A,B,P,1./Y);y=1./Y);
  variable p = atan2 (my,mx);
  p +=dp;
  if (b > a) (a,b,p) = (b,a, p+0.5*PI); % make sure that 'a' is the semimajor axis
  return (a,b,p mod PI);
}
