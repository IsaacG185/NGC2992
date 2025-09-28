define y2label()
%!%+
%\function{y2label}
%\synopsis{labels the second y-axis}
%\usage{y2label(String_Type s);}
%\qualifiers{
%\qualifier{color}{[=1] textcolor}
%\qualifier{f}{[=0.03] fraction of the plot-area's width that the label is to the right}
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
  xylabel(coords_in_box(1+qualifier("f", 0.03), 0.5), s, 90, 0.5);
}
