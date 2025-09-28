define string_intersection()
%!%+
%\function{string_intersection}
%\synopsis{Returns the common substrings within all strings of the given array}
%\usage{String_Type string_intersection(String_Type[] strings);}
%\qualifiers{
%    \qualifier{minlen}{restrict the returned substrings to a minimum length}
%    \qualifier{longest}{return the longest substring only}
%}
%\example
%    a = string_intersection(["mister", "twister"]; minlen = 3);
%    % -> ["ister", "ster", "ter", "ste", "iste", "ist"]
%!%-
{
  variable str;
  switch (_NARGS)
    { case 1: str = (); }
    { help(_function_name); return; }

  variable minlen = qualifier("minlen", 1);

  % find the shortest string in the given array
  variable lens = array_map(Integer_Type, &strlen, str);
  variable s = wherefirstmin(lens);
  % build up substring matrix of the shortest string
  variable n = lens[s]-minlen+1;
  variable match = String_Type[n*(n-1)/2+n];
  variable i, j, k = 0;
  _for i (0, n-1, 1) _for j (0, n-i-1, 1) {
    match[k] = substr(str[s], i+1, minlen+j);
    k++;
  }

  % loop over remaining strings
  str = array_remove(str, s);
  i = 0;
  while (i < length(str) && any(match != "")) {
    % remove non-substrings from the matrix (no an array)
    match = match[where(
      array_map(Integer_Type, &is_substr, str[i], match) > 0
    )];
    i++;
  }
  
  % reduce
  match = match[where(match != "")];
  match = match[unique(match)];
  if (qualifier_exists("longest")) {
    match = match[where_max(array_map(Integer_Type, &strlen, match))];
  }

  return match;
}
