define load_par_tbnew(filename)
%!%+
%\function{load_par_tbnew}
%\synopsis{load a parameter file after decreasing the upper limit for tbnew.PL}
%\usage{load_par_tbnew(String_Type filename);}
%\description
%    Early versions of the \code{TBnew} absorption model allowed
%    for a too large upper limit of the \code{PL} parameter of 5.
%    This function reduces the \code{PL} parameter to 3.999,
%    rewrites the parameter file, and loads it with \code{load_par}.
%\seealso{load_par}
%!%-
{
  variable fp = fopen(filename, "r");
  variable line, lines = fgetslines(fp);
  ()=fclose(fp);

  variable s = "[ \t]+";  % white spaces
  variable num = `\d*\.?\d*`;  % a number
  fp = fopen(filename, "w");
  foreach line (lines)
  {
    variable m = string_matches(line, `^\(.*[Tt][Bb]new(\d+)\.PL$s\d+$s[01]$s$num$s$num$s\)\($num\)`$);
    if(m!=NULL)
      ()=fprintf(fp, "%s%S\n", m[1], _min(3.999, atof(m[2])));
    else
      ()=fprintf(fp, "%s", line);
  }
  ()=fclose(fp);

  load_par(filename);
}
