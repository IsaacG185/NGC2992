%%%%%%%%%%%%%%%%%%%%%
define pulsarorbit_fluxerror_mc()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulsarorbit_fluxerror_mc}
%\synopsis{estimates additional uncertainties caused by the flux measurements}
%\usage{Double_Type[] pulsarorbit_fluxerror_mc(Integer_Type dataset);}
%\qualifiers{
%    \qualifier{runs}{number of MC loops (default: 100)}
%    \qualifier{save}{save the uncertainty estimation to the
%              assigned FITS-filename}
%    \qualifier{collect}{file-pattern used by 'glob' to read and
%              merge all FITS-files from previous runs}
%    \qualifier{modify}{add the estimated uncertainties to the
%              dataset(s) assigned to this qualifier
%              (see below for a detailed description)}
%    \qualifier{chatty}{be chatty if > 0 (default: 0)}
%}
%\description
%    The flux measurements used to calculate the evolution
%    of the spin-period in the fit-function 'pulsarorbit'
%    usually have uncertainties. These uncertainties are
%    not taken into account during an ordinary fit. This
%    function performs Monte Carlo simulations to estimate
%    the uncertainties of the modelled period induced by
%    the flux uncertainties.
%
%    During each run the flux evolution associated to the
%    dataset 'id' is varied using
%      flux = flux + grand * flux_err
%    such that synthetic flux evolutions are created. Then
%    a fit is performed using only the given dataset 'id'.
%    This results in many modelled period evolutions. Their
%    standard deviation at each time is finally considered
%    as an additional uncertainty in the period space.
%    These uncertainties are returned by the function.
%
%    If the 'modify'-qualifier is set, the dataset(s)
%    assigned to that qualifier or, in case of NULL, the
%    dataset 'id' is modified as follows:
%      new_error = sqrt(sqr(data_error) + sqr(mc_error))
%    where data_error is the current 'error'-field of the
%    dataset and mc_error is the estimated additional
%    uncertainty as calculated by this function. In case
%    of multiple given datasets, the time range of 'id'
%    should include all of these datasets to get a proper
%    period evolution.
%\seealso{pulsarorbit}
%!%-
{
  variable id;
  if (_NARGS != 1) { help(_function_name); return; }
  id = ();

  variable chatty = qualifier("chatty", 0);
  
  % either perform the simulation or load from previous runs
  variable sim, n;
  if (qualifier_exists("collect")) {
    if (chatty) { message("collecting previous runs"); }
    sim = array_map(Array_Type, &get_struct_field,
      array_map(Struct_Type, &fits_read_table, glob(qualifier("collect"))), "periods"
    );
    variable dim = [0,array_shape(sim[0])[1]];
    _for n (0, length(sim)-1, 1) {
      dim[0] += array_shape(sim[n])[0];
    };
    sim = _reshape(array_flatten(sim), dim);
  } else {  
    % get flux evolution
    variable L = get_dataset_metadata(id);
    if (L == NULL) {
      vmessage("error (%s): metadata-structure is not set", _function_name); return;
    }
    if (not struct_field_exists(L, "time") or not struct_field_exists(L, "flux") or not struct_field_exists(L, "flux_err")) {
      vmessage("error (%s): metadata-structure does not have the required fields", _function_name); return;
    }

    variable pars = get_params;
    variable incl = all_data[where(merge_struct_arrays(get_data_info(all_data)).exclude == 0)];
    exclude(all_data);
    include(id);
    
    % Monte Carlo uncertainty estimation
    seed_random(_time);
    if (chatty) { message("starting MC runs"); }
    variable runs = qualifier("runs", 100);
    sim = Array_Type[runs];
    _for n (1, runs, 1) {
      variable mcflux = L.flux + grand(length(L.flux))*L.flux_err;
      mcflux[where(mcflux < 0)] = 0.;

      set_dataset_metadata(id, struct_combine(L, struct { flux = mcflux } ));

      ()=fit_counts(; fit_verbose = -1);

      sim[n-1] = get_model_counts(id).value;
    }

    % restore original flux data and parameter
    set_dataset_metadata(id, L);
    set_params(pars);
    exclude(id);
    include(incl);

    % reshape
    sim = _reshape(array_flatten(sim), [length(sim), length(sim[0])]);
  }

  if (chatty) {
    vmessage("time length = %d, runs = %d", length(sim[0,*]), length(sim[*,0]));
  }
  % eventually save
  if (qualifier_exists("save")) {
    if (chatty) { message("saving runs"); }
    fits_write_binary_table(qualifier("save"), "mcflux", struct { periods = sim });
  }
  
  % calculate standard deviation
  variable err = Double_Type[length(sim[0,*])];
  _for n (0, length(err)-1, 1) {
    err[n] = moment(sim[*,n]).sdev;
  }

  % modify dataset
  if (qualifier_exists("modify")) {
    variable mid = qualifier("modify");
    if (mid == NULL) { mid = [id]; }
    if (typeof(mid) != Array_Type or (_typeof(mid) != Integer_Type and _typeof(mid) != UInteger_Type)) {
      vmessage("error (%s): 'modify' must be an array of integers", _function_name); return;
    }

    % loop and modify
    variable t = get_data_counts(id).bin_lo;
    foreach n (mid) {
      if (chatty) { vmessage("modifying dataset %d", n); }
      variable cts = get_data_counts(n);
      cts.err = sqrt(sqr(cts.err) + sqr(interpol(cts.bin_lo, t, err)));
      put_data(n, cts);
    }
  }
  
  return err;
}
