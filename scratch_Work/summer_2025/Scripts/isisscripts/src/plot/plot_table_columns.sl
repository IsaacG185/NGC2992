define plot_table_columns()
%!%+
%\function{plot_table_columns}
%\synopsis{plots columns of a table against each other}
%\usage{plot_table_columns(Struct_Type table);}
%\qualifiers{
%\qualifier{x}{array of columns to be used for the x-axis [default: all columns]}
%\qualifier{y}{array of columns to be used for the y-axis [default: all columns]}
%\qualifier{path}{path to save the postscript plots}
%\qualifier{multiplot}{produce one single multiplot (does not call open_plot)}
%}
%!%-
{
  variable table;
  switch(_NARGS)
  { case 1: table = (); }
  { help(_function_name()); return; }

  variable columns = get_struct_field_names(table);
  variable Xcolumn, Xcolumns = [qualifier("x", columns)];
  variable Ycolumn, Ycolumns = [qualifier("y", columns)];
  variable path = qualifier("path", ".");
  if(stat_file(path)==NULL)
    mkdir(path);
  if(qualifier_exists("multiplot"))
  {
    variable n = 0;
    foreach Xcolumn (Xcolumns)
      foreach Ycolumn (Ycolumns)
        if(Xcolumn != Ycolumn)
          n++;
    multiplot(ones(n));
  }
  foreach Xcolumn (Xcolumns)
    foreach Ycolumn (Ycolumns)
      if(Xcolumn != Ycolumn)
      {
	ifnot(qualifier_exists("multiplot"))
	  ()=open_plot(path + "/" + Xcolumn + "-" + Ycolumn + ".ps/ps");
	xlabel(Xcolumn);
	ylabel(Ycolumn);
        plot(get_struct_field(table, Xcolumn), get_struct_field(table, Ycolumn));
	ifnot(qualifier_exists("multiplot"))
	  close_plot;
      }
}
