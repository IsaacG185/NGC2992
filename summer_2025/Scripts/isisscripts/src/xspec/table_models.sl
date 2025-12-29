% -*- mode: slang; mode: fold; -*- %

private define tableModelInvalid (self) %{{{
{
  throw UsageError, "Table model object has become invalid!";
}
%}}}

private define tableModelReset (table) %{{{
{
  table.close();
  table.set_function = &tableModelInvalid;
  table.set_additional = &tableModelInvalid;
  table.set_grid = &tableModelInvalid;
  table.add_parameter = &tableModelInvalid;
  table.add_additional = &tableModelInvalid;
  table.numbvals = NULL;
  table.parameter_list = {};
  table.additional_parameter_list = {};

  % remove is safe, we have created it deliberately
  remove(table.filename);
}
%}}}

private define tableModelParameterList (list, name, values) %{{{
{
  variable param = struct {
    name = name,
    values = NULL,
    method = qualifier_exists("log"),
    unit = qualifier("unit", ""),
    minimum = qualifier("minimum", 0.),
    bottom = qualifier("bottom", 0.),
    top = qualifier("top", 1.),
    maximum = qualifier("maximum", 1.),
    initial = qualifier("inital", 0.),
    delta = qualifier("delta", 1e-3),
  };
  
  if (NULL != values) {
    param.values=  values[array_sort(values)];
    param.minimum= qualifier("minimum", min(values));
    param.bottom=  qualifier("bottom", min(values));
    param.top=     qualifier("top", max(values));
    param.maximum= qualifier("maximum", max(values));
    param.initial= qualifier("initial", mean(values));
    param.delta=   qualifier("delta", (max(values)-min(values))*1e-3);
  };

  list_append(@list, param);
}
%}}}

