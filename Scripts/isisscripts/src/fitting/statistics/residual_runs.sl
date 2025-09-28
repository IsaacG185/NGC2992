#ifexists normal_cdf

private define __runs_info (seq)
{
  variable confidence = [.10,.05,.01];

  variable n2;
  variable n1 = where(seq>0, &n2);

  variable s = Int_Type[length(seq)];
  s[n1] = 1;
  s[n2] = 0;
  variable w = where(s[[1:]]-s[[:-2]]);
  variable r = length(w)+1;
  variable l = (1 == r) ? length(seq) : w-[-1, w[[:-2]]]; 
  variable p;
  n1 = length(n1);
  n2 = length(n2);

  variable info = struct {
    runs = -1,
    over = n1,
    under = n2,
    min_run = -1,
    max_run = -1,
    test = [0,0,0],
    over_test = [0,0,0],
    under_test = [0,0,0],
    confidence = confidence,
  };

  if (n1 < 2 or n2 < 2 or r < 2 or r > n1 + n2)
    return info;

  p = __runs_p(n1, n2, r);

  if (NULL == p)
    return info;

  info.runs = r;
  info.min_run = min(l);
  info.max_run = max(l);
  info.test = confidence/2.<p and confidence/2.<(1-p);
  info.under_test = confidence < p;
  info.over_test = confidence < (1-p);

  return info;
}

%%%%%%%%%%%%%%%%%%%%%%%
define residual_runs ()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{residual_runs}
%\synopsis{Perform runs test on model and data}
%\usage{status = residual_runs([&stat]);}
%\description
%    While the Chi2 test tests for the absolute difference
%    of model and data, the runs test (Wald-Wolfowitz test)
%    accounts for the sign difference.
%
%    The test is in particular usefull for checking if the
%    model misses essential features of the data. As a simple
%    example concider data coming from a linear relation
%    described by a constant function. Although the chi2 test
%    might give a reasonable result the improper model is
%    easily spotted in the residuals.
%
%    The results are presented for 3 different confidence
%    regions. Each model passing the test is added to the
%    entries of the result matrix.
%
%    Note: The Confidence region is the total confidence. It
%    can happen that the test fails for the two tailed test but
%    succeeds for both one tailed tests!
%
%    If a reference is given as argument the same information
%    is stored as struct in that reference.
%\seealso{runs_test, normal_cdf}
%!%-
{
  variable res;
  switch (_NARGS)
  { case 0: res = NULL; }
  { case 1: res = (); }
  { help("residual_runs"); return; }

  variable ret, save_verbose = Fit_Verbose;
  Fit_Verbose = -1;
  ret = eval_counts();
  Fit_Verbose = save_verbose;

  variable active = all_data(1);
  variable id,model,data,noti;
  variable w, s, dinfo;
  variable coll = {};

  variable info = struct {
    num_bins = 0,
    runs = 0,
    over = 0,
    under = 0,
    min_run = INT_MAX,
    max_run = 0,
    test = [0,0,0],
    over_test = [0,0,0],
    under_test = [0,0,0],
    confidence = [.10,.05,.01],
    skipped = Int_Type[0],
  };

  foreach id (active) {
    noti = get_data_info(id).notice_list;
    model = get_model(id).value;
    data = get_data(id).value;

    s = data/model-1;
    w = where(s != 0); % ignore exact matches

    dinfo = __runs_info(s);
    dinfo = struct { id = id, @dinfo, num_bins = length(noti) };
    list_append(coll, dinfo);
  }

  foreach s (coll) {
    info.num_bins += s.num_bins;
    info.runs += s.runs;
    info.over += s.over;
    info.under += s.under;
    if (-1 != s.min_run) {
      info.min_run = min([info.min_run, s.min_run]);
      info.max_run = max([info.max_run, s.max_run]);
    } else
      info.skipped = [info.skipped, s.id];
    info.test += s.test;
    info.over_test += s.over_test;
    info.under_test += s.under_test;
  }


  if (Fit_Verbose >= 0 && ret == 0) {
    variable msg =
`       Number of runs = %s
 Num. of above points = %d
 Num. of below points = %d
      Min. run length = %s
      Max. run length = %s
            Data bins = %d
  Successful tests: Two tail, Lower tail, Upper tail 
       Confidence
     (%05.2f)%%:    % 10d, % 10d, %10d
     (%05.2f)%%:    % 10d, % 10d, %10d
     (%05.2f)%%:    % 10d, % 10d, %10d
     Skipped data sets = %d`;
    vmessage(msg, info.runs==-1 ? sprintf("NaN") : sprintf("%d", info.runs),
	     info.over,
	     info.under,
	     info.min_run == INT_MAX ? sprintf("NaN") : sprintf("%d", info.min_run),
	     info.max_run == 0 ? sprintf("NaN") : sprintf("%d", info.max_run),
	     info.num_bins,
	     info.confidence[0]*100, info.test[0], info.under_test[0], info.over_test[0],
	     info.confidence[1]*100, info.test[1], info.under_test[1], info.over_test[1],
	     info.confidence[2]*100, info.test[2], info.under_test[2], info.over_test[2],
	     length(info.skipped));
  }

  if (NULL != res && Ref_Type != typeof(res))
    throw UsageError, "Requires a reference";

  if (Ref_Type == typeof(res))
    @res = info;

  return ret;
}

#endif