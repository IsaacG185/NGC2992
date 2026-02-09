%%%%%%%%%%%%%%%%%%%%%%%%%%
define change_plot_options()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{change_plot_options}
%\synopsis{changes the currently used plot options}
%\usage{Struct_Type change_plot_options([plot_opt]; [default,] opt=value, opt2=value2, ...);}
%\description
%    The current plot options will be used as a starting point unless
%    an explicit argument \code{plot_opt} is specified, which is used in this case.
%
%    These plot options are then modified by the \code{opt} qualifiers (\code{opt} can be
%    any fieldname of the structure returned by \code{get_plot_options}, i.e.,
%    \code{xmin}, \code{xmax}, \code{ymin}, \code{ymax}, \code{xlabel}, \code{ylabel}, \code{tlabel}, \code{xopt}, \code{yopt}, \code{logx}, \code{logy},
%    \code{color}, \code{start_color}, \code{x_unit}, \code{line_style}, \code{start_line_style}, \code{line_width},
%    \code{frame_line_width}, \code{point_style}, \code{connect_points}, \code{char_height}, \code{point_size},
%    \code{ebar_term_length}, \code{use_errorbars}, \code{use_bin_density},
%    \code{ovp_xmin}, \code{ovp_xmax}, \code{ovp_ymin}, \code{ovp_ymax}),
%    unless the qualifier \code{default} is specified. In this latter case,
%    default plot options are set regardless of the starting plot options
%    and the other qualifiers.
%
%    The return value is the \code{get_plot_options} structure before \code{change_plot_options}
%    was called. It can be used to reset the plot options after a change was applied.
%\example
%    \code{variable plot_options = change_plot_options(; line_style=2);}\n
%    \code{plot(lineX, lineY);}\n
%    \code{set_plot_options(plot_options);}\n
%\seealso{get_plot_options, set_plot_options}
%!%-
{
  if(_NARGS>1)  { help(_function_name()); return; }

  variable initial_plot_options = get_plot_options();

  if(qualifier_exists("default"))
  {
    xrange;
    yrange;
    label("", "", "");
    xlin;
    ylin;
    color(1);
    % plot_unit("A or keV?");
    line_style(1);
    set_line_width(1);
    pointstyle(-1);
    connect_points(1);
    charsize(1);
    point_size(1);
    errorbars(0);
    plot_bin_integral;
    set_outer_viewport( struct { xmin=0.075765, xmax=0.924235, ymin=0.1, ymax=0.9 } );
    return initial_plot_options;
  }

  variable plot_options = (_NARGS ? () : initial_plot_options);
  plot_options = @plot_options;  % make a copy in order not to change the initial structure

  variable option;
  foreach option (get_struct_field_names(plot_options))
    if(qualifier_exists(option))
      set_struct_field(plot_options, option, qualifier(option));
  set_plot_options(plot_options);

  return initial_plot_options;
}
