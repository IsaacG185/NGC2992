define douglas_peucker(x,y,maxdist2);
define douglas_peucker(x,y,maxdist2) {
%!%+
%\function{douglas_peucker}
%\synopsis{Simplify polygons using the Douglas Peucker Algorithm}
%\usage{(xx,yy)=douglas_peucker(x,y,d2);}
%\description
%   This function implements an algorithm to simplify complex
%   polygons (Douglas & Peucker, 1973, Cartographica 10(2), 112).
%   A recursive version presented by Hershberger & Snoeyink (1992,
%   Proc. 5th Intl. Symp. on Spatial Data Handling, 134-143) is
%   used.
%   For a polygon P defined by positions in given by the arrays (x,y),
%   the algorithm returns the polygon P2 defined by coordinates (xx,yy) 
%   with the property that the maximum distance between the lines segments
%   of P and P2 is smaller than sqrt(d2). 
%   Note 1:
%   The algorithm only yields a good result if P is not self-intersecting.
%   Note 2:
%   As discussed by Hershberger & Snoeyink, the worst performance of
%   the Douglas-Peucker-algorithm is O(N^2). Hershberger & Snoeyink (1998,
%   Computational Geometry 11(3-4), 175-185) present a O(N log N) algorithm.
%   Unfortunately for me (J. Wilms), this algorithm is too complex to be
%   implementable on the ICE between Hamburg and Bamberg...
%   Note 3:
%   This function is called recursively and does not perform sanity checks on
%   x,y,d2. If you do not know about the properties of your data, use
%   simplify_polygon.
%   
%\seealso{simplify_polygon}
%!%-
    variable npt=length(x);
    %
    % segment cannot be simplified
    %
    if (npt<=2) {
	return x,y;
    }
    
    %
    % find point with maximum distance from the polygon
    %
    variable i;
    variable isplit=0;
    variable maxdi2=0.;

    _for i(1,npt-2,1) {
	variable dist2=point_distance2_from_line(x[i],y[i],x[0],y[0],x[npt-1],y[npt-1]);
	if (dist2>maxdi2) {
	    maxdi2=dist2;
	    isplit=i;
	}
    }

    if (maxdi2>=maxdist2) {
	%
	% recursively simplify polygon further
	%
	variable xx1,yy1,xx2,yy2;
	(xx1,yy1)=douglas_peucker(x[[0:isplit]],y[[0:isplit]],maxdist2);
	(xx2,yy2)=douglas_peucker(x[[isplit:npt-1]],y[[isplit:npt-1]],maxdist2);

	return ([xx1,xx2[[1:]]] , [yy1,yy2[[1:]]] );
    }

    return([x[0],x[npt-1]],[y[0],y[npt-1]]);
}

define simplify_polygon() 
%!%+
%\function{simplify_polygon}
%\synopsis{Simplify polygons using the Douglas Peucker Algorithm}
%\usage{(xx,yy)=simplify_polygon(x,y,d);}
%\description
% Use the Douglas Peucker Algorithm to simplify the polygon P
% defined by the positions in the arrays x,y such that the
% maximum distance between all segments  of the resulting
% polygon P2 defined by (xx,yy) is smaller than d.
% See the help for the function douglas_peucker for caveats
% Note that the argument d in simplify_polyon defines the
% distance, while the corresponding argument in douglas_peucker
% defines the distance squared!
%
% \seealso{douglas_peucker}
%!%-
{

    if (_NARGS != 3 ) {
	help(_function_name());
	return;
    }

    variable x,y,maxdist;
    (x,y,maxdist)=();
    
    if (length(maxdist)!=1) {
	throw UsageError,sprintf("%s: maxdist must be a scalar\n",_function_name());
    }

    if (maxdist<=0) {
	throw UsageError, sprintf("%s: maxdist must be positive\n",_function_name());
    }

    if (length(x)!=length(y)) {
	throw UsageError, sprintf("%s: x, y must have the same length\n",_function_name());
    }
    
    if (length(x)<2) {
	throw UsageError, sprintf("%s: x, y must include at least two points\n",_function_name());
    }

    douglas_peucker(x,y,maxdist*maxdist);
}
