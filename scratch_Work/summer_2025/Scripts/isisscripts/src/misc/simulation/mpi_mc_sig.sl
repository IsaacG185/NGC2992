% -*- mode:slang; mode:fold -*-
#ifexists rcl_mpi_init
private define verbexec (script){
  %{{{
  variable chatty = qualifier("chatty", 0); if (chatty == NULL) chatty = 1;
  if (script != NULL) {
    if (chatty){ vmessage("calling %s", script);}
    ()=evalfile(script); 
  }
}
%}}}
private define compare_stat(beforeData, afterData, beforeFit, info, id, withFun, withParams, woFun, woParams){
  %{{{
  % apply binning and noticing
  variable statWO, statWith;
  variable chatty = qualifier("chatty", 0); if (chatty == NULL) chatty = 1;
  ifnot (qualifier_exists("ignbinning")) {
    array_map(Void_Type, &group, id);
    array_map(Void_Type, &rebin_data, id, array_struct_field(info, "rebin"));
  }
  ifnot (qualifier_exists("ignnotice")) {
    array_map(Void_Type, &ignore, id);
    array_map(Void_Type, &notice_list, id, array_struct_field(info, "notice_list"));
  }
  % load or set the model *without* the component
  fit_fun(woFun);
  set_params(woParams);
  % evaluate a scriptfile before fitting
  if (beforeFit != NULL) { if (chatty) vmessage("    calling %s", beforeFit[0]); ()=evalfile(beforeFit[0]); }
  % fit the fake spectra WITHOUT the compoment
  ()=fit_counts(&statWO; fit_verbose = -1);
  % load or set the model *with* the component
  fit_fun(withFun);
  set_params(withParams);
  % evaluate a scriptfile before fitting
  if (beforeFit != NULL) { if (chatty) vmessage("    calling %s", beforeFit[1]); ()=evalfile(beforeFit[1]); }
  % fit the fake spectra *with* the component
  ()=fit_counts(&statWith; fit_verbose = -1);

  return  (statWO.statistic - statWith.statistic);
}
%}}}
private define receive_spectrum(id){
  %{{{
  % Loop over IDs and receive all spectra as array of counts
  variable ii;
  variable origspec, nbins;
  foreach ii (id){
    group(ii); %Unset grouping before overwriting data. Data will be rebinned before fitting anyway
    origspec = get_data_counts(ii);
    nbins = length(get_data_info(ii).rebin);
    variable value = Double_Type[nbins];
    variable error = Double_Type[nbins];
    () = rcl_mpi_recv_double(value, nbins);
    () = rcl_mpi_recv_double(error, nbins);
    put_data_counts(ii, origspec.bin_lo, origspec.bin_hi, value, error); 
  }
}
%}}}
private define send_spectrum(rank, id){
  %{{{
  % Loop over IDs and send all spectra as array of counts
  variable ii;
  variable spec;
  foreach ii (id){
    spec = get_data_counts(ii);
    () = rcl_mpi_send_double(spec.value, length(spec.value), rank,1);
    () = rcl_mpi_send_double(spec.err, length(spec.err), rank,1);
  }
}
%}}}
private define distribute_runs(mcruns, nclients){
  %{{{
  % Distribute the mc runs on the different clients.
  % This is important if the number of runs is not the
  % same for every client which happens if the
  % the number of runs is not an integer multiple
  % of the number of nodes.
  variable dist = Integer_Type[nclients];
  dist[*] = int (mcruns /nclients);
  variable rest = mcruns mod nclients;
  dist[[0:rest-1]] +=1;
  return dist;
}
%}}}
private define save_results(realdchisqr, fakedchisqr, nfalse, significance, file){
  %{{{
  variable fp = fits_open_file(file, "c");
  fits_write_binary_table(fp, "REALDELTACHISQUARE", struct{realdchisqr = realdchisqr});
  fits_write_binary_table(fp, "FAKEDELTACHISQUARE", struct{fakedchisqr = fakedchisqr});
  fits_write_binary_table(fp, "FALSEPOSITIVES", struct{nfalse = nfalse});
  fits_write_binary_table(fp, "SIGNIFICANCE", struct{significance =significance});
  fits_close_file(fp);
}
%}}}
%
%%%%%%%%%%%%%%%%%%%%%
define mpi_mc_sig()
%%%%%%%%%%%%%%%%%%%%%
% HELP
%{{{
%!%+
%\function{mpi_mc_sig}
%\synopsis{calculates the significance of a spectral component doing a Monte Carlo (MC) simulation}
%\usage{Struct_Type mpi_mc_sig(String_Type withComponent.fits, String_Type withoutComponent.fits [, String_Type results.fits]);}
%\qualifiers{
%    \qualifier{mcruns}{number of MC loops (default: 10)}
%    \qualifier{beforeData}{script to be called before any data is loaded (default: NULL)}
%    \qualifier{afterData}{script to be called after the data have been loaded (default: NULL)}
%    \qualifier{beforeFit}{array of scripts to be called right before a fit of faked data to
%                 the model without [0] and with [1] the component (default: NULL)}
%    \qualifier{id}{override the dataset ID(s) after fits_load_fit with the given one(s)}
%    \qualifier{ignbinning}{do not apply the same binning after faking the data}
%    \qualifier{ignnotice}{do not use the same energy ranges after faking the data}
%    \qualifier{chatty}{a number >0 means more chatty (default: 0)}
%    \qualifier{seed}{seed for random number generator}
%    \qualifier{ }{additional qualifiers are passed to fits_load_fit}
%}
%\description
%    This function calculates the significance of a spectral component
%    found in real data. During each Monte Carlo loop, spectra data
%    without the component are simulated (for each detector) and these
%    data are then fitted with a model containing the component (that
%    needs to be tested for) and separately fitted with a model without
%    it.
%    The resulting simulated differences in chi-square between these
%    fits are returned and compared to the measured difference: the
%    number of simulated chi squares below the measured one corresponds
%    to the significance, that the spectral component is real (i.e. in
%    80 cases out of 100 runs the simulated chi square difference is
%    below the measured chi square difference, the significance is 80%).
%
%    Two FITS-files created with fits_save_fit must be provided, the
%    first includes the model "with" the component to be tested and
%    the second one "without" it. An optional third filename may be given
%    to store the results to. Otherwise, a default file will be created.
%
%    This function is supposed to be used for parallel computation with
%    MPI. The mcruns qualifier specifies the total number of MC runs which
%    is split accordingly among the available nodes.
%
%    The function will create a FITS file containing the following extensions:
%      realdeltachisquare - the measured difference in chi square
%      fakedeltachisquare - an array of simulated differences in chi square
%      falsepositives     - the number of detected false positives
%      significance       - the resulting significance as defined above
%\example
%    % FITS-files created by fitting a cutoffpl and iron line to
%    % RXTE-PCA, -HEXTE and Swift-XRT data (Rmf_OGIP_Compliance = 0 to
%    % load XRT data, see help of fits_load_fit)
%
%     mpi_mc_sig("rxte_swift_cutoffpl_ironline.fits",
%                "rxte_swift_cutoffpl.fits",
%                "significance.fits";
%                 mcruns = 100, ROC = [2,2,0],
%                 beforeData = "defineMyModels.sl",
%                 afterData = "setDataHooks.sl",
%                 chatty = 2);
%    % A typical call from the command line could look like this
%
%    mpiexec -n 4 isis <script>
%
%    to use 4 cores for the MC run. However, it is highly
%    recommended to use a job scheduling system (e.g., SLURM)
%    for these kind of simulations.
%                              
%\seealso{fits_save_fit, fits_load_fit, fakeit, mc_sig}
%!%-
%}}}
{
  % Arguments and qualifiers
  %{{{
  variable withFits, woFits, resfile = "significance.fits";
  switch (_NARGS)
  { case 2: (withFits, woFits) = ();}
  { case 3: (withFits, woFits, resfile) = (); }
  { help(_function_name); return; }
  
  variable mcruns = qualifier("mcruns", 100);
  
  % additional loading scripts and qualifiers
  variable beforeData = qualifier("beforeData", NULL);
  variable afterData = qualifier("afterData", NULL);
  variable beforeFit = qualifier("beforeFit", NULL);
  variable chatty = qualifier("chatty", 0); if (chatty == NULL) chatty = 1;
  variable seed = qualifier("seed", NULL); % seed for random number generator
  %}}}
  % some error handling
  %{{{
  if (access(withFits, F_OK) != 0) { vmessage("error (%s): %s not found", _function_name, withFits); return; }
  if (access(woFits, F_OK) != 0) { vmessage("error (%s): %s not found", _function_name, woFits); return; }
  if (mcruns < 1) { vmessage("error (%s): number of MC runs has to be greater zero", _function_name); return; }
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
  %}}}  

  variable PROC_RANK=rcl_mpi_init();
  variable PROC_TOTAL=rcl_mpi_numtasks();

  variable REQUEST=-255; % Just some random integer signal
  variable COLLECT=128;
  variable MASTER=0;
  variable SIG=Integer_Type[2];
  variable FAKE_FINISHED=0;
  variable statWith, statWO;
  variable realdchisqr = fits_read_col(woFits, "chi")[0] - fits_read_col(withFits, "chi")[0]; 
  
  if (chatty){vmessage("measured delta chi square = %.2f", realdchisqr);}
  if (seed != NULL){seed_random(seed);}

  %%% SIGNIFICANCE CALCULATION %%%
  
  % evaluate a scriptfile before any data is loaded
  verbexec(beforeData;; __qualifiers);
  
  % load the data and best-fit model (containing the component needed to be checked)
  variable id = fits_load_fit(withFits;; struct_combine(struct { noeval }, __qualifiers));
  if (qualifier_exists("id")) { id = [qualifier("id")]; }
  
  % evaluate a scriptfile before any model is evaluated
  verbexec(afterData;; __qualifiers);
  
  % remember noticing and binning
  variable info = array_map(Struct_Type, &get_data_info, id);

  % preapre MC loop
  variable woParams, withParams, woFun, withFun, mc, simdchisqr = Double_Type[0];
  variable fake_counter = 0; %keep track of how many spectra have been faked

  % Save fit-functions and parameters
  ()=fits_load_fit(withFits; nodata);
  withFun = get_fit_fun();
  withParams = get_params();
  
  ()=fits_load_fit(woFits; nodata);
  woFun = get_fit_fun();
  woParams = get_params();

  %%%%% The master process (rank = 0) is only responsible for the faking and for coordinating  %%%%%

  if (PROC_RANK == MASTER){
    
    % Tell the clients how many runs they'll have to do
    variable dist = distribute_runs(mcruns, PROC_TOTAL - 1);
    variable client;
    _for client (1, PROC_TOTAL-1){
      () = rcl_mpi_send_int([dist[client-1]],1,client,1);
    }
    
    % allow ISIS to overwrite the loaded spectra with fake data
    if (chatty) { vmessage("fake datatset ID(s) = [%s]",
			   strjoin(array_map(String_Type, &sprintf, "%d", id), ",")); 
    }
    array_map(Void_Type, &set_fake, id, 1);
    array_map(Void_Type, &group, id); % Unset grouping for faking
    
    % Wait for fake request from clients
     while(FAKE_FINISHED !=1 ) { 
      () = rcl_mpi_recv_int(SIG,2);
      if (SIG[0] == REQUEST){
	% fake the spectra WITHOUT the component
	fit_fun(woFun);
	set_params(woParams);
	fakeit();
	% Send faked spectra to client
	send_spectrum(SIG[1], id);
	fake_counter++;
	if (fake_counter == mcruns){FAKE_FINISHED = 1;}
      }
    }
  }
  %%%%% The clients are only responsible for the fitting %%%%%
  
  if (PROC_RANK != MASTER){
    % First receive the number of runs from master
    variable mccl;
    () = rcl_mpi_recv_int(&mccl, 1);
    variable results = Double_Type[mccl];
    _for mc (0, mccl-1, 1){
      % Send request to master
      () = rcl_mpi_send_int([REQUEST, PROC_RANK],2,MASTER,1);
      receive_spectrum(id); % Listen to reply from master
      results[mc] = compare_stat(beforeData, afterData, beforeFit, info, id, withFun, withParams, woFun, woParams;; __qualifiers);
    }
    if (chatty){vmessage("Process %d finished fitting", PROC_RANK);}
  }
  rcl_mpi_barrier(); % Wait for all clients to finish

  % Finally, the master process collects all results
  % Since the number of runs may differ from one client to the other,
  % we do this only upon request from the master who knows how
  % many results to expect
  
  if (PROC_RANK != MASTER){
    () = rcl_mpi_recv_int(SIG,2); % wait for request from master
    if (SIG[0] == COLLECT){
      () = rcl_mpi_send_double(results, mccl, MASTER, 1); % Send results from MC runs to master
    }
  }

  % Collect results
  if (PROC_RANK == MASTER){
    _for client (1, PROC_TOTAL-1){
      variable tmpres = Double_Type[dist[client-1]];
      () = rcl_mpi_send_int([COLLECT, PROC_RANK],2,client,1);
      () = rcl_mpi_recv_double(tmpres, dist[client-1]);
      simdchisqr = [simdchisqr,tmpres];
    }
    % return result
    variable nfalse = length(where(simdchisqr >= realdchisqr));
    variable signif = 1. - (nfalse == 0 ? 1./mcruns : 1.*nfalse/mcruns);

    if (chatty){
      vmessage("false positives = %d", nfalse);
      vmessage("-> significance %s %.3f", nfalse == 0 ? ">=" : "=", signif);
    }
    save_results(realdchisqr, simdchisqr, nfalse, signif, resfile);
  }
  rcl_mpi_finalize();
}
#endif