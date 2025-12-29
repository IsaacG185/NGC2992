% -*- mode: slang; mode: fold -*-

require("./share/isisscripts");

define test_easter(y,jd_expected) {
    variable jd=EasterSunday(y);
    variable passed=(jd==jd_expected);
    ifnot(passed) {
	vmessage("EasterSunday(%S) gave %12.2f but should give %12.2f",y,jd,jd_expected);
    }
    return passed;
}

define test_easter_eastern(y,jd_expected) {
    variable jd=EasterSunday(y;orthodox);
    variable passed=(jd==jd_expected);
    ifnot(passed) {
	vmessage("EasterSunday(%S;orthodox) gave %12.2f but should give %12.2f",y,jd,jd_expected);
    }
    return passed;
}

variable passed1=all([
test_easter(1991,JDofDate(1991,3,31)),
test_easter(1992,JDofDate(1992,4,19)),
test_easter(1993,JDofDate(1993,4,11)),
test_easter(1954,JDofDate(1954,4,18)),
test_easter(2000,JDofDate(2000,4,23)),
test_easter(1818,JDofDate(1818,3,22))]);

variable passed2=all([
test_easter_eastern(179,JDofDate(179,4,12;julian_calendar)),
test_easter_eastern(711,JDofDate(711,4,12;julian_calendar)),
test_easter_eastern(1243,JDofDate(1243,4,12;julian_calendar)),
test_easter_eastern(2020,JDofDate(2020,4,19))
]);

exit( (passed1 && passed2) ? 0 : 1);
