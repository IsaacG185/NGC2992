define history()
%!%+
%\function{history}
%\synopsis{shows the history of commands on the interactive ISIS-shell}
%\usage{history();}
%\seealso{save_input}
%!%-
{
  variable tmpFile = sprintf("/tmp/ISIS.history.%d.%d", getuid(), getpid());
  save_input(tmpFile);

  variable fp = fopen(tmpFile, "r"), line;
  foreach line (fp)
    message(line);
  ()=fclose(fp);
  ()=remove(tmpFile);
}
