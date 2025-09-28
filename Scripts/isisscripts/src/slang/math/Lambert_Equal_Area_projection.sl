define Lambert_Equal_Area_projection(phi,theta) {
%!%+
%\function{Lamberg_Equal_Area_projection}
%\synopsis{Computes the Lambert_Equal_Area_projection}
%\usage{(Double_Type x, y) = Lambert_Equal_Area_projection(Double_Type phi,theta);}
%\qualifiers{
%\qualifier{deg}{\code{phi} and \code{theta} are in degrees, not in radian}
%\qualifier{inverse}{calculate the inverse projection, interpreting phi as the x- and
%               theta as the y-coordinate; all other qualifiers are 
%               also interpreted as expected.}
%}
%\description
% This is an equal area projection centered on the North Pole (when plotting
% southern objects, flip the sign of theta!). phi is the angle along the 
% equator, theta is measured from the equator.
%
%    \code{R =sin((pi/2 - theta)/2);}\n
%    \code{x = R * sin(phi);}\n
%    \code{y = R * cos(phi);}\n
%
% The inverse function returns nan if the arguments given are not possible.
%
%\seealso{Aitoff_projection, Hammer_projection}
%!%-

    if (qualifier_exists("inverse")) {
	variable x=phi;
	variable y=theta;

	phi=atan2(x,-y);
	variable rtheta=sqrt(x*x+y*y);
	theta=PI/2 - 2*asin(rtheta/2.);

	if (qualifier_exists("deg")) {
	    phi*=180./PI;
	    theta*=180./PI;
	}
	return(phi,theta);
    }


    if (qualifier_exists("deg")) {
	phi  *=PI/180.0;
	theta*=PI/180.0;
    }

    if(typeof(phi)==Array_Type) {
	while(any(abs(phi)>PI)) {
	    phi[where(phi> PI)] -= 2*PI;
	    phi[where(phi<-PI)] += 2*PI;
	}
    } else { 
	while(phi> PI)  phi-= 2*PI;
	while(phi<-PI)  phi+= 2*PI;
    }

    rtheta=sin((PI/2.-theta)/2.);
    
    variable sinp,cosp;
    (sinp,cosp)=sincos(phi);

    return (rtheta*sinp, rtheta*cosp);

}
