define angle2string()
%!%+
%\function{angle2string}
%\synopsis{convert an angle to a string for pretty printing}
%\usage{string=angle2string(angle;qualifiers)}
%\qualifiers{
%   \qualifier{hoursign}{angle is a hour angle, always include sign}
%   \qualifier{declination}{angle is a declination, always include sign}
%   \qualifier{latitude}{angle is a latitude, always include sign}
%   \qualifier{hours}{display hours, not degrees}
%   \qualifier{deg}{input angle is in degrees (default: radians)}
%   \qualifier{separator}{string to insert between the degrees/hours,
%        minutes, and after the seconds. If a scalar: insert between
%        degrees and minutes only [e.g., ":"]. If an array: insert
%        the three array elements between the output numbers (e.g.,
%        ["h","m","s"]). Default is ["d","m","s"] and ["h","m","s"]
%        depending on whether the hours-qualifier is set or not.}
%   \qualifier{blank}{do not display leading zeros}
%   \qualifier{secfmt}{sprintf format for the seconds (default:
%           %04.1f, i.e., a precision of 0.1 sec)}
%   \qualifier{mas}{display to a precision of milliseconds
%        corresponds to secfmt="%06.3f"}
%   \qualifier{muas}{display to a precision of microseconds
%        corresponds to secfmt="%08.5f"}
%}
%\description
%  This function is used to produce well formatted strings out of
%  angular quantities which are given in radians or degrees.
%  (the default is radian).
%
%  Angles can be displayed either in degrees or in hours, 
%  various separators can be used to separate the hms-terms,
%  and the routine can be told to always display a sign (e.g.,
%  for declination- or latitude-like quantities), or not.
%
%  This routine is array safe.
%
%\seealso{hms2deg,dms2deg,generate_iauname}
%!%-
{
    variable angle=();

    if (Array_Type==typeof(angle)) {
	variable retarr=String_Type[length(angle)];
	variable i;
	_for i(0,length(angle)-1,1) {
	    retarr[i]=angle2string(angle[i];;__qualifiers());
	}
	return retarr;
    }


    
    variable sg=" ";
    if (qualifier_exists("hoursign") or
        qualifier_exists("declination") or
        qualifier_exists("latitude")) {
	sg="+";
    }

    if (angle<0.) {
	sg="-";
	angle=abs(angle);
    }

    if (not qualifier_exists("deg")) {
	angle=angle*180./PI;
    }

    variable sep;
    if (qualifier_exists("separator")) {
	sep=qualifier("separator");
	if (length(sep)==1) {
	    sep=[sep,sep,""];
	}
    } else {
	sep=["d","m","s"];
	if (qualifier_exists("hours")) {
	    sep[0]="h";
	}
    }
    
    variable d,m,s;
    if (qualifier_exists("hours")) {
	(d,m,s)=deg2dms(angle;hours);
    } else {
	(d,m,s)=deg2dms(angle);
    }

    variable fmt;
    variable zero="0";
    if (qualifier_exists("blank")) {
	zero=" ";
    }

    variable secfmt;
    if (qualifier_exists("mas")) {
	secfmt="%06.3f";
    } else {
	if (qualifier_exists("muas")) {
	    secfmt="%08.5f";
	} else {
	    secfmt=qualifier("secfmt","%04.1f");
	}
    }
    
    if (qualifier_exists("hours") or qualifier_exists("latitude") or qualifier_exists("declination")) {
	% fmt for degree/hour has only two digits
	fmt="%"+zero+"2u"+sep[0]+"%"+zero+"2u"+sep[1]+secfmt+sep[2];
    } else {
	% fmt for degree/hour has only two digits
	fmt="%"+zero+"3u"+sep[0]+"%"+zero+"2u"+sep[1]+secfmt+sep[2];
    }

    variable ret=sg+sprintf(fmt,d,m,s);
    return ret;
}
