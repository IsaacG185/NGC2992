%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define plot_combined_data_model_residuals()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_combined_data_model_residuals}
%\synopsis{plots data and model counts, and residuals for a combination of data sets}
%\usage{plot_combined_data_model_residuals([Integer_Type id[]]);}
%\qualifiers{
%\qualifier{dcol}{color of data [default=1]}
%\qualifier{mcol}{color of model [default=2]}
%}
%\description
%    If no indices \code{id} of data sets are specified, \code{all_data} are used.\n
%    The combined data, model and residuals are plotted in a two panel multiplot.
%\seealso{get_combined_data_model_residuals}
%!%-
{
  variable datasets;
  switch(_NARGS)
  { case 0: datasets = all_data; }
  { case 1: datasets = (); }

  variable d, m, r;
  (d, m, r) = get_combined_data_model_residuals(datasets);

  multiplot([4,1]);
  plot_bin_density;
  color(qualifier("dcol", 1)); plot_with_err(d);
  color(qualifier("mcol", 2)); ohplot(m);
  plot_bin_integral;
  color(qualifier("dcol", 1)); plot_with_err(r);
  r.value *= 0;
  color(qualifier("mcol", 1)); ohplot(r);
}
