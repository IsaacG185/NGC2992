
%%% import("%%slmpi");
%%% require("%%fork_socket");

#ifeval __get_reference("rcl_mpi_init")!=NULL && __get_reference("fork_slave")!=NULL 


%  ==== already define SUBS   ===== %
private define kill_all_slaves ();
private define wait_for_slave_to_exit();
private define print_log();
private define init_setup();
private define clean_messages();
private define forked_conf();
private define mpi_gather_results();
private define mpi_write_conf_file();
private define get_fit_options_from_qualifiers();

% ================================================================ %
% #1: Initialize important variables know to ALL routines  ======= %
private variable n_param, mpi_host,mpi_rank;
private variable mpi_stdout_file;
private variable MPI_FINISHED = 0;
private variable MPI_ABORT = 0;
private variable MPI_TAG_STATE = 10;
private variable MPI_TAG_PARAMS = 20;
private variable MPI_READ_MESSAGES_TIME_INTERVAL = 0.01;
private variable MPI_USE_FORK=1;
% ================================================================ %

public define mpi_new_best_fit_hook();

%  =================================== %
private define client_main(pars,n_param)
%  ===================================  %
{
   variable info = get_params(pars);
   variable param = merge_struct_arrays(info).value;
   
   variable all_info = get_params();
   variable all_param = merge_struct_arrays(all_info).value;
   variable n_all_param = length(all_info);
   
   variable state = Integer_Type;
   variable i_param = pars[mpi_rank];
   variable master_has_best_fit=0;
   variable bufid;
   variable states = Integer_Type[n_param];

   variable level,tolerance,fitmethod;
   (level,tolerance,fitmethod) = get_fit_options_from_qualifiers(;;__qualifiers);
   set_fit_method(fitmethod);

   print_log(0,sprintf("Calculating Parameter < %s >",get_par_info(i_param).name));

   % ============  DO IT: the LOOP  ==================== %
   do
   {
      master_has_best_fit=0;
      % #1 === ALL === Calculate the Confidence Interval ================
      variable lo, hi,name;
      if (MPI_USE_FORK)  (lo, hi) = forked_conf (i_param,level,tolerance); %===  ALL  ====
      else               (lo, hi) = conf (i_param,level,tolerance);


      % #2 === new best fit found?  =====================================
      if( lo == hi && (rcl_mpi_iprobe_tag(MPI_TAG_PARAMS) == 0) )
      {
	 % store the new parameters in the variable
	 all_param = merge_struct_arrays(get_params()).value;

	 % exit slaves and program if anything went wrong on the
	 % conf-calculation
	 % XXX still need to find a better solution !!! XXX
	 if (lo==NULL) param[0] = DOUBLE_MAX;

	 variable stat;()=eval_counts(&stat;fit_verbose=-1);stat = stat.statistic;
	 if (hi!=NULL) 
	   print_log(0,sprintf(" ****** New Best Fit Found [chi2=%.2f]for < %s >: <%.4f>",stat,get_par_info(i_param).name,hi));
	 
	 % only send the values if NOT MASTER
	 if (rcl_mpi_master()) master_has_best_fit=1;  %  ====  MASTER  =====
	 else
	   {                                           %  ====  CLIENTS  ====
	      rcl_mpi_return_param(all_param,n_all_param,MPI_TAG_PARAMS);
	   }
      }
      else ifnot (rcl_mpi_master())                    %  ====  CLIENTS  ====
      {
	 rcl_mpi_return_state([0],1,MPI_TAG_STATE);
      }

     if (lo!=hi) print_log(0,sprintf(" < %s > finished: <%.4f,%.4f>",get_par_info(i_param).name,lo,hi));


      % #3a: MASTER test for new parameters             % ==== MASTER ==== %
      %     (only if parameters and not status sent !!! )
      if (rcl_mpi_master() && master_has_best_fit==0)
      {
	% master assumes everybody is still working
	% (as no messages were received yet)
	states[*]=1;
	% master is finshed (and does not have the a new best fit)
	states[rcl_mpi_rank_master()]=0;

	 % wait for parameters/messages from Clients
	 forever
	 {
	   if (rcl_mpi_iprobe())
	   {
	     variable RANK = rcl_mpi_status_src();
	     variable FLAG = rcl_mpi_status_tag();
	     if (FLAG == MPI_TAG_PARAMS)
	     {
	       rcl_mpi_recv_param(all_param,n_all_param);

		% XXXX check if any error occured: has to be fixed XXXXX
		% XXX still need to find a better solution !!! XXX
		if (param[0] == DOUBLE_MAX)
		  {
		     MPI_FINISHED=1;
		     print_log(0," ******* An Error Occured: Exiting mpi_fit_pars()!");
		  }
		
		clean_messages(n_all_param);
		break;
	     }
	     else if (FLAG == MPI_TAG_STATE)
	     {
	       variable mpi_rank_client = Integer_Type;
	       rcl_mpi_recv_state(&mpi_rank_client,1);

	       states[RANK]=0;
	       print_log(0,sprintf("Parameters left < %d >",int(sum(states)));single);

	       % jump out of the loop if all process are finished
	       % (i.e, == 0)
	       if (int(sum(states))==0)
	       {
		 MPI_FINISHED=1;
		 break;
	       }
	     }
	   }
	   else  sleep(MPI_READ_MESSAGES_TIME_INTERVAL);
	 }
      }  % ===================================================================== %


     % #4: SEND the PARAMS and STATE to the clients
     % === BCAST PARAMS  =============
      if (rcl_mpi_master()) rcl_mpi_dist_param(all_param,n_all_param,MPI_TAG_PARAMS);
      else  rcl_mpi_recv_param(all_param,n_all_param);
      rcl_mpi_barrier();

     % === BCAST STATE  =============
      variable bcast_int = [MPI_FINISHED];
      rcl_mpi_bcast_int(bcast_int,1);
      MPI_FINISHED = bcast_int[0];

      
      % XXXX check if any error occured: has to be fixed XXXXX
      % XXX still need to find a better solution !!! XXX
      if (param[0] == DOUBLE_MAX) MPI_ABORT=1;

      
      % #5a: === JUMP out of the loop if FINISHED
      if (MPI_FINISHED) break;

      % #5b: === reset everything and load new parameters for the NEXT ROUND
      % set the NEW PARAMETERS AND START ALL OVER
      variable i;
      _for i(0,n_all_param-1,1)
      {
	 all_info[i].value = all_param[i];
      }
      % ... and load them
      set_params(all_info);

      % =========  get rid of useless messages     % ==== MASTER ==== %
      if (rcl_mpi_master())
      {
	 % ====== Hook for saving Data %
	 mpi_new_best_fit_hook();
	 clean_messages(n_all_param);
      }


   } while (MPI_FINISHED != 1);
  % =================================================== %

   if (MPI_ABORT) return NULL,NULL;

   variable b_lo = Double_Type[n_param];
   variable b_hi = Double_Type[n_param];
   b_lo[*] = 0;
   b_hi[*] = 0;

   lo = [lo]; hi = [hi];
   rcl_mpi_gather_conf(lo,hi,b_lo,b_hi,n_param);
   ifnot (rcl_mpi_master()) {b_lo=NULL;b_hi=NULL;}

   rcl_mpi_barrier();
   return b_lo,b_hi;
}






