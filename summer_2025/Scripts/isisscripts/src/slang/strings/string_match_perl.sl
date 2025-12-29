%%%%%%%%%%%%%%%%%%%%%%%%
define string_match_perl()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{string_match_perl}
%\synopsis{matches a string against a RE and stores the results in $1, $2, ...}
%\usage{Integer_Type string_match(String_Type str, pat[, Integer_Type pos])}
%\description
%    The string \code{str} is matched against the regular expression \code{pat},
%    starting at the position \code{pos} (numbered from 1, which is the default).
%    The function returns the position of the start of the match in \code{str}.
%    The entire matching string is stored in the global variable $0,
%    the substrings of patterns enclosed by "\\\\( ... \\\\)" pairs
%    are stored in $1, $2, ..., $9  (as in Perl).
%
%    \code{string_match_perl} is deprecated. Use S-Lang's string_matches instead.
%\example
%    \code{if( string_match_perl("hello world", "\\\\([a-z]+\\\\) \\\\([a-z]+\\\\)"R) )}\n
%    \code{  ()=printf("1=%s, 2=%s\n", $1, $2);}
%
%    \code{%} Equivalent way using \code{string_matches}:\n
%    \code{variable m = string_matches("hello world", `\\([a-z]+\\) \\([a-z]+\\)`, 1);}\n
%    \code{if(m!=NULL)  vmessage("1=%s, 2=%s", m[1], m[2]);}
%\seealso{string_matches}
%!%-
{
  message("string_match_perl is deprecated. Use S-Lang's string_matches instead.");

  variable str, pat, pos=1, len;
  switch(_NARGS)
  { case 2: (str, pat) = (); }
  { case 3: (str, pat, pos) = (); }
  { return help(_function_name()); }

  variable str_m = string_match(str, pat, pos);
  if(str_m)
  {
    (pos, len) = string_match_nth(0);
    $0  = substr(str, pos+1, len);

    variable ok=1;
    try { (pos, len) = string_match_nth(1); } catch AnyError: { ok = 0; }
    $1 = substr(str, pos+1, len);

    ok=1;
    try { (pos, len) = string_match_nth(2); } catch AnyError: { ok = 0; }
    if(ok)  $2 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(3); } catch AnyError: { ok = 0; }
    if(ok)  $3 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(4); } catch AnyError: { ok = 0; }
    if(ok)  $4 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(5); } catch AnyError: { ok = 0; }
    if(ok)  $5 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(6); } catch AnyError: { ok = 0; }
    if(ok)  $6 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(7); } catch AnyError: { ok = 0; }
    if(ok)  $7 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(8); } catch AnyError: { ok = 0; }
    if(ok)  $8 = substr(str, pos+1, len);  else  return str_m;

    try { (pos, len) = string_match_nth(9); } catch AnyError: { ok = 0; }
    if(ok)  $9 = substr(str, pos+1, len);  else  return str_m;
  }

  return str_m;
}
