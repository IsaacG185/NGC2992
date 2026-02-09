require("./share/isisscripts.sl");

define test_dms2deg(d, m, s, expected_deg)
{
    variable deg = dms2deg(d, m, s);
    variable passed = (abs(deg-expected_deg)<1e-6);

    variable ndx=where(not passed);
    if (length(ndx)!=0) {
        if (length(passed)==1) {
            vmessage("dms2deg with scalar:");
            vmessage("   dms2deg(%S, %S, %S) gave %S, but should give %S", d, m, s, deg, expected_deg);
        } else {
            vmessage("dms2deg with arrays (not all might be wrong):");
            variable j;
            _for j(0,length(d)-1,1) {
                vmessage("   dms2deg(%S, %S, %S) gave %S, but should give %S", d[j], m[j], s[j], deg[j], expected_deg[j]);
            }
        }
    }
    return length(ndx)==0;
}

variable passed = all([
  test_dms2deg( 1,  2,  3,   (1 + 2/60. + 3/3600.)),
  test_dms2deg(-1,  2,  3,  -(1 + 2/60. + 3/3600.)),
  test_dms2deg( 0,  2,  3,   (    2/60. + 3/3600.)),
  test_dms2deg( 0, -2,  3,  -(    2/60. + 3/3600.)),
  test_dms2deg( 0,  0,  3,   (            3/3600.)),
  test_dms2deg( 0,  0, -3,  -(            3/3600.)),
  test_dms2deg( [1,-1], [2,2], [3,3],  [(1 + 2/60. + 3/3600.),-1.*(1 + 2/60. + 3/3600.)]),
  test_dms2deg( [1, 0], [2,-1], [3,3], [(1 + 2/60. + 3/3600.),-1.*(   1/60. + 3/3600.)]),
  test_dms2deg( [1, 0], [2, 0], [3,-3], [(1 + 2/60. + 3/3600.),-1.*(    3/3600.)]),
  test_dms2deg( [-1, 0],[2, 0], [3,-3], [-1.*(1 + 2/60. + 3/3600.),-1.*(    3/3600.)]),
]);
exit(passed ? 0 : 1);
