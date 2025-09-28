define get2matches(str, regexp)
{
  if(string_match(str, regexp, 1))
  {
    variable pos1, len1, pos2, len2;
    (pos1, len1) = string_match_nth(1);
    (pos2, len2) = string_match_nth(2);
    return (substr(str, pos1+1, len1), substr(str, pos2+1, len2));
  }

  return NULL;
}
