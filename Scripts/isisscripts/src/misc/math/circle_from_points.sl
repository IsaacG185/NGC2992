define circle_from_points(x,y) 
%!%+
%\function{circle_from_points}
%\synopsis{find the best fitting circle for a set of points}
%\usage{pars=circle_from_points(Array_Type x,Array_Type y);
%}
%\description
%    Given arrays of x/y coordinates of points which lie approximately on
%    a circle, this function returns the center coordinate and radius of
%    the circle. This is a numerically unstable procedure, but the
%    routine generally returns parameters which are good enough to start
%    a more advanced fitting routine.
%    The function is an implementation of ideas described by L. Maisonobe
%    in a document entitled "Finding the circle that best fits a set of
%    points" (see http://www.spaceroots.org/downloads.html): For each
%    tuple of three points of  coordinates it finds the center
%    and radius, which is possible in an exact manner, assuming that
%    the points are not on a straight line. This is done for all or a
%    subset of the points, and the resulting radius and center coordinates
%    are then averaged.
%    The function returns a structure with the tags xc and yc (x- and y-
%    coordinate of the center of the circle) and radius (radius of the circle),
%    or NULL if no solution could be found (points are on a straight line).
%
% \qualifiers{
%    \qualifier{eps}{if the determinant of the three point solution is less than
%                      than this number, the points lie on a straight line}    
%    \qualifier{maxiter}{average at most maxiter tuples of three points}
%}
%!%-
{
    if (length(x)<3 or length(y)<3) {
	throw UsageError, sprintf("Usage error in %s: need at least three points to estimate circle",_function_name());
    }

    if (length(x)!=length(y)) {
	throw UsageError, sprintf("Usage error in %s: need the same number of x- and y-coordinates", _function_name());
    }

    variable eps=qualifier("eps",1e-7);
    variable maxiter=qualifier("maxiter",1000);
    
    variable npt=length(x);

    % helpers
    variable xy2=x*x+y*y;
    variable sx=0.;
    variable sy=0.;
    variable nn=0;
    variable i,j,k,xc,yc,del;
    variable totnum=(npt-2.)*(npt-1.)*npt;

    if (totnum<maxiter) {
	% go through all triple combinations, determine
	% the circle position, and average all positions
	_for i (0,npt-3,1) {
	    _for j (i+1,npt-2,1) {
		_for k (j+1,npt-1,1) {
		    del=2*((x[k]-x[j])*(y[j]-y[i])-(x[j]-x[i])*(y[k]-y[j]));
		    if (del>=eps) {
			xc= ((y[k]-y[j])*xy2[i]+(y[i]-y[k])*xy2[j]+(y[j]-y[i])*xy2[k])/del;
			yc=-((x[k]-x[j])*xy2[i]+(x[i]-x[k])*xy2[j]+(x[j]-x[i])*xy2[k])/del;
			sx+=xc;
			sy+=yc;
			nn++;
		    }
		}
	    }
	}
    } else {
	% too many points: go through a random subset of points
	% (note: tupels where two coordinates are the same will
	% automatically be rejected)
	variable ii;
	_for ii(0,maxiter-1,1) {
	    i=int(npt*urand());
	    j=int(npt*urand());
	    k=int(npt*urand());
	    del=2*((x[k]-x[j])*(y[j]-y[i])-(x[j]-x[i])*(y[k]-y[j]));
	    if (del>=eps) {
		xc= ((y[k]-y[j])*xy2[i]+(y[i]-y[k])*xy2[j]+(y[j]-y[i])*xy2[k])/del;
		yc=-((x[k]-x[j])*xy2[i]+(x[i]-x[k])*xy2[j]+(x[j]-x[i])*xy2[k])/del;
		sx+=xc;
		sy+=yc;
		nn++;
	    }
	}
    }
    % no radius found: points lie on a line
    if (nn==0) {
	return NULL;
    }
    % center coordinates
    xc=sx/nn;
    yc=sy/nn;
    variable ra=mean(sqrt((x-xc)^2.+(y-yc)^2.));

    return struct {xc=xc,yc=yc,radius=ra};
}