%  ===================================  %
define mpi_fit_pars()
%  ===================================  %
%!%+
%\function{mpi_fit_pars}
%\synopsis{computes confidence intervals using MPI}
%\usage{Struct_Type results = mpi_fit_pars([Integer_Type pars[]]);}
%\description
%    The function \code{mpi_fit_pars} is designed to provide a similar
%    interface then \code{pvm_fit_pars}, written by M. Hanke for the
%    isis-scripts. Please pay special attention to the notes marked IMPORTANT
%    below.
%
%    \code{pars} is an array of parameters, for which the confidence levels are to be fitted.
%    If \code{pars} is not specified, all free parameters of the current model are used.
%    The best fit which is eventually found is always saved in
%    <\code{dir}>/<\code{basefilename}>\code{_best.par}; the confidence limits are
%    written in plain-text to <\code{dir}>/<\code{basefilename}>\code{_conf.txt} and as a
%    FITS table to <\code{dir}>/<\code{basefilename}>\code{_conf.fits}.
%
%    The verbosity of \code{mpi_fit_pars} is controlled by the intrinsic variable \code{Fit_Verbose}.
%
%    The return value \code{results = struct { index, name, value, min, max, conf_min, conf_max, buf_below, buf_above, tex }}
%    is a table with the following information for each parameter:\n
%    \code{min} and \code{max} are the minimum/maximum values allowed.
%    \code{conf_min} and \code{conf_max} are the confidence limits.
%    \code{buf_below} (\code{buf_above}) is the fraction of the allowed range \code{[min:max]}
%    which seperates the lower (upper) confidence limit from \code{min} (\code{max}).
%    If one of these buffers is 0, your confidence interval has bounced.
%
%    Perhaps more usefully, this information is written to the files
%    <\code{dir}>/<\code{basefilename}>\code{_conf.txt} and
%    <\code{dir}>/<\code{basefilename}>\code{_conf.fits}.  In case of any
%    error, the return value is \code{NULL}. If run via slurm/torque, these
%    files will only be written by the host node once all threads have
%    completed - i.e., there's no danger of the results being written by
%    several machines at the same time.
%
%    NOTE: The function "mpi_new_best_fit_hook()" can be defined by the
%    user. This function will be called whenever a new best fit is found. This
%    can be used to, e.g, store the newly found best fit (although the usual
%    caveats about writing files to disk while running via MPI still apply...).
%
%    IMPORTANT: Rember that the whole script containing the call
%    "mpi_fit_pars()" is typically run on N > 1 computers. Therefore only the
%    *minimum* amount of code necessary to run mpi_fit_pars() should be
%    included in the script.
%
%    IMPORTANT: This function relies on MPI. This means that it only
%    works when started externally via, e.g., \code{mpiexec isis-script
%    my_script.sl} or via a slurm jobfile. Slurm or mpiexec must be able to
%    start as many processes as you have parameters for which you want to
%    calculate confidence limits (e.g., if you want error bars on four
%    parameters, you need four tasks - no more, no less).
%
%    IMPORTANT: This code is still in <beta> test. It might happen
%    that the function ends unexpectedly.
%\qualifiers{
%\qualifier{level}{confidence level to be computed.
%             As for conf, 0 means 68%, 1 means 90% [default], and 2 means 99% confidence level.}
%\qualifier{tolerance}{the tolerance for chi^2 improvements without interrupting the search
%                 for the confidence intervals, see \code{help("conf");}. The default is \code{1e-3}.}
%\qualifier{fitmethod}{fit-method to be used, see \code{help("set_fit_method");}
%                 Default is the currently used fit-method returned by \code{get_fit_method()}.}
%\qualifier{dir}{[="."] specifies the directory in which the logfiles shall be stored.
%                  It may be a relative path to the current working directory.}
%\qualifier{basefilename}{[=startdate]}
%\qualifier{verbose}{Files with the stdout and the inital parameters are kept after program
%                     is finished. }
%\qualifier{forked}{[=0] Use a separate (forked) process to
%                  calculate the confidence levels. It speeds up the calculation, but
%                  might cause troubles for models which write files to disk, as this
%                  process is killed  immediatelly when asked to restart
%                  calculation and not stopped smoothly. This option can also
%                  cause your job to be killed if run via slurm, as it requests
%                  additional threads beyond those allocated by slurm.  }
%\qualifier{do_not_finalize}{if set, "mpi_finalize()" is not called
%                  within the routine. In this case the code following the
%                  mpi_fit_pars() call will be executed on *all* nodes. Only the
%                  master process will return the confidence structure (see above);
%                  all other processes will return NULL. This can be used to start
%                  more than one mpi_fit_pars() in one script. Only use it for very
%                  quick evaluations and if you *know that you're doing*. At the end
%                  of such an script, it is important to call "mpi_finalize()" manually.}
%\example
%     % EXAMPLE 1
%     % Simple script for confidence level calcualtion with mpi_fit_pars()
%     variable id = load_data("my_data.pha");   % load the data
%     xnotice_en(id,0.5,16);                    % initialize data
%     load_par("my_best_fit.par");
%
%     variable result = mpi_fit_pars(pars);     % do calculation for pars[]
%     fits_save_fit("result.fits",result);      % save all information
%                                               % to disk
%                                               % Note that mpi_fit_pars() alone will save information to disk,
%                                               % by default in files named <date>_best.par, <date>_conf.txt,
%                                               % and <date>_conf.fits
%
%     % EXAMPLE 2 - Uses slurm to schedule jobs on the Remeis cluster.
%     % This requires two files - mpi_fit.sl, containing the ISIS code to be
%     % executed, and mpi_fit.slurm, containing the job specification for slurm.
%     % This would be run by calling "sbatch mpi_fit.slurm" at the command line.
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % ISIS script (mpi_fit.sl)
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     variable id = load_data("my_data.pha");   % load the data
%     xnotice_en(id,0.5,16);                    % initialize data
%     load_par("my_best_fit.par");
%     variable pars = [1,2];                    % obviously you will pick whatever parameters you need here
%     () = mpi_fit_pars(pars;                   % Do the confidence limit calculations. Results will be saved to
%       basefilename="my_fit");                 % "my_fit_conf.fits","my_fit_conf.txt", and "my_fit_best.par".
%                                               % Note that unlike the above example, we do not manually save
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            % the results to a file - mpi_fit_pars does this on its own.
%     % Jobfile (mpi_fit.slurm)
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     #!/bin/bash
%     #SBATCH --job-name my_fit                 # name of the job to be run by slurm
%     #SBATCH --time 00:10:00                   # You might need more (or less) time.
%     #SBATCH --ntasks 2                        # we want erors on two parameters (see above), so we need 2 cores
%     #SBATCH --mem-per-cpu 1G                  # 1 gig of memory per core (tweak to your liking)
%     srun /usr/bin/nice -n +19 isis mpi_fit.sl # run the script with srun (and nice +19 because you don't 
%                                               # want to bog down someone else's machine)
%                                               
%}
%\seealso{fit_pars; conf, set_fit_method, pvm_fit_pars}
%!%-
{
   variable status = 1;
   variable SetupFile=NULL, pars = NULL;
   MPI_USE_FORK = qualifier("forked",0);

   switch(_NARGS)
   {case 0: pars = NULL;
%      if(length(glob("init.sl"))>0) { SetupFile = "init.sl"; }
%      if(length(glob("loaddata.sl"))>0) { SetupFile = "loaddata.sl"; }
%      if(SetupFile==NULL) { help(_function_name()); return; }
%      message(_function_name()+": using SetupFile " + SetupFile);
   }
   { case 1:  pars = (); }
%   { case 2: (SetupFile, pars) = (); }
   { help(_function_name()); return; }

   % log file:
   variable dir = qualifier("dir", ".");
   variable startdate = strftime("%Y-%m-%d_%H:%M:%S", localtime(_time()));
   variable basefilename = qualifier("basefilename", startdate);
   variable logbasefilename = dir + "/" + basefilename;
   variable Best_filename = logbasefilename+"_best.par";
   variable logbasefilename_stdout = logbasefilename+"_stdout.log";
   mpi_stdout_file = fopen(logbasefilename_stdout, "w");

   % are there enough MPI processes available?
   %  ===  2 === initialize MPI  =========================================================
   if ( rcl_mpi_init() < 0) { print_log(0,"MPI could not be initialzied. Exiting ..."); status = 0; return NULL;}

   % initialize variables depending on the single hosts
   pars = init_setup(pars);

   % check the number of parameters
   if (n_param < 2)
   { status=0;
      if (rcl_mpi_master()) print_log(0,sprintf("Only %d free parameter(s); no caculation with N < 2 is possible.",n_param);single);
   }

   if (rcl_mpi_numtasks() != n_param )
   { status=0;
      if (rcl_mpi_master()) print_log(0,sprintf("MPI Tasks (%d) not equal to # parameters (%d).",rcl_mpi_numtasks(), n_param);single);
   }
   if ( status != 1 )
   {
      if (rcl_mpi_master()) print_log(0,"MPI can not be set up. Exiting mpi_fit_pars ...";single);
      rcl_mpi_finalize();
      return NULL;
   }


  %  ===  3  ===
  % start the single processes, if everything is set up correctly
  if (rcl_mpi_rank() == 0) print_log(0,"Starting "+string(rcl_mpi_numtasks())+ " MPI tasks ... ";single);

  %  ===== MAIN ===========  %
  variable conf_lo,conf_hi;
   (conf_lo,conf_hi) = client_main(pars,n_param;;__qualifiers);

   % if something went wrong; quit immediatelly
   if (MPI_ABORT)
   {
      rcl_mpi_finalize();
      return NULL;
   }
   
   % QUIT all other processes except the MASTER
   ifnot (qualifier_exists("do_not_finalize"))
   {
      rcl_mpi_finalize();
      ifnot (rcl_mpi_master()) { exit(1);}
   }


   %  ===  5  ===  Build Resulting Structure
   variable results = NULL;
   if (rcl_mpi_master())
   {
      save_par(Best_filename);
      results = mpi_gather_results(pars,conf_lo,conf_hi);

      variable stat;()=eval_counts(&stat;fit_verbose=-1);
      fits_write_binary_table(logbasefilename+"_conf.fits", "pvm_fit_pars-results", results, struct {
	 chi2 = stat.statistic,
	 num_bins = stat.num_bins,
	 n_var_pars = stat.num_variable_params,
	 dof = stat.num_bins-stat.num_variable_params,
	 chi2red = stat.statistic/(stat.num_bins-stat.num_variable_params)
      } );


      mpi_stdout_file = fopen(logbasefilename+"_conf.txt", "w");
      mpi_write_conf_file(results,stat,logbasefilename);
      ()=fclose(mpi_stdout_file);

      ifnot(qualifier_exists("verbose"))
      {
	 ()=remove(logbasefilename+"_stdout.log");
	 ()=remove(logbasefilename+"_initial.par");
      }

   }
   return results;
}



