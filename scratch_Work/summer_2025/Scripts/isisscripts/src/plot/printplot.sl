define new_printplot()
%!%+
%\function{new_printplot}
%\synopsis{returns a new printplot-structure}
%\usage{Struct_Type new_printplot(Double_Type x0, x1, y0, y1);}
%\qualifiers{
%    \qualifier{W, H}{the width, i.e. the number of columns,
%                 and the height, i.e. the number of rows,
%                 of the plotting area without any axes or
%                 ticmarks (default: 60 and 10)}
%    \qualifier{[x,y]axis}{if set to zero do not draw the axis}
%    \qualifier{[x,y]tics}{if set to zero do not draw the ticmark}
%    \qualifier{[x,y]format}{sprintf format of the tics
%                 (default: "%f")}
%    \qualifier{[x,y]strlen}{maximum string length of the ticmarks
%                 (default: 4)}
%}
%\description
%    For printing a simple plot into the terminal a char
%    matrix is returned by this function, which can be
%    later printed by 'printplot_out'.
%    Per default, the matrix is 20x4 in size. Changing its
%    size can be done by the W- and H-qualifiers. The
%    arguments specify the x- and y-ranges of the plotting
%    area. The minimum and maximum values are the only
%    ticmarks which are added. Note that the char-matrix
%    is enlarged to fit the axes and ticmarks.
%\seealso{printplot_out, printplot, printhplot}
%!%-
{
  variable x0, y0, x1, y1;
  switch (_NARGS)
    { case 4: (x0,x1,y0,y1) = (); }
    { help(_function_name); return; }

  % qualifiers
  variable W = qualifier("W", 60);
  variable H = qualifier("H", 10);
  variable xaxis = qualifier("xaxis", 1);
  variable yaxis = qualifier("yaxis", 1);
  variable xtics = qualifier("xtics", 1);
  variable ytics = qualifier("ytics", 1);
  variable xform = qualifier("xformat", "%f");
  variable yform = qualifier("yformat", "%f");
  variable xlen = qualifier("xstrlen", 4);
  variable ylen = qualifier("ystrlen", 4);

  % offsets due to axes and ticmarks
  variable xoff = 0, yoff = 0;
  if (xtics) { yoff += 1; } % the x-tics fit in one row
  if (ytics) { xoff += ylen; } % the y-tics require more
  if (yaxis) { xoff++; }
  % define the char-matrix
  variable out = Char_Type[H+yoff,W+xoff];
  out[*,*] = ' '; % fill with spaces
  % draw axis
  if (xaxis) { out[H-1,[xoff:]] = '_'; }
  if (yaxis) { out[[:H-1],xoff-1] = '|'; }
  % draw tics
  variable tstr;
  if (xtics) {
    tstr = substr(sprintf(xform, x0), 1, xlen);
    out[H,[:strlen(tstr)-1]] = unpack(sprintf("c%d", strlen(tstr)), tstr);
    tstr = substr(sprintf(xform, x1), 1, xlen);
    out[H,[-strlen(tstr):]] = unpack(sprintf("c%d", strlen(tstr)), tstr);
  }
  if (ytics) {
    tstr = substr(sprintf(yform, y0), 1, ylen);
    out[H-1,[:strlen(tstr)-1]] = unpack(sprintf("c%d", strlen(tstr)), tstr);
    tstr = substr(sprintf(yform, y1), 1, ylen);
    out[0,[:strlen(tstr)-1]] = unpack(sprintf("c%d", strlen(tstr)), tstr);
  }

  return struct {
    matrix = out, W = W, H = H,
    world = struct {
      x0 = x0, x1 = x1, y0 = y0, y1 = y1,
      xoff = xoff, yoff = yoff
    }
  };
}

%%%%%%%%%%%%%%%
define printplot_out()
%%%%%%%%%%%%%%%
%!%+
%\function{printplot_out}
%\synopsis{print a char-matrix into the terminal}
%\usage{printplot_out(Char_Type[] matrix);}
%\seealso{new_printplot}
%!%-
{
  variable out, n;
  switch (_NARGS)
    { case 1: (out) = (); }
    { help(_function_name); return; }

  _for n (0, length(out[*,0])-1, 1) {
    vmessage(strjoin(array_map(String_Type, &sprintf, "%c", out[n,*])));
  }
}

