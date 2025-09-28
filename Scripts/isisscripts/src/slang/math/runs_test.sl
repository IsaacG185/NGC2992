#ifexists normal_cdf

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define __runs_p (n1, n2, r)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implement runs probability after
% "Statistics for management and economics"
% Mendenhall, Reinmush & Beaver 1989
% Use table in Appendix for small values
% of n1,n2 and use Gaussian approximation
% for larger.
{
  % for 2 <= n1, n2 <= 10
  variable small_p = Array_Type[45];
  % n1 = 2, n2 = 2 .. 10
  small_p[0] = [.333, .666, 1.];
  small_p[1] = [.200, .500, .900, 1.];
  small_p[2] = [.133, .400, .800, 1.];
  small_p[3] = [.095, .333, .714, 1.];
  small_p[4] = [.071, .286, .643, 1.];
  small_p[5] = [.056, .250, .583, 1.];
  small_p[6] = [.044, .222, .533, 1.];
  small_p[7] = [.036, .200, .491, 1.];
  small_p[8] = [.030, .182, .455, 1.];

  % n1 = 3, n2 = 3 .. 10
  small_p[9] = [.100, .300, .700, .900, 1.];
  small_p[10] = [.057, .200, .543, .800, .971, 1.];
  small_p[11] = [.036, .143, .429, .714, .929, 1.];
  small_p[12] = [.024, .107, .345, .643, .881, 1.];
  small_p[13] = [.017, .083, .283, .583, .833, 1.];
  small_p[14] = [.012, .067, .236, .533, .788, 1.];
  small_p[15] = [.009, .055, .200, .491, .745, 1.];
  small_p[16] = [.007, .045, .171, .455, .706, 1.];

  % n1 = 4, n2 = 4 .. 10
  small_p[17] = [.029, .114, .371, .629, .886, .971, 1.];
  small_p[18] = [.016, .071, .262, .500, .786, .929, .992, 1.];
  small_p[19] = [.010, .048, .190, .405, .690, .881, .976, 1.];
  small_p[20] = [.006, .033, .142, .333, .606, .833, .954, 1.];
  small_p[21] = [.004, .024, .109, .279, .533, .788, .929, 1.];
  small_p[22] = [.003, .018, .085, .236, .471, .745, .902, 1.];
  small_p[23] = [.002, .014, .068, .203, .419, .706, .874, 1.];

  % n1 = 5, n2 = 5 .. 10
  small_p[24] = [.008, .040, .167, .357, .643, .833, .960, .992, 1.];
  small_p[25] = [.004, .024, .110, .262, .522, .738, .911, .976, .998, 1.];
  small_p[26] = [.003, .015, .076, .197, .424, .652, .854, .955, .992, 1.];
  small_p[27] = [.002, .010, .054, .152, .347, .576, .793, .929, .984, 1.];
  small_p[28] = [.001, .007, .039, .119, .287, .510, .734, .902, .972, 1.];
  small_p[29] = [.001, .005, .029, .095, .239, .455, .678, .874, .958, 1.];

  % n1 = 6, n2 = 6 .. 10
  small_p[30] = [.002, .013, .067, .175, .392, .608, .825, .933, .987, .998, 1.];
  small_p[31] = [.001, .008, .043, .121, .296, .500, .733, .879, .966, .992, .999, 1.];
  small_p[32] = [.001, .005, .028, .086, .226, .413, .646, .821, .937, .984, .998, 1.];
  small_p[33] = [.000, .003, .019, .063, .175, .343, .566, .762, .902, .972, .994, 1.];
  small_p[34] = [.000, .002, .013, .047, .137, .288, .497, .706, .864, .958, .990, 1.];

  % n1 = 7, n2 = 7 .. 10
  small_p[35] = [.001, .004, .025, .078, .209, .383, .617, .791, .922, .975, .996, .999, 1.];
  small_p[36] = [.000, .002, .015, .051, .149, .296, .514, .704, .867, .949, .988, .998, 1.00, 1.];
  small_p[37] = [.000, .001, .010, .035, .108, .231, .427, .622, .806, .916, .975, .994, .999, 1.];
  small_p[38] = [.000, .001, .006, .024, .080, .182, .355, .549, .743, .879, .957, .990, .998, 1.];

  % n1 = 8, n2 = 8 .. 10
  small_p[39] = [.000, .001, .009, .032, .100, .214, .405, .595, .786, .900, .968, .991, .999, 1.00, 1.];
  small_p[40] = [.000, .001, .005, .020, .069, .157, .319, .500, .702, .843, .939, .980, .996, .999, 1.00, 1.];
  small_p[41] = [.000, .000, .003, .013, .048, .117, .251, .419, .621, .782, .903, .964, .990, .998, 1.00, 1.];

  % n1 = 9, n2 = 9 .. 10
  small_p[42] = [.000, .000, .003, .012, .044, .109, .238, .399, .601, .762, .891, .956, .988, .997, 1.00, 1.00, 1.];
  small_p[43] = [.000, .000, .002, .008, .029, .077, .179, .319, .510, .681, .834, .923, .974, .992, .999, 1.00, 1.00, 1.];

  % n1 = 10, n2 = 10
  small_p[44] = [.000, .000, .001, .004, .019, .051, .128, .242, .414, .586, .758, .872, .949, .981, .996, .999, 1.00, 1.00, 1.];

  variable p;
  if (n1 < 2 or n2 < 2)
    throw DomainError, "Only defined for n1,n2 >= 2";
  if (r < 2 or r > n1+n2)
    throw DomainError, "r must be in range 2 .. n1 + n2";

  % swap if needed
  if (n1 > n2)
    (n1,n2) = (n2,n1);

  if (n1 < 11 and n2 < 11)
    return small_p[(n1-2)*9+(n2-2)-((n1-2)*(n1-1))/2][r-2]; % access upper triangle matrix

  variable ex = 2.*n1*n2/(n1+n2) + 1;
  variable var2 = (ex-1)*(ex-2)/(n1+n2-1);

  variable z = (r-ex)/sqrt(var2);

  return round(1e3*normal_cdf(z))*1e-3; % table has only 3 significants
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%
define runs_test (sequence)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{runs_test}
%\synopsis{Perform runs test on sequence}
%\usage{Int_Type = runs_test(Num_Type[]);}
%\qualifiers{
%  \qualifier{confidence}{[=0.05]: Critical test probability}
%  \qualifier{overmixing}{Test for overmixing}
%  \qualifier{undermixing}{Test for undermixing}
%}
%\description
%    This function performs the runs test (Wald-Wolfowitz test)
%    on the given array. The sequence is assumend to represent
%    a dichotom set with n1 where sequence > 0 and n2 the
%    complementary.
%
%    The test returns true if the sequence is sufficiently
%    randomly divided into the two sets (determined by the
%    confidence qualifier).
%
%    Per default the sequence is tested against over- and
%    undermixing but can be adjusted to only test for one with
%    the appropriate qualifier.
%
%\seealso{normal_cdf}
%!%-
{
  variable confidence = qualifier("confidence", 0.05);
  variable mode = qualifier_exists("overmixing") ? 1
    : (qualifier_exists("undermixing") ? -1 : 0);

  variable n2;
  variable n1 = where(sequence>0, &n2);

  variable s = Int_Type[length(sequence)];
  s[n1] = 1;
  s[n2] = 0;
  variable r = length(where(s[[1:]]-s[[:-2]]))+1;
  variable p;
  n1 = length(n1);
  n2 = length(n2);

  if (n1 < 2 or n2 < 2 or r < 2 or r > n1 + n2)
    p = NULL;
  else
    p = __runs_p(n1, n2, r);

  if (NULL == p)
    return 0;

  switch (mode)
  { case 0: return confidence/2.<p && confidence/2.<(1-p); }
  { case -1: return confidence < p; }
  { case 1: return confidence < (1-p); }
}
#endif
