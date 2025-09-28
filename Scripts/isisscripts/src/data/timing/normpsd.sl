define normpsd()
%!%+
%\function{normpsd}
%\usage{psd_norm = normpsd(psd, normtype, avrate, avbackrate, timeseg, dimseg);}
%\description
%    \code{psd} is the unnormalized power spectrum.
%    \code{avrate} is the average countrate of corresponding lightcurve.
%    \code{avbackrate} is the average background countrate of corresponding lightcurve.
%    \code{timeseg} is the real time of one corresponding lightcurve segment.
%    \code{dimseg} is the number of bins in one lightcurve segment.
%
%    String_Type \code{normtype} can be:\n
%    - "Miaymoto" (default) [Miyamoto et al. (1991), ApJ 383, 784]\n
%      \code{psd *= 2 * timeseg / (dimseg * [avrate-avbackrate]^2)}\n
%    - "Leahy" [Leahy et al. (1983), ApJ 266, 160]\n
%      \code{psd *= 2 * timeseg / (dimseg^2 * avrate)}\n
%    - "Schlittgen" [Schlittgen, H.J., Streitberg, B. (1995), Zeitreihenanalyse, R. Oldenbourg]
%      \code{psd /= dimseg}\n
%!%-
{
  variable psd, normtype, avrate, avbackrate=0, timeseg, dimseg;
  switch(_NARGS)
  { case 5: (psd, normtype, avrate, timeseg, dimseg) = ();
            vmessage("warning (%s): avbackrate=%g is assumed", _function_name(), avbackrate);
  }
  { case 6: (psd, normtype, avrate, avbackrate, timeseg, dimseg) = (); }
  { help(_function_name()); return; }

  switch(normtype)
  { case "Schlittgen": return psd                /  dimseg; }
  { case "Leahy":      return psd * 2. * timeseg / (dimseg * dimseg * avrate); }
  { % case "Miyamoto":  % and default
                       return psd * 2. * timeseg / (dimseg * (avrate-avbackrate))^2; }

}