% ================================================== %
% ==============   SUBS   ========================== %
% ================================================== %

% =============   FORKED SLAVES  =================== %
private define mpi_slave_fun(s,lo,hi,i,level,tolerance)
{
   variable e;
   try(e)
   {
      (lo,hi) = conf(i,level,tolerance);
   }
   catch AnyError:
   {
      print_log(0,e.message);
      lo = NULL; hi = NULL;
   } 

   send_objs(s,lo,hi,get_params);

   return 0;
}

private define fork_probe_status(s)
{
   variable status = select(s.sock,NULL,NULL,0);
   if (status != NULL && status.nready) return 1;
   return 0;
}

%  ===================================  %
private define forked_conf(i_param,level,tolerance)
%  ===================================  %
{
   variable lo=NULL,hi=NULL;
   variable param = get_params();

   () = new_slave_list;
   variable s = fork_slave(&mpi_slave_fun,lo,hi,i_param,level,tolerance);

   forever
   {
      if ( rcl_mpi_iprobe_tag(MPI_TAG_PARAMS))
      {
	 break;
      }
      else if (fork_probe_status(s))
      {
	 variable obs = recv_objs(s);
	 lo = obs[0]; hi = obs[1];
	 param=obs[2];	 set_params(param);
	 break;
      }
      else
      {
	 sleep(MPI_READ_MESSAGES_TIME_INTERVAL);
      }
   }
   % end slave here !
   kill_all_slaves(s);

%   if (lo!= NULL) () = print_log(0,sprintf("Returned value from forked_conf: <%.3f , %.3f>",lo,hi));

   return lo,hi;
}

