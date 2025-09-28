%%%%%%%%%%%%%%%%%%%%%%
define hist_fwhm_index ()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{hist_fwhm_index}
%\usage{(lo,hi) = hist_fwhm_index(hist [, max_index]);}
%\synopsis{Compute index bounds spaning FWHM of histogram}
%\description
%    When given a single array hist_fwhm_index tries to find the FWHM
%    range from the maximum. This works much better if the second argument
%    is given which has to be the index of the maximum (or at least close to
%    it). By interative stepping of the boundaries the function will stop
%    when the lo and hi enclose the true fwhm or has hit the array boundaries.
%
%!%-
{
  variable Histogram; % input histogram
  variable maxIndex; % input index
  variable iplus; % runs to lower indices
  variable iminus; % runs to higher indices
  variable histLen; % hist length
  variable fullMax; % maximum value of hist
  variable newMax; % if new maximum found
  variable loBounced; % if low hit bound
  variable hiBounced; % if high hit bound
  variable interp = qualifier_exists("interp"); % linear interpolate to get "true" fwhm
  variable loSlope; % slope for interpolation
  variable hiSlope;
  variable iplusinterp;
  variable iminusinterp;

  switch (_NARGS)
  { case 1: Histogram = ();
    maxIndex = wherefirstmax(Histogram);
  }
  { case 2: (Histogram, maxIndex) = ();
  }
  { help(_function_name);
    return;
  }

  fullMax = Histogram[maxIndex];
  iplus = maxIndex;
  iminus = maxIndex;
  histLen = length(Histogram);

  if (histLen <= maxIndex || 0 > maxIndex)
    throw UsageError, "given index not in range of array";

  newMax = 0;
  loBounced = 0;
  hiBounced = 0;
  while (not loBounced || not hiBounced) {
    if (not loBounced && iminus>0)
      iminus--;

    if (not hiBounced && iplus < histLen-1)
      iplus++;

    if (iminus == 0 || Histogram[iminus] <= .5*fullMax)
      loBounced = 1;

    if ((iplus == (histLen-1)) || Histogram[iplus] <= .5*fullMax)
      hiBounced = 1;

    if (Histogram[iminus] > fullMax) {
      fullMax = Histogram[iminus];
      maxIndex = iminus;
      newMax = 1;
    }

    if (Histogram[iplus] > fullMax) {
      fullMax = Histogram[iplus];
      maxIndex = iplus;
      newMax = 1;
    }

    if (newMax) {
      hiBounced = 0;
      loBounced = 0;

      while (Histogram[iplus] < .5*fullMax)
	iplus--;

      while (Histogram[iminus] < .5*fullMax)
	iminus++;

      newMax = 0;
    }
  }

  if (interp) {
    loSlope = Histogram[iminus+1]-Histogram[iminus];
    hiSlope = Histogram[iplus]-Histogram[iplus-1];
    iminusinterp = 1.*iminus + ((iminus == 0)         ? 0. : .5*fullMax/loSlope - Histogram[iminus]/loSlope);
    iplusinterp = 1.*iplus  + ((iplus == histLen-1) ? 0. : .5*fullMax/hiSlope - Histogram[iplus]/hiSlope);
    iminus = (loSlope == 0) ? iminus : iminusinterp;
    iplus =  (hiSlope == 0) ? iplus  : iplusinterp;
  }

  return (iminus, iplus);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_instrument_resolution_from_data (id)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_instrument_resolution_from_data}
%\usage{R = get_instrument_resolution_from_data(id)}
%\synopsis{Compute energy resolution from data set 'id'}
%\qualifiers{
%\qualifier{energy}{If given will return the grid as energy grid
%               instead of wavelength}
%}
%\description
%   This function can be used to estimate the instrument resolution
%   from the data set specified with id. The return value is a struct
%   { value, bin_lo, bin_hi } where bin_lo and bin_hi is the data
%   grid (usually in Angstrom) and value is the resolution in keV.
%
%   Note that this function removes any binning from the data set.
%
%\seealso{hist_fwhm_index}
%!%-
{
  rebin_data(id, 0);
  variable response = get_dataset_response(id);
  variable cmin, cmax;
  variable resolution = Double_Type[length(response)];
  variable i;
  variable grid = get_rmf_data_grid(get_data_info(id).rmfs[0]);
  variable fmin, fmax;
  variable energy = qualifier_exists("energy");

  _for i (0, length(response)-1, 1) {
    (cmin,cmax) = hist_fwhm_index(response[i], i);
    fmin = (response[i][cmin+1] == response[i][cmin]) ? 0.0 :
      (max(response[i][[cmin:cmax]])*.5-response[i][cmin])/
      (response[i][cmin+1]-response[i][cmin]);
    fmax = (response[i][cmax] == response[i][cmax-1]) ? 0.0 :
      (max(response[i][[cmin:cmax]])*.5-response[i][cmax])/
      (response[i][cmax]-response[i][cmax-1]);
    resolution[i] = _A(grid.bin_lo[cmin] + (grid.bin_lo[cmin+1]-grid.bin_lo[cmin])*fmin)
      -_A(grid.bin_hi[cmax] - (grid.bin_hi[cmax]-grid.bin_hi[cmax-1])*fmax);
  }

  if (energy)
    return struct { value = resolution, bin_lo = _A(grid.bin_hi), bin_hi = _A(grid.bin_lo) };
  else
    return struct { value = resolution, @grid };
}
