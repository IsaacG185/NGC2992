define point_distance2_from_line(xp,yp,x1,y1,x2,y2) 
%!%+
%\function{point_distance2_from_line}
%\synopsis{Calculate the squared distance of a point from a line}
%\usage{d2=point_distance2_from_line(xp,yp,x1,y1,x2,y2)}
%\description
% Calculate the  distance of point (xp,yp) from the line
% defined by the points P1=(x1,y1) and P2=(x2,y2), where
% P1!=P2. This condition is not tested for speed
% reasons and will result in a division by zero.
%!%-
{
    variable dy=y2-y1;
    variable dx=x2-x1;

    variable nom=dy*xp-dx*yp+x2*y1-y2*x1;
    
    return nom*nom/(dy*dy+dx*dx);
}

