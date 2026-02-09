define fit_pars_read_stdoutlogfile()
%!%+
%\function{fit_pars_read_stdoutlogfile}
%\synopsis{reads chi2-improvements from a stdout-logfile created by (pvm_)fit_pars}
%\usage{(t, chi2) = fit_pars_read_stdoutlogfile(String_Type filename);}
%\description
%    \code{t} is the number of seconds since the start of (\code{pvm_})\code{fit_pars}.
%\seealso{fit_pars, pvm_fit_pars}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }
  
  variable F = fopen(filename, "r");
  variable T0, t=Double_Type[0], chi2 = Double_Type[0];
  variable m = string_matches(fgetslines(F, 1)[0], `^\(started on\) \(\d\d\d\d\)-\(\d\d\)-\(\d\d\)_\(\d\d\):\(\d\d\):\(\d\d\)`, 1);
  T0 = mktime(struct { tm_sec=atoi(m[7]), tm_min=atoi(m[6]), tm_hour=atoi(m[5]), tm_mday=atoi(m[4]), tm_mon=atoi(m[3])-1, tm_year=atoi(m[2])-1900, tm_wday=0, tm_yday=0, tm_isdst=0 });
  foreach ( fgetslines(F) )
  { % line = first argument of string_matches: left on stack
    m = string_matches(`^found improved fit (chisqr=\([^)]*\)) .* \[\(\d\d\d\d\)-\(\d\d\)-\(\d\d\) \(\d\d\):\(\d\d\):\(\d\d\)\]`, 1);  % second and third argument
    if(m!=NULL)
    { chi2 = [chi2, atof(m[1])];
      t = [t, mktime(struct { tm_sec=atoi(m[7]), tm_min=atoi(m[6]), tm_hour=atoi(m[5]), tm_mday=atoi(m[4]), tm_mon=atoi(m[3])-1, tm_year=atoi(m[2])-1900, tm_wday=0, tm_yday=0, tm_isdst=0 })];
    }
  }
  ()=fclose(F);
  return  t-T0, chi2;
}
