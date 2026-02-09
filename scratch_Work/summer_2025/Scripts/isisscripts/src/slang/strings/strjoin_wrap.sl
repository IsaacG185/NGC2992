define strjoin_wrap()
%!%+
%\function{strjoin_wrap}
%\synopsis{concatenates elements of an array and inserts linebreaks}
%\usage{Sting_Type strjoin_wrap(Array_Type x, String_Type delim);}
%\qualifiers{
%\qualifier{maxlen}{[=72]: maximum number of characters in a line}
%\qualifier{newline}{[="  "]: new line string}
%\qualifier{initial}{[=""]: initial delimiter}
%\qualifier{final}{[=""]: final delimiter}
%}
%\seealso{strjoin}
%!%-
{
  variable x, delim=", ";
  switch(_NARGS)
  { case 1: x = (); }
  { case 2: (x, delim) = (); }
  { help(_function_name()); return; }

  variable newline = qualifier("newline", "  ");
  variable maxlen = qualifier("maxlen", 72) - strlen(delim);
  variable result = "";
  variable i, buf = qualifier("initial", "");
  _for i (0, length(x)-2, 1)
  { variable xstr = string(x[i]);
    if(strlen(buf+xstr)>maxlen)
    { result += buf+"\n";
      buf = newline;
    }
    buf += xstr+delim;
  }
  if(strlen(buf+string(x[-1]))>maxlen)
  { result += buf+"\n";
    buf = newline;
  }
  return result + buf + string(x[-1]) + qualifier("final", "");
}
