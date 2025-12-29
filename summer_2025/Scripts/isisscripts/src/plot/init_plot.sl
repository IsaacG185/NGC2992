%%%%%%%%%%%%%%%%
define init_plot()
%%%%%%%%%%%%%%%%
%!%+
%\function{init_plot}
%\synopsis{starts a new plot, such that other plots can be overplotted}
%\usage{init_plot();}
%\description
%    plot is used to plot a single point in the lower left corner.
%    Before init_plot is called, x- and yrange have to be set.
%\seealso{plot, get_plot_options}
%!%-
{
  variable plot_options = get_plot_options();
  if(plot_options.xmin<-3e38 || plot_options.xmax>3e38 || plot_options.ymin<-3e38 || plot_options.ymax>3e38)
     return vmessage(`error (%s): The ranges are not set, see  help("%s");`,
		     _function_name(), dup);

  connect_points(-1);
  plot(plot_options.xmin, plot_options.ymin);
  connect_points(plot_options.connect_points);
}
