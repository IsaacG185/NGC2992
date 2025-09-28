define save_statistics()
%!%+
%\function{save_statistics}
%\synopsis{saves the fit-statistic in a textfile}
%\usage{save_statistics(String_Type filename);}
%\seealso{eval_counts}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable F = fopen(filename, "w");
  variable s;
  variable FV = Fit_Verbose;
  Fit_Verbose = -1;
  ()=eval_counts(&s);
  Fit_Verbose = FV;
  ()=fprintf(F, "Parameters [Variable] = %d [%d]\n", length(get_params()), s.num_variable_params);
  ()=fprintf(F, "            Data bins = %d\n", s.num_bins);
  variable stat = strtok(get_fit_statistic(), ";")[0];
  if(stat == "chisqr")
  {
    ()=fprintf(F, "           Chi-square = %0.7g\n", s.statistic);
    if(s.num_bins > s.num_variable_params)
      ()=fprintf(F, "   Reduced chi-square = %0.7g\n", s.statistic/(s.num_bins-s.num_variable_params));
  }
  else
    ()=fprintf(F, "%20s = %0.7g\n", "Statistic ("+stat+")", s.statistic);

  ()=fclose(F);
}