private define wait_for_slave_to_exit(s)
{
   variable w;
   do
   {
      w = waitpid (s.pid, WNOHANG|WUNTRACED);
   } while (w.pid == 0);

   return;
}

private define kill_all_slaves (slaves)
{
   variable s;
   foreach s (slaves)
   {
      if (kill (s.pid, 0) == 0)
      {
	 if (kill (s.pid, SIGTERM) == 0)
	   wait_for_slave_to_exit(s);
      }
      s.status = SLAVE_EXITED;
      s.sock = NULL;
      s.fp = NULL;
   }
   return;
}


%  =================================== %


private define clean_messages(n_param)
{
   variable dump = Double_Type[n_param];
   variable i_dump = Double_Type;
   while(rcl_mpi_iprobe()>0)
   {
      if (rcl_mpi_iprobe_tag(MPI_TAG_PARAMS)) { rcl_mpi_recv_param(dump,n_param); }
      else if (rcl_mpi_iprobe_tag(MPI_TAG_STATE)) {rcl_mpi_recv_state(&i_dump,1); }
   }
}


public define isis_fit_improved_hook()
{
   if (MPI_USE_FORK) return 0;  % always return normally when using the FORK method

   if ( rcl_mpi_iprobe_tag(MPI_TAG_PARAMS))
   {
      return 1;
   }
   return 0;
}


