%%% functions for model and data binning following certain criteria
%%% 
%%%

%%% optimal binning after Kaastra & Bleeker 2016

%%%
private define binWidthKaastraBleeker (numCounts, numResolver)
%%%
%%+
%\function{binWidthKaastraBleeker}
%\synopsis{Caluculate optimized bin width per data resolution}
%\usage{Double_Type[] binWidthKaastraBleeker (Double_Type[] numCounts,
%                                             Double Type numResolver)}
%\description
%    Kaaster & Bleeker (2016) describe an aproximation to data binning to
%    minimize the number of bins by keeping the resolving power for near
%    resolution limit features.
%    
%    The approximation is based on a Monte Carlo approach to band limited
%    data. The result gives the optimized bin width per FWHM for each data
%    channel. It depends on the number of counts for each channel in the
%    FWHM of the instrument <numCounts> and the number of resolution elemets
%    <numResolver> (roughly sum 1/c_i where c_i is the FWHM in channels for
%    channel i)
%\seealso{}
%%-
{
  variable r = 1 + .2*log(numResolver);
  variable t = log(numCounts*r);
  variable d = 1.;

  if (t>2.110)
    d = (0.08 + 7./t + 1.8/(t^2))/(1+5.9/t);

  return d;
}
%%%

%%%
private define countsInResolver (c1, c2, response, counts)
%%%
%%+
%\function{countsInResolver}
%\synopsis{Calculate approximated number of counts per FWHM}
%\usage{Double_Type[] countsInResolver (Double_Type[] c1,
%                                       Double_Type[] c2,
%                                       Double_Type[][] response,
%                                       Double_Type[] counts)}
%\description
%
%\seealso{}
%%-
{
  variable i1, i2;
  variable size;
  variable c, h;

  i1 = int(c1);
  i2 = int(c2);
  size = length(response);
  c = sum(counts[[i1:i2]]);
  h = sum(response)/sum(response[[(i1-((i1 == 0)?0:1)):(i2+((i2==size-1)?0:1))]]);

  return c*h;
}

%%%
private define buildOptimalBins (id, minCounts)
%%%
{
  variable cResponse;
  variable channel;
  variable c1,c2;
  variable resWidth;
  variable numResolver;
  variable counts, resolverCnts;

  variable channelWidth;
  variable fakeId, grid, data, fit;
  variable to, size;
  variable rebin, flip;

  if (all(all_data() != id))
    throw UsageError, "Dataset $id not defined"$;

  (fakeId, grid, data) = responseEvalSetup(id);
  counts = get_data(fakeId).value;
  include(fakeId);
  fit = open_fit();

  size = length(grid.bin_lo);
  channel = 0;
  rebin = Int_Type[size];
  flip = -1;

  while (channel < size) {
    cResponse = responseEval(fakeId, grid, channel, fit);
    (c1, c2) = hist_fwhm_index(cResponse, channel; interp);
    resWidth = c2-c1;
    numResolver = sum(1./resWidth);
    resolverCnts = countsInResolver(c1, c2, cResponse, counts);
    channelWidth = int(binWidthKaastraBleeker(resolverCnts, numResolver)*resWidth);
    if (channelWidth < 1) channelWidth = 1;

    to = min([channel+channelWidth-1, size-1]);
    while (sum(counts[[channel:to]])<minCounts && to<(size-1))
      to++;

    rebin[[channel:to]] = flip;
    flip *= -1;

    channel = to+1;
  }

  % remove temporary values
  fit.close();
  responseEvalCleanup(fakeId, data);

  return rebin;
}

