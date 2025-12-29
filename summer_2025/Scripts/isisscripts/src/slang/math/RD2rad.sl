define RD2rad()
%!%+
%\function{RD2rad}
%\synopsis{Convert right ascension (h, m, s) and declination (deg, arcmin, arcsec) to radians}
%\usage{RD2rad(Double_Types ah[], am[], as[], dd[], dm[], ds[])}
%\description
%    Given right ascension in hours, minutes, seconds and declination in degrees,
%    minutes of arc, seconds of arc, the function converts them to radians. Always
%    provide six numbers, i.e., fill up with zeros where necessary. Right ascension
%    is assumed to be positive. If the degrees argument of declination is negative
%    the minus sign is automatically applied to the minutes and seconds parameters.
%    If the degrees argument of declination is zero, the sign of the minutes argument
%    (if nonzero) is applied to the seconds parameter.
%\example
%    (raInRad, declInRad) = RD2rad(01, 45, 12.54, 87, 55, 45.34);
%    (raInRad, declInRad) = RD2rad(01, 45.209, 0, -87, 55, 45.34);
%    (raInRad, declInRad) = RD2rad(01.753472, 0, 0, 0, -55, 45.34);
%    (raInRad, declInRad) = RD2rad(01, 45, 12.54, 0, 0, 45.34);
%    (raInRad, declInRad) = RD2rad([01, 01], [45,45.209], [12.54,0], [87,-87], [55,55], [45.34,45]);
%    (raInRad, declInRad) = RD2rad(rad2RD(0,-PI/4.));
%\seealso{hms2deg,dms2deg,rad2RD}
%!%-
{
  if(_NARGS != 6)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable  ah, am, as, dd, dm, ds;
    (ah, am, as, dd, dm, ds) = ();
    ah = [1.*ah]; am = [1.*am]; as = [1.*as]; dd = [1.*dd]; dm = [1.*dm]; ds = [1.*ds];
    % convert right ascention to radians:
    variable raInRad = PI*(ah/12. + am/720. + as/43200.); % right ascension in radians = ah*(2.*PI/24.) + am*(2.*PI/(24.*60.)) + as*(2.*PI/(24.*3600.));
    % convert declination to radians with the proper sign conversions:
    variable ind;
    ind = where(dd != 0);
    dm[ind] *= sign(dd[ind]);
    ds[ind] *= sign(dd[ind]);
    ind = where(dd == 0 and dm != 0);
    ds[ind] *= sign(dm[ind]);
    variable declInRad = PI*(dd/180. + dm/10800. + ds/648000.); % declination in radians = dd * (2.*PI/360.) + dm * (2.*PI/(360.*60.)) + ds * (2.*PI/(360.*60.^2.));
    if(length(raInRad)==1) {return (raInRad[0], declInRad[0]);}
    else return (raInRad, declInRad);
  }
}

define rad2RD()
%!%+
%\function{rad2RD}
%\synopsis{Convert right ascension and declination from radians to (h, m, s) and (deg, arcmin, arcsec)}
%\usage{rad2RD(Double_Types RA[], D[])}
%\description
%    Given right ascension and declination in radians, the function converts them to
%    hours, minutes, seconds and degrees, minutes of arc, seconds of arc. In case of
%    negative declinations, the minus sign is assigned only to the highest non-vanishing
%    term, i.e., to degrees if degrees is nonzero, to minutes if minutes is nonzero but
%    degrees is zero, ... . Negative right ascensions are not expected.
%\example
%    (ah, am, as, dd, dm, ds) = rad2RD(0,-PI/4.);
%    (ah, am, as, dd, dm, ds) = rad2RD(0,-PI/181.);
%    (ah, am, as, dd, dm, ds) = rad2RD(3/4.*PI,0);
%    (ah, am, as, dd, dm, ds) = rad2RD([0,3/4.*PI],[-PI/4,0]);
%    (ah, am, as, dd, dm, ds) = rad2RD(RD2rad(01, 45, 12.54, 87, 55, 45.34));
%\seealso{RD2rad}
%!%-
{
  if(_NARGS != 2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable raInRad, declInRad;
    (raInRad, declInRad) = ();
    raInRad = [1.*raInRad]; declInRad = [1.*declInRad];
    % convert right ascention to (h, m, s):
    variable ah, am, as;
    raInRad *= (12./PI);
    ah = floor(raInRad);
    raInRad = (raInRad-ah)*60.;
    am = floor(raInRad);
    as = (raInRad-am)*60.;
    % convert declination to (deg, arcmin, arcsec) with the proper sign conversions:
    variable s = sign(declInRad);
    declInRad *= s; % all declinations positive; s contains information which ones were negative
    variable dd, dm, ds;
    declInRad *= (180./PI);
    dd = floor(declInRad);
    declInRad = (declInRad-dd)*60.;
    dm = floor(declInRad);
    ds = (declInRad-dm)*60.;
    % recover sign of declination:
    dd *= s;
    variable ind = where( dd==0 );
    dm[ind] *= s[ind];
    ind = where( dd==0 and dm==0 );
    ds[ind] *= s[ind];
    % return output:
    if(length(raInRad)==1) {return (ah[0], am[0], as[0], dd[0], dm[0], ds[0]);}
    else return (ah, am, as, dd, dm, ds);
  }
}
