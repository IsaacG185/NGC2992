%%%%%%%%%%%%%%
define makepsd()
%%%%%%%%%%%%%%
%!%+
%\function{makepsd}
%\synopsis{Calculate the power density spectrum of a single energy band.}
%\usage{(psd, nipsd) = makepsd(rate, timeseg, dimseg);}
%\description
%    Input:
%      rate - input rate array
%      timeseg - real time of one segment of rate
%      dimseg  - number of bins in each segment of rate
%
%    Output:
%      psd   - unnormalized, averaged PSD
%      nipsd - averaged PSD, individual segments normalized
%\qualifiers{
%\qualifier{avgbkg}{Average background count rate for Miyamoto normalization}
%\qualifier{normtype}{"Miyamoto", "Leahy", "Schlittgen" normalization type}
%}
%!%-
{
  variable rate, timeseg, dimseg;
  switch(_NARGS)
  { case 3: (rate, timeseg, dimseg) = (); }
  { help(_function_name()); return; }

  variable numseg = int(length(rate)/dimseg);
  variable normtype = qualifier("normtype", "Miyamoto");
  variable avgbkg = qualifier("avgbkg", 0.);
  variable startbin = 0;
  variable endbin = dimseg - 1;
  variable outarray = 0.;
  variable normoutarray = 0.;
  loop(numseg)
  {
    variable temppsd = sqr(abs( dorDFT(rate[[startbin:endbin]]) ));
    variable indivavgrate = mean(rate[[startbin:endbin]]);
    normoutarray += normpsd(temppsd, normtype, indivavgrate, avgbkg, timeseg, dimseg);
    outarray += temppsd;
    startbin += dimseg;
    endbin += dimseg;
  }
  return outarray/(numseg*dimseg), normoutarray/(numseg*dimseg);
}
