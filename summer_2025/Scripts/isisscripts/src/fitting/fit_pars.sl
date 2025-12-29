variable fit_pars_last_results = NULL;

%%%%%%%%%%%%%%
define fit_pars()
%%%%%%%%%%%%%%
%!%+
%\function{fit_pars}
%\synopsis{computes single-parameter confidence limits for several parameters}
%\usage{Struct_Type results = fit_pars([Integer_Type pars[]]);}
%\qualifiers{
%\qualifier{strict}{[=1]: restarts the calculation if a new best fit was found}
%\qualifier{saveoutput}{[=1]}
%\qualifier{basefilename}{[=<date_time>]}
%\qualifier{level}{[=1]: specifies the confidence level. Values of 0, 1, or 2
%                 indicate 68%, 90%, or 99% confidence levels respectively.
%                 By default, 90% confidence limits are computed.}
%\qualifier{chi2diff}{if given, fit_pars invokes fconf instead of
%                    conf with the value given to caluculate confidence in chi2
%                    range. Defaults to 1.0.}
%\qualifier{tolerance}{convergence criterion for the calculation of the confidence
%      limits (see help for the conf command). Default: 1e-3}
%}
%\qualifier{quiet}{If set, don't print any information on stdout}
%\description
%    The return value \code{results = struct { index, name, value, min, max, conf_min, conf_max, buf_below, buf_above, tex }}
%    is a table with the following information for each parameter:\n
%    \code{min} and \code{max} are the minimum/maximum values allowed.
%    \code{conf_min} and \code{conf_max} are the confidence limits.
%    \code{buf_below} (\code{buf_above}) is the fraction of the allowed range \code{[min:max]}
%    which separates the lower (upper) confidence limit from \code{min} (\code{max}).
%    If one of these buffers is 0, your confidence interval has bounced.
%\seealso{pvm_fit_pars, conf, fconf}
%!%-
{
  variable pars;
  switch(_NARGS)
  { case 0: pars = thawedParameters(); }
  { case 1: pars = (); }
  { help(_function_name()); return; }

  variable strict = qualifier("strict", 1);
  variable saveoutput = qualifier("saveoutput", 1);
  variable basefilename = qualifier("basefilename", strftime("%Y-%m-%d_%H:%M:%S", localtime(_time())))+ "_";
  variable level = qualifier("level",1);
  variable tolerance = qualifier("tolerance",1e-3);
  variable chi2diff = qualifier("chi2diff", 1.);
  variable quiet = qualifier_exists("quiet");
  if (not(level==0 or level==1 or level==2)) {
	 message("requested confidence level not available. Default to level =1: 90%\n");
	 level=1;
  }
   
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
  _for i (0, n-1, 1)
  { info = get_par_info(pars[i]);
    results.name[i] = info.name;
    results.min[i] = info.min;
    results.max[i] = info.max;
  }

  thaw(pars);
  variable ok;
  do
  { ok = 1;
    for(i=0; i<n && ok; i++)
    { do
      { 
	if (qualifier_exists("chi2diff"))
	  (results.conf_min[i], results.conf_max[i]) = fconf(pars[i],chi2diff,tolerance);
	else
	  (results.conf_min[i], results.conf_max[i]) = conf(pars[i],int(level),tolerance);
        if(results.conf_min[i]==results.conf_max[i] && strict)
          ok = 0;
      } while(results.conf_min[i]==results.conf_max[i]);
      if(saveoutput)
        try { save_par(basefilename+"best.par"); }
	catch AnyError: { vmessage("Could not write to %sbest.par.", basefilename); }

      info = get_par_info(pars[i]);
      results.value[i] = info.value;
      results.buf_below[i] = (results.conf_min[i] - info.min)/(info.max-info.min);
      results.buf_above[i] = (info.max - results.conf_max[i])/(info.max-info.min);
      results.tex[i] = TeX_value_pm_error(info.value, results.conf_min[i], results.conf_max[i]);
      ifnot (quiet) {
        vmessage("(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s",
	    results.min[i], results.conf_min[i], results.name[i], results.value[i], results.conf_max[i], results.max[i],
	    100*results.buf_below[i], 100*results.buf_above[i], results.tex[i]);
      }
    }
  } while(not ok);

  variable stat;
  ()=eval_counts(&stat);

  if(saveoutput)
    try
    {
      fits_write_binary_table(basefilename+"conf.fits", "fit_pars-results", results, struct {
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

  ifnot (quiet) {
    vmessage("\n");
    vmessage("(%10s <=) %10s < %38s < %10s (<= %10s)", "min.all.", "conf.min.", "parameter value", "conf.max.", "max.all.");
    _for i (0, n-1, 1)
    vmessage("(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s",
	      results.min[i], results.conf_min[i], results.name[i], results.value[i], results.conf_max[i], results.max[i],
	      100*results.buf_below[i], 100*results.buf_above[i], results.tex[i]);
    }

  fit_pars_last_results = results;
  return results;
}
