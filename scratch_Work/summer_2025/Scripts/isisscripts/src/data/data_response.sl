private define responseEvalSetup (id)
{
  % to restore user settings
  variable data = struct {
    includes = all_data(1),
    par = get_params("delta(1).*"), % in case this is in use
  };

  variable info = get_data_info(id);
  rebin_data(id, 0); % need all 
  variable fakeId = define_counts(get_data(id));
  rebin_data(id, info.rebin);
  notice_list(id, info.notice_list);
  assign_arf(info.arfs, fakeId);
  assign_rmf(info.rmfs, fakeId);

  assign_model(fakeId, "delta(1)");
  set_par("delta(1).*"; min=0, max=0);
  exclude(all_data());

  variable rmfId = get_data_info(fakeId).rmfs[0]; % get the first rmf, this defines the data grid
  variable grid = get_rmf_data_grid(rmfId); % might be NULL if default RMF is used
  if (NULL == grid) grid = get_data(id); % use the data grid instead

  return fakeId, grid, data;
}

private define responseEval (fakeId, grid, channel, fit)
% expects that everything is set up!
{
  ifnot (0 <= channel < length(grid.bin_lo))
    return Double_Type[length(grid.bin_lo)];

  if (NULL == fit)
    fit = open_fit();

  if (qualifier_exists("energy")) {
    channel = length(grid.bin_lo)-channel-1;
    % delta on nominal bin wavelength
    () = fit.eval_statistic([1, (grid.bin_hi[channel]+grid.bin_lo[channel])*.5]);
    return reverse(get_model(fakeId).value);
  } else {
    % delta on nominal bin wavelength
    () = fit.eval_statistic([1, (grid.bin_hi[channel]+grid.bin_lo[channel])*.5]);
    return get_model(fakeId).value;
  }
}

private define responseEvalCleanup (fakeId, data)
{
  assign_model(fakeId, NULL);
  exclude(all_data);
  include(data.includes);
  if (NULL != data.par && data.par[0] != NULL)
    set_params(data.par);
  delete_data(fakeId);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_dataset_response ()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_dataset_response}
%\usage{Response = get_dataset_response(id, [channel]);}
%\synopsis{Compute response of dataset associated to 'id' to delta peak}
%\qualifiers{
%\qualifier{energy}{If given, return response on energy grid (default: wavelength)}
%}
%\description
%    This function evaluates a delta peak function set at each nominal
%    grid value folded through the response of dataset \code{id}. If a
%    channel is given, only the response for the corresponding channel
%    is calculated.
%
%    The returned value is either an array of arrays for each channel in the
%    detector, or the array of the response in channel \code{channel}.
%    The delta function is placed at the nominal energy of the channel. If
%    \code{channel} is outside of the detector channels, a zero array is
%    returned.
%
%    Per default the response is returned as 'seen' by ISIS, that is, on
%    a wavelength grid. Use the 'energy' qualifier to revers the
%    response.
%
%\seealso{get_rmf_data_grid, assign_rmf, assign_rsp}
%!%-
{
  variable id, channel = NULL;
  switch (_NARGS)
  { case 1: id = (); }
  { case 2: (id, channel) = (); }
  { help(_function_name); return; }

  % check if dataset exists
  if (all(id != all_data()))
    throw UsageError, sprintf("Dataset %d not defined", id);

  variable fakeId, grid, data;
  (fakeId, grid, data) = responseEvalSetup(id);

  variable response, fit = NULL;
  include(fakeId);

  if (NULL == channel) {
    response = Array_Type[length(grid.bin_lo)];
    fit = open_fit();
    _for channel (0, length(grid.bin_lo)-1)
      response[channel] = responseEval(fakeId, grid, channel, fit;; __qualifiers);
  } else {
    response = responseEval(fakeId, grid, channel, fit;; __qualifiers);
  }

  if (NULL != fit)
    fit.close(); % done

  responseEvalCleanup(fakeId, data);

  return response;
}