%%%%%%%%%%%%%%%
define printplot()
%%%%%%%%%%%%%%%
%!%+
%\function{printplot}
%\synopsis{print a plot of xy-values into the terminal}
%\usage{printplot(Double_Type[] x, y[, Struct_Type printplot]);}
%\qualifiers{
%    \qualifier{sym}{the char used for a data point (default: 'x')}
%    \qualifier{get}{return the structure instead of printing}
%}
%\description
%    Prints a very simpel ASCII-version of plotting the
%    given xy-values into the terminal. The x- and y-ranges
%    are defined automatically by the input, but can be
%    specified via the optional printplot-structure (see
%    'new_printplot'). The only drawn ticmarks represent
%    these ranges.
%
%    All qualifiers are also passed to new_printplot.
%\example
%    % plot a sin
%    x = [0:2*PI:#100];
%    printplot(x, sin(x));
%
%    % overplot a cosin
%    printplot(x, .5*cos(x), printplot(x, sin(x); get); sym = '*');
%\seealso{new_printplot, printhplot}
%!%-
{
  variable x, y, plot = NULL;
  switch (_NARGS)
    { case 2: (x,y) = (); }
    { case 3: (x,y,plot) = (); }
    { help(_function_name); return; }

  % sanity checks
  if (length(x) != length(y)) {
    vmessage("error (%s): x and y must be of equal length!", _function_name);
    return;
  }

  % qualifiers
  variable sym = qualifier("sym", 'x');

  % create a new printplot structure if not already given
  if (plot == NULL) {
    plot = new_printplot(min(x), max(x), min(y), max(y);; __qualifiers);
  }

  % plot the data
  variable i, xd, yd;
  _for i (0, length(x)-1, 1) {
    if (plot.world.x0 < x[i] < plot.world.x1 && plot.world.y0 < y[i] < plot.world.y1) {
      xd = int(plot.world.xoff + plot.W*(x[i]-plot.world.x0)/(plot.world.x1 - plot.world.x0));
      yd = plot.H - int(plot.world.yoff + plot.H*(y[i]-plot.world.y0)/(plot.world.y1 - plot.world.y0));
      plot.matrix[yd, xd] = sym;
    }
  }

  % print or return
  if (qualifier_exists("get")) { return plot; }
  else { printplot_out(plot.matrix); }
}

%%%%%%%%%%%%%%%
define printhplot()
%%%%%%%%%%%%%%%
%!%+
%\function{printhplot}
%\synopsis{print a plot of a histogram into the terminal}
%\usage{printplot(Double_Type[] lo, hi, values[, Struct_Type printplot]);}
%\qualifiers{
%    \qualifier{sym}{the char used for the bar (default: 'o')}
%    \qualifier{get}{return the structure instead of printing}
%}
%\description
%    Prints a very simple ASCII-version of plotting the
%    given histogram into the terminal. The x- and y-ranges
%    are defined automatically by the input, but can be
%    specified via the optional printplot-structure (see
%    'new_printplot'). The only drawn ticmarks represent
%    these ranges.
%
%    All qualifiers are also passed to new_printplot
%\example
%    % plot gaussian distributed random numbers
%    (lo,hi) = linear_grid(-3, 3, 40);
%    printhplot(lo, hi, histogram(grand(10000), lo, hi); W=40);
%\seealso{new_printplot, printplot}
%!%-
{
  variable lo, hi, value, plot = NULL;
  switch (_NARGS)
    { case 3: (lo,hi,value) = (); }
    { case 4: (lo,hi,value,plot) = (); }
    { help(_function_name); return; }

  % sanity checks
  if (length(lo) != length(hi) || length(hi) != length(value)) {
    vmessage("error (%s): lo, hi, and values must be of equal length!", _function_name);
    return;
  }

  % qualifiers
  variable sym = qualifier("sym", 'o');

  % create a new printplot structure if not already given
  if (plot == NULL) {
    plot = new_printplot(lo[0], hi[-1], min(value), max(value);; __qualifiers);
  }

  % plot the histogram
  variable i, bd, hd;
  _for i (0, length(lo)-1, 1) {
    if (lo[i] >= plot.world.x0 && lo[i] <= plot.world.x1) {
      if (value[i] > plot.world.y0) {
        bd = int(round(plot.world.xoff + plot.W*(lo[i]-plot.world.x0)/(plot.world.x1 - plot.world.x0)));
        if (value[i] > plot.world.y1) { hd = 0; }
        else {
          hd = plot.H - int(plot.world.yoff + round(plot.H*(value[i]-plot.world.y0)/(plot.world.y1 - plot.world.y0)));
        }
	if (bd > plot.W+plot.world.xoff-1) { bd = plot.W+plot.world.xoff-1; }
        if (hd > plot.H-1) { hd = plot.H-1; }
        if (hd < 0) { hd = 0; }
        plot.matrix[[hd:plot.H-1], bd] = sym;
      }
    }
  }

  % print or return
  if (qualifier_exists("get")) { return plot; }
  else { printplot_out(plot.matrix); }
}
