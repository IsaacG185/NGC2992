
private variable confmap_data_x, confmap_data_y, confmap_data_absdiff_x, confmap_data_absdiff_y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define compare_confmap_data_indices(i, j)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  if(confmap_data_y[i] < confmap_data_y[j] - confmap_data_absdiff_y)
    return -1;
  if(confmap_data_y[i] > confmap_data_y[j] + confmap_data_absdiff_y)
    return +1;

  if(confmap_data_x[i] < confmap_data_x[j] - confmap_data_absdiff_x)
    return -1;
  if(confmap_data_x[i] > confmap_data_x[j] + confmap_data_absdiff_x)
    return +1;
  return 0;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_confmap_collect_results()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_confmap_collect_results}
%\synopsis{collect results produced by get_confmap}
%\usage{get_confmap_collect_results(String_Type save_basefilename);}
%\description
%    \code{get_confmap_collect_results} is used internally by \code{get_confmap},
%    but it can also collect the results of an unfinsihed calculation.
%\qualifiers{
%\qualifier{remove_files}{: if set, \code{save_basefilename+"_*.dat"} files will be deleted when read}
%\qualifier{use_file_from_save_conf}{: if set, results are appended to \code{save_basefilename+".fits"}}
%}
%\seealso{get_confmap}
%!%-
{
  if(_NARGS!=1) return help(_function_name());
  variable confmap_save_basefilename = ();
  variable remove_files = qualifier("remove_files");
  if(remove_files==NULL)  remove_files = qualifier_exists("remove_files");
  variable use_file_from_save_conf = qualifier_exists("use_file_from_save_conf");

  variable infofile = confmap_save_basefilename+".info";
  variable fp = fopen(infofile, "r");

  % tokens of line #1: 0=parameter name, 1=best fit value, 2=min[grid], 3=max[grid], 4=n[grid], 5=max[grid,ISIS]
  variable tok = strtok(fgetslines(fp,1)[0], "\t");
  variable origpar1 = tok[0],  best_par1 = atof(tok[1]), n1 = atoi(tok[4]), max1=atof(tok[5]);
  variable par1 = escapedParameterName(origpar1);
  variable Xvalues = [atof(tok[2]) : atof(tok[3]) : #n1];
  confmap_data_absdiff_x = (Xvalues[1]-Xvalues[0])/3.;

  % tokens of line #2: 0=parameter name, 1=best fit value, 2=min[grid], 3=max[grid], 4=n[grid], 5=max[grid,ISIS]
           tok = strtok(fgetslines(fp,1)[0], "\t");
  variable origpar2 = tok[0],  best_par2 = atof(tok[1]), n2 = atoi(tok[4]), max2=atof(tok[5]);
  variable par2 = escapedParameterName(origpar2);
  variable Yvalues = [atof(tok[2]) : atof(tok[3]) : #n2];
  confmap_data_absdiff_y = (Yvalues[1]-Yvalues[0])/3.;

  % tokens of line #3: 0=fit_statistic, 1=best_statistic
           tok = strtok(fgetslines(fp,1)[0], "= ");
  variable fit_statistic = tok[0], best_statistic = atof(tok[1]);

  % line #4: the fit-function
  variable fitfun = fgetslines(fp,1)[0];

  % tokens of line #5: parameter names and chi2
  variable fieldnames = strtok(fgetslines(fp,1)[0], "\t\n");
  variable i, n = length(fieldnames);
  variable confmap_data = @Struct_Type(fieldnames);

  ()=fclose(fp);

  variable file, datafiles = glob(confmap_save_basefilename+"_[0-9]*.dat");
  foreach file (datafiles)
    _for i (0, n-1, 1)
    {
      variable col = readcol(file, 1+i);
      variable COL = get_struct_field(confmap_data, fieldnames[i]);
      set_struct_field(confmap_data, fieldnames[i], COL==NULL ? col : [COL, col]);
    }
  col = NULL; COL = NULL;

  confmap_data_x = get_struct_field(confmap_data, par1);
  confmap_data_y = get_struct_field(confmap_data, par2);

  variable n_data = length(get_struct_field(confmap_data, fit_statistic));
  if(n_data < n1*n2)
  {
    vmessage("warning (%s): expecting %d parameter combinations, found %d",
	     _function_name(), n1*n2, n_data);
    variable x, y, Xmiss={}, Ymiss={};
    foreach x (Xvalues)
      foreach y (Yvalues)
	ifnot(any(    feqs(confmap_data_x, x, 0, confmap_data_absdiff_x)
		  and feqs(confmap_data_y, y, 0, confmap_data_absdiff_y)))
	  list_append(Xmiss, x),
	  list_append(Ymiss, y);
    confmap_data_x = [confmap_data_x, list_to_array(Xmiss)];
    confmap_data_y = [confmap_data_y, list_to_array(Ymiss)];
    set_struct_field(confmap_data, par1, confmap_data_x);
    set_struct_field(confmap_data, par2, confmap_data_y);
    variable n_miss = length(Xmiss);
    vmessage("adding %d NaNs => %d %s= %dx%d parameter combinations in total", n_miss, n_data+n_miss, (n_data+n_miss-n1*n2 ? "!" : ""), n1, n2);
    variable NaNs = Double_Type[n_miss] + _NaN;
    variable field;
    foreach field (fieldnames)
      if(field!=par1 && field!=par2)
	set_struct_field(confmap_data, field,
			 [get_struct_field(confmap_data, field), NaNs]);
  }
  n_data = length(get_struct_field(confmap_data, fit_statistic));
  if(n_data != n1*n2)
    vmessage("warning (%s): something is wrong!", _function_name());

  % sort parameter table
  struct_filter(confmap_data, array_sort([0:n_data-1], &compare_confmap_data_indices));

  _for i (0, n-1, 1)
    set_struct_field(confmap_data, fieldnames[i],
		     typecast(get_struct_field(confmap_data, fieldnames[i]), Float_Type)
		    );
  fp = fits_open_file(confmap_save_basefilename+".fits", use_file_from_save_conf ? "w" : "c");
  ifnot(use_file_from_save_conf)
  {
    % fits_write_image(fp, "chi2", _reshape(confmap_data.chi2, [n2, n1]),
    %                  Xvalues, Yvalues, par1, par2; WCS="P");

    % after <ISIS-source-dir>/share/fits_module_dep.sl:
    ()=_fits_create_img(fp, -32, [n2, n1]);
    ()=_fits_write_img(fp, _reshape(get_struct_field(confmap_data, fit_statistic)-best_statistic, [n2, n1]));
    ()=_fits_update_key(fp, "BESTSTAT", best_statistic, "Best-fit $fit_statistic value"$);
    ()=_fits_update_key(fp, "BEST_X",  best_par1, "X-coordinate, best-fit $fit_statistic value"$);
    ()=_fits_update_key(fp, "BEST_Y",  best_par2, "Y-coordinate, best-fit $fit_statistic value"$);
    ()=_fits_update_key(fp, "PXNAME", origpar1, "");
    ()=_fits_update_key(fp, "PXMIN", Xvalues[0], "");
    ()=_fits_update_key(fp, "PXMAX", max1, "");
    ()=_fits_update_key(fp, "PXNUM", n1, "");
    ()=_fits_update_key(fp, "PYNAME", origpar2, "");
    ()=_fits_update_key(fp, "PYMIN", Yvalues[0], "");
    ()=_fits_update_key(fp, "PYMAX", max2, "");
    ()=_fits_update_key(fp, "PYNUM", n2, "");
    ()=_fits_write_comment (fp, `fit_fun("$fitfun")`$);
    variable dx = (max1-Xvalues[0])/double(n1);
    variable dy = (max2-Yvalues[0])/double(n2);
    ()=_fits_update_key(fp, "CTYPE1P", par1, "");
    ()=_fits_update_key(fp, "CRVAL1P", Xvalues[0], "");
    ()=_fits_update_key(fp, "CRPIX1P", 1.0, "");
    ()=_fits_update_key(fp, "CDELT1P", dx, "");
    ()=_fits_update_key(fp, "WCSTY1P", "PHYSICAL", "");
    ()=_fits_update_key(fp, "CUNIT1P", "", "");
    ()=_fits_update_key(fp, "CTYPE2P", par2, "");
    ()=_fits_update_key(fp, "CRVAL2P", Yvalues[0], "");
    ()=_fits_update_key(fp, "CRPIX2P", 1.0, "");
    ()=_fits_update_key(fp, "CDELT2P", dy, "");
    ()=_fits_update_key(fp, "WCSTY2P", "PHYSICAL", "");
    ()=_fits_update_key(fp, "CUNIT2P", "", "");
    if(dx != 0.0 && dy != 0.0)
    {
      ()=_fits_update_key(fp, "LTV1",   1.0 - Xvalues[0]/dx, "");
      ()=_fits_update_key(fp, "LTM1_1", 1.0/dx, "");
      ()=_fits_update_key(fp, "LTV2",   1.0 -Yvalues[0]/dy, "");
      ()=_fits_update_key(fp, "LTM2_2", 1.0/dy, "");
    }
  }

  fits_write_binary_table(fp, "confmap data", confmap_data);
  variable par;
  foreach par (fieldnames[[:-2]])
    ifnot(par==par1 || par==par2)
      fits_write_image(fp, par,
		       _reshape(get_struct_field(confmap_data, par), [n2, n1]),
		       Xvalues, Yvalues, par1, par2);
  fits_close_file(fp);

  % If no error has occured so far:
  if(remove_files)
  {
    foreach file (datafiles)
      ()=remove(file);
    ()=remove(infofile);
  }
}
