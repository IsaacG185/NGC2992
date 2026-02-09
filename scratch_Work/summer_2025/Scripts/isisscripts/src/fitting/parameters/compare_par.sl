%%%%%%%%%%%%%%%%%%
define compare_par()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{compare_par}
%\synopsis{compares models saved in parameter files}
%\usage{compare_par([String_Type pattern]);
%\altusage{Struct_Type info = compare_par([String_Type pattern]; get_list);}
%}
%\qualifiers{
%\qualifier{fit_fun}{include fit-function}
%\qualifier{fit_fun=fitfun}{only include models using the fit-function \code{fitfun}}
%\qualifier{get_list}{the information is not printed, but returned}
%\qualifier{load_best}{load the best fit parameters}
%\qualifier{verbose}{}
%}
%\description
%    It is assumed that the corresponding data sets are already initialized.
%\seealso{load_par, eval_counts}
%!%-
{
  variable pat;
  switch(_NARGS)
  { case 0: pat = "*.par"; }
  { case 1: pat = (); }
  { help(_function_name()); return; }

  variable include_fit_fun = qualifier_exists("fit_fun");
  variable fit_fun_to_look_for = qualifier("fit_fun");
  if(fit_fun_to_look_for != NULL)  include_fit_fun = 0;
  variable verbose = qualifier_exists("verbose");

  variable FV = Fit_Verbose;
  variable old_fit_fun = get_fit_fun();
  variable params = get_params();

  variable info = struct {
    filename = String_Type[0],
    mtime = String_Type[0],
    numPar = Integer_Type[0],
    numFreePar = Integer_Type[0],
    statistic = Double_Type[0],
    red_stat = Double_Type[0],
    best
  };
  if(include_fit_fun)
    info = struct {
      filename = String_Type[0],
      mtime = String_Type[0],
      fit_fun = String_Type[0],
      numPar = Integer_Type[0],
      numFreePar = Integer_Type[0],
      statistic = Double_Type[0],
      red_stat = Double_Type[0],
      best
    };
  variable parfile, e;
  foreach parfile (glob(pat))
  {
    try (e)  load_par(parfile);
    catch AnyError:  { if(verbose)  vmessage("%% %s could not be loaded due to %s exception (%s)", parfile, e.descr, e.message);
                       continue; }
    if(verbose)
      vmessage("%% %s", parfile);
    if(fit_fun_to_look_for==NULL || fit_fun_to_look_for==get_fit_fun())
    {
      variable stat;
      Fit_Verbose = -1;
        ()=eval_counts(&stat);
      Fit_Verbose = FV;
      info.filename  = [info.filename, parfile];
      info.mtime     = [info.mtime, strftime("%Y-%m-%d %H:%M", localtime(stat_file(parfile).st_mtime))];
      if(include_fit_fun)
        info.fit_fun    = [info.fit_fun, get_fit_fun()];
      info.numPar    = [info.numPar, length(get_params)];
      info.numFreePar= [info.numFreePar, stat.num_variable_params];
      info.statistic = [info.statistic, stat.statistic];
      info.red_stat  = [info.red_stat, stat.statistic/(stat.num_bins-stat.num_variable_params)];
    }
  }
  if(old_fit_fun != "")
  {
    fit_fun(old_fit_fun);
    set_params(params);
  }

  info.best = Char_Type[length(info.filename)];  % info.best[*] = 0;
  info.best[where_max(info.statistic)] = -1;
  info.best[where_min(info.statistic)] = +1;
  struct_filter(info, reverse(array_sort(info.statistic)));

  if(qualifier_exists("get_list"))
    info;  % left on stack
  else
    print_struct(info);

  if(qualifier_exists("load_best"))
    if(any(info.best==1))
    { message("loading parameters from "+info.filename[-1]);
      load_par(info.filename[-1]);
    }
    else
      message("no best fit parameters available");
}
