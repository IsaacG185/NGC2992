
define x2label()
%!%+
%\function{x2label}
%\synopsis{labels the second x-axis}
%\usage{x2label(String_Type s);}
%\qualifiers{
%\qualifier{color}{[=1] textcolor}
%\qualifier{f}{[=0.03] fraction of the plot-area's height that the label is above}
%}
%\seealso{xylabel}
%!%-
{
  variable s;
  switch(_NARGS)
  { case 1: s = (); }
  { help(_function_name()); return; }

  variable plot_opt = get_plot_options();
  color( qualifier("color", 1) );
  xylabel(coords_in_box(0.5, 1+qualifier("f", 0.03)), s, 0, 0.5);
}
