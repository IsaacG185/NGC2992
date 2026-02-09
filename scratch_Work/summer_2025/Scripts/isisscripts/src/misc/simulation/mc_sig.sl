require( "rand" );

%%%%%%%%%%%%%%%%%%%%%
define mc_sig()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{mc_sig}
%\synopsis{calculates the significance of a spectral component doing a Monte Carlo (MC) simulation}
%\usage{Struct_Type mc_sig(String_Type withComponent.fits, String_Type withoutComponent.fits);
% or Struct_Type mc_sig(String_Type torqueDir);}
%\qualifiers{
%    \qualifier{mcruns}{number of MC loops (default: 10)}
%    \qualifier{beforeData}{script to be called before any data is loaded (default: NULL)}
%    \qualifier{afterData}{script to be called after the data have been loaded (default: NULL)}
%    \qualifier{beforeFit}{array of scripts to be called right before a fit of faked data to
%                 the model without [0] and with [1] the component (default: NULL)}
%    \qualifier{id}{override the dataset ID(s) after fits_load_fit with the given one(s)}
%    \qualifier{ignbinning}{do not apply the same binning after faking the data}
%    \qualifier{ignnotice}{do not use the same energy ranges after faking the data}
%    \qualifier{torque}{calculate significance using given number of torque jobs, i.e., total
%                 number of runs = mcruns*torque (default: 0, i.e., don't use torque)}
%    \qualifier{walltime}{walltime of each torque job in minutes (default: 3 minutes times
%                 number of MC runs per job)}
%    \qualifier{dontSubmit}{do not submit the torque job-file (implies qualifier 'dontwaint')
%                 (default: submit)}
%    \qualifier{dontWait}{do not wait on the the torque jobs to complete (implies qualifier
%                 'dontClean') (default: wait)}
%    \qualifier{torqueDir}{temporary directory to save necessary torque files
%                 NOTE: this directory will be deleted afterwards completely!
%                 (default: ~/.isis_mc_sig/)}
%    \qualifier{dontClean}{do not delete temporary torque directory afterwards}
%    \qualifier{chatty}{a number >0 means more chatty (default: 0)}
%    \qualifier{ }{additional qualifiers are passed to fits_load_fit}
%}
%\description
%    This function calculates the significance of a spectral component
%    found in real data. During each Monte Carlo loop, spectra data
%    without the component are simulated (for each detector) and this
%    data are then fitted with a model containing the component (that
%    needs to be tested for) and separately fitted with a model without
%    it.
%    The resulting simulated differences in chi square between these
%    fits are returned and compared to the measured difference: the
%    number of simulated chi squares below the measured one corresponds
%    to the significance, that the spectral component is real (i.e. in
%    80 cases out of 100 runs the simulated chi square difference is
%    below the measured chi square difference, the significance is 80%).
%
%    If two FITS-files created with fits_save_fit are provided, the
%    first includes the model "with" the component to be tested and
%    the second one "without" it.
%
%    If only one argument is given, this has to be a temporary directory
%    with results of a previous torque run (e.g. if "dontWait" was set).
%    The function tries to collect and return the results as usual.
%
%    The returned structure is defined as follows:
%      readdchisqr  - the measured difference in chi square
%      fakedchisqr  - an array of simulated differences in chi square
%      nfalse       - the number of detected false positives
%      significance - the resulting significance as defined above
%\example
%    % FITS-files created by fitting a cutoffpl and iron line to
%    % RXTE-PCA, -HEXTE and Swift-XRT data (Rmf_OGIP_Compliance = 0 to
%    % load XRT data, see help of fits_load_fit)
%    sig = mc_sig("rxte_swift_cutoffpl_ironline.fits",
%                 "rxte_swift_cutoffpl.fits";
%                 mcruns = 1, ROC = [2,2,0],
%                 beforeData = "defineMyModels.sl",
%                 afterData = "setDataHooks.sl",
%                 chatty = 2);
%\seealso{fits_save_fit, fits_load_fit, fakeit}
%!%-
{
  variable withFits, woFits;
  switch (_NARGS)
    % try to collect results from a previous torque run
    { case 1: withFits = ();
      % check if all files are there
      ifnot (access(withFits, X_OK) == 0 && access(sprintf("%s/collect.sl", withFits), F_OK) == 0
          && access(sprintf("%s/mc_sig.sl", withFits), F_OK) == 0 && access(sprintf("%s/torque.job", withFits), F_OK) == 0) {
	vmessage("error (%s): %s does not contain the necessary files", _function_name, withFits); return;
      }
      % collect and return the result
      () = evalfile(sprintf("%s/collect.sl", withFits));
      return eval("collect;");
    }
    { case 2: (withFits, woFits) = (); }
    { help(_function_name); return; }

  variable mcruns = qualifier("mcruns", 100);

  % additional loading scripts and qualifiers
  variable beforeData = qualifier("beforeData", NULL);
  variable afterData = qualifier("afterData", NULL);
  variable beforeFit = qualifier("beforeFit", NULL);
  variable chatty = qualifier("chatty", 0); if (chatty == NULL) chatty = 1;
  variable torque = qualifier("torque", NULL);

  % some error handling
  if (access(withFits, F_OK) != 0) { vmessage("error (%s): %s not found", _function_name, withFits); return; }
  if (access(woFits, F_OK) != 0) { vmessage("error (%s): %s not found", _function_name, woFits); return; }
  if (mcruns < 1) { vmessage("error (%s): number of MC runs has to be greater zero", _function_name); return; }
  if (torque != NULL && torque < 1) { vmessage("error (%s): number of torque jobs has to be greater zero", _function_name); return; }
  if (beforeData != NULL) {
    if (typeof(beforeData) != String_Type) { vmessage("error (%s): beforeData has to be of String_Type", _function_name); return; }
    if (access(beforeData, F_OK) != 0) { vmessage("error (%s): beforeData (%s) not found", _function_name, beforeData); return; }
  }
  if (afterData != NULL) {
    if (typeof(afterData) != String_Type) { vmessage("error (%s): afterData has to be of String_Type", _function_name); return; }
    if (access(afterData, F_OK) != 0) { vmessage("error (%s): afterData (%s) not found", _function_name, afterData); return; }
  }
  if (beforeFit != NULL) {
    if (length(beforeFit) != 2) { vmessage("error (%s): beforeFit has to be an array containing exactly two file names", _function_name); return; }
    if (_typeof(beforeFit) != String_Type) { vmessage("error (%s): beforeFit has to be an array of String_Type", _function_name); return; }
    variable i; _for i (0, 1, 1) {
      if (access(beforeFit[i], F_OK) != 0) { vmessage("error (%s): beforeFit[%d] (%s) not found", _function_name, i, beforeFit[i]); return; }
    }
  }

  % get the real delta chi square
  variable statWith = fits_read_col(withFits, "chi")[0];
  variable statWO = fits_read_col(woFits, "chi")[0];
  variable realdchisqr = statWO - statWith;
  if (chatty) vmessage("measured delta chi square = %.2f", realdchisqr);
  variable dchisqr; % will contain the simulated chi squares

  %% WRITE TORQUE JOB-SCRIPT %%
  if (torque) {
    variable walltime = qualifier("walltime", 3*mcruns);
    if (walltime < 0) { vmessage("error (%s): walltime has to be greater zero", _function_name); return; }

    % create the temporary torque directory
    variable torquedir = qualifier("torqueDir", NULL);
    if (torquedir == NULL) {   
      % get current user
      variable user, pp = popen("whoami", "r");
      ()=fgets(&user, pp);
      ()=pclose(pp);
      user = strreplace(user, "\n", "");
      torquedir = sprintf("/home/%s/.isis_mc_sig", user);
    }
    ()=system(sprintf("mkdir -p %s/log", torquedir));
    
    if (chatty) message("writing torque job-script and -file");

    % get current directory
    variable pwd;
    pp = popen("pwd", "r");
    ()=fgets(&pwd, pp);
    ()=pclose(pp);
    pwd = strreplace(pwd, "\n", "");

    % write calculation script
    variable scriptstring = "";
    scriptstring += "require(\"isisscripts\");\n";
    scriptstring += "seed_random(atoi(__argv[-2]));\n";
    scriptstring += "variable torquedir = path_dirname(__argv[-3]);\n";
    scriptstring += sprintf("variable sig = mc_sig(\"%s\", \"%s\"; mcruns = %d", withFits, woFits, mcruns);
    if (beforeData != NULL) scriptstring += sprintf(", beforeData = \"%s\"", beforeData);
    if (afterData != NULL) scriptstring += sprintf(", afterData = \"%s\"", afterData);
    if (beforeFit != NULL) scriptstring += sprintf(", beforeFit = [\"%s\", \"%s\"]", beforeFit[0], beforeFit[1]);
    % handle the additional qualifiers to fits_load_fit
    variable q;
    foreach q (get_struct_field_names(__qualifiers)) {
      if (wherefirst(q == ["mcruns","beforeData","afterData","beforeFit","torque","walltime","dontSubmit","dontWait","torqueDir","dontClean","chatty"]) == NULL) {
	scriptstring += sprintf(", %s", q);
	if (q == "ROC") scriptstring += sprintf(" = [%s]", strjoin(array_map(String_Type, &sprintf, "%d", get_struct_field(__qualifiers, q)), ","));
      }
    }
    scriptstring += ");\n";
    scriptstring += "fits_write_binary_table(sprintf(\"%s/run%s.fits\", torquedir, __argv[-1]), , struct { fakedeltachisqr = sig.fakedeltachisqr });\n";
    variable fp = fopen(sprintf("%s/mc_sig.sl", torquedir), "w+");
    ()=fputs(scriptstring, fp);
    ()=fclose(fp);

    % write collection script
    if (qualifier_exists("dontWait") || qualifier_exists("dontSubmit")) {
      scriptstring = "";
      scriptstring += "variable collect = struct {\n";
      scriptstring += sprintf("  realdeltachisqr = %f,\n", realdchisqr);
      scriptstring += sprintf("  fakedeltachisqr = merge_struct_arrays(array_map(Struct_Type, &fits_read_table, glob(\"%s/*.fits\"))).fakedeltachisqr,\n", torquedir);
      scriptstring += sprintf("  nfalse = 0,\n");
      scriptstring += sprintf("  significance = 0.\n");
      scriptstring += "};\n";
      scriptstring += "variable runs = length(collect.fakedeltachisqr);\n";
      scriptstring += sprintf("if (runs != %d) {\n", torque*mcruns);
      scriptstring += sprintf("  vmessage(\"warning (%%s): there are results missing (found %%d, should be %d)\", _function_name, runs);\n", torque*mcruns);
      scriptstring += "}\n";
      scriptstring += "collect.nfalse = length(where(collect.fakedeltachisqr >= collect.realdeltachisqr));\n";
      scriptstring += "collect.significance = 1. - (collect.nfalse == 0 ? 1./runs : 1.*collect.nfalse/runs);\n";
      scriptstring += "vmessage(\"false positives = %d\", collect.nfalse);\n";
      scriptstring += "vmessage(\"-> significance %s %.3f\", collect.nfalse == 0 ? \">=\" : \"=\", collect.signif);\n";
      
      fp = fopen(sprintf("%s/collect.sl", torquedir), "w+");
      ()=fputs(scriptstring, fp);
      ()=fclose(fp);
    }
    
    % write jobfile
    variable jobstring = "";
    jobstring += "#!/bin/bash\n#\n";
    jobstring += "#PBS -S /bin/bash -V\n";
    jobstring += sprintf("#PBS -t 0-%d%%10000\n", torque-1);
    jobstring += "#PBS -l nodes=1\n";
    jobstring += "#PBS -l arch=x86_64\n";
    jobstring += sprintf("#PBS -l walltime=00:%02d:00\n", walltime);
    jobstring += "#PBS -N mc_sig\n";
    jobstring += sprintf("#PBS -o %s/log/out\n", torquedir);
    jobstring += sprintf("#PBS -e %s/log/err\n", torquedir);
    jobstring += "export HOST=`hostname`\n";
    jobstring += "export HOSTNAME=$HOST\n\n";
    jobstring += sprintf("cd %s\n", pwd);
#ifexists rand
    variable random_nrs = rand(torque);
#else
    variable random_nrs = typecast (urand(torque)*UINT_MAX, UInteger_Type);
#endif
    _for i (0, torque-1, 1)
    jobstring += sprintf("COMMAND[%d]=\"isis-script %s/mc_sig.sl %d %d\"\n", i, torquedir, random_nrs[i], i+1);
    jobstring += "/usr/bin/nice -n +15 ${COMMAND[$PBS_ARRAYID]}\n";
    fp = fopen(sprintf("%s/torque.job", torquedir), "w+");
    ()=fputs(jobstring, fp);
    ()=fclose(fp);

    ifnot (qualifier_exists("dontSubmit")) {
      % submit job-script
      if (chatty) message("submitting job-file and waiting on exit");
      ()=system(sprintf("qsub %s/torque.job", torquedir));

      ifnot (qualifier_exists("dontWait")) {
        % waint until all fits-files appeared
        variable n = 0, t = 0;
        do {
          sleep(1);
          variable resultfits = glob(sprintf("%s/*.fits", torquedir));
          _for i (1, length(resultfits)-n, 1) ()=system("echo -n .");
          n = length(resultfits); t++;
  	  if (1.*t/60 > walltime) {
  	    vmessage("error (%s): the walltime of %d min. has passed!\n", _function_name, walltime);
	    vmessage("error (%s): please check %s\n", _function_name, torquedir);
	    vmessage("error (%s): exiting without results", _function_name);
	    return 0;
	  }
        } while (n < torque);

        % collect the results
        if (chatty) message("\ncollecting results");
        dchisqr = merge_struct_arrays(array_map(Struct_Type, &fits_read_table, resultfits)).fakedchisqr;
        mcruns *= torque;

        % clean
        ifnot (qualifier_exists("dontClean")) ()=system(sprintf("rm -r %s/", torquedir));
      } else { if (chatty) vmessage("you can find all files in %s", torquedir); return 1; }
    } else { if (chatty) vmessage("you can find all files in %s", torquedir); return 1; }
  }
  
  %% SIGNIFICANCE CALCULATION %%
  else {
    % evaluate a scriptfile before any data is loaded
    if (beforeData != NULL) { if (chatty) vmessage("calling %s", beforeData); ()=evalfile(beforeData); }
  
    % load the data and best-fit model
    % (containing the component needed to be checked)
    if (chatty) vmessage("loading data and best-fit model");
    variable id = fits_load_fit(withFits;; struct_combine(struct { noeval }, __qualifiers));
    if (qualifier_exists("id")) { id = [qualifier("id")]; }
    
    % evaluate a scriptfile before any model is evaluated
    if (afterData != NULL) { if (chatty) vmessage("calling %s", afterData); ()=evalfile(afterData); }

    % allow ISIS to overwrite the loaded spectra with fake data
    if (chatty) { vmessage("fake datatset ID(s) = [%s]",
			   strjoin(array_map(String_Type, &sprintf, "%d", id), ",")); }
    array_map(Void_Type, &set_fake, id, 1);

    % remember noticing and binning
    variable info = array_map(Struct_Type, &get_data_info, id);

    % plot
    if (qualifier_exists("plot")) {
      xlog;ylog;
      title("real data and best-fit model");
      plot_data({__push_array(all_data)}; res = 1);
      ()=keyinput(; nchr = 1, silent, prompt = "press any key to continue");
      message("");
    }
    
    % preapre MC loop
    variable woParams, withParams, woFun = NULL, withFun = NULL;
    % Monte Carlo loop
    variable mc; dchisqr = Double_Type[mcruns];
    if (chatty) message("starting Monte Carlo run");
    _for mc (0, mcruns-1, 1) {
      if (chatty) vmessage("  run %d of %d", mc+1, mcruns);
      
      % load or set the model WITHOUT the component
      if (mc == 0) {
        ()=fits_load_fit(woFits; nodata);
	woFun = get_fit_fun();
	woParams = get_params();
      } else {
	fit_fun(woFun);
        set_params(woParams);
      }
      
      % fake the spectra WITHOUT the component
      fakeit;

      % apply binning and noticing
      ifnot (qualifier_exists("ignbinning")) {
	array_map(Void_Type, &group, id);
        array_map(Void_Type, &rebin_data, id, array_struct_field(info, "rebin"));
      }
      ifnot (qualifier_exists("ignnotice")) {
	array_map(Void_Type, &ignore, id);
        array_map(Void_Type, &notice_list, id, array_struct_field(info, "notice_list"));
      }
      
      % evaluate a scriptfile before fitting
      if (beforeFit != NULL) { if (chatty) vmessage("    calling %s", beforeFit[0]); ()=evalfile(beforeFit[0]); }
      % fit the fake spectra WITHOUT the compoment
      ()=fit_counts(&statWO; fit_verbose = -1);

      % plot
      if (qualifier_exists("plot")) {
        title("fake data and fit without component");
        plot_data({__push_array(all_data)}; res = 1);
        ()=keyinput(; nchr = 1, silent, prompt = "    -> press any key to continue");
        message("");
      }

      % load or set the model *with* the component
      if (mc == 0) {
        ()=fits_load_fit(withFits; nodata);
	withFun = get_fit_fun();
	withParams = get_params();
      } else {
	fit_fun(withFun);
        set_params(withParams);
      }
    
      % evaluate a scriptfile before fitting
      if (beforeFit != NULL) { if (chatty) vmessage("    calling %s", beforeFit[1]); ()=evalfile(beforeFit[1]); }
      % fit the fake spectra *with* the component
      ()=fit_counts(&statWith; fit_verbose = -1);

      % plot
      if (qualifier_exists("plot")) {
        title("fake data and fit with component");
        plot_data({__push_array(all_data)}; res = 1);
        ()=keyinput(; nchr = 1, silent, prompt = "    -> press any key to continue");
        message("");
      }
      
      dchisqr[mc] = statWO.statistic - statWith.statistic;
      if (chatty) vmessage("    simulated delta chi square = %.3f", mc+1, dchisqr[mc]);
    }
  }

  % exit and return result
  variable signif = 1.*length(where(dchisqr <= realdchisqr)) / mcruns;
  if (chatty) vmessage("significance = %.3f", signif);
  return struct { realdeltachiqsr = realdchisqr, fakedeltachisqr = dchisqr, significance = signif };
}
