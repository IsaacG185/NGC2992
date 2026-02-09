%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_unpiled_fit_fun()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_unpiled_fit_fun}
%\synopsis{return the currently defined fit function without simple_gpile*}
%\usage{String_Type get_unpiled_fit_fun()}
%\description
%    \code{simple_gpile*(Isis_Active_Dataset, } is replaced by \code{(}.
%\seealso{get_fit_fun}
%!%-
{
  variable fitFun = get_fit_fun();
  variable m = string_matches(fitFun, `^\(.*\)simple_gpile\d* *( *Isis_Active_Dataset, *\(.*\)$`);
  if(m!=NULL)  fitFun = m[1] + "(" + m[2];
  return fitFun;
}
