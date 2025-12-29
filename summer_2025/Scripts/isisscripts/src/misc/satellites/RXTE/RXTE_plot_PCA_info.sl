define RXTE_plot_PCA_info()
%!%+
%\function{RXTE_plot_PCA_info}
%\synopsis{plots an overview of an RXTE observation (lc, GTI, SAA, bkg)}
%\usage{RXTE_plot_PCA_info(String_Type dirs[]);
%\altusage{Struct_Type RXTE_plot_PCA_info(String_Type dirs[]; get_info)}
%}
%\qualifiers{
%\qualifier{electron}{set to electron ratio threshold for data extraction}
%\qualifier{noback}{set if no bkg subtraction is to be performed}
%\qualifier{earthvle}{set if EarthVLE background model is to be used}
%\qualifier{faint}{set if Faint background model is to be used}
%\qualifier{q6}{set if Q6 background model is to be used (default is to test for earthvle,faint,q6)}
%\qualifier{skyvle}{set if SkyVLE background model is to be used (default)}
%\qualifier{exclusive}{set to search for data that was extracted
%                 with the exclusive keyword to pca_standard being set.}
%\qualifier{top}{set to read top-layer data}
%\qualifier{nopcu0}{set to search for data that was extracted ignoring PCU0}
%\qualifier{fivepcu}{plot count-rates wrt to whole PCA, i.e., normalizing to 5 PCUs.
%               Default is to plot the average countrate per PCU.}
%\qualifier{charsize_obsid}{}
%\qualifier{get_info}{returns the info structure}
%}
%\description
%    The elements of \code{dirs} may contain globbing expressions.
%\seealso{aitlib/rxte/rxtescreen.pro}
%!%-
{
  variable dirs;
  switch(_NARGS)
  { case 1: dirs = (); }
  { help(_function_name()); return; }

  variable dir, real_dirs = String_Type[0];
  foreach dir (glob(dirs))
    if(stat_is("dir", stat_file(dir).st_mode))
      real_dirs = [real_dirs, dir];
  dirs = real_dirs;

  % call RXTE_PCA_info
  variable qualifiers = __qualifiers();
  variable info = RXTE_PCA_info(dirs;; qualifiers);

  % check info (should top and exclusive have been set?)
  if(length(info.lc.time)==0)
  {
    vmessage("warning (%s): no data found", _function_name());
    ifnot(qualifier_exists("exclusive") || qualifier_exists("top"))
    { message("trying options 'exclusive' and 'top':\n");
      info = RXTE_PCA_info(dirs;; struct_combine(qualifiers, struct { exclusive, top }));
      if(length(info.lc.time)==0)
        vmessage("warning (%s): still no data found", _function_name());
    }
    if(length(info.lc.time)==0)
      if(qualifier_exists("get_info"))
        return info;
      else
	return;
  }

  % prepare plotting
  variable time0 = round(info.lc.time[0]);
  variable tmin = info.lc.time[ 0] - time0;
  variable tmax = info.lc.time[-1] - time0;
  variable dt = 0.05*(tmax-tmin);
  tmin -= dt;
  tmax += dt;

  % plot
  multiplot([2,1,3]);
  xrange(tmin, tmax);

  % lightcurve
  yrange(0.9*min(info.lc.rate), 1.1*max(info.lc.rate));
  ylabel("PCA counts/s/PCU");
  if(qualifier_exists("fivepcu"))  ylabel("PCA counts/s");
  plot_with_err(info.lc.time-time0, info.lc.rate, info.lc.error);

  % electron ratio
  ylabel("El. ratio");
  yrange(0, _max(0.25, 1.02*info.xfl.electron));
  init_plot;
  variable i1 = 0;
  variable i2, len = length(info.xfl.time);
  _for i2 (1, len, 1)
    if(i2==len || info.xfl.time[i2]>info.xfl.time[i2-1]+32/86400.)
    { color(1); oplot(info.xfl.time[[i1:i2-1]]-time0, info.xfl.electron[[i1:i2-1]]);
      i1 = i2;
    }
  oplot([tmin, tmax], qualifier("electron", 0.1)*[1, 1]);

  % multiple horizontal lines (=> no numerical y-axis)
  variable i, X, y=11;
  mpane(3);
  _pgsci(1);
  _pgswin(tmin, tmax, 0, y+1);
  _pgbox("BCNST", 0, 1, "BC", 0, 1);

  % ObsID
  _pgptxt(tmin-dt, y-0.5, 0, 0.5, "ObsID");
  _pgsch(qualifier("charsize_obsid", 0.8));
  _for i (0, length(info.obstime.start)-1, 1)
  { X = [info.obstime.start[i], info.obstime.stop[i]]-time0;
    ()=_pgline(2, X, [y, y]);
    _pgptxt((X[0]+X[1])/2, y-0.25-0.5*(-1)^i, 0, 0.5, strtok(dirs[i], "/")[-1]);
  }
  y -= 2;
  _pgsch(1);

  % all others are done in the same way
  variable label_start_stop;
  foreach label_start_stop ([
    { "SAA",    info.obscat.in_saa,     info.obscat.out_saa },
    { "occult", info.obscat.in_occult,  info.obscat.out_occult },
    { "Good",  info.obscat.start_good, info.obscat.end_good },
    { "GTI",   info.gti.start,         info.gti.stop },
    { "PCU 0", info.xfl.pcu0.start,    info.xfl.pcu0.stop },
    { "PCU 1", info.xfl.pcu1.start,    info.xfl.pcu1.stop },
    { "PCU 2", info.xfl.pcu2.start,    info.xfl.pcu2.stop },
    { "PCU 3", info.xfl.pcu3.start,    info.xfl.pcu3.stop },
    { "PCU 4", info.xfl.pcu4.start,    info.xfl.pcu4.stop },
  ])
  { _pgptxt(tmin-dt, y-0.2, 0, 0.5, label_start_stop[0]);
    _for i (0, length(label_start_stop[1])-1, 1)
    { X = [label_start_stop[1][i], label_start_stop[2][i]]-time0;
      if(X[0]>tmin || tmax<X[1])
        ()=_pgline(2, X, [y, y]);
    }
    y--;
  }
  % FIXME:
  _pgptxt((tmin+tmax)/2, y-2, 0, 0.5, sprintf("days since MJD %.0f", time0));

  multiplot(1);

  % return info if requested
  if(qualifier_exists("get_info"))  return info;
}
