define get1match()
%!%+
%\function{get1match}
%\synopsis{returns one (the first) matching substring of a regular expression matching}
%\usage{String_Type match_str = get1match(String_Type str, String_Type regexp);}
%\description
%   get1match is deprecated. Use S-Lang's string_matches instead.
%\seealso{string_matches}
%!%-
{
  message("get1match is deprecated. Use S-Lang's string_matches instead.");

  variable str, regexp;
  switch(_NARGS)
  { case 2: (str, regexp) = (); }
  { help(_function_name()); return; }

  if(string_match(str, regexp, 1)) {
      variable pos, len;
      (pos, len) = string_match_nth(1);
      return substr(str, pos+1, len);
  }

  return NULL;
}
