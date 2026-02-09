%%%%%%%%%%%%%%
define cl_save()
%%%%%%%%%%%%%%
%!%+
%\function{cl_save}
%\synopsis{computs single-parameter confidence lmits for several parameters, using multiple cores on one machine}
%\usage{Struct_Type results = cl_save([Integer_Type pars[]]);}
%\qualifiers{
%\qualifier{strict}{[=1]: restarts the calculation if a new best fit was found}
%\qualifier{saveoutput}{[=1]}
%\qualifier{basefilename}{[=<date_time>]}
%\qualifier{level}{[=1]: specifies the confidence level. Values of 0, 1, or 2
%                 indicate 68%, 90%, or 99% confidence levels respectively.
%                 By default, 90% confidence limits are computed.}
%\qualifier{tolerance}{convergence criterion for the calculation of the confidence
%      limits (see help for the conf command). Default: 1e-3}
%\qualifier{cleanup}{will remove all temporary files ending in *.[0-9][0-9]* from the basefilename directory}
%}
%\description
%    This function is a direct copy of fit_pars, however, using
%    "conf_loop" to allow multi-core support on one machine. The
%    number of slaves is determined by the global variable
%    Isis_Slaves.num_slaves.
%    The return value \code{results = struct { index, name, value, min, max, conf_min, conf_max, buf_below, buf_above, tex }}
%    is a table with the following information for each parameter:\n
%    \code{min} and \code{max} are the minimum/maximum values allowed.
%    \code{conf_min} and \code{conf_max} are the confidence limits.
%    \code{buf_below} (\code{buf_above}) is the fraction of the allowed range \code{[min:max]}
%    which separates the lower (upper) confidence limit from \code{min} (\code{max}).
%    If one of these buffers is 0, your confidence interval has bounced.
%\seealso{fit_pars, pvm_fit_pars, conf}
%!%-

{
   variable pars ;
   switch(_NARGS)
     { case 0: pars = thawedParameters() ; }
     { case 1: pars = () ;}
     { help(_function_name()); return; }

   
   variable lvls = qualifier("levels", 1);
   variable tol = qualifier("tolerance", 1e-3) ;

   variable saveoutput = qualifier("saveoutput", 1);
   variable basefilename = qualifier("basefilename", strftime("%Y-%m-%d_%H:%M:%S", localtime(_time())))+ "_";

  variable n = length(pars);
  variable results = struct {
    index     = pars,
    name      = String_Type[n],
    value     = Double_Type[n],
    min       = Double_Type[n],
    max       = Double_Type[n],
    conf_min  = Double_Type[n],
    conf_max  = Double_Type[n],
    buf_below = Double_Type[n],
    buf_above = Double_Type[n],
    tex       = String_Type[n],
  };

     variable i, info;
     variable clquals ;
   if (saveoutput) 
     {
	clquals = struct_combine(__qualifiers, struct{save=1,prefix=basefilename});
     }
   else clquals = __qualifiers ;
   
   print(clquals) ;
   
   (results.conf_min, results.conf_max ) = conf_loop(pars,lvls,tol;; clquals) ;

   if(saveoutput)
        try { save_par(basefilename+"best.par"); }
        catch AnyError: { vmessage("Could not write to %sbest.par.", basefilename); }

   _for i (0, n-1, 1)
       { 
	  info = get_par_info(pars[i]);
	  results.name[i] = info.name;
	  results.min[i] = info.min;
	  results.max[i] = info.max;
  	  results.value[i] = info.value;
  	  results.buf_below[i] = (results.conf_min[i] - info.min)/(info.max-info.min);
	  results.buf_above[i] = (info.max - results.conf_max[i])/(info.max-info.min);
	  results.tex[i] = TeX_value_pm_error(info.value, results.conf_min[i], results.conf_max[i]);
	  vmessage("(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s",
	       results.min[i], results.conf_min[i], results.name[i], results.value[i], results.conf_max[i], results.max[i],
  	       100*results.buf_below[i], 100*results.buf_above[i], results.tex[i]);
       }

   variable stat;
  ()=eval_counts(&stat);

  if(saveoutput)
    try
    {
      fits_write_binary_table(basefilename+"conf.fits", "CL", results, struct {
    chi2 = stat.statistic,
    num_bins = stat.num_bins,
    n_var_pars = stat.num_variable_params,
    dof = stat.num_bins-stat.num_variable_params,
    chi2red = stat.statistic/(stat.num_bins-stat.num_variable_params)
  });
      variable F = fopen(basefilename+"conf.txt", "w");
      ()=fprintf(F, "%s\n", get_fit_fun());
      ()=fprintf(F, "(%10s <=) %10s < %38s < %10s (<= %10s)\n", "min.all.", "conf.min.", "parameter value", "conf.max.", "max.all.");
      for($1=0; $1<length(results.name); $1++)
        ()=fprintf(F, "(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s\n",
		      results.min[$1], results.conf_min[$1], results.name[$1], results.value[$1], results.conf_max[$1], results.max[$1],
		      100*results.buf_below[$1], 100*results.buf_above[$1], results.tex[$1]);
      ()=fprintf(F, "\n%s/dof = %f/%d = %f\n", Fit_Statistic, stat.statistic, stat.num_bins-stat.num_variable_params, stat.statistic/(stat.num_bins-stat.num_variable_params));
      ()=fclose(F);
    }
    catch AnyError: vmessage("Could not write to %sconf.fits and/or %sconf.txt", basefilename, basefilename);

  vmessage("\n");
  vmessage("(%10s <=) %10s < %38s < %10s (<= %10s)", "min.all.", "conf.min.", "parameter value", "conf.max.", "max.all.");
  _for i (0, n-1, 1)
    vmessage("(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s",
	      results.min[i], results.conf_min[i], results.name[i], results.value[i], results.conf_max[i], results.max[i],
	      100*results.buf_below[i], 100*results.buf_above[i], results.tex[i]);

  if (qualifier_exists("cleanup"))
     {
	()=system(sprintf("rm %s*.[0-9][0-9]*", basefilename));
     }
   
   
  return results;
}