private define init_setup(pars)
{
   mpi_rank = rcl_mpi_rank();
   mpi_host = uname.nodename;

   % if not specified differently: use all free parameters
   if (pars == NULL) pars = freeParameters();


   variable p = get_params(pars);
   n_param = (p!= NULL)?length(p):0;

   return pars;
}


private define print_log(thres, s)
{
   variable msg;
   variable t = strftime("%Y-%m-%d_%H:%M:%S", localtime(_time()));
   if (qualifier_exists("single")) msg= "%s\n"$;
   else msg= "@$mpi_host-$mpi_rank($t): %s\n"$;

   if(Fit_Verbose >= thres)  () = printf(msg,s);
  ()=fprintf(mpi_stdout_file, msg, s);
  ()=fflush(mpi_stdout_file);
}




%  GATHER the INFORMATION

private define mpi_gather_results(pars,conf_min,conf_max)
{
  variable info = get_params(pars);

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
  variable i,d,cmin,cmax;
  _for i(0,n_param-1,1)
  {
    d = info[i]; cmin = conf_min[i]; cmax = conf_max[i];

    variable buf_below = (cmin-d.min)/(d.max-d.min);
    variable buf_above = (d.max-cmax)/(d.max-d.min);
    results.index     = [results.index,     d.index];
    results.name      = [results.name,      d.name];
    results.value     = [results.value,     d.value];
    results.conf_min  = [results.conf_min,  cmin];
    results.conf_max  = [results.conf_max,  cmax];
    results.min       = [results.min,       d.min];
    results.max       = [results.max,       d.max];
    results.buf_below = [results.buf_below, buf_below];
    results.buf_above = [results.buf_above, buf_above];
    results.tex       = [results.tex,       TeX_value_pm_error(d.value, cmin, cmax)];
  }

  return results;
}

