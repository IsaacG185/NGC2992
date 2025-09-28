%%%%%%%%%%%%%%%%%%%
define binarydigits(x)
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{binarydigits}
%\synopsis{retrieves a number's dual representaion}
%\usage{String_Type binarydigits(Integer_Type x)}
%\qualifiers{
%\qualifier{n}{[\code{=16}] number of bits}
%}
%!%-
{
  vmessage("warning: %s is deprecated, use  sprintf(\"%.<n>B\", ...)  instead", _function_name());

  variable s="";
  loop( qualifier("n", 16) )
  { s = string( x & 1 ) + s;
    x = x >> 1;
  }
  return s;
}
