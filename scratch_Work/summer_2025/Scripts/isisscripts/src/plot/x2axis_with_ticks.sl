define x2axis_with_tics()
%!%+
%\function{x2axis_with_tics}
%\usage{x2axis_with_tics(Double_Type X[][, Label]);}
%\qualifiers{
%\qualifier{ftick}{[=0.08]: fraction of box-height that tick marks are below axis}
%\qualifier{flabel}{[=0.05]: fraction of box-height that labels are above axis}
%}
%!%-
{
  variable X, Label;
  switch(_NARGS)
  { case 1:  X = (); Label = X; }
  { case 2: (X, Label) = (); }
  { help(_function_name()); return; }

  if(length(X)>0)
    switch( typeof([Label][0]) )
    { case String_Type:
      ; % Label is already ok.
    }
    { case Null_Type:
        Label = String_Type[length(X)];
        Label[*] = "";
    }
    { % else:
        Label = array_map(String_Type, &string, Label);
    }

  variable plot_opt = get_plot_options();
  variable x1 = plot_opt.xmin;
  variable x2 = plot_opt.xmax;
  variable y1 = plot_opt.ymin;
  variable y2 = plot_opt.ymax;
  variable yt = coordY_in_box(1-qualifier("ftick", 0.08));
  variable yl = coordY_in_box(1+qualifier("flabel", 0.05));

  color(1);
  set_line_width(1);
  oplot([x1, x2], [y2, y2]);
  variable i, I = where(x1 <= X <= x2);
  foreach i (I)
  {
%    _pgsci(1);
%    variable v = (X[i]-x1)/(x2-x1);  % if linear
%    _pgtick(x1, y2, x2, y2, v, 0.5, 0, 0.5, 0, "a");
    color(1); oplot(X[i]*[1,1], [yt, y2]);
    color(1); xylabel(X[i], yl, Label[i], 0, 0.5);
  }

  set_plot_options(plot_opt);
}
