%%%%%%%%%%%%%%%%%%%%%
define getVarPeriod(lc, minp, maxp)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{getVarPeriod}
%\synopsis{Determines the period of a variation in a lightcurve}
%\usage{Double_Type getVarPeriod(Struct_Type lc, Double_Type minperiod, Double_Type maxperiod)}
%\qualifiers{
%    \qualifier{plot}{plot chi-square distribution and modelled
%              gaussians. Pause the assigned number in
%              seconds between each step (default 0.3)}
%    \qualifier{nogauss}{skip the gaussian fit}
%
% \qualifier{PIPED TO EPFOLD}{:}
%    \qualifier{dt}{exposure of every lightcurve time bin, should
%               be given to ensure correct results.}
%    \qualifier{sampling}{how many periods per peak to use (default=10)}
%    \qualifier{nsrch}{how many periods to search in a linear grid (default not set)}
%    \qualifier{dp}{delta period of linear period grid (default not set)}
%    \qualifier{lstat}{use L-statistics instead of chi^2 statistics}
%    \qualifier{nbins}{number of bins for the pulse profile}
%    \qualifier{exact}{calculate the pulse profile in a more exact
%               way, see description of pfold (not recommed
%               as it takes a very long time!).}}
%\description
%    ****
%    This function is deprecated!! It will be removed in
%    2017 Mai. If you heavily depend on this function,
%    please write an email to
%    matthias.kuehnel@sternwarte.uni-erlangen.de
%    ****
%    Performs an Epoch Folding of the lightcurve in the
%    given period range (same time unit as used in the
%    lightcurve) and returns the period corresponding
%    to the maximum.
%    If not skipped by the 'nogauss' qualifier, a gaussian
%    it fitted to the maximum to get its position more
%    accurate. The gaussian parameters and used data-
%    points are applied automatically and improved step
%    by step. The steps can be monitored using the 'plot'
%    qualifier.
%\seealso{epfold}
%!%-
{
 message("****");
 message("The function getVarPeriod is deprecated! It will be removed in");
 message("2017 Mai. If you heavily depend on this function, please write");
 message("an to matthias.kuehnel@sternwarte.uni-erlangen.de");
 message("****");

 variable pldt = qualifier("plot",0.3); if (pldt == NULL) pldt = 0.3;
 variable epf = epfold(lc.time, lc.rate, minp, maxp;; __qualifiers);
 variable period = epf.p[where_max(epf.stat)];
 if (length(period)>1) period = period[0];

 % eventually do a gaussian fit
 ifnot (qualifier_exists("nogauss"))
 {
  delete_data(all_data);
  % select only high "chisquared" data
  variable ndx = moment(epf.stat);
  ndx = where(epf.stat > ndx.ave + ndx.sdev);
  if (length(ndx)<5) { vmessage("warning (%s): no significant gaussian region in chi^2 distribution found ndx", _function_name); ndx = [0:length(epf.stat)-1]; }
  % define data
  variable dp0 = max(epf.p[ndx]) - min(epf.p[ndx]);
  period = min(epf.p[ndx]) + dp0/2.;
  variable grid = make_hi_grid(epf.p[ndx]);
  ()=define_counts(epf.p[ndx], grid, epf.stat[ndx], epf.stat[ndx]*0.05); % error is not correct!
  set_data_exposure(1,1);
  fit_fun("constant(1)+gauss(1)");
  set_par("constant(1).factor",min(epf.stat[ndx]),0,0.0,max(epf.stat[ndx]));
  set_par("gauss(1).sigma",dp0/2,0,0.0,1.5*dp0);
  set_par("gauss(1).center",period,0,min(epf.p[ndx]),max(epf.p[ndx]));
  set_par("gauss(1).area",length(ndx)*max(epf.stat[ndx]),0,0.0,3.0*length(ndx)*max(epf.stat[ndx]));

  variable model = struct { value = 0 };
  variable fm = get_fit_method;

  xrange; yrange;
  set_fit_method("subplex");
  if (qualifier_exists("plot"))
  {
    ()=eval_counts(;fit_verbose=-1);
    xlabel("Period (s)"); ylabel("\\gx\\u2\\d-value");
    model=get_model_counts(1);
    color(15); plot(epf.p*86400,epf.stat);
    color(1); oplot(epf.p[ndx]*86400,epf.stat[ndx]);
    color(2); oplot(epf.p[ndx]*86400,model.value);
    sleep(pldt);
  }
  % fit until maximum position is near the global one and the
  % shrinking of the used range has stopped
  ()=fit_counts(;fit_verbose=-1); % fit
  model = get_model_counts(1);
  if (qualifier_exists("plot"))
  {
    color(15); plot(epf.p*86400,epf.stat);
    color(1); oplot(epf.p[ndx]*86400,epf.stat[ndx]);
    color(2); oplot(epf.p[ndx]*86400,model.value);
  }
  if (qualifier_exists("plot")) sleep(pldt*5);
 }
 delete_data(all_data);
 set_fit_method(fm);
 return period;
}
