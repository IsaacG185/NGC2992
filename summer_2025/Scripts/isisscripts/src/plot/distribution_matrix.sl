% -*- mode: slang; mode: fold; -*- %

require("xfig");
require("gcontour");

define hist1d_confidence (lo, hi, h)
%!%+
%\function{hist1d_confidence}
%#c%{{{
%\synopsis{Find the confidence interval for histogram}
%\usage{(Min,Max) = hist1d_confidence(lo, hi, hist);}
%\qualifiers{
%\qualifier{conf}{[=0.9] confidence limit (between 0 and 1)}
%\qualifier{index}{if given, return the indices of lo and hi bin}
%}
%\description
%    Find the bin boundary values such that they enclose the smallest volume
%    equal to \code{conf}. The result is guaranteed to have at least \code{conf}
%    integral. Works only for unimodal dsitributions.
%!%-
{
  variable conf = _min(1.0, _max(0.68, qualifier("conf", 0.9)));
  variable i,j,ii,jj,s,t;

  s = [0,cumsum(h*1./sum(h))];

  i = wherefirst(s>conf);
  j=0;
  ii=i;
  jj=j;

  t = s[i]-s[j];

  while (i<(length(s)-1))
  {
    i++;
    j++;

    if ((s[i]-s[j])>=t)
    {
      ii=i;
      while (j<i)
      {
	if ((s[i]-s[j])<conf)
	  break;
	j++;
      }
      jj=j;
      t = s[i]-s[j];
    }
  }
  if (jj>0) jj--;
  if (ii>=length(hi)) ii = length(hi)-1;

  if (qualifier_exists("index"))
    return jj,ii;
  return lo[jj], hi[ii];
}
%}}}

define hist2d_confidence (x, y, img)
%!%+
%\function{hist2d_confidence}
%#c%{{{
%!%-
{
#iffalse
  variable conf = _min(1.0, _max(0.0, qualifier("conf", 0.9)));

  variable dim = array_shape(img);
  variable wmax = wherefirstmax(img);

  variable l,r,t,b;

  l = wmax, r = wmax, t = wmax, b = wmax;

  variable i;
  variable r = gcontour_compute(img+imin, [s])[0];
  variable x0 = x[0], xm = (x[-1]-x0)/dim[0];
  variable y0 = y[0], ym = (y[-1]-y0)/dim[1];

  _for i (0, length(r.x_list)-1)
  {
    r.x_list[i] = r.x_list[i]*xm+x0;
    r.y_list[i] = r.y_list[i]*ym+y0;
  }

  return r;
#endif
}
%}}}

private define distM_array (dist) %{{{
{
  variable i,j;

  variable rnames = {"pairs", "hist2d", "hist1d", "grids"};
  if (qualifier_exists("conf"))
  {
    list_append(rnames, "conf1d");
    list_append(rnames, "conf2d");
  }
  variable r = @Struct_Type(list_to_array(rnames));
  variable conf = qualifier("conf", 0.9);
  if (conf == NULL)
    conf = 0.9;

  r.grids = Array_Type[length(dist)];
  _for i (0, length(dist)-1)
    r.grids[i] = qualifier(sprintf("grid%d", i),
	[qualifier(sprintf("grid%dmin", i), min(dist[i])):qualifier(sprintf("grid%dmax",i), max(dist[i])):#qualifier("n", 50)]);

  r.hist1d = Array_Type[length(dist)];
  if (qualifier_exists("conf"))
    r.conf1d = Double_Type[length(dist), 2];

  _for i (0, length(dist)-1)
  {
    r.hist1d[i] = histogram(dist[i], r.grids[i][[:-2]], r.grids[i][[1:]]);
    r.hist1d[i] *= 1./length(dist[i]);
    if (qualifier_exists("conf"))
    {
      r.conf1d[i, *] = [hist1d_confidence(r.grids[i][[:-2]], r.grids[i][[1:]], r.hist1d[i]; conf=conf)];
    }
  }

  r.hist2d = Array_Type[length(dist)-1];
  r.pairs = Array_Type[length(dist)-1];
  if (qualifier_exists("conf"))
    r.conf2d = Array_Type[length(dist)-1];

  _for i (0, length(dist)-2)
  {
    variable x = 2*i; ifnot (x<length(dist)) x = 2*(length(dist)-i-1)+1;
    r.pairs[i] = Array_Type[length(dist)-1-i];
    r.hist2d[i] = Array_Type[length(dist)-1-i];

    if (qualifier_exists("conf"))
      r.conf2d[i] = Struct_Type[length(dist)-1-i];

    _for j (0, length(dist)-2-i)
    {
      variable y = 2*j+1; ifnot (y < length(dist)) y = 2*(length(dist)-1-j);
      r.pairs[i][j] = [x,y];
      r.hist2d[i][j] = histogram2d(dist[x], dist[y], r.grids[x][[:-2]], r.grids[y][[1:]]);
      r.hist2d[i][j] *= 1./length(dist[i]);

      if (qualifier_exists("conf"))
	r.conf2d[i][j] = hist2d_confidence(r.grids[x], r.grids[y], r.hist2d[i][j]; conf=conf);
    }
  }

  return r;
}
%}}}

private define distM_struct (dist) %{{{
{
  variable fields = qualifier("fields", get_struct_field_names(dist));

  variable arr = Array_Type[length(fields)];
  variable i;
  _for i (0, length(arr)-1)
    arr[i] = get_struct_field(dist, fields[i]);

  return distM_array(arr;; __qualifiers());
}
%}}}%

define distribution_matrix (distribution_points)
%!%+
%\function{distribution_triangle}
%#c%{{{
%\synopsis{Calculate 1D and 2D probability distributions}
%\usage{Struct_Type dm = distribution_matrix(Array_Type/List_Type v);
%\altusage{dm = distribution_matrix(Struct_Type v);}}
%\qualifiers{
%\qualifier{gridX}{histogram grid for dimension X where X starts counting at 0}
%\qualifier{gridXmin}{[=min(vX)] bottom boundary for dimension X grid}
%\qualifier{gridXmax}{[=max(vX)] top boundary for dimension X grid}
%\qualifier{n}{number of grid points (only relevant for min/max)}
%\qualifier{fields}{Use only struct fields given in this name array (only
%  relevant if input is a struct)}
%}
%\description
%    Calculates the probability distributions from a given high dimensional
%    set of state vectors (think MCMC results). The resulting structure
%    can be used with \code{xfig_plot_distribution_matrix} to plot the distributions
%    in a projection like triangle matrix.
%
%\seealso{xfig_plot_distribution_matrix}
%!%-
{
  if (Struct_Type == typeof(distribution_points))
    return distM_struct(distribution_points;; __qualifiers());
  else
    return distM_array(distribution_points;; __qualifiers());
}
%}}}

