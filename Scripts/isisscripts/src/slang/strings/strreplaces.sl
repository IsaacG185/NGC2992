define strreplaces() {
%!%+
%\function{strreplaces}
%\synopsis{Replace one or more substrings}
%\usage{String_Type strreplaces(String_Type a, String_Type[] b, String_Type[] c[, Integer_Type max_n]);}
%\description
%    This is a modificaiton to 'strreplace', where
%    multiple, different substrings (given as arrays)
%    are replaced at the same time.
%\seealso{strreplace}
%!%-
  variable a, b, c, n = NULL;
  switch (_NARGS)
    { case 3: (a,b,c) = (); }
    { case 4: (a,b,c,n) = (); }
    { help(_function_name); return; }
  
  if (typeof(b) != Array_Type) b = [b];
  if (typeof(c) != Array_Type) c = [c];
  if (length(b) != length(c)) { vmessage("error (%s): given arrays must be of equal length", _function_name); return; }
  variable i;
  _for i (0, length(b)-1, 1)
    if (n == NULL) a = strreplace(a, b[i], c[i]);
    else (a,) = strreplace(a, b[i], c[i], n);
  return a;
}