private define tableModelUniqueParameter (table, name) %{{{
{
  variable p;
  foreach p (table.parameter_list)
    if (p.name == name)
      throw UsageError, sprintf("Parameter with name '%s' already exists", name);
  foreach p (table.additional_parameter_list)
    if (p.name == name)
      throw UsageError, sprintf("Parameter with name '%s' already exists", name);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelAddParameter (self, name, values)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.add_parameter}
%\synopsis{Add interpolation parameter to table model}
%\usage{table_model.add_parameter(String_Type name, Double_Type[] values);}
%#c%{{{
%\qualifiers{
%  \qualifier{log}{if given, parameter is interpolated logarithmically rather than linearly}
%  \qualifier{unit}{[=""] Set the unit of the parameter}
%  \qualifier{minimum}{[=min(values)] Set hard lower limit}
%  \qualifier{bottom}{[=min(values)] Set minimum parameter range}
%  \qualifier{top}{[=max(values)] Set maximum parameter range}
%  \qualifier{maximum}{[=max(values)] Set hard upper limit}
%  \qualifier{initial}{[=mean(values)] Set initial parameter value}
%  \qualifier{delta}{[=(max(values)-min(values))*1e-2] Set parameter step hint}
%}
%\description
%  Each call to this function adds a new parameter with the given name
%  and given interpolation points for this parameter. The table model gets
%  interpolated for this given points.
%
%\seealso{table_model.add_additional}
%!%-
{
  tableModelUniqueParameter(self, name);
  tableModelParameterList(&(self.parameter_list), name, values;; __qualifiers);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelAddAdditionalParameter (self, name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.add_additional}
%\synopsis{Add additional contribution to interpolated spectra}
%\usage{table_model.add_additional(String_Type name);}
%#c%{{{
%\qualifiers{
%  \qualifier{unit}{[=""] Set the unit of the parameter}
%  \qualifier{minimum}{[=min(values)] Set hard lower limit}
%  \qualifier{bottom}{[=min(values)] Set minimum parameter range}
%  \qualifier{top}{[=max(values)] Set maximum parameter range}
%  \qualifier{maximum}{[=max(values)] Set hard upper limit}
%  \qualifier{initial}{[=mean(values)] Set initial parameter value}
%  \qualifier{delta}{[=(max(values)-min(values))*1e-2] Set parameter step hint}
%}
%\description
%  Add additional contributions to the interpolated spectra. These parameters
%  are simply a normalization for the contributions, e.g., 0 means there is
%  no contribution, 1 means there is full contribution. For each of this
%  contributions an additional spectrum is added to the interpolated model.
%
%\seealso{table_model.add_parameter}
%!%-
{
  tableModelUniqueParameter(self, name);
  tableModelParameterList(&(self.additional_parameter_list), name, NULL;; __qualifiers);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelSetEnergyGrid (self, bin_lo, bin_hi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.set_grid}
%\synopsis{Set the energy grid for the table model}
%\usage{table_model.set_grid(bin_lo, bin_hi);}
%#c%{{{
%\qualifiers{
%  \qualifier{lolimit}{[=0] The model value if lower than lowest bin}
%  \qualifier{hilimit}{[=0] The model value if higher than highest bin}
%}
%\description
%  Set the energy grid on which the model gets interpolated.
%  Boundaries of the bins have to match.
%
%\seealso{table_model.set_function, table_model.set_additional}
%!%-
{
  self.lolimit = 1.*qualifier("lolimit", 0.);
  self.hilimit = 1.*qualifier("hilimit", 0.);

  if (any(array_sort(bin_lo) != [0:length(bin_lo)-1])
      || any(array_sort(bin_hi) != [0:length(bin_hi)-1]))
    throw UsageError, "Bin arrays not in ascending order";
  if (length(bin_lo) != length(bin_hi))
    throw UsageError, "Bin arrays have unequal length";
  if (any(bin_lo[[1:]] != bin_hi[[:-2]]))
    throw UsageError, "Bin boundaries have to match";
  if (any(bin_lo<=0))
    throw UsageError, "Energy grid can not have negative values";

  self.energy_grid = [bin_lo, bin_hi[-1]];
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelSetFunction (self, function)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.set_function}
%\synopsis{Set interpolation model function}
%\usage{table_model.set_function(Ref_Type function);}
%#c%{{{
%\description
%  Set the table model function that gets stored in the table
%  on the defined energy grid. The function must be of the form
%  \code{define modelfunction (bin_lo, bin_hi, params)}
%  where bin_lo and bin_hi are the bin boundary arrays and
%  params is the parameter array set by table_model.add_parameter.
%  The function may use qualifiers.
%
%\seealso{table_model.set_additional}
%!%-
{
  self.function = function;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelSetAdditionalFunction (self, function)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.set_additional}
%\synopsis{Set interpolation model contributions}
%\usage{table_model.set_additional(Ref_Type function);}
%#c%{{{
%\description
%  Set the table model contributions function that gets stored
%  in the table on the defined energy grid. The function must
%  be of the form
%  \code{define modelfunction (bin_lo, bin_hi, params, k)}
%  where bin_lo and bin_hi are the bin boundary arrays and
%  params is the parameter array set by table_model.add_parameter.
%  The additional argument k is set to the number of the additional
%  parameter. So k=1 for the first additonal parameter, k=2 for the
%  second and so on.
%
%  The function is expected to calculate the k-th contribution with
%  the parameter for this contribution set to 1.
%
%\seealso{table_model.set_additional}
%!%-
{
  self.additional = function;
}
%}}}

private define tableModelWriteHeader (table) %{{{
{
  if (_fits_movabs_hdu(table.fitsfile, 1)) {
    tableModelReset(table);
    throw IOError, "Unable to write to header";
  }

  variable name = table.model_name;
  variable unit = qualifier("unit", "photons/cm^2/s");

  variable header = struct {
    HDUCLASS= "OGIP",
    HDUCLAS1= "XSPEC TABLE MODEL",
    HDUVERS= "1.1.0",
    MODLNAME= name,
    MODLUNIT= unit,
    REDSHIFT= not not qualifier_exists("redshift"),
    ADDMODEL= not qualifier_exists("mult"),
    LOELIMIT= (table.use_double) ? qualifier("loLimit", 0.0) : 1.f*qualifier("loLimit", 0.0),
    HIELIMIT= (table.use_double) ? qualifier("hiLimit", 0.0) : 1.f*qualifier("hiLimit", 0.0)
  };

  variable k;
  foreach k (get_struct_field_names(header))
    fits_update_key(table.fitsfile, k, get_struct_field(header, k));

  fits_update_key(table.fitsfile, "LOELIMIT", table.lolimit, "Model value outside of energy grid (lower)");
  fits_update_key(table.fitsfile, "HIELIMIT", table.hilimit, "Model value outside of energy grid (higher)");
}
%}}}

private define tableModelWriteParameterHeader (table) %{{{
{
  variable parameters_header = struct {
    HDUCLASS= "OGIP",
    HDUCLAS1= "XSPEC TABLE MODEL",
    HDUCLAS2= "PARAMETERS",
    HDUVERS= "1.0.0",
    NINTPARM= length(table.parameter_list),
    NADDPARM= length(table.additional_parameter_list)
  };

  variable k;
  variable max_unitlen = 1;
  table.numbvals = Int_Type[length(table.parameter_list)];
  _for k (0, length(table.parameter_list)-1) {
    max_unitlen = max([max_unitlen, strlen(table.parameter_list[k].unit)]);
    table.numbvals[k] = length(table.parameter_list[k].values);
  }
  _for k (0, length(table.additional_parameter_list)-1)
    max_unitlen = max([max_unitlen, strlen(table.additional_parameter_list[k].unit)]);
  variable max_parlen = max(table.numbvals);

  variable colnames = ["NAME",
		       "METHOD",
		       "INITIAL",
		       "DELTA",
		       "MINIMUM",
		       "BOTTOM",
		       "TOP",
		       "MAXIMUM",
		       "NUMBVALS",
		       "VALUE",
		       "UNIT"];
  variable colform = table.use_double ? ["12A","J","D","D","D","D","D","D","J",
					 sprintf("%dD", max_parlen),
					 sprintf("%dA", max_unitlen)]
                                      : ["12A","J","E","E","E","E","E","E","J",
					 sprintf("%dE", max_parlen),
					 sprintf("%dA", max_unitlen)];
  variable colcoms = String_Type[length(colform)];

  fits_create_binary_table(table.fitsfile, "PARAMETERS", 0, colnames, colform, colcoms);

  foreach k (get_struct_field_names(parameters_header))
    fits_update_key(table.fitsfile, k, get_struct_field(parameters_header, k));
}
%}}}

private define tableModelWriteParameterValues (table) %{{{
{
  variable k;
  variable aType = (table.use_double) ? Double_Type : Float_Type;
  variable allValues = aType[length(table.parameter_list), max(table.numbvals)];
  _for k (0, length(table.parameter_list)-1)
    allValues[k, [:table.numbvals[k]-1]] = table.parameter_list[k].values;
  if (_fits_write_col(table.fitsfile, 10, 1, 1, allValues)) { % values at 10
    tableModelReset(table);
    throw IOError, "Unable to write paramter values";
  }
}
%}}}

private define tableModelWriteParameterMethods (table) %{{{
{
  variable k;
  variable allValues = Int_Type[length(table.parameter_list)];
  _for k (0, length(table.parameter_list)-1)
    allValues[k] = table.parameter_list[k].method;
  if (_fits_write_col(table.fitsfile, 2, 1, 1, allValues)) { % methods at 2
    tableModelReset(table);
    throw IOError, "Unable to write method values";
  }
}
%}}}

private define tableModelWriteParameterNames (table) %{{{
{
  variable k;
  variable allValues = String_Type[length(table.parameter_list)+length(table.additional_parameter_list)];
  _for k (0, length(table.parameter_list)-1)
    allValues[k] = table.parameter_list[k].name;
  _for k (0, length(table.additional_parameter_list)-1)
    allValues[length(table.parameter_list)+k] = table.additional_parameter_list[k].name;
  if (_fits_write_col(table.fitsfile, 1, 1, 1, allValues)) { % names at 1
    tableModelReset(table);
    throw IOError, "Unable to write parameter names";
  }
}
%}}}

private define tableModelWriteParameterUnits (table) %{{{
{
  variable k;
  variable allValues = String_Type[length(table.parameter_list)+length(table.additional_parameter_list)];
  _for k (0, length(table.parameter_list)-1)
    allValues[k] = table.parameter_list[k].unit;
  _for k (0, length(table.additional_parameter_list)-1)
    allValues[length(table.parameter_list)+k] = table.additional_parameter_list[k].unit;
  if (_fits_write_col(table.fitsfile, 11, 1, 1, allValues)) { % units at 11
    tableModelReset(table);
    throw IOError, "Unable to write parameter units";
  }
}
%}}}

private define tableModelWriteParameterInitials (table) %{{{
{
  variable aType = table.use_double ? Double_Type : Float_Type;
  variable k;

  variable npar=       length(table.parameter_list);
  variable nadd=       length(table.additional_parameter_list);
  variable total_pars= npar+nadd;
  variable initV=      aType[total_pars];
  variable deltaV=     aType[total_pars];
  variable minimumV=   aType[total_pars];
  variable bottomV=    aType[total_pars];
  variable topV=       aType[total_pars];
  variable maximumV=   aType[total_pars];

  _for k (0, npar-1) {
    initV[k]=    table.parameter_list[k].initial;
    deltaV[k]=   table.parameter_list[k].delta;
    minimumV[k]= table.parameter_list[k].minimum;
    bottomV[k]=  table.parameter_list[k].bottom;
    topV[k]=     table.parameter_list[k].top;
    maximumV[k]= table.parameter_list[k].maximum;
  }
  _for k (0, nadd-1) {
    initV[k+npar]=    table.additional_parameter_list[k].initial;
    deltaV[k+npar]=   table.additional_parameter_list[k].delta;
    minimumV[k+npar]= table.additional_parameter_list[k].minimum;
    bottomV[k+npar]=  table.additional_parameter_list[k].bottom;
    topV[k+npar]=     table.additional_parameter_list[k].top;
    maximumV[k+npar]= table.additional_parameter_list[k].maximum;
  }
  if (_fits_write_col(table.fitsfile, 3, 1, 1, initV)
      || _fits_write_col(table.fitsfile, 4, 1, 1, deltaV)
      || _fits_write_col(table.fitsfile, 5, 1, 1, minimumV)
      || _fits_write_col(table.fitsfile, 6, 1, 1, bottomV)
      || _fits_write_col(table.fitsfile, 7, 1, 1, topV)
      || _fits_write_col(table.fitsfile, 8, 1, 1, maximumV)) {
    tableModelReset(table);
    throw IOError, "Unable to write paramter vector";
  }
}
%}}}

private define tableModelWriteParameter (table) %{{{
{
  tableModelWriteParameterHeader(table);
  tableModelWriteParameterValues(table);
  tableModelWriteParameterMethods(table);
  tableModelWriteParameterNames(table);
  tableModelWriteParameterUnits(table);
  tableModelWriteParameterInitials(table);
  if (_fits_write_col(table.fitsfile, 9, 1, 1, table.numbvals)) { % numbvals at 9
    tableModelReset(table);
    throw IOError, "Unable to write number of values";
  }
}
%}}}

private define tableModelWriteGrid (table) %{{{
{
  fits_create_binary_table(table.fitsfile, "ENERGIES", 0,
    ["ENERG_LO", "ENERG_HI"], table.use_double ? ["D", "D"] : ["E", "E"], ["keV", "keV"]);

  variable energies_header = struct {
    HDUCLASS="OGIP",
    HDUCLAS1="XSPEC TABLE MODEL",
    HDUCLAS2="ENERGIES",
    HDUVERS="1.0.0",
  };

  variable k;
  foreach k (get_struct_field_names(energies_header))
    fits_update_key(table.fitsfile, k, get_struct_field(energies_header, k));

  if (_fits_write_col(table.fitsfile, 1, 1, 1, table.energy_grid[[:-2]])
      || _fits_write_col(table.fitsfile, 2, 1, 1, table.energy_grid[[1:]])) {
    tableModelReset(table);
    throw IOError, "Unable to write energy grid";
  }
}
%}}}

private define iterateParameterVector (par_set, par_has) %{{{
{
  % reduce the par_set vector one by one, using par_has
  % as reference. So we step as [2,2] -> [2,1] -> [1,2] -> [1,1]
  % return 1 if the iterating vector is to be use, else 0
  % This is used to exit the while loop
  ifnot (length(par_set))
    return 0;

  variable p = length(par_set)-1;
  forever {
    par_set[p]--;
    if (par_set[p])
      break;
    p--;
    if (p<length(par_set)-1)
      par_set[p+1] = par_has[p+1];
    if (p<0)
      return 0;
  }

  return 1;
}
%}}}

private define tableModelWriteSpectraHeader (table) %{{{
{
  variable npar=    length(table.parameter_list);
  variable nadd=    length(table.additional_parameter_list);
  variable npoints= length(table.energy_grid)-1;
  variable k;

  variable colnams = ["PARAMVAL",
		      "INTPSPEC",
		      array_map(String_Type, &sprintf, "ADDSP%03d", [1:nadd])];
  variable colform = table.use_double ? [sprintf("%dD", npar),
					 sprintf("%dD", npoints),
					 array_map(String_Type, &sprintf, "%dD", Int_Type[nadd]+npoints)]
                                      : [sprintf("%dE", npar),
					 sprintf("%dE", npoints),
					 array_map(String_Type, &sprintf, "%dE", Int_Type[nadd]+npoints)];
  variable colcoms = String_Type[length(colform)];

  fits_create_binary_table(table.fitsfile, "SPECTRA", 0, colnams, colform, colcoms);

  variable spectra_header = struct {
    HDUCLASS="OGIP",
    HDUCLAS1="XSPEC TABLE MODEL",
    HDUCLAS2="MODEL SPECTRA",
    HDUVERS="1.0.0"
  };

  foreach k (get_struct_field_names(spectra_header))
    fits_update_key(table.fitsfile, k, get_struct_field(spectra_header, k));
}
%}}}

private define tableModelWriteSpectra (table) %{{{
{
  tableModelWriteSpectraHeader(table);

  variable aType = table.use_double ? Double_Type : Float_Type;

  variable npar=    length(table.parameter_list);
  variable nadd=    length(table.additional_parameter_list);
  variable npoints= length(table.energy_grid)-1;
  variable nval=    table.numbvals[[:-2]]; % we iterate over the last parameter

  variable par_set= @nval; % parameter vector, used as iterator
  variable specs=   aType[table.numbvals[-1], npoints];
  variable parmat=  aType[table.numbvals[-1], npar];
  variable addspec= aType[table.numbvals[-1], npoints];
  variable pV=      aType[npar];

  variable i,k;
  
  variable firstRow= 1;

  % use par_set as iterator
  do {
    _for i (0, npar-2)
      pV[i] = table.parameter_list[i].values[nval[i]-par_set[i]];
    _for i (0, table.numbvals[-1]-1) {
      pV[-1] = table.parameter_list[-1].values[i];
      parmat[i,*] = pV;
      specs[i,*] = @(table.function)(table.energy_grid[[:-2]], table.energy_grid[[1:]],
				     pV;; __qualifiers);

      if (_fits_write_col(table.fitsfile, 1, firstRow, 1, parmat)
	  || _fits_write_col(table.fitsfile, 2, firstRow, 1, specs)) {
	tableModelReset(table);
	throw IOError, "Unable to write table values";
      }
    }
    _for k (0, nadd-1) {
      _for i (0, table.numbvals[-1]-1) {
	addspec[i,*] = @(table.additional)(table.energy_grid[[:-2]],
					   table.energy_grid[[1:]],
					   parmat[i,*],
					   k;; __qualifiers);
      }

      if (_fits_write_col(table.fitsfile, k+3, firstRow, 1, addspec)) {
	tableModelReset(table);
	throw IOError, "Unable to write table values";
      }
    }
    firstRow += table.numbvals[-1];
  } while (iterateParameterVector(par_set, nval));
}
%}}}

private define tableModelSummary (table) %{{{
{
  variable msg = `
Generating table model '%s':
  Parameter:            %d
  Additional Parameter: %d
  Energy grid bins:     %d

  Lowest energy:        %lg keV
  Highest energy:       %lg keV
  Model limit low:      %lg
  Model limit high:     %lg

 > %s`;
  vmessage(msg,
	   table.model_name,
	   length(table.parameter_list),
	   length(table.additional_parameter_list),
	   length(table.energy_grid)-1,
	   min(table.energy_grid),
	   max(table.energy_grid),
	   table.lolimit,
	   table.hilimit,
	   table.filename);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelWriteTable (self)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.write}
%\synopsis{Write table model to file}
%\usage{table_model.write();}
%#c%{{{
%\qualifiers{
%  \qualifier{redshift}{if given, set redshift parameter flag}
%  \qualifier{mult}{if given, model is multiplicative (default additive)}
%  \qualifier{verbose}{show additional information}
%}
%\description
%  Given the model function and additional contributions, this
%  function evaluates the model and contributions on the given
%  parameter values and writes the resulting spectra to the
%  table file. Any qualifier passed to this function is passed
%  on to the model functions.
%
%  IMPORTANT: This function calls the evaluation functions
%  several times and may take a long time to finish. Depending
%  on the evaluation time of the model functions.
%
%\seealso{table_model.close}
%!%-
{
  if (length(self.parameter_list) && NULL == self.function)
    throw UsageError, "No model function given";
  if (length(self.additional_parameter_list) && NULL == self.additional)
    throw UsageError, "No additional function given";
  if (NULL == self.energy_grid)
    throw UsageError, "Energy grid not set";

  if (qualifier_exists("verbose"))
    tableModelSummary(self);

  tableModelWriteParameter(self);
  tableModelWriteGrid(self);
  tableModelWriteSpectra(self;; __qualifiers);
  tableModelWriteHeader(self;; __qualifiers);
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define tableModelClose (self)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{table_model.close}
%\synopsis{Finish table model}
%\usage{table_model.close();}
%#c%{{{
%\description
%  Write the checksums to each HDU and close the
%  table model file.
%!%-
{
  variable nhdus = fits_get_num_hdus(self.fitsfile);
  variable k;
  _for k (1, nhdus) {
    if (_fits_movabs_hdu(self.fitsfile, k)) {
      tableModelReset(self);
      throw IOError, "Unable to write checksums";
    }
    fits_write_chksum(self.fitsfile);
  }

  fits_close_file(self.fitsfile);
}
%}}}

private define tableModelOpenFile (table) %{{{
{
  variable stat = stat_file(table.filename);
  if ( (NULL != stat && stat_is("reg", stat.st_mode))
     && not qualifier_exists("overwrite"))
    throw IOError, "File exists";

  table.fitsfile = fits_open_file(table.filename, "c");

  if (NULL == table.fitsfile)
    throw IOError, "Unable to creat fits file";
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define new_table_model (filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{new_table_model}
%\synopsis{Initialize object and file to create table model}
%\usage{Struct_Type model = new_table_model(String_Type filename)}
%#c%{{{
%\qualifiers{
%  \qualifier{name}{[=<filename-no-ext>] set model name}
%  \qualifier{double}{if set, stores all values as doubles instead of floats}
%  \qualifier{overwrite}{if set, ignores existing file with same name}
%}
%\description
%  Giving a file name the function creates a fits file with the given
%  name and returns a handle that eases the process of creating a
%  table model according to the XSPEC format
%     OGIP Memo 92-009 (XSPEC Table Model File Format)
%
%  To create a file one has to give the interpolation points of the
%  model, the additional contributions and the model spectra.
%
%\example
%  variable table = new_table_model("test_model.fits");
%
%  % create "parameter1" with given interpolation points
%  table.add_parameter("parameter1", [0:2:0.1]);
%  table.add_parameter("parameter2", [-1:1:0.001]); % create "parameter2"
%  % create additional parameter "additional"
%  table.add_additional("additional");
%
%  table.set_grid(bin_lo, bin_hi); % define the valid energy grid for the model
%  table.set_function(&my_fancy_model); % set the model function
%  % set additional contributions
%  % (only necessary if additional parameters are given)
%  table.set_additional(&my_fancy_contributions);
%
%  table.write(); % fill table
%  table.close(); % finish table
%\seealso{table_model.add_parameter, table_model.add_additional,
%  table_model.set_grid, table_model.set_function, table_model.set_additional,
%  table_model.write, table_model.close}
%!%-
{
  variable table = struct {
    filename = path_realpath(filename),
    model_name = qualifier("name", path_basename_sans_extname(filename)),
    fitsfile = NULL,

    add_parameter = &tableModelAddParameter,
    add_additional = &tableModelAddAdditionalParameter,
    set_grid = &tableModelSetEnergyGrid,
    set_function = &tableModelSetFunction,
    set_additional = &tableModelSetAdditionalFunction,
    write = &tableModelWriteTable,
    close = &tableModelClose,

    function = NULL,
    additional = NULL,
    energy_grid = NULL,
    numbvals = NULL,
    use_double = qualifier_exists("double"),
    lolimit = 0.,
    hilimit = 0.,
    parameter_list = {},
    additional_parameter_list = {}
  };

  tableModelOpenFile(table;;__qualifiers);

  return table;
}
%}}}
