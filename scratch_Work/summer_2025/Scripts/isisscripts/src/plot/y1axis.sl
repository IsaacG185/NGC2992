
define y1axis()
%!%+
%\function{y1axis}
%\synopsis{(re)draws a first y-axis}
%\usage{y1axis(Double_Type min_value, Double_Type max_value[, Double_Type step]);}
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
%\qualifier{xrel}{[=0] relative position of the y1axis (0=left, 1=right)}
%\qualifier{ymin}{[=ymin] absolute y-position of the axis}
%\qualifier{ymax}{[=ymax] absolute y-position of the axis}
%}
%\seealso{x2axis (and references therein)}
%!%-
{
  variable po = get_plot_options();
  variable min_value, max_value, step=0;
  switch(_NARGS)
  { case 2: (min_value, max_value) = (); }
  { case 3: (min_value, max_value, step) = (); }
  { help(_function_name()); return; }

  variable opt = "N";
  variable ymin = qualifier("ymin", po.ymin);
  variable ymax = qualifier("ymax", po.ymax);
  if(po.logy)
  { ymin = log10(ymin);
    ymax = log10(ymax);
    opt = "LN";
    min_value = log10(min_value);
    max_value = log10(max_value);
  }
  variable x = coordX_in_box( qualifier("xrel", 0) );
  if(po.logx)  x = log10(x);
  _pgsci( qualifier("color", 1) );
  _pgslw( qualifier("linewidth", 1) );
  _pgaxis(qualifier("opt", opt), x, ymin, x, ymax,
          min_value, max_value,  step, qualifier("nsub", 0),
          qualifier("majo", 0), qualifier("maji", 0.5), qualifier("fmin", 0.5), -qualifier("disp", 0.5),
          qualifier("angle", 0)
         );
}
