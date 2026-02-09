define strreplace1()
%!%+
%\function{strreplace1}
%\synopsis{replaces one occurence of a substring in a string by another string}
%\usage{String_Type res = strreplace1(String_Type str, search_str, repl_str);}
%\description
%    replaces the first occurence of \code{search_str} in \code{str} by \code{repl_str}:\n
%    \code{(res, ) = strreplace(str, search_str, repl_str, 1);}
%!%-
{
  variable str, search_str, repl_str;
  switch(_NARGS)
  { case 3: (str, search_str, repl_str) = (); }
  { help(_function_name()); return; }

  variable res;
  (res, ) = strreplace(str, search_str, repl_str, 1);
  return res;
}
