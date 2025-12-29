define rescale_range()
%!%+
%\function{rescale_range}
%\synopsis{rescales a value}
%\usage{Double_Type y = rescale_range(Double_Type x);}
%\qualifiers{
%\qualifier{in}{inputrange}
%\qualifier{out}{outputrange}
%}
%\description
%    possibilities for in/out and the corresponding scaling function:\n
%    \code{"0:1"}, no scaling\n
%    \code{"-inf:inf"}, arctan
%!%-
{
  variable x;
  switch(_NARGS)
  { case 1: x = (); }
  { help(_function_name()); return; }

  variable in  = qualifier("in", "-inf:inf");
  variable out = qualifier("out", "0:1");

  variable x01;
  switch(in)
  { case "0:1": x01 = x; }
  { case "-inf:inf": x01 = 0.5 + atan(x)/PI; }
  { vmessage(`error (%s): input range "%s" unknown`, _function_name(), in); return; }

  switch(out)
  { case "0:1": return x01; }
  { case "-inf:inf": return tan(PI*(x01-0.5)); }
  { vmessage(`error (%s): output range "%s" unknown`, _function_name(), out); return; }
}