private define xfig_prepare_dm_xpp (dm, tile_size) %{{{
{
  variable xpp = {};
  variable i,j,x,y;

  _for i (0, length(dm.pairs)-1)
  {
    list_append(xpp, {});
    _for j (0, length(dm.pairs[i])-1)
    {
      list_append(xpp[-1], xfig_plot_new(tile_size,tile_size));
      x = dm.pairs[i][j][0];
      y = dm.pairs[i][j][1];
      xpp[-1][-1].xaxis(;; qualifier_exists("axis") ? qualifier("axis")[x] : qualifier(sprintf("axis%d", x)));
      xpp[-1][-1].yaxis(;; qualifier_exists("axis") ? qualifier("axis")[y] : qualifier(sprintf("axis%d", y)));
      xpp[-1][-1].axis(; off);
      xpp[-1][-1].world(min(dm.grids[x]), max(dm.grids[x]), min(dm.grids[y]), max(dm.grids[y]));
      xpp[-1][-1].plot_png(-transpose(dm.hist2d[i][j]); cmap=qualifier("cmap", "gray"));
      if (qualifier_exists("mark"))
	xpp[-1][-1].plot(qualifier("mark")[x], qualifier("mark")[y]; sym="x", color=qualifier("color", "red"));
    }
  }

  return xpp;
}
%}}}

private define xfig_prepare_dm_ypp (dm, tile_size) %{{{
{
  variable i,x,lo,hi;

  variable ypp = {};
  variable ymax = 0.0;
  _for i (0, length(dm.pairs)-1)
  {
    x = dm.pairs[i][0][0];
    ymax = _max(ymax, max(dm.hist1d[x]));
  }

  _for i (0, length(dm.pairs)-1)
  {
    list_append(ypp, xfig_plot_new(tile_size,tile_size));
    x = dm.pairs[i][0][0];
    ypp[-1].x2axis(;; qualifier_exists("axis") ? qualifier("axis")[x] : qualifier(sprintf("axis%d", x)));
    ypp[-1].xaxis(;off);
    ypp[-1].yaxis(; off);
    ypp[-1].world(min(dm.grids[x]), max(dm.grids[x]),
		  qualifier("y1min", qualifier("ymin", 0)),
		  qualifier("y1max", qualifier("ymax", ymax)));
    ypp[-1].hplot(dm.grids[x], dm.hist1d[x]);
    if (qualifier_exists("mark"))
      ypp[-1].plot(qualifier("mark")[x]+[0,0], [0,1]; world10, color=qualifier("color", "red"));
    if (qualifier_exists("conf"))
    {
      ifnot (struct_field_exists(dm, "conf1d"))
	(lo,hi) = hist1d_confidence(dm.grids[x][[:-2]], dm.grids[x][[1:]], dm.hist1d[x]);
      else
	(lo, hi) = (dm.conf1d[x][0],dm.conf1d[x][1]);
      ypp[-1].plot([lo, lo], [0,1]; world10, line=1);
      ypp[-1].plot([hi, hi], [0,1]; world10, line=1);
    }
  }

  return ypp;
}
%}}}

