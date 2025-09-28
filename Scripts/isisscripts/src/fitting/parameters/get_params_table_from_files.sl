define get_params_table_from_files()
%!%+
%\function{get_params_table_from_files}
%\synopsis{retrieves fit-parameter information from files}
%\usage{Struct_Type get_params_table_from_files(String_Type filenames[]);}
%\qualifiers{
%\qualifier{free}{only include free parameters}
%\qualifier{par}{array of parameters to be included}
%\qualifier{filename}{include filenames into the structure}
%\qualifier{nominmax}{do not include min max values}
%\qualifier{eval_counts}{evaluates the model and returns the statistic as well.
%                   It is assumed that the appropriate data is already loaded.}
%\qualifier{verbose}{show name of parameter files while being processed}
%}
%\description
%    \code{filename} may be a globbing expression.
%    It is assumed that all parameter files rely on the same model
%    and that this model can be loaded with the current data set.
%!%-
{
  variable parfiles;
  switch(_NARGS)
  { case 1: parfiles = (); }
  { help(_function_name()); return; }

  parfiles = glob(parfiles);
  parfiles = parfiles[array_sort(parfiles)];
  variable i, n = length(parfiles);

  variable fieldname, fieldnames = String_Type[0];  % field names of the returned structure

  variable store_filenames = qualifier_exists("filename");
  if(store_filenames)  fieldnames = [fieldnames, "filename"];

  load_par(parfiles[0]);  % use parameter names from first file
  variable par = get_params();
  variable parnames = array_struct_field(par, "name");
  if(qualifier_exists("free"))
    parnames = parnames[where(    array_struct_field(par, "freeze")==0
%			      and array_struct_field(par, "tie")==NULL  % array_struct_field cannot work with NULLs and integers
%			      and array_struct_field(par, "fun")==NULL  % same here
			     )];
  parnames = qualifier("par", parnames);
  variable nominmax = qualifier_exists("nominmax");
  foreach par ( par )  % (get_params())
    if(any(par.name == parnames))
      fieldnames = [fieldnames, escapedParameterName(par.name)+(nominmax ? "" : ["", "_min", "_max"])];
  if(qualifier_exists("eval_counts"))
    fieldnames = [fieldnames, "statistic", "num_variable_params", "red_statistic"];
  variable params_table = @Struct_Type(fieldnames);
  foreach fieldname (fieldnames)  set_struct_field(params_table, fieldname, Double_Type[n]);
   if(store_filenames)  params_table.filename = parfiles;

  variable verbose = qualifier_exists("verbose") || qualifier_exists("eval_counts");
  _for i (0, n-1, 1)
  { if(verbose)  vmessage("processing %s", parfiles[i]);
    load_par(parfiles[i]);
    foreach par (get_params())
      if(any(par.name == parnames))
      { variable escaped_par_name = escapedParameterName(par.name);
        get_struct_field(params_table, escaped_par_name       )[i] = par.value;
	ifnot(nominmax)
	{ get_struct_field(params_table, escaped_par_name+"_min")[i] = par.min;
          get_struct_field(params_table, escaped_par_name+"_max")[i] = par.max;
	}
      }
    if(qualifier_exists("eval_counts"))
    { variable s;
      ()=eval_counts(&s);
      params_table.statistic          [i] = s.statistic;
      params_table.num_variable_params[i] = s.num_variable_params;
      params_table.red_statistic      [i] = s.statistic/(s.num_bins-s.num_variable_params);
    }
  }
  return params_table;
}
