define multiple_string(n, s)
{
  variable res = "";
  for(; n>0; n--) { res += s; }
  return res;
}
