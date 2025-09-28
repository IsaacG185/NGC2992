define pos_modulo()
%!%+
%\function{pos_modulo}
%\synopsis{computes the modulo and ensures that it is positive}
%\usage{m = pos_modulo(a, b);}
%\description
%    \code{a} and \code{b} can either be arrays or scalars of a numerical type.
%
%    \code{m =  a mod b;  %} if m is positive, otherwise:\n
%    \code{m = (a mod b) + b;}
%!%-
{
  variable a, b;
  switch(_NARGS)
  { case 2: (a, b) = (); }
  { help(_function_name()); return; }

  variable m = a mod b;
  if(typeof(m)==Array_Type)
    m[where(m<0)] += b;
  else
    if(m<0)  m += b;
  return m;
}
