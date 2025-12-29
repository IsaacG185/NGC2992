define oplot_rect()
%!%+
%\function{oplot_rect}
%\synopsis{overplots a rectangle}
%\usage{oplot_rect(Double_Type x1, y1, x2, y2);
%\altusage{oplot_rect(Double_Type [x1, x2], [y1, y2]);}
%}
%!%-
{
  variable x1, y1, x2, y2;
  switch(_NARGS)
  { case 2:
      variable x, y; (x, y) = ();
      x1=x[0]; y1=y[0]; x2=x[1]; y2=y[1];
  }
  { case 4: (x1, y1, x2, y2) = (); }
  { help(_function_name()); return; }

  variable plot_opt = get_plot_options();
  connect_points(-1);
  oplot([x1,x2,x2,x1,x1], [y1,y1,y2,y2,y1]);
  connect_points(plot_opt.connect_points);
}
