define angular_separation()
%!%+
%\function{angular_separation}
%\usage{ sep=angular_separation(ra1,dec1,ra2,dec2);}
%\synopsis{calculates the angular distance between two points on a sphere}
%\qualifiers{
%\qualifier{deg}{if set, the input coordinates and output are in degrees (default: radian)}
%\qualifier{radian}{if set, the input coordinates and output are in radian (the default))}
%}
%\description
% This routine calculates the angular separation between points on the sky
% with coordinates ra1/dec1 and ra2/dec2.
%
% The function is equivalent to greatcircle_distance but is compatible in terms
% of its qualifiers with the other coordinate system routines. It also returns
% the angular separation in the units of the input parameters rather than
% always in rad and, by using the haversine formula, is less prone to round
% off errors for small angular separations.
%
% This function is array safe (for either ra1/dec1 or ra2/dec2).
%
%\seealso{hms2deg,dms2deg,angle2string,position_angle}
%!%-
{
    variable ra1in,dec1in,ra2in,dec2in;
    variable ra1,dec1,ra2,dec2;
    switch(_NARGS)
    { case 4: (ra1in,dec1in,ra2in,dec2in)=(); }
    { help(_function_name()); return; }

    if (qualifier_exists("deg")) {
	ra1=ra1in*PI/180.;
	dec1=dec1in*PI/180.;
	ra2=ra2in*PI/180.;
	dec2=dec2in*PI/180.;
    } else {
	ra1=@ra1in;
	dec1=@dec1in;
	ra2=@ra2in;
	dec2=@dec2in;
    }

    % haversine equation (per RW Sinnott, 1984, Sky and Telescope)
    variable a=sin((dec2-dec1)/2.)^2.+cos(dec1)*cos(dec2)*sin((ra2-ra1)/2.)^2.;
    variable dist=2*atan2(sqrt(a),sqrt(1.-a));
    
    if (qualifier_exists("deg")) {
	return dist*180./PI;
    }
    return dist;
}
