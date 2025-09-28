define generate_iauname() {
%!%+
%\function{generate_iauname}
%\synopsis{for a given position, generate a coordinate string obeying the IAU convention}
%\usage{string=generate_iauname(ra,dec)}
%\qualifiers{
% \qualifier{prefix}{prefix for the string (e.g., "XMMU_")}
% \qualifier{radian}{if set, the angles are in radians, not degrees}
%}
%\description
% This is a convenience routine to produce strings of the type
% XMMU Jhhmmss.s+ddmmss
% from J2000.0 positions. The routine obeys the IAU convention of
% truncating (not rounding!) the coordinate to the digits shown.
%
% The default-string is "Jhhmmss.s+ddmmss", use the prefix qualifier
% to prepend the mission name.
%
% Use angle2string to format coordinates with appropriate rounding.
%
%\seealso{dms2deg, hms2deg, angle2string, deg2dms}
%!%-
    variable ra,dec;
    
    switch(_NARGS) 
	{case 2:  (ra,dec)=(); }
	{return help(_function_name());
    }

    variable hh,mm,ss;
    variable dd,dm,ds;


    if (qualifier_exists("radian")) {
	ra*=180./PI;
	dec*=180./PI;
    }

    variable prefix=qualifier("prefix","");
	
    variable sgn= (dec<0.) ? "-" : "+";
	
    (hh,mm,ss)=deg2dms(ra;hours);
    (dd,dm,ds)=deg2dms(abs(dec));

    % chop off digits per IAU convention
    ss=int(ss*10.)/10.;
	
    return sprintf("%sJ%02i%02i%04.1f%1s%02i%02i%02i",
          prefix,int(hh),int(mm),ss,sgn,int(dd),int(dm),int(ds));
}
