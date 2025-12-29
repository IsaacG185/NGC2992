%%%%%%%%%%%%%%%%%%%%%%%%%
define draw_plot_commands()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{draw_plot_commands}
%\synopsis{creates plot commands for drawing lines with the mouse}
%\usage{draw_plot_commands();}
%\qualifiers{
%\qualifier{init}{[\code{=1}] initializes plot window at the beginning}
%}
%!%-
{
  xlin;
  ylin;
  xrange(0, 1);
  yrange(0, 1);

  title("left mouse button = set point;   middle mouse button = finish line;  right mouse button = exit");
  if(qualifier("init", 1))
    plot(0, 0);
  variable XX = {}, YY = {}, X = Double_Type[0], Y = @X, i;
  do
  {
    variable x, y, ch;
    cursor(&x,  &y, &ch);
    if(ch=="A")
      X = [X, x],
      Y = [Y, y];
    if(ch=="D" && length(X)>0)
    { list_append(XX, X);
      list_append(YY, Y);
      X = Double_Type[0];
      Y = Double_Type[0];
    }
    if(length(X)>0)  plot(X, Y);  else  plot(0, 0);
    _for i (0, length(XX)-1, 1)
    { color(1);
      oplot(XX[i], YY[i]);
    }
  } while(ch!="X");
  if(length(XX[i])>0)
  { list_append(XX, X);
    list_append(YY, Y);
  }

    vmessage("xrange(0, 1);\nyrange(0, 1);\n%s],\n%s]);",
             strjoin_wrap(array_map(String_Type, &sprintf, "%.3f", XX[0]), ", "; initial=" plot([", newline="       ", maxlen=80),
   	     strjoin_wrap(array_map(String_Type, &sprintf, "%.3f", YY[0]), ", "; initial="      [", newline="       ", maxlen=80));
  _for i (1, length(XX)-1, 1)
    vmessage("color(1);\n%s],\n%s]);",
 	     strjoin_wrap(array_map(String_Type, &sprintf, "%.3f", XX[i]), ", "; initial="oplot([", newline="       ", maxlen=80),
	     strjoin_wrap(array_map(String_Type, &sprintf, "%.3f", YY[i]), ", "; initial="      [", newline="       ", maxlen=80));
}