private define xfig_prepare_dm_zpp (dm, tile_size) %{{{
{
  variable zpp = {};
  variable zmax = 0.0;
  variable j,y,lo,hi;
  _for j (0, length(dm.pairs[0])-1)
  {
    y = dm.pairs[0][j][1];
    zmax = _max(zmax, max(dm.hist1d[y]));
  }

  _for j (0, length(dm.pairs[0])-1)
  {
    list_append(zpp, xfig_plot_new(tile_size,tile_size));
    y = dm.pairs[0][j][1];
    zpp[-1].yaxis(;; qualifier_exists("axis") ? qualifier("axis")[y] : qualifier(sprintf("axis%d", y)));
    zpp[-1].yaxis(; off);
    zpp[-1].xaxis(; off);
    zpp[-1].world(qualifier("y2max", qualifier("ymax", zmax)),
		  qualifier("y2min", qualifier("ymin", 0)),
		  min(dm.grids[y]), max(dm.grids[y]));
    zpp[-1].plot(dm.hist1d[y][[0:2*length(dm.hist1d[y])-1]/2],
		 dm.grids[y][[1:2*(length(dm.grids[y])-1)]/2]);
    if (qualifier_exists("mark"))
      zpp[-1].plot([0,1], qualifier("mark")[y]+[0,0]; world01, color=qualifier("color", "red"));
    if (qualifier_exists("conf"))
    {
      ifnot (struct_field_exists(dm, "conf1d"))
	(lo,hi) = hist1d_confidence(dm.grids[y][[:-2]], dm.grids[y][[1:]], dm.hist1d[y]);
      else
	(lo,hi) = (dm.conf1d[y][0], dm.conf1d[y][1]);
      zpp[-1].plot([0,1], [lo, lo]; world01, line=1);
      zpp[-1].plot([0,1], [hi, hi]; world01, line=1);
    }
  }

  return zpp;
}
%}}}

private define xfig_prepare_dm (dm) %{{{
{
  variable tile_size = qualifier("tile_size", qualifier("size", 20)*1./(length(dm.grids)-1));

  variable xpp = xfig_prepare_dm_xpp(dm, tile_size;; __qualifiers());
  variable ypp = xfig_prepare_dm_ypp(dm, tile_size;; __qualifiers());
  variable zpp = xfig_prepare_dm_zpp(dm, tile_size;; __qualifiers());

  variable i;

  variable blank = xfig_plot_new(tile_size,tile_size);
  blank.axis(; off);
  variable Y = xfig_new_hbox_compound(blank, __push_list(ypp));
  variable Z = xfig_new_vbox_compound(__push_list(zpp));
  _for i (0, length(dm.pairs)-1)
    Z = xfig_new_hbox_compound(Z, xfig_new_vbox_compound(__push_list(xpp[i])));

  variable X = xfig_new_vbox_compound(Y, Z);

  return X, xpp, ypp, zpp;
}
%}}}

define xfig_plot_distribution_matrix ()
%!%+
%\function{xfig_plot_distribution_matrix}
%#c%{{{
%\synopsis{Plot distribution matrix}
%\usage{xfig_plot_distribution_matrix(Struct_Type dm[, String_Type file]);}
%\qualifiers{
%\qualifier{names}{string array containting the names for all dimensions}
%\qualifier{nameX}{add label for dimension X}
%}
%\description
%    Plot the distribution matrix to file \code{file} using xfig. If 
%    \code{file} is not given or is \code{NULL} return instead the xfig
%    object.
%
%\example
%    variable dm = distribution_matrix({v0, v1, v2}); % vX are the state values in the dimensions
%    variable names = ["dim0", "dim1", "dim2"];
%    xfig_plot_distribution_matrix(dm, "distribution.pdf"; names=names, name1="other label");
%
%\seealso{distribution_matrix}
%!%-
{ 
  variable dm, file = NULL;

  switch (_NARGS)
  { case 1: dm = (); }
  { (dm, file) = (); }
  variable X, xpp, ypp, zpp, i, j;
  (X, xpp, ypp, zpp) = xfig_prepare_dm(dm;; __qualifiers());
  variable y1label_x = _Inf;

  _for i (0, length(dm.pairs)-1)
  {
    ypp[i].x2axis(; on);
    if (qualifier_exists(sprintf("labels%d", dm.pairs[i][0][0])) || qualifier_exists("labels"))
      ypp[i].x2label(qualifier(sprintf("labels%d", dm.pairs[i][0][0]), qualifier("labels")[dm.pairs[i][0][0]]));
  }

  _for j (0, length(dm.pairs[0])-1)
  {
    zpp[j].y1axis(; on);
    if (qualifier_exists(sprintf("labels%d", dm.pairs[0][j][1])) || qualifier_exists("labels"))
      zpp[j].ylabel(qualifier(sprintf("labels%d", dm.pairs[0][j][1]), qualifier("labels")[dm.pairs[0][j][1]]));
    if (zpp[j].plot_data.y1axis.axis_label != NULL)
      y1label_x = _min(y1label_x, zpp[j].plot_data.y1axis.axis_label.X.x);
  }

  _for j (0, length(zpp)-1)
  {
    if (zpp[j].plot_data.y1axis.axis_label != NULL)
      zpp[j].plot_data.y1axis.axis_label.X.x = y1label_x;
  }

  if (NULL != file)
    X.render(file);
  else
    return X;
}
%}}}
