%%%%%%%%%%%%%
define x2axis()
%%%%%%%%%%%%%
%!%+
%\function{x2axis}
%\synopsis{draws a second x-axis}
%\usage{x2axis(Double_Type min_value, Double_Type max_value[, Double_Type step]);}
%\qualifiers{
%\qualifier{nsub}{[=0] number of minor tick marks within each major divison (nsub=0 => no minor ticks)}
%\qualifier{maji}{[=0.5] length of major tick marks, drawn inwards (in units of the character height)}
%\qualifier{majo}{[=0] length of major tick marks, drawn outwards (in units of the character height)}
%\qualifier{fmin}{[=0.5] length of minor tick marks (as fraction of the major tick marks)}
%\qualifier{disp}{[=0.5] displacement of baseline of tick labels to the axis (in units of the character height)}
%\qualifier{angle}{[=0] orientation of the text (in degrees)}
%\qualifier{color}{[=1] color of the axis}
%\qualifier{linewidth}{[=1] line width of the axis}
%\qualifier{opt}{[="N"/"LN"] pgaxis-options: "L" (log), "N" (numbers), "1" (force decimal), "2" (force EE)}
%\qualifier{yrel}{[=1] relative position of the x2axis (0=bottom, 1=top)}
%\qualifier{xmin}{[=xmin] absolute x-position of the axis}
%\qualifier{xmax}{[=xmax] absolute x-position of the axis}
%}
%\description
%    \code{x2axis} has to be called after the plot window is drawn.
%    It relies on the world coordinates set by \code{xrange}, \code{yrange}.
%    The automatical x2axis can be switched off with \code{change_plot_options}.
%\example
%    ()=change_plot_options(; xopt="BNST");  % default: "BCNST", see _pgbox
%    xrange(0, 360); yrange(-1.1, 1.1);
%    plot([0:360], sin([0:2*PI:#361]));
%    x2axis(0, 2);
%\seealso{_pgaxis, change_plot_options, coords_in_box, y2axis, x1axis, y1axis}
%!%-
{
  variable po = get_plot_options();
  variable min_value, max_value, step=0;
  switch(_NARGS)
  { case 2: (min_value, max_value) = (); }
  { case 3: (min_value, max_value, step) = (); }
  { help(_function_name()); return; }

  variable opt = "N";
  variable xmin = qualifier("xmin", po.xmin);
  variable xmax = qualifier("xmax", po.xmax);
  if(po.logx)
  { xmin = log10(xmin);
    xmax = log10(xmax);
    opt = "LN";
    min_value = log10(min_value);
    max_value = log10(max_value);
  }
  variable y = coordY_in_box( qualifier("yrel", 1) );
  if(po.logy)  y = log10(y);
  _pgsci( qualifier("color", 1) );
  _pgslw( qualifier("linewidth", 1) );
  _pgaxis(qualifier("opt", opt), xmin, y, xmax, y,
          min_value, max_value,  step, qualifier("nsub", 0),
          qualifier("majo", 0), qualifier("maji", 0.5), qualifier("fmin", 0.5), -qualifier("disp", 0.5),
          qualifier("angle", 0)
         );
}