private define mpi_write_conf_file(results,stat,logbasefilename)
{
   % write confidence file
   print_log(-1, get_fit_fun();single);
   print_log(-1, sprintf("(%10s <=) %10s < %38s < %10s (<= %10s)", "min.all.", "conf.min.", "parameter value", "conf.max.", "max.all.");single);
   for($1=0; $1<length(results.name); $1++)
     print_log(-1, sprintf("(%10g <=) %10g < %25s = %10g < %10g (<= %10g)   [%4.1f%% (conf)%5.1f%%]   %s",
			  results.min[$1], results.conf_min[$1], results.name[$1], results.value[$1], results.conf_max[$1], results.max[$1],
			  100*results.buf_below[$1], 100*results.buf_above[$1], results.tex[$1]);single);
   print_log(-1, sprintf("\nstatistic/dof = %f/%d = %f",
			stat.statistic, stat.num_bins-stat.num_variable_params, stat.statistic/(stat.num_bins-stat.num_variable_params));single);
   return;
}




private define  get_fit_options_from_qualifiers()
{
   variable level = qualifier("level", 1);
   if(all(level!=[0:2]))
   {
      message("warning ("+_function_name()+"): level has to be 0 (68%), 1 (90%), or 2 (99%).\nUsing default level = 1.");
      level = 1;
   }
   if(level==NULL) { level = 1; }
   variable tolerance = qualifier("tolerance", 1e-3);
   variable fitmethod = qualifier("fitmethod", get_fit_method());
   return level,tolerance,fitmethod;
}

#endif
