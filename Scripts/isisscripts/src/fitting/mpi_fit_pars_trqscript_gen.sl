%%%%%%%%%%%%%%%%%%%%%%%%%%%
define mpi_fit_pars_trqscript_gen(){
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{mpi_fit_pars_trqscript_gen}
%\synopsis{Creates torque scripts for derivation of confidence intervals}
%\usage{mpi_fit_pars_trqscript_gen(String_Type fitfile, String_Type resultfile, String_Type scriptfile)}
%\description
%    This function generates 1) an executable S-Lang file
%    that is loading a previous fit saved with \code{fits_save_fit}, 
%    calling \code{mpi_fit_pars} with the current number of free parameters
%    and saving the result via \code{fits_save_fit} and \code{save_pars},
%    2) writing the .cmd and 3) the .cmd.job file
%    that can be submitted to Torque via 'qsub *.cmd.job'.
%
%    If only two arguments are given
%    (the resultfile and the scriptfile), the function expects
%    that you want to calculate the uncertainties out of isis
%    In that case the function will itself save the fit to a
%    file in the results-directory. When mpi_fit_pars is finished,
%    you have to delete it by your own.
%
%    ATTENTION: make sure that the min/max parameter borders
%    are set wide enough in your previous fit but still with
%    a reasonable width to allow mpi to find the best fit and
%    ncertainties in a reasonable amount of time.
%
%    NOTE: All given qualifiers are passed to the function
%    fits_load_fit. 
%\qualifiers{
%\qualifier{walltime}{[="00:30:00"]: String_Type, wallime for the torque}
%\qualifier{ROC}{Rmf OGIP Compliance (see fits_load_fit}
%\qualifier{submit}{1-submit to torque, 0-only create job files}%
%}
%\example
%    isis>
%
%    isis> mpi_fit_pars_trqscript_gen("input.fits","result.fits","trq_scripts/mpi_script.sl";
%                                      walltime="01:00:00")
%    OR 
%    isis> mpi_fit_pars_trqscript_gen("result.fits","trq_scripts/mpi_script.sl";
%                                      walltime="01:00:00")
%
%    THEN
%    
%    qsub trq_scripts/mpi_script.cmd.job
%
%\seealso{fits_save_fit, mpi_fit_pars, fits_list_fit_pars}
%!%-

  variable fitfile,resultfile,scriptfile,parfile,year,month,day,hr,mn,sc;
  switch(_NARGS)
  { case 2:  (resultfile,scriptfile) = (); }    
  { case 3:  (fitfile,resultfile,scriptfile) = (); }
  { help(_function_name()); return; }
  
  variable walltime = qualifier("walltime", "00:30:00");
  variable submit = qualifier("submit",0);
  variable logdir = path_dirname(resultfile);

  % create directories if non existing
  system(sprintf("mkdir -p %s %s",path_dirname(resultfile), path_dirname(scriptfile)));
  
  sc = string(localtime(_time).tm_sec);
  mn = string(localtime(_time).tm_min);
  hr = string(localtime(_time).tm_hour);
  day = string(localtime(_time).tm_mday);
  month = string(localtime(_time).tm_mon+1);
  year = string(localtime(_time).tm_year+1900);
  
  %   /////////////////////////
  %  //// SCRIPT GENERATOR ///
  % /////////////////////////
  
  % I    err scripts for all obsid's
  % II   cmd script for trq combining all err calc scripts
  % III  job script out of cmd script for torque ('qsub xxx.cmd.job')
  
  variable i,j,f,cmd,fitfun,freePars,job,roc_arr,strct,roc_strng;

  % initialize files
  f = fopen(scriptfile, "w");
  cmd = fopen(strreplace(scriptfile,".sl",".cmd"), "w");

  switch(_NARGS)
  { case 2: fits_save_fit(path_dirname(resultfile)+"/fit_tmp.fits"); fitfile=path_dirname(resultfile)+"/fit_tmp.fits";}
  
  % load attempt file
  ()=fits_load_fit(fitfile;; __qualifiers() );
  variable roc = __qualifiers().ROC;
  fitfun = get_fit_fun;
  
  %    if (is_substr(fitfun,"pexrav") > 0){
  %      % to file
  %      fputs(sprintf("fit_fun(\"%s\");\n", fitfun), f);
  %      fputs("__set_hard_limits (\"pexrav(1).rel_refl\",-1,1e6);\n\n", f);
  %      % execute here for getting freePars
  %      fit_fun(sprintf("%s", fitfun));
  %      __set_hard_limits("pexrav(1).rel_refl",-1,1e6);
  %      }
  
  % write to mpi_fit_pars exec file ----------------------------------------------------------------------
  roc_strng="[";
  for (i=0;i<length(roc);i++){
    if (i!=length(roc)-1) roc_strng+=string(roc[i])+",";
    if (i==length(roc)-1) roc_strng+=string(roc[i]);
  }
  roc_strng+="]";
  ()=fputs(sprintf("fits_load_fit(\"%s\";ROC=%s);\n\n", fitfile,roc_strng), f);
  freePars = length(freeParameters);
  
  % ERROR CALCULATION VIA MPI
  ()=fputs("variable pars = freeParameters;\n", f);
  ()=fputs(sprintf("system(\"mkdir -p %s/logdir/\");\n", logdir), f);
  ()=fputs(sprintf("variable result = mpi_fit_pars(pars; verbose, dir=\"%s/logdir/\");\n", logdir), f);
  ()=fputs(sprintf("fits_save_fit(\"%s\",result);\n",resultfile), f);
  parfile = strreplace(resultfile,".fits",".par");
  ()=fputs(sprintf("save_par(\"%s\");", parfile), f);
  ()=fclose(f);
  % ------------------------------------------------------------------------------------------------------
  
  % write to command file --------------------------------------------------------------------------------
  ()=fputs(sprintf("mpiexec isis-script %s\n",scriptfile), cmd);
  % ------------------------------------------------------------------------------------------------------

  
  % write job script -------------------------------------------------------------------------------------
  job = fopen(strreplace(scriptfile,".sl",".cmd.job"), "w");
  ()=fputs("#!/bin/bash\n", job);
  ()=fputs("#\n", job);
  ()=fputs("#PBS -S /bin/bash -V\n", job);
  ()=fputs("#PBS -t 0-0%10000\n", job);
  ()=fputs(sprintf("#PBS -l nodes=%d\n", freePars), job);
  ()=fputs(sprintf("#PBS -l walltime=%s\n", walltime), job);
  ()=fputs(sprintf("#PBS -N %s\n", strreplace(scriptfile,".sl",".cmd")), job);
  ()=fputs(sprintf("#PBS -o /tmp/pbs/beuchert/err_calc_%s-%s-%s_%s:%s:%s.cmd.out\n",year,month,day,hr,mn,sc), job);
  ()=fputs(sprintf("#PBS -e /tmp/pbs/beuchert/err_calc_%s-%s-%s_%s:%s:%s.cmd.err\n",year,month,day,hr,mn,sc), job);
  ()=fputs("export HOST=hostname\n\n", job);
  ()=fputs("export HOSTNAME=$HOST\n\n\n", job);
  ()=fputs(sprintf("COMMAND[0]=\"mpiexec isis-script %s\"\n", scriptfile), job);
  ()=fputs("/usr/bin/nice -n +15 ${COMMAND[$PBS_ARRAYID]}\n", job);
  ()=fclose(job);
  % ------------------------------------------------------------------------------------------------------
  
  delete_data(1);
  delete_arf(1);
  delete_rmf(1);
  
  ()=fclose(cmd);

  if (submit == 1) system(sprintf("qsub %s",strreplace(scriptfile,".sl",".cmd.job")));

}
