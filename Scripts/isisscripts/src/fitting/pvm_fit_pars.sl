require("pvm_ms");

private variable USER_SLAVE_NEWTASK = 1;
private variable USER_SLAVE_RESULT  = 2;
private variable USER_SLAVE_EXIT    = 3;

private variable Statistic;
private variable Num_Params, Pars_Left;
private variable Best_Statistic = NULL, Best_Params = NULL;
private variable Best_filename, stdout_file;
private variable Limits;
private variable Host=Assoc_Type[String_Type], StillWorking=Assoc_Type[Char_Type];

public variable pvm_fit_pars_last_results = NULL;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define print_stdout_and_file(thres, s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  if(Fit_Verbose >= thres)  message(s);
  ()=fprintf(stdout_file, "%s\n", s);
  ()=fflush(stdout_file);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define restart_slaves_with_new_params(params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  Pars_Left = Num_Params;
  variable par;
  foreach par (assoc_get_keys(Host))
    StillWorking[par] = 1;
  set_params(params);
  save_par(Best_filename);
  variable master_tid = pvm_mytid();
  foreach  (pvm_tasks(0).ti_tid)
  { variable tid = ();
    if(tid != master_tid)
    { pvm_psend(tid, USER_SLAVE_NEWTASK);
      pvm_send_obj(tid, USER_SLAVE_RESULT, params);
    }
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define exit_all_slaves()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable master_tid = pvm_mytid();
  variable s = pvm_tasks(0);
  variable i = where(s.ti_tid != master_tid);
  array_map(Void_Type, &pvm_psend, s.ti_tid[i], USER_SLAVE_EXIT);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define handle_user_message(msgid, tid)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable cl;
  switch(msgid)
  { case USER_SLAVE_NEWTASK:
      cl = pvm_recv_obj();
      if(Best_Statistic == NULL || cl.statistic < Best_Statistic)
      { print_stdout_and_file(1, sprintf("found improved fit (%s=%4.6f) @ %s [%s] for %s = %g",
					 Statistic, cl.statistic,
					 cl.hostname, strftime("%Y-%m-%d %H:%M:%S", localtime(_time())),
					 cl.name, cl.value)
			     );
        Best_Statistic = cl.statistic;
        Best_Params = cl.params;
        restart_slaves_with_new_params(Best_Params);
      }
      else
      { pvm_psend(tid, USER_SLAVE_NEWTASK);
        pvm_send_obj(tid, USER_SLAVE_RESULT, Best_Params);
      }
   }
   { case USER_SLAVE_RESULT:
       cl = pvm_recv_obj();
       variable info = get_par_info(cl.name);
       Pars_Left--;
       StillWorking[cl.name] = 0;
       variable msg = Pars_Left ? "\nworking on $Pars_Left more parameter"$ + (Pars_Left>1 ? "s" : "") : "";
       if(0 < Pars_Left <= 10)
       {
	 msg += " @ ";
	 variable par, first=1;;
	 foreach par (assoc_get_keys(Host))
	   if(StillWorking[par])
	     msg += (first ? "" : ", ") + Host[par],  first = 0;
       }
       print_stdout_and_file(0, sprintf("%10s finished [%s]:\n(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   %s%s",
					cl.hostname, strftime("%Y-%m-%d %H:%M:%S", localtime(_time())),
					info.min,
					cl.lo, cl.name, cl.value, cl.hi,
					info.max,
					TeX_value_pm_error(cl.value, cl.lo, cl.hi),
					msg
				       )
			    );
       Limits[cl.name] = [cl.value, cl.lo, cl.hi];
       ifnot(Pars_Left)  exit_all_slaves();
   }
   return 1;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define slave_spawned_callback(tid, host, argv)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable par = argv[1];
  Host[par] = host;
  StillWorking[par] = 1;
  print_stdout_and_file(1, sprintf("%10s spawned for %s", host, par) );
}


%%%%%%%%%%%%%%%%%%%
define pvm_fit_pars()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pvm_fit_pars}
%\synopsis{computes confidence intervals with PVM}
%\usage{Struct_Type results = pvm_fit_pars(String_Type SetupFile[, Integer_Type pars[]]);}
%\description
%    With SetupFile, one has to provide an ISIS-script which loads/rebins the spectra
%    and loads/assigns the response. If the model requires additional modules,
%    they have to be activated as well in \code{SetupFile}. It is, however, not necessary
%    to define/load the model itself, as the currently defined model will be saved
%    into a file <\code{dir}>/<\code{basefilename}>\code{_initial.par}.
%
%    \code{pars} is an array of parameters, for which the confidence levels are to be fitted.
%    If \code{pars} is not specified, all free parameters of the current model are used.
%    The best fit which is eventually found is always saved in <\code{dir}>/<\code{basefilename}>\code{.par}.
%
%    The verbosity of \code{pvm_fit_pars} is controlled by the intrinsic variable \code{Fit_Verbose}.
%
%    The return value \code{results = struct { index, name, value, min, max, conf_min, conf_max, buf_below, buf_above, tex }}
%    is a table with the following information for each parameter:\n
%    \code{min} and \code{max} are the minimum/maximum values allowed.
%    \code{conf_min} and \code{conf_max} are the confidence limits.
%    \code{buf_below} (\code{buf_above}) is the fraction of the allowed range \code{[min:max]}
%    which seperates the lower (upper) confidence limit from \code{min} (\code{max}).
%    If one of these buffers is 0, your confidence interval has bounced.
%
%    The same infomation is stored in the files <\code{dir}>/<\code{basefilename}>\code{_conf.txt}
%    and <\code{dir}>/<\code{basefilename}>\code{_conf.fits}.
%    In case of any error, the return value is \code{NULL}.
%\qualifiers{
%\qualifier{level}{confidence level to be computed.
%             As for conf, 0 means 68%, 1 means 90% [default], and 2 means 99% confidence level.}
%\qualifier{tolerance}{the tolerance for chi^2 improvements without interrupting the search
%                 for the confidence intervals, see \code{help("conf");}. The default is \code{1e-3}.}
%\qualifier{fitmethod}{fit-method to be used, see \code{help("set_fit_method");}
%                 Default is the currently used fit-method returned by \code{get_fit_method()}.}
%\qualifier{nph}{the number of processes per host, see \code{pvm_ms}.}
%\qualifier{debug}{[=1] prints additional debug information from \code{pvm_ms}. (Default=0)}
%\qualifier{dir}{[="."] specifies the directory in which the logfiles shall be stored.
%                  It may be a relative path to the current working directory.}
%\qualifier{basefilename}{[=startdate]}
%\qualifier{verbose}{log every output -- from the master script or any slave --
%               in the file <\code{dir}>/<\code{basefilename}>\code{_stdout.log},
%               and keep the initial parameters.}
%\qualifier{isisscript}{[="isis-script"] command to start ISIS for slaves.}
%}
%\seealso{fit_pars; conf, set_fit_method, cl_master/cl_slave [Houck/Noble], pvm_ms [S-Lang module]}
%!%-
{
  variable SetupFile=NULL, pars = freeParameters();
  switch(_NARGS)
  { case 0:
      if(length(glob("init.sl"))>0) { SetupFile = "init.sl"; }
      if(length(glob("loaddata.sl"))>0) { SetupFile = "loaddata.sl"; }
      if(SetupFile==NULL) { help(_function_name()); return; }
      message(_function_name()+": using SetupFile " + SetupFile);
  }
  { case 1:  SetupFile = (); }
  { case 2: (SetupFile, pars) = (); }
  { help(_function_name()); return; }

  variable level = qualifier("level", 1);
  if(all(level!=[0:2]))
  {
    message("warning ("+_function_name()+"): level has to be 0 (68%), 1 (90%), or 2 (99%).\nUsing default level = 1.");
    level = 1;
  }
  if(level==NULL) { level = 1; }
  variable tolerance = qualifier("tolerance", 1e-3);
  variable fitmethod = qualifier("fitmethod", get_fit_method());
  variable debug_PVM = qualifier("debug", 0);
  variable num_processes_per_host = qualifier("nph", 2);
  variable dir = qualifier("dir", ".");
  variable isisscript = qualifier("isisscript", "isis-script");
  variable nicelevel = qualifier("nice", 19);
  variable remove_slave = 1;

  variable ok=1;
  try { variable pvmconfig = pvm_config(); } catch AnyError: { ok=0; };
  ifnot(ok)
  { message("error ("+_function_name()+"): PVM has not been started");
    return NULL;
  }
  variable num_hosts = length(pvmconfig.hi_tid);
  Num_Params = length(pars);

  if(num_hosts*num_processes_per_host < Num_Params)
  { vmessage("error (%s): only %d PVM-hosts available; %d processes/host is not enough for %d parameters", _function_name(), num_hosts, num_processes_per_host, Num_Params);
    return NULL;
  }

  variable CWD = getcwd();
  variable startdate = strftime("%Y-%m-%d_%H:%M:%S", localtime(_time()));
  variable basefilename = qualifier("basefilename", startdate);
  variable logbasefilename = dir + "/" + basefilename;
  stdout_file = fopen(logbasefilename+"_stdout.log", "w");
  print_stdout_and_file(1, "started on " + startdate);

  thaw(pars);
  save_par(logbasefilename+"_initial.par");
  Best_filename = logbasefilename+".par";
  Statistic = strtok( get_fit_statistic(), ";")[0];
  Limits = Assoc_Type[Any_Type, NULL];

  % setting up the PVM
  pvm_ms_set_debug(debug_PVM);
  pvm_ms_set_num_processes_per_host(num_processes_per_host);
  pvm_ms_set_message_callback(&handle_user_message);
  pvm_ms_set_slave_spawned_callback(&slave_spawned_callback);

  variable master_tid = pvm_mytid();
  USER_SLAVE_NEWTASK += master_tid * 10;
  USER_SLAVE_RESULT  += master_tid * 10;
  USER_SLAVE_EXIT    += master_tid * 10;

  % setting up the slave script
  variable filename_slave = startdate + "_slave";
  variable F = fopen(filename_slave, "w");
  ()=fputs(
`#! /usr/bin/env $isisscript
% -*- mode: SLang -*-
% $filename_slave generated by pvm_fit_pars() [Manfred Hanke <Manfred.Hanke@sternwarte.uni-erlangen.de>],
% which is based on:
%
% cl_slave: Slave program for parallel computation of single-parameter
%           confidence limits in ISIS, using PVM, as described in
%           "Using the Parallel Virtual Machine for Everyday Analysis,"
%           by Noble et al 2006 (http://arxiv.org/abs/astro-ph/0510688)
%
% Authors:  John C. Houck <houck@space.mit.edu>
%           Michael S. Noble <mnoble@space.mit.edu>
%
% Version:  Thu Mar  6 11:24:42 EST 2008

require("pvm_ms");

pvm_sigterm_enable(1);

private variable Have_New_Params = 0;

public define isis_fit_improved_hook()
{
  variable bufid = pvm_nrecv($master_tid, $USER_SLAVE_NEWTASK);  % non-blocking receive
  if(bufid > 0)
  { Have_New_Params = 1;
    return 1;
  }
  return 0;
}

private variable info = struct { name, value, lo, hi, hostname, params, statistic };

private define slave_next_task();
private define slave_next_task()
{
   variable bufid = pvm_recv($master_tid, -1);  % blocking receive
   variable msgid; (, msgid, ) = pvm_bufinfo(bufid);
   switch(msgid)
   { case $USER_SLAVE_RESULT:
       variable param, params = pvm_recv_obj();
       message("receiving new parameters:");
       foreach param (params)
         if(param.value != get_par(param.name))
           ()=printf("%s = %S; ", param.name, param.value);
       ()=printf("\n");
       set_params(params);
       return 1;
   }
   { case $USER_SLAVE_NEWTASK:
       return slave_next_task();
   }
   return 0;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

()=system("renice +$nicelevel " + string(getpid()) + " >> /dev/null");

()=chdir("$CWD");
()=evalfile("$SetupFile");
load_par("${logbasefilename}_initial.par");
set_fit_method("$fitmethod");

info.name = __argv[1];
info.hostname = uname().nodename;

variable status = 1;
do
{
   Have_New_Params = 0;

   % do it
   (info.lo, info.hi) = conf (info.name, $level, $tolerance);
   info.value = get_par (info.name);
   ifnot(Have_New_Params)
   {
     if(info.lo == info.hi)  % Found better fit
     {
       variable x; ()=fit_counts(&x);
       info.statistic = x.statistic;
       info.params = get_params();
       pvm_send_obj($master_tid, $USER_SLAVE_NEWTASK, info);
     }
     else
     {
       info.params = NULL;
       info.statistic = NULL;
       pvm_send_obj($master_tid, $USER_SLAVE_RESULT, info);
     }
   }
} while(0 != slave_next_task() );

pvm_ms_slave_exit(status);
exit(status);
`$, F); % fputs
  ()=fclose(F);
  ()=system("chmod u+x "+filename_slave);

  % starting slaves
  Pars_Left = Num_Params;
  variable slave_argvs = Array_Type[length(pars)];
  _for $1 (0, Num_Params-1, 1)  slave_argvs[$1] = [CWD + filename_slave, get_par_info(pars[$1]).name];
  tic;
  variable exit_status = pvm_ms_run_master(slave_argvs);

  % finished
  variable runtime = int(toc()); % runtime, in seconds
  print_stdout_and_file(1, strftime("finished on %Y-%m-%d %H:%M:%S", localtime(_time())));
  if(remove_slave)  ()=remove(filename_slave);

  variable hours = runtime mod (24*60*60);
  variable mins = hours mod 3600;
  print_stdout_and_file(1, sprintf("runtime: %dd %dh %dmin %dsec", runtime/86400, hours/3600, mins/60, mins mod 60));
  message("");

  foreach $1 (exit_status)
  { ()=fprintf(stdout_file, "------------------------------------------------------------------------\n%s: (exit_status %d)\n%S\n\n", $1.host, $1.exit_status, $1.stdout); }

  ()=fclose(stdout_file);

  % collect results
  variable results = struct {
             index     = Integer_Type[0],
             name      = String_Type[0],
             value     = Double_Type[0],
             min       = Double_Type[0],
             max       = Double_Type[0],
             conf_min  = Double_Type[0],
             conf_max  = Double_Type[0],
             buf_below = Double_Type[0],
             buf_above = Double_Type[0],
             tex       = String_Type[0],
           };
  variable name, v;
  foreach name, v (Limits) using ("keys", "values")
  {
    variable info = get_par_info(name);
    variable buf_below = (v[1]-info.min)/(info.max-info.min);
    variable buf_above = (info.max-v[2])/(info.max-info.min);
    results.index     = [results.index,     info.index];
    results.name      = [results.name,      name];
    results.value     = [results.value,     v[0]];
    results.conf_min  = [results.conf_min,  v[1]];
    results.conf_max  = [results.conf_max,  v[2]];
    results.min       = [results.min,       info.min];
    results.max       = [results.max,       info.max];
    results.buf_below = [results.buf_below, buf_below];
    results.buf_above = [results.buf_above, buf_above];
    results.tex       = [results.tex,       TeX_value_pm_error(v[0], v[1], v[2])];
    set_par(name, v[0]);
  }
  save_par(Best_filename);
  variable stat, FV = Fit_Verbose;
  Fit_Verbose = -1;
  ()=eval_counts(&stat);
  Fit_Verbose = FV;

  struct_filter(results, array_sort(results.index));
  pvm_fit_pars_last_results = results;
  fits_write_binary_table(logbasefilename+"_conf.fits", "pvm_fit_pars-results", results, struct {
    chi2 = stat.statistic,
    num_bins = stat.num_bins,
    n_var_pars = stat.num_variable_params,
    dof = stat.num_bins-stat.num_variable_params,
    chi2red = stat.statistic/(stat.num_bins-stat.num_variable_params)
  } );

  % write confidence file
  stdout_file = fopen(logbasefilename+"_conf.txt", "w");
  print_stdout_and_file(0, get_fit_fun());
  print_stdout_and_file(0, sprintf("(%10s <=) %10s < %38s < %10s (<= %10s)", "min.all.", "conf.min.", "parameter value", "conf.max.", "max.all."));
  for($1=0; $1<length(results.name); $1++)
    print_stdout_and_file(0, sprintf("(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s",
				      results.min[$1], results.conf_min[$1], results.name[$1], results.value[$1], results.conf_max[$1], results.max[$1],
				      100*results.buf_below[$1], 100*results.buf_above[$1], results.tex[$1]));
  print_stdout_and_file(0, sprintf("\nstatistic/dof = %f/%d = %f", stat.statistic, stat.num_bins-stat.num_variable_params, stat.statistic/(stat.num_bins-stat.num_variable_params)));
  ()=fclose(stdout_file);

  ifnot(qualifier_exists("verbose"))
  {
    ()=remove(logbasefilename+"_stdout.log");
    ()=remove(logbasefilename+"_initial.par");
  }

  return results;
}

