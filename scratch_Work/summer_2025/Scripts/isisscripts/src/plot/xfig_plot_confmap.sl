% try to load  modules if available
require("xfig");
require("gcontour");
require("gsl","gsl");


define xfig_plot_confmap() %{{{
%!%+
%\function{xfig_plot_confmap}
%\synopsis{Create an xfig plot of a confidence map}
%\usage{xfig_plot_new fig = xfig_plot_confmap(String_Type cm; qualifiers)}
%\description
%    Create an xfig plot from a pre-calculated confidence map `cm' computed and saved with
%    the function `get_confmap'.
%\qualifiers{
%\qualifier{best_fit}{Mark the best fit with a cross.}
%\qualifier{CDF}{If set to a positive integer, the chi^2 values are converted to a cumulative
%      distribution function with the degree of freedom given by this qualifier. For
%      instance, CDF=1 implies that chi^2 values of 1, 2.71, and 6.63 are converted
%      to 0.68, 0.9, and 0.99 (this qualifier requires the gsl-module).}
%\qualifier{colormap [="haxby"]}{Choose, e.g., "ds9sls", "seis", "rainbow", "haxby", "topo",
%      "globe" (see the function `png_get_colormap' for more information).}
%\qualifier{colormap_gmin, colormap_gmax}{Minimum and maximum grayscale value for the colormap,
%      see `png_gray_to_rgb'.}
%\qualifier{chi2 [=Double_Type[0]]}{Chi^2 values for which contour lines should be drawn (this
%      qualifier requires the gcontour-module).}
%\qualifier{chi2_color [="magenta"]}{Color of the contour lines and the best fit cross.}
%\qualifier{factor [=1]}{Factor by which the x- and y-sampling of the confidence map is increased.}
%\qualifier{field [="chisqr"]}{Which field of the confidence map shall be plotted.}
%\qualifier{width [=8], height [=8]}{Width and height of the confidence map.}
%\qualifier{latex_package [="txfonts"]}{Load a package in the preamble of LaTeX documents.}
%\qualifier{reverse_axes}{If present, both axes are reversed.}
%\qualifier{[xyz]label}{Add a x-, y-, or z-label to the confidence map.}
%\qualifier{[xyz]axis [=struct{ticlabels_confine=0, ticlabels2=0}]}{Modify the x-, y-, or z-axis
%      by providing a structure whose fields are qualifiers of the function `xfig_plot.axis'.
%      Note that the `log' qualifier (set logarithmic axis scale) does not work.}
%\qualifier{nomultiplot}{Return the confidence map and its corresponding colormap in two separate
%      xfig objects instead of one multiplot object.}
%}
%\example
%    fig = xfig_plot_confmap("confmap.fits"; chi2=[1, 2.71, 6.63], zlabel="$\\chi^2$"R, zaxis=struct{format="%g", ticlabels1=0});
%    fig.render("test.pdf");
%\seealso{get_confmap}
%!%-
{
  if(_NARGS!=1)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  variable fp;
  fp = ();
  variable width = qualifier("width", 8);
  variable height = qualifier("height", 8);
  variable factor = qualifier("factor", 1);
  variable colormap = qualifier("colormap", "haxby");
  variable chi2 = qualifier("chi2", Double_Type[0]);
  variable chi2_color = qualifier("chi2_color", "magenta");
  variable field_to_be_plotted = qualifier("field", "chisqr");
  variable reverse = qualifier_exists("reverse_axes");
  xfig_add_latex_package(qualifier("latex_package", "txfonts")); % txfonts as used in A&A
  variable i;
  % -----------
  % read input:
  variable cm = fits_read_table(fp; casesen);
  ifnot(struct_field_exists(cm,field_to_be_plotted))
  {
    print(get_struct_field_names(cm));
    throw UsageError, sprintf("Usage error in '%s': Field '%s' does not exist. Check the list of available fields above.", _function_name(), field_to_be_plotted);
  }
  variable keys = fits_read_key_struct(fp, "pxnum",  "pynum", "pxname", "pyname", "best_x", "best_y", "beststat");
  %keys.pxname = strreplace(keys.pxname, "(1).", "1_");
  %keys.pyname = strreplace(keys.pyname, "(1).", "1_");
  keys.pxname = escapedParameterName(keys.pxname);
  keys.pyname = escapedParameterName(keys.pyname);
  variable min_chi = min(get_struct_field(cm, "chisqr"));
  if(min_chi < keys.beststat)
  {
    variable ind_min = where(get_struct_field(cm, "chisqr")==min(get_struct_field(cm, "chisqr")));
    vmessage("Warning in '%s': Found fit better than best-fit assumed by confidence map:", _function_name());
    vmessage("Warning in '%s': Original best-fit with chi-square of %f at position (%f, %f)", _function_name(), keys.beststat, keys.best_x, keys.best_y);
    _for i(0, length(ind_min)-1, 1)
      vmessage("Warning in '%s': Found chi-square of                  %f at position (%f, %f)", _function_name(), get_struct_field(cm, "chisqr")[ind_min[i]],
	       get_struct_field(cm, keys.pxname)[ind_min[i]], get_struct_field(cm, keys.pyname)[ind_min[i]]);
    % update keys.beststat, keys.best_x, keys.best_y:
    keys.beststat = min_chi;
    keys.best_x = get_struct_field(cm, keys.pxname)[ind_min[i]];
    keys.best_y = get_struct_field(cm, keys.pyname)[ind_min[i]];
  }
  % -----------
  % ------------------------------------
  % Smooth confmap via 2D interpolation:
  set_struct_field(cm, "chisqr", sqrt(get_struct_field(cm, "chisqr")-min_chi)); % convert `chi^2' to `sqrt(delta chi^2)' ~ `delta chi' -> linear interpolation (see below) works better
  variable fieldnames = union(keys.pyname, keys.pxname, field_to_be_plotted, "chisqr");
  struct_filter(cm, array_sort(get_struct_field(cm, keys.pyname))); % sort by y-values
  struct_filter(cm, array_sort(get_struct_field(cm, keys.pxname))); % sort by x-values -> order of equal elements in y-values is preserved, see method `merge-sort' in help on function `array_sort'
  variable old_x = union(get_struct_field(cm, keys.pxname));
  % divide each interval in [a:b:#n] in x parts: [a:b:#(n*x-x+1)] because (n-1) segments need (x-1) additional points plus the origional number of points n: (n-1)*(x-1)+n=n*x-x+1
  variable new_x = [old_x[0]:old_x[-1]:#(keys.pxnum*factor-factor+1)];
  variable old_y = union(get_struct_field(cm, keys.pyname));
  variable new_y = [old_y[0]:old_y[-1]:#(keys.pynum*factor-factor+1)];
  variable field;
  foreach field (fieldnames)
  {
    reshape(get_struct_field(cm, field), [keys.pxnum,keys.pynum]);
    variable temp1 = Double_Type[length(new_x), keys.pynum]; % temporary variable
    _for i(0, keys.pynum-1, 1)
      temp1[*,i] = interpol(new_x, old_x, (get_struct_field(cm, field))[*,i]); % add additional points for x-grid
    variable temp2 = Double_Type[length(new_x), length(new_y)]; % finer 2D-array for field
    _for i(0, length(new_x)-1, 1)
      temp2[i,*] = interpol(new_y, old_y, temp1[i,*]); % add additional points for y-grid
    temp2 = transpose(temp2); % to have correct x- and y-axes
    if(reverse)
      array_reverse(temp2); % reverse axes
    set_struct_field(cm, field, temp2);
  }
  if(reverse)
  {
    array_reverse(new_x); % to account for array_reverse(temp2)
    array_reverse(new_y); % to account for array_reverse(temp2)
  }
  set_struct_field(cm, "chisqr", get_struct_field(cm, "chisqr")^2); % convert `delta chi' to `delta chi^2'
  % ------------------------------------
#ifeval __get_reference("gsl->cdf_chisq_P")!=NULL
  if(qualifier_exists("CDF") && typeof(qualifier("CDF"))==Integer_Type)
  {
    set_struct_field(cm, "chisqr", gsl->cdf_chisq_P(get_struct_field(cm, "chisqr"), qualifier("CDF")));
    chi2 = gsl->cdf_chisq_P(chi2, qualifier("CDF"));
  }
#endif
  variable fig = xfig_new_compound();
  % --------
  % colormap
  variable w1 = xfig_plot_new(0.075*width, height);
  variable mi, ma;
  if(qualifier_exists("colormap_gmin"))
    mi = qualifier("colormap_gmin");
  else
    mi = min(get_struct_field(cm, field_to_be_plotted));
  if(qualifier_exists("colormap_gmax"))
    ma = qualifier("colormap_gmax");
  else
    ma = max(get_struct_field(cm, field_to_be_plotted));
  w1.world(0, 0.075*width, mi, ma);
  w1.xaxis(; ticlabels=["0","0"], major=[0, 0.075*width], ticlabel_color="white", ticlabels2=0);
  if(qualifier_exists("zaxis") && typeof(qualifier("zaxis"))==Struct_Type)
    w1.yaxis(;; reduce_struct(qualifier("zaxis"), "log"));
  else
    w1.yaxis(; ticlabels_confine=0, ticlabels1=0);
  if(qualifier_exists("zlabel"))
    w1.xlabel(qualifier("zlabel"));
  w1.plot_png(_reshape([0:255],[256,1]); depth=100, cmap=colormap);
  variable CL;
  foreach CL (chi2)
  {
    if(field_to_be_plotted=="chisqr")
      w1.plot([0,0.075*width], [CL,CL] ; line=0, width=2, depth=99, color=chi2_color);
  }
  w1.translate(vector(1.01*width, 0, 0));
  fig.append(w1);
  % --------
  % -------
  % confmap
  variable w2 = xfig_plot_new(width, height);
  if(reverse)
    w2.world(new_x[0]+.5*(new_x[0]-new_x[1]), new_x[-1]-.5*(new_x[0]-new_x[1]), new_y[0]+.5*(new_y[0]-new_y[1]), new_y[-1]-.5*(new_y[0]-new_y[1]));
  else
    w2.world(new_x[0]-.5*(new_x[1]-new_x[0]), new_x[-1]+.5*(new_x[1]-new_x[0]), new_y[0]-.5*(new_y[1]-new_y[0]), new_y[-1]+.5*(new_y[1]-new_y[0]));
  if(qualifier_exists("xaxis") && typeof(qualifier("xaxis"))==Struct_Type)
    w2.xaxis(;; reduce_struct(qualifier("xaxis"),"log"));
  else
    w2.xaxis(; ticlabels_confine=0, ticlabels2=0);
  if(qualifier_exists("yaxis") && typeof(qualifier("yaxis"))==Struct_Type)
    w2.yaxis(;; reduce_struct(qualifier("yaxis"),"log"));
  else
    w2.yaxis(; ticlabels_confine=0, ticlabels2=0);
  w2.plot_png(get_struct_field(cm, field_to_be_plotted); cmap=colormap, depth=100, gmin=mi, gmax=ma);
  if(qualifier_exists("xlabel"))
    w2.xlabel(qualifier("xlabel"));
  if(qualifier_exists("ylabel"))
    w2.ylabel(qualifier("ylabel"));
  % --------------------
#ifeval __get_reference("gcontour_compute")!=NULL
  % chi^2 contour lines:
  foreach CL (gcontour_compute(get_struct_field(cm, "chisqr"), chi2))
  {
    variable cl;
    _for cl (0, length(CL.x_list)-1, 1)
      w2.plot( new_x[0] + (new_x[1]-new_x[0]) * CL.x_list[cl], new_y[0] + (new_y[1]-new_y[0]) * CL.y_list[cl]; line=0, width=2, depth=99, color=chi2_color);
  }
#endif
  % --------------------
  % -------
  % -----------------------
  % Mark best fit with "+":
  if(qualifier_exists("best_fit"))
    w2.plot(keys.best_x, keys.best_y; sym="+", width=1, color=chi2_color);
  % -----------------------
  fig.append(w2);
  %
  if(qualifier_exists("nomultiplot"))
    return w2, w1;
  else
    return fig;
}%}}}

