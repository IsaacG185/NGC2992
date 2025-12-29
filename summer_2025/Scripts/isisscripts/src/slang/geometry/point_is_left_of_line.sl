define point_is_left_of_line()
%!%+
%\function{point_is_left_of_line}
%\usage{ret=point_is_left_of_line(p0,p1,p2);}
%\altusage{ret=point_is_left_of_line(p0x,p0y,p1x,p1y,p2x,p2y);}
%\synopsis{determines whether point p2 is left of a line through p0 and p1}
%\description
% This function tests if point p2 is to the left of an infinite line defined
% by points p0 and p1. The points are defined by structs p=struct{x,y},
% where x is the x-coordinate and y is the y-coordinate.
%
% The function returns
%   +1 if P2 is left of the line
%    0 if P2 is on the line
%   -1 -1 if P2 is right of the line
%
% Based on code by Dan Sunday, http://geomalgorithms.com/a03-_inclusion.html
%
%\seealso{crossing_number_polygon,winding_number_polygon,point_in_polygon,simplify_polygon}
%!%-
{
    variable p0,p1,p2;
    variable cross;
    if (_NARGS==6) {
	variable p0x,p0y,p1x,p1y,p2x,p2y;
	(p0x,p0y,p1x,p1y,p2x,p2y)=();
	cross= (p1x-p0x)*(p2y-p0y) - (p2x-p0x)*(p1y-p0y);
    } else {
	if (_NARGS==3) {
	    (p0,p1,p2)=();
	    cross= (p1.x-p0.x)*(p2.y-p0.y) - (p2.x-p0.x)*(p1.y-p0.y);
	} else {
	    throw UsageError,sprintf("%s: Wrong number of arguments.\n",_function_name());
	}
    }
    return sign(cross);
}
