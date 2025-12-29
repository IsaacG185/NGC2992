% -*- mode: slang; mode: fold -*-

require("./share/isisscripts");

define test_jd_check(y,m,d,jd_expected) {
    variable jd=JDofDate(y,m,d);
    variable mjd=JDofDate(y,m,d;mjd);
    variable mjdexpect=jd2mjd(jd_expected);
    variable passed1= (jd==jd_expected && mjd==mjdexpect);
    ifnot(passed1) {
       vmessage("JDofDate(%S, %S, %S) gave %S, but should give %S or we got MJD %S rather than %S ", y,m,d,jd,jd_expected,mjd,mjdexpect);
    }
    
    variable dd=DateOfJD(jd);

    variable ddtmp=dd.day+(dd.hour+(dd.minute+dd.second/60.)/60.)/24.;
    variable passed2=(dd.year==y && dd.month==m && abs(ddtmp-d)<1e-8);
    ifnot(passed2) {
	vmessage("DateOfJD(%S) gave %S.%S.%S but should yield %S.%S.%S ",jd,dd.year,dd.month,ddtmp,y,m,d);
    }
    
    return (passed1 && passed2);
}

define test_julian_check(y,m,d,jd_expected) {
    variable jd=JDofDate(y,m,d;julian_calendar);
    variable passed1= (jd==jd_expected);
    ifnot(passed1)
       vmessage("JDofDate(%S, %S, %S) gave %S, but should give %S", y,m,d,jd,jd_expected);

    % checks julian switch
    variable dd=DateOfJD(jd);

    variable ddtmp=dd.day+(dd.hour+(dd.minute+dd.second/60.)/60.)/24.;
    variable passed2=(dd.year==y && dd.month==m && abs(ddtmp-d)<1e-8 );
    ifnot(passed2) {
	vmessage("DateOfJD(%S) gave %S.%S.%S but should yield %S.%S.%S ",jd,dd.year,dd.month,ddtmp,y,m,d);
    }
  return (passed1 && passed2);
}

% dates from Meeus, Astronomical Algorithms, p62
variable passed1 = all([
test_jd_check(2000, 1, 1.5, 2451545.0),
test_jd_check(1999, 1, 1.0, 2451179.5),
test_jd_check(1987, 1,27.0, 2446822.5),
test_jd_check(1987, 6,19.5, 2446966.0),
test_jd_check(1988, 1,27.0, 2447187.5),
test_jd_check(1900, 1, 1.0, 2415020.5),
test_jd_check(1600, 1, 1.0, 2305447.5),
test_jd_check(1600,12,31.0, 2305812.5)]);

variable passed2=all([
test_julian_check(  837, 4,10.3, 2026871.8),
test_julian_check( -123,12,31.0, 1676496.5),
test_julian_check( -122, 1, 1.0, 1676497.5),
test_julian_check(-1000, 7,12.5, 1356001.0),
test_julian_check(-1000, 2,29.0, 1355866.5),
test_julian_check(-1001, 8,17.9, 1355671.4),
test_julian_check(-4712, 1, 1.5,       0.0)]);

variable passed=( passed1 && passed2);

exit(passed ? 0 : 1);
