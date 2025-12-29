%%%%%%%%%%%%%%%%%%%%%%%%
define plot_with_y2axis()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_with_y2axis}
%\synopsis{plot two functions with different y-axes}
%\usage{plot_with_y2axis(x1, y1, [ x2,] y2);}
%\qualifiers{
%\qualifier{color}{set the color of the 2nd y-axis [default: red]}
%\qualifier{yspace}{space above and below the last data point in units of the total y-range.}
%}
%\description
%    This function plots two different parameters y1 and y2, which depend
%    on the same paramter x. By default, the same x is taken for
%    both parameters.\n
%    \n
%    The y2-axis and the ranges are set automatically.\n
%    \n
%    Additionally the function returns the rescaled y2 values, which
%    now lie in the range of the y1 values.
%!%-
{
  variable X,Y,Xold,Yold;
  switch(_NARGS)
  { case 3:
      (X,Yold,Y) = ();
      Xold = X;
  }
  { case 4:
      (Xold,Yold,X,Y) = ();
  }
  { % else:
      help(_function_name()); return;
  }

  variable col = qualifier("color", 2);
  variable yspace = qualifier("yspace", 0);

  variable ymnOld = min(Yold);
  variable ymxOld = max(Yold);

  variable ymn = min(Y);
  variable ymx = max(Y);

  variable scale = 1.*(ymxOld - ymnOld)/ (ymx - ymn);
  variable Ynew = (Y - ymn)*scale + ymnOld;

  variable offset = (ymxOld-ymnOld)*yspace;

  xrange(min_max([X,Xold]));
  yrange (ymnOld-offset, ymxOld+offset);

  variable plo = change_plot_options(; yopt="BNST");
  plot(Xold, Yold);
  color(col);
  oplot(X, Ynew);
  y2axis(ymn,ymx;color=col);

  set_plot_options(plo);

  return Ynew;
}
