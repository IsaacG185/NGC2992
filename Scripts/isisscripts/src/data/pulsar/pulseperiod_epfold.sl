
%%%%%%%%%%%%%%%%%%%%%%%%
define pulseperiod_epfold() {
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulseperiod_epfold}
%\synopsis{UNDER DEVELOPMENT; performs an automatic pulse period search on the given light curve(s)}
%\usage{Struct_Type pulseperiod_epfold(Struct_Type[] lc, Double_Type p0);}
%\qualifiers{
%    \qualifier{nbins}{profile bins (default: 32)}
%    \qualifier{fracexp}{minimum fracexp all bins should have (default: 1.0)}
%    \qualifier{dpscale}{period search range relative to formal resolution
%               of epfold (default: 3)}
%    \qualifier{dpmin}{minimum period search range (default: 0.01 s)}
%    \qualifier{gapscale}{factor for maximum allowed gap length relative to
%               formal resolution o f epfold (default: .5)}
%    \qualifier{goodness}{threshold for the goodness of any signal
%               (default: 3)}
%    \qualifier{pbins}{mininum number of consecutive bins in epfold with
%               'goodness' to define a signal (default: 3)}
%    \qualifier{chatty}{chattiness (default: 1)}
%    \qualifier{plotlc}{reference to function(Struct_Type[] lc)}
%    \qualifier{plotepf}{reference to
%               function(Struct_Type epf, Double_Type median, norm)}
%}
%\description
%    UNDER DEVELOPMENT, USE WITH CAUTION! Send questions or bugs to
%    matthias.kuehnel@sternwarte.uni-erlangen.de
%
%    lc[] = struct { time, rate, error, fracexp }
%    with time in MJD
%
%    p0 = pulse period in seconds
%    
%    returns struct {
%      time (mean in MJD)
%      period (in s)
%      error (in s)
%      epfold (structure returned by epfold)
%      lc (input light curves, but maybe splitted)
%    }    
%\seealso{epfold}
%!%-
  variable lc, p0;
  switch (_NARGS)
    { case 2: (lc, p0) = (); }
    { help(_function_name); return; }

  % sanity checks
  if (typeof(lc) != Array_Type) { lc = [lc]; }
  if (_typeof(lc) != Struct_Type) { vmessage("error(%s): light curves have to be an array of structures!", _function_name); return; }
  if (typeof(p0) != Double_Type) { vmessage("erros(%s): pulse period has to be a floating point number!", _function_name); return; }
  if (p0 <= 0) { vmessage("error(%s): pulse period has to be > 0", _function_name); return; }

  % pre-process input
  variable nlc = length(lc);
  p0 /= 86400; % s -> d
  lc = array_map(Struct_Type, &struct_combine, COPY(lc), struct { split = 0, splitnum = 0 });
  % qualifiers
  variable nbins = qualifier("nbins", 32);
  variable fracexp = qualifier("fracexp", 1.);
  variable sdp = qualifier("dpscale", 4.);
  if (sdp < 3.) { vmessage("warning(%s): setting sdp=3 (minimum recommended value)", _function_name); sdp = 3.; }
  variable dpmin = qualifier("dpmin", .01/86400);
  if (dpmin < 0) { vmessage("error(%s): dpmin has to be > 0",  _function_name); return; }
  variable gs = qualifier("gapscale", .5);
  variable qsig = qualifier("goodness", 3.);
  variable nsig = int(qualifier("pbins", 3));
  variable chatty = qualifier("chatty", 1);
  
  % light curve properties and eventually split them
  if (chatty) { vmessage("condition checks"); }
  variable lcp = struct {
    time = Double_Type[nlc], % mean time
    dt = Double_Type[nlc], % time resolution
    len = Double_Type[nlc], % length
    bins = Integer_Type[nlc], % number of time bins
    dp = Double_Type[nlc], % formal epfold period resolution
  };
  % loop over light curve(s) (if splitted below until all segments were looped)
  variable i = 0;
  while (i < nlc) {
    % field checks
    if (any(array_map(Integer_Type, &struct_field_exists, lc[i], ["time", "rate", "error", "fracexp"]) == 0)) { vmessage("erros(%s): light curve does not have all required fields!"); return; }
    % filter on fractional exposure
    struct_filter(lc[i], where(lc[i].fracexp >= fracexp));
    % determine properties
    lcp.dt[i] = lc[i].time[1]-lc[i].time[0];
    lcp.len[i] = lc[i].time[-1]-lc[i].time[0] + lcp.dt[i];
    lcp.bins[i] = length(lc[i].time);
    lcp.time[i] = lc[i].time[0] + .5*lcp.len[i];
    lcp.dp[i] = p0^2 / lcp.len[i];
    % check on gaps and split light curve
    variable splitted = 0;
    if (lcp.len[i] - lcp.dt[i]*lcp.bins[i] > lcp.dt[i]) {
      variable gt = gs*(p0^2/lcp.dp[i] - p0); % gap threshold
      if (chatty) { vmessage("  light curve [%d] contains gaps (threshold %.0f s)", i, gt*86400); }
      variable slc = split_lc_at_gaps(lc[i], gt);
      if (qualifier_exists("plotlc")) {
	(@(qualifier("plotlc")))(slc);
      }
      % splitted
      if (length(slc) > 1) {
        splitted = 1;
        slc[0].splitnum = length(slc)-1;
        if (chatty) { vmessage("    splitted into %d segments", slc[0].splitnum+1); }
        variable j;
        _for j (1, length(slc)-1, 1) {
          slc[j].split = j;
          slc[j].splitnum = slc[0].splitnum;
        }
        % insert into main array
        lc = [
          i>0 ? lc[[:i-1]] : Struct_Type[0], % up to i-1
          slc, % splitted ones
          lc[[i+1:]] % from i+1
        ];
        % increase number of light curves and property structure
        struct_filter(lcp, [[0:nlc-1], ones(slc[0].splitnum)*0]);
        nlc += slc[0].splitnum;
      }
    }
    % go on
    if (splitted == 0) { i++; }
  }
  
  % prepare output structure
  variable out = struct {
    time = Double_Type[nlc], period = Double_Type[nlc],
    error = Double_Type[nlc], epfold = Struct_Type[nlc],
    lc = lc
  };
  
  % epoch folding
  if (chatty) { vmessage("epoch folding"); }
  _for i (0, nlc-1, 1) {
    if (qualifier_exists("skiphack")) {
      if (any(qualifier("skiphack") == i)) { continue; }
    }
    if (p0-lcp.dp[i]*sdp < 0 || p0+lcp.dp[i]*sdp > lcp.len[i]) {
      vmessage("warning(%s): period search range too large, skipping light curve [%d]", _function_name, i);
      continue;
    }
    % epoch folding
    variable psr = _max(lcp.dp[i]*sdp, dpmin); % period search range
    variable epf = epfold(
      lc[i].time, lc[i].rate, p0-psr, p0+psr;;
      struct_combine(struct {
	nbins = nbins, dt = lcp.dt[i]*lc[i].fracexp, exact, chatty = -1
%	nsrch = int(lcp.dp[i]*sdp*2 / lcp.dt[i] * 10)
      }, __qualifiers)
    );
    % normalize
    variable n = where(abs(epf.p - epf.p[where_max(epf.stat)]) > lcp.dp[i]);
    variable med = median(epf.stat[n]);
    variable norm = sqrt(sum(sqr(epf.stat[n] - med))*1./(length(n)-1));
    if (qualifier_exists("plotepf")) {
      (@(qualifier("plotepf")))(epf, med, norm);
    }
    % save into output
    out.epfold[i] = struct_combine(epf, struct { median = med, norm = norm });
    % where normalized chi^2 > threshold
    variable w = (epf.stat - med) / norm >= qsig;
    % number of consecutive bins where chi^2 > threshold
    variable k, ci = @w;
    _for k (1, length(w)-1, 1) {
      ci[k] = ci[k-1] == 0 ? w[k] : w[k]*(ci[k-1]+1);
    }
    % where consecutive bins > threshold
    w = where(ci > nsig);
    if (length(w) == 0) {
      vmessage("warning(%s): no period signal found in light curve [%d]", _function_name, i);
      continue;
    }
    if (length(w) != max(ci[w])-nsig) { % max(ci) should be equal the expected number of consecutive bins
      vmessage("warning(%s): multiple signals found in light curve [%d]", _function_name, i);
      continue;
    }
    % result
    out.time[i]   = mean(lc[i].time);
    out.period[i] = mean(epf.p[[w[0]-nsig:w[-1]]]) * 86400;
    out.error[i]  = lcp.dp[i] * 86400;
  }

  % sort by time
  n = array_sort(lcp.time);
  struct_filter(lcp, n);
  struct_filter(out, n);
  
  if (qualifier_exists("getlcp")) {
    (@(qualifier("getlcp"))) = lcp;
  }
  
  return out;
}
