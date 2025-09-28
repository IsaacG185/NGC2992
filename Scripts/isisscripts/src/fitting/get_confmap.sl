
private variable confmap_pars, confmap_save_basefilename;

%%%%%%%%%%%%%%%%%%%%%%%%
private define confmap_save_hook(p)
%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable fp = fopen(sprintf("%s_%d.dat", confmap_save_basefilename, getpid()), "a");
  variable par;
  foreach par (get_params(confmap_pars))
    ()=fprintf(fp, "%S\t", par.value);
  ()=fprintf(fp, "%S\n", p.statistic);
  ()=fclose(fp);
}

%%%%%%%%%%%%%%%%%%
define get_confmap()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_confmap}
%\synopsis{computes a 2d confidence map and possibly stores the fit-parameters in a file}
%\usage{conf_map = get_confmap(par1, min1, max1[, n1], par2, min2, max2[, n2]);}
%\qualifiers{
%\qualifier{save}{[=\code{"confmap"}]: save all parameters to \code{save}+".fits"}
%\qualifier{fail}{[=\code{NULL}]: failure recovery hook, see \code{conf_map_counts}}
%\qualifier{mask}{[=\code{NULL}]: region mask out hook, see \code{conf_map_counts}}
%}
%\description
%    (All qualifiers are also passed to the \code{conf_map_counts} function.)
%
%    \code{par1} is stepped from \code{min1} to \code{max1} in \code{n1} (default=8) steps;
%    \code{par2} is stepped from \code{min2} to \code{max2} in \code{n2} (default=8) steps.
%    A save hook is used to write each step's parameter values and chi^2 to files
%    named \code{sav+"*.dat}, which are finally collected by \code{get_confmap_collect_results}
%    and converted to a table.
%    Parameters from this table can be set with \code{set_par_from_confmap_table}.
%\seealso{conf_grid, conf_map_counts, load_conf, plot_conf, get_confmap_collect_results, set_par_from_confmap_table}
%!%-
{
  variable par1, min1, max1, n1=8,
           par2, min2, max2, n2=8;
  switch(_NARGS)
  { case  6: (par1, min1, max1,     par2, min2, max2) = (); }
  { case  8: (par1, min1, max1, n1, par2, min2, max2, n2) = (); }
  { help(_function_name()); return; }

   variable grid1, grid2;

#ifeval _isis_version_string  < "1.6.1-37"
   grid1 = conf_grid(par1, min1, (n1*max1-min1)/(n1-1.), n1);
   grid2 = conf_grid(par2, min2, (n2*max2-min2)/(n2-1.), n2);
#else
   grid1 = conf_grid(par1, min1, max1, n1);
   grid2 = conf_grid(par2, min2, max2, n2);
#endif   
   
  variable info = struct { fail=qualifier("fail"), save, mask=qualifier("mask") };
  thaw(par1, par2);
  confmap_pars = freeParameters();
  confmap_save_basefilename = qualifier("save", "confmap");
  variable fit_info, FV=Fit_Verbose;
  Fit_Verbose = -1;
  ()=eval_counts(&fit_info);
  Fit_Verbose = FV;
  if(length( glob(confmap_save_basefilename+"_[0-9]*.dat") )>0)
    vmessage("warning (%s): There are already %s_*.dat files.\n        confmap data will not be saved.", _function_name(), confmap_save_basefilename);
  else
  { info.save = &confmap_save_hook;
    variable fp = fopen(confmap_save_basefilename+".info", "w");
    ()=fprintf(fp, "%S\t%S\t%S\t%S\t%d\t%S\n", get_par_info(par1).name, get_par(par1), min1, max1, n1, grid1.max);
    ()=fprintf(fp, "%S\t%S\t%S\t%S\t%d\t%S\n", get_par_info(par2).name, get_par(par2), min2, max2, n2, grid2.max);
    ()=fprintf(fp, "%s = %S\n", Fit_Statistic, fit_info.statistic);
    ()=fprintf(fp, "%S\n", get_fit_fun());
    variable par;
    foreach par (get_params(confmap_pars))
      ()=fprintf(fp, "%s\t", escapedParameterName(par.name));
    ()=fprintf(fp, "%s\n", Fit_Statistic);
    ()=fclose(fp);
  }

  variable confmap = conf_map_counts(grid1, grid2, info;; __qualifiers);
  confmap;  % return value, left on stack

  try { ()=save_conf(confmap, confmap_save_basefilename+".fits"); }
  catch AnyError: { vmessage("warning (%s) could not save confmap to %s", _function_name(), confmap_save_basefilename);
                    return;
                  }
  if(info.save != NULL)
    get_confmap_collect_results(confmap_save_basefilename
				%; remove_files, use_file_from_save_conf, @__qualifiers  % requires S-Lang >= pre-2.2.3-39
				;; struct_combine(struct { remove_files, use_file_from_save_conf },
						  __qualifiers)
			       );
}