%%%
define rebin_dataset_optimal (histIdx)
%%%
%!%+
%\function{rebin_dataset_optimal}
%\usage{rebin_dataset_optimal (Int_Type index);}
%\altusage{rebin_dataset_optimal (Int_Type[] index);}
%\synopsis{Rebin datasets addressed by <index> based on Kaastra & Bleeker 2016}
%\qualifiers{
%\qualifier{min_counts}{[=0]: Ensure a minimum number of counts per bin (alters statistical properties).}
%}
%\description
%  Rebin a dataset to a numerical optimum defined by the associated
%  response matrix. The algorithm tries to balance the maximum
%  possible information with the smallest possible grid to represent
%  it.
%\seealso{rebin_data}
%!%-
{
  variable idx;
  variable mask;

  variable min_counts = qualifier("min_counts", 0);

  foreach idx (histIdx) {
    mask = buildOptimalBins(idx, min_counts);
    rebin_data(idx, mask); % The binning mask, applied on a wavelength grid
  }
}

%%%
private define buildOptimalBinsGroup (id, minCounts)
%%%
{
  variable cResponse;
  variable channel;
  variable c1,c2;
  variable resWidth;
  variable numResolver;
  variable counts, resolverCnts;

  variable channelWidth;
  variable fakeId, grid, data, fit;
  variable to, size;
  variable rebin, flip;

  % for grouping we have to set all fake datasets
  variable dataIds, numData, fid, did, weights, i, countsId, errorValue = NULL;

  try (errorValue) { dataIds = combination_members(id); }
  catch TypeMismatchError;
  if (NULL != errorValue)
    throw UsageError, "Dataset group $id not defined"$;

  numData = length(dataIds);
  fakeId = Int_Type[numData];
  data = Struct_Type[numData];
  weights = Double_Type[numData];
  countsId = Array_Type[numData];

  % setup all data
  _for i (0, numData-1) {
    (fid, grid, did) = responseEvalSetup(dataIds[i]);
    weights[i] = get_data_info(fid).combo_weight;
    countsId[i] = get_data(fid).value;
    fakeId[i] = fid;
    data[i] = did;
    ifnot (__is_initialized(&counts))
      counts = Double_Type[length(grid.bin_lo)];
    counts += countsId[i]*weights[i];
  }

  include(fakeId);
  fit = open_fit();

  % all grids have to be the same
  size = length(grid.bin_lo);
  channel = 0;
  rebin = Int_Type[size];
  flip = -1;

  while (channel < size) {
    cResponse = Double_Type[size];
    _for i (0, numData-1) {
      cResponse += responseEval(fakeId[i], grid, channel, fit)*weights[i];
    }

    (c1, c2) = hist_fwhm_index(cResponse, channel; interp);
    resWidth = c2-c1;
    numResolver = sum(1./resWidth);
    resolverCnts = countsInResolver(c1, c2, cResponse, counts);
    channelWidth = int(binWidthKaastraBleeker(resolverCnts, numResolver)*resWidth);
    if (channelWidth < 1) channelWidth = 1;

    to = min([channel+channelWidth-1, size-1]);
    if (minCounts>0) {
      _for i (0, numData-1) {
	while (sum(countsId[i][[channel:to]])<minCounts && to<(size-1))
	  to++;
      }
    }

    rebin[[channel:to]] = flip;
    flip *= -1;

    channel = to+1;
  }

  % remove temporary values
  fit.close();

  _for i (0, numData-1)
    responseEvalCleanup(fakeId[i], data[i]);
  exclude(all_data());
  _for i (0, numData-1)
    include(data[i].includes);

  return rebin;
}

%%%
define rebin_combined_optimal (groupsIdx)
%%%
%!%+
%\function{rebin_combined_optimal}
%\usage{rebin_combined_optimal (Int_Type group_index);
%\altusage{rebin_combined_optimal Int_Type[] group_index);}}
%\synopsis{Rebin a dataset combination based on Kaastra & Bleeker 2016}
%\qualifiers{
%\qualifier{min_counts}{[=0]: Ensure a minimum number of counts per bin per dataset.}
%}
%\description
%  Rebin a dataset combination using the numerical optimum defined by the
%  response. From the combination a combined response is calculated respecting
%  the weights.
%\seealso{combine_datasets, rebin_combined}
%!%-
{
  variable gid;
  variable mask;

  variable min_counts = qualifier("min_counts", 0);

  foreach gid (groupsIdx) {
    mask = buildOptimalBinsGroup(gid, min_counts);
    rebin_combined(gid, mask);
  }
}
