define RXTE_ASM_lightcurve()
%!%+
%\function{RXTE_ASM_lightcurve}
%\synopsis{retrieves ASM lightcurves for a given source}
%\usage{Struct_Type RXTE_ASM_lightcurve(String_Type sourcename);}
%\qualifiers{
%\qualifier{MJDmin}{earliest MJD to be used}
%\qualifier{MJDmax}{latest MJD to be used}
%\qualifier{dt}{if specified, time resolution in MJD for rebinning}
%\qualifier{no_filter_nan}{do not remove empty bins after rebinning (only with \code{dt})}
%\qualifier{list}{lists available sources; \code{sourcename} may be omitted but can be a regular expression}
%\qualifier{get_list}{as list, but the list of sources is returned as an array of strings}
%\qualifier{save}{saves the light curve data in a local FITS file}
%\qualifier{verbose}{}
%}
%!%-
{
  variable src=NULL;
  switch(_NARGS)
  { case 0: ifnot(qualifier_exists("list")) { help(_function_name()); return; } }
  { case 1: src = (); }
  { help(_function_name()); return; }

  variable filename = "./RXTE-ASM_" + src + ".fits";
  if(qualifier_exists("save"))
  { vmessage("%s: writing %s", _function_name(), filename);
    fits_write_binary_table(filename, src, RXTE_ASM_lightcurve(src));
    return;
  }

  variable path_to_data = NULL;
  try {
    foreach path_to_data ([local_paths.RXTE_ASM_data])
      if(stat_file(path_to_data)!=NULL)  break;
  } catch NotImplementedError: { vmessage("warning (%s): local_paths.RXTE_ASM_data not defined",_function_name()); };

  if(qualifier_exists("list") || qualifier_exists("get_list"))
  {
    if(_isnull(path_to_data) || stat_file(path_to_data)==NULL)
    { vmessage("error (%s): no path to RXTE data found", _function_name());
      return;
    }
    variable source, sources = String_Type[0];
    foreach source (glob(path_to_data+"lightcurves/xa_*_d1.lc"))
    {
      (source,) = strreplace(source, path_to_data+"lightcurves/xa_", "", 1);
      (source,) = strreplace(source, "_d1.lc", "", 1);
      if(src==NULL || string_match(source, src, 1))
	sources = [sources, source];
    }
    sources = sources[array_sort(sources)];
    if(qualifier_exists("get_list"))
      return sources;
    foreach source (sources)
      message(source);
    return;
  }

  variable asm, asm_sum, asm_col, n, col_a, col_b, col_c;
  if(_isnull(path_to_data) || stat_file(path_to_data)==NULL)
  {
    if(stat_file(filename)==NULL)
    { vmessage("error (%s): no path to RXTE data found", _function_name());
      return;
    }
    vmessage("warning (%s): no path to RXTE data found, but using %s", _function_name(), filename);
    asm = fits_read_table(filename);
    asm_sum = struct {
      time = asm.time,
      timedel = asm.timedel,
      rate = asm.rate,
      error = asm.err,
      rdchi_sq = asm.chi2red
    };
    n = length(asm.time);
    asm_col = struct {
      time = [asm.time, asm.time, asm.time],
      timedel = [asm.timedel, asm.timedel, asm.timedel],
      band = String_Type[3*n],
      rate = [asm.rate_a, asm.rate_b, asm.rate_c],
      error = [asm.err_a, asm.err_b, asm.err_c],
      rdchi_sq = [asm.chi2red_a, asm.chi2red_b, asm.chi2red_c],
    };
    asm_col.band[ [  0 :   n-1] ] = "A";
    asm_col.band[ [  n : 2*n-1] ] = "B";
    asm_col.band[ [2*n : 3*n-1] ] = "C";
  }
  else
  {
    filename = path_to_data+"lightcurves/xa_"+src+"_d1.lc";
    if(stat_file(filename)==NULL)
    { vmessage("error (%s): %s does not exist\nAre you sure that the source is called '%s'?", _function_name(), filename, src);
      vmessage("use %s(\"\";list); to see the list of source names", _function_name());
      return NULL;
    }
    asm_sum = fits_read_table(filename, ["time", "rate", "error", "timedel", "rdchi_sq"]);
    %MJDREFF wrong in ASM headers (=0), thus not used.
    %for reference see
    %https://heasarc.gsfc.nasa.gov/docs/xte/recipes/asm_recipe.html
    asm_sum.time = asm_sum.time + fits_read_key(filename, "MJDREFI")+0.000696574074;;

    filename = path_to_data+"colors/xa_"+src+"_d1.col";
    asm_col = fits_read_table(filename, ["time", "band", "rate", "error", "timedel", "rdchi_sq"]);
    %MJDREFF wrong in ASM headers (=0), thus not used.
    %for reference see
    %https://heasarc.gsfc.nasa.gov/docs/xte/recipes/asm_recipe.html
    asm_col.time = asm_col.time + fits_read_key(filename, "MJDREFI")+0.000696574074;
  }

  variable MJDmin = qualifier("MJDmin", min([asm_sum.time, asm_col.time]));
  variable MJDmax = qualifier("MJDmax", max([asm_sum.time, asm_col.time]));
  struct_filter(asm_sum, where(MJDmin <= asm_sum.time <= MJDmax));
  struct_filter(asm_col, where(MJDmin <= asm_col.time <= MJDmax));

  col_a = where(asm_col.band=="A");
  col_b = where(asm_col.band=="B");
  col_c = where(asm_col.band=="C");

  variable i;
  if(length(col_a) != length(col_b) || length(col_b) != length(col_c) || length(col_c) != length(asm_sum.time))
  { vmessage("warning (%s): lightcurves A, B, C, SUM do not have the same length", _function_name());
    vmessage("  len(A)=%d, len(B)=%d, len(C)=%d, len(SUM)=%d", length(col_a), length(col_b), length(col_c), length(asm_sum.time));
    i = min([length(col_a), length(col_b), length(col_c), length(asm_sum.time)]);
    vmessage("  trying to cut light curves to common length %d", i);
    i = [0:i-1];
    col_a = col_a[i];
    col_b = col_b[i];
    col_c = col_c[i];
    struct_filter(asm_sum, i);
  }
  if(length(col_a)==0)
  {
    vmessage("warning (%s): no data on %s found for %.1f <= MJD <= %.1f", _function_name(), src, MJDmin, MJDmax);
    return NULL;
  }
  variable maxdiff_time = maxabs([asm_col.time[col_a]-asm_col.time[col_b],
				  asm_col.time[col_b]-asm_col.time[col_c],
				  asm_col.time[col_c]-asm_sum.time ]);
  variable maxdiff_timedel = maxabs([asm_col.timedel[col_a]-asm_col.timedel[col_b],
				     asm_col.timedel[col_b]-asm_col.timedel[col_c],
				     asm_col.timedel[col_c]-asm_sum.timedel ]);
  if(qualifier_exists("verbose") || maxdiff_time > 1e-6 || maxdiff_timedel > 1e-6)
  {
    vmessage("max |time(A) - time(B)|   = %f", maxabs(asm_col.time[col_a]-asm_col.time[col_b]) );
    vmessage("max |time(B) - time(C)|   = %f", maxabs(asm_col.time[col_b]-asm_col.time[col_c]) );
    vmessage("max |time(C) - time(SUM)| = %f", maxabs(asm_col.time[col_c]-asm_sum.time       ) );

    vmessage("max |timedel(A) - timedel(B)|   = %f", maxabs(asm_col.timedel[col_a]-asm_col.timedel[col_b]) );
    vmessage("max |timedel(B) - timedel(C)|   = %f", maxabs(asm_col.timedel[col_b]-asm_col.timedel[col_c]) );
    vmessage("max |timedel(C) - timedel(SUM)| = %f", maxabs(asm_col.timedel[col_c]-asm_sum.timedel       ) );
  }

  if(qualifier_exists("dt"))
  {
    variable time_lo = [MJDmin : MJDmax : qualifier("dt")];
    variable time_hi = make_hi_grid(time_lo);
    n = length(time_lo);
    variable rev;
    asm = struct {
      time_lo = time_lo,
      time_hi = time_hi,
      time    = (time_lo+time_hi)*0.5,
      n       = histogram(asm_sum.time, time_lo, time_hi, &rev),
      rate    = Float_Type[n],
      err     = Float_Type[n],
      rate_a  = Float_Type[n],
      err_a   = Float_Type[n],
      rate_b  = Float_Type[n],
      err_b   = Float_Type[n],
      rate_c  = Float_Type[n],
      err_c   = Float_Type[n]
    };
    _for i (0, n-1, 1)
    { variable one_over_n = 1./asm.n[i];
      asm.rate[i]   =       sum(asm_sum.rate [      rev[i] ]  )   * one_over_n;
      asm.err[i]    = sqrt( sum(asm_sum.error[      rev[i] ]^2) ) * one_over_n;
      asm.rate_a[i] =       sum(asm_col.rate [col_a[rev[i]]]  )   * one_over_n;
      asm.err_a[i]  = sqrt( sum(asm_col.error[col_a[rev[i]]]^2) ) * one_over_n;
      asm.rate_b[i] =       sum(asm_col.rate [col_b[rev[i]]]  )   * one_over_n;
      asm.err_b[i]  = sqrt( sum(asm_col.error[col_b[rev[i]]]^2) ) * one_over_n;
      asm.rate_c[i] =       sum(asm_col.rate [col_c[rev[i]]]  )   * one_over_n;
      asm.err_c[i]  = sqrt( sum(asm_col.error[col_c[rev[i]]]^2) ) * one_over_n;
    }
    ifnot(qualifier_exists("no_filter_nan"))
      struct_filter(asm, where(asm.n>0));
    return asm;
  }
  else
    return struct {
      time      = asm_sum.time,
      timedel   = asm_sum.timedel,
      rate      = asm_sum.rate,
      err       = asm_sum.error,
      chi2red   = asm_sum.rdchi_sq,
      rate_a    = asm_col.rate    [col_a],
      err_a     = asm_col.error   [col_a],
      chi2red_a = asm_col.rdchi_sq[col_a],
      rate_b    = asm_col.rate    [col_b],
      err_b     = asm_col.error   [col_b],
      chi2red_b = asm_col.rdchi_sq[col_a],
      rate_c    = asm_col.rate    [col_c],
      err_c     = asm_col.error   [col_c],
      chi2red_c = asm_col.rdchi_sq[col_a],
    };
}
