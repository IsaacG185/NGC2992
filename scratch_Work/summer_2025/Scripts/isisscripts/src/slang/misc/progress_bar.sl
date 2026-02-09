define draw_progress_bar(cur, goal)
%!%+
%\function{draw_progress_bar}
%\synopsis{Draw a progress bar}
%\usage{draw_progress_bar( position , maximum )}
%\qualifiers{
%\qualifier{tip}{String to draw tip of the arrow (default: ">")}
%\qualifier{bar}{String to draw bar of the arrow (default: "=")}
%\qualifier{front}{String to draw space in front of arrow (default: ".")}
%\qualifier{append}{String to append to each drawn progress bar (default: "")}
%\qualifier{columns}{Columns to use to write progress bar (default: Terminal width)}
%\qualifier{fmt}{Format to use for writing the percentage info in front of the bar.
%		   The printing function gets passed the percentage of the current
%		   state to the function as the second argument after the format
%		   (default: "%.1f%%", for example 01.3%)}
%}
%\description
%	Draw a progress bar across the prompt.
%	The width of the bar (arrow) is calculated from the fraction of
%	position/maximum. In case position is greater than maximum nothing happens.
%	Note that the function automatically determines the width of the current terminal.
%	This procedure takes some tens of milliseconds. The function can be sped by
%	setting the "columns" qualifier manually.
%!%-
{
  if ( cur > goal )
  {
    return ;
  }
  variable tip = qualifier("tip", ">");
  variable tiplen = strlen(tip);
  variable bar = qualifier("bar", "=");
  variable barlen = strlen(bar);
  variable front = qualifier("front", ".");
  variable frontlen = strlen(front);
  variable append = qualifier("append", "");
  variable fmt = qualifier("fmt", "%.1f%%");

  variable cols;

  if ( qualifier_exists("columns") )
  {
    cols = qualifier("columns");
  } else {
    % Determine columns of current terminal
    variable str;
    variable fptr = popen("stty size", "r");
    () = fgets(&str, fptr);
    () = fclose(fptr);
    () = sscanf(str, "%*d %d\n", &cols);
  }

  variable frac = double(cur)/double(goal);
  () = printf("\r");
  variable printed = printf(fmt+"[", frac * 100);
  variable printbar = int(frac * (cols - printed - 1)) - tiplen;
  variable ii;
  _for ii(1, printbar/barlen, 1)
  {
    printed += printf("%s", bar);
  }
  printed += printf("%s", tip);
  while ( (printed + tiplen + frontlen ) < cols + 1)
  {
    printed += printf("%s", front);
  }
  while (printed < cols - 1)
  {
    printed += printf(" ");
  }
  () = printf("]");
  () = printf("%s", append);
  () = fflush(stdout);
}
