define solve_2d_system_of_equations(ax1, ay1, c1, ax2, ay2, c2)
%!%+
%\function{solve_2d_system_of_equations}
%\usage{(x, y) = solve_2d_system_of_equations(ax1, ay1, c1, ax2, ay2, c2)}
%\description
%    \code{ax1 * x  +  ay1 * y  =  c1}\n
%    \code{ax2 * x  +  ay2 * y  =  c2}\n
%!%-
{
  variable D  = ax1 * ay2 - ax2 * ay1;
  variable Dx =  c1 * ay2 -  c2 * ay1;
  variable Dy = ax1 *  c2 - ax2 *  c1;
  if(D!=0)
    return Dx/D,  Dy/D;
  else
    if(Dx!=NULL)
      return NULL, NULL;  % 0 solutions
    else
      return NULL, NULL;  % infinitely many solutions
}
