define removeLeadingZeros(s)
{
  variable res = string_matches(s, `0*\([^0].*\)`, 1);
  return res==NULL ? s : res[1];
}
