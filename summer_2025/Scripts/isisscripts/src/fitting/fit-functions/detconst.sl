%!%+
%\function{detconst}
%\synopsis{fit-function providing detector calibration constants}
%\usage{detconst(id)}
%\description
%    Simply returns a constant depending on the detector of
%    the current dataset the model is evaluated on. This can
%    be used to account for flux calibration differences
%    between several detectors.
%
%    To use this fit-function, the detectors has to be
%    defined first using 'detconst_init'.
%\seealso{detconst_init}
%!%-


%%%%%%%%%%%%%%%%%%%%%
define detconst_init() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{detconst_init}
%\synopsis{initializes the "dectonst" fit-function}
%\usage{detconst_init(String_Type[] detectors);
% or detconst_init(List_Type detectors);}
%\description
%    Before any detector calibration constants can be fitted
%    by using the 'detconst' fit-function, this function has
%    to be called. It initalizes and defines the fit-function
%    based on the given detector names (and if statements).
%
%    In general, the detector names are given as an array of
%    strings. Each entry has to represent the 'instrument'
%    field defined in the FITS-header of any used dataset.
%    Internally, the 'detconst' matches this field against
%    the given names and returns the corresponding parameter.
%
%    If the instrument field is not enough to determine the
%    parameter (e.g., if multiple instruments are build within
%    the same detector), a list of strings can be provided
%    instead of an array. If a list item itself is an array
%    with exactly two strings, the first one is the detector
%    name and the second specifies the if statement to be
%    evaluated to determine the corresponding parameter.
%    Within the if statement, information about the dataset
%    can be accessed via the 'info' struct (see get_data_info).
%
%    If the 'debug' qualifier is given, the S-Lang code of
%    the fit-function is printed out as well.
%\example
%    % RXTE consisted of two instruments: PCA and HEXTE
%    detconst_init(["PCA", "HEXTE"]);
%    
%    % SUZAKU consists of six instruments: XIS0-3, PIN,
%    % and GSO. PIN and GSO are, however, within one detector
%    % called HXD (as in the FITS-header). Thus, identify
%    % these two instruments via the PHA-filename
%    detconst_init({"XIS0", "XIS1", "XIS2", "XIS3",
%      ["PIN", "is_substr(info.file, \\"hxd_pin\\")"],
%      ["GSO", "is_substr(info.file, \\"hxd_gso\\")"]
%    }; debug);
%\seealso{detconst, get_data_info, add_slang_function}
%!%-
  variable dtctrs = list_new();
  variable d;
  
  if (_NARGS == 1) {
    variable in = ();
    % convert input into list
    if (typeof(in) == String_Type) list_append(dtctrs, in);
    else if (typeof(in) == Array_Type && _typeof(in) == String_Type) foreach d (in) list_append(dtctrs, d);
    else if (typeof(in) == List_Type) dtctrs = in;
    else { vmessage("error (%s): input list of detectors is of wrong type", _function_name); return; }
  }
  else { help(_function_name); return; }

  % define fit function
  variable ffstrng = "", nonspecial = 0;
  variable dtctrnms = String_Type[0], special = Integer_Type[0];
  ffstrng += "define detconst_fit(lo, hi, pars) {\n  variable dtctrs =";
  ffstrng += " [";
  _for d (0, length(dtctrs)-1, 1) { % get detector names and entries with special if cases
    if (typeof(dtctrs[d]) == String_Type) {
      ffstrng += sprintf("\"%s\",", dtctrs[d]);
      dtctrnms = [dtctrnms, dtctrs[d]]; nonspecial++;
    }
    else {
      ffstrng += sprintf("\"%s\",", dtctrs[d][0]);
      dtctrnms = [dtctrnms, dtctrs[d][0]], special = [special, d];
    }
  }
  ffstrng = substr(ffstrng, 1, strlen(ffstrng)-1);
  if (nonspecial > 0) { ffstrng += "];\n"; }
  else { ffstrng += "String_Type[0];\n"; }
  ffstrng += "  variable info = get_data_info(Isis_Active_Dataset);\n";
  % search and return detector calibration constant without special if case
  ffstrng += "  variable n = wherefirst(dtctrs == info.instrument);\n";
  ffstrng += "  if (n != NULL) { return pars[n[0]]; }\n";
  % write statements for detectors with special if case
  foreach d (special) {
    ffstrng += sprintf("  if (%s) { return pars[%d]; }\n", dtctrs[d][1], d);
  }
  ffstrng += "  vmessage(\"warning (detconst): instrument '%s' of dataset %d does not have a known fit parameter\", info.instrument, Isis_Active_Dataset);\n";
  ffstrng += "  return 0;\n}";

  if (qualifier_exists("debug")) message(ffstrng);
  eval(ffstrng, "isis");

  % defaults function
  eval("private define detconst_defaults(i) { return struct { value = 1, freeze = i == 0 ? 1 : 0, min = .5, max = 2, hard_min = 0, hard_max = 10, step = 1e-3, relstep = 1e-4 }; }", "isis");

  % add function to fit-functions
  eval(sprintf("add_slang_function(\"detconst\", [\"%s\"]);", strjoin(dtctrnms, "\",\"")), "isis");
  eval("set_param_default_hook(\"detconst\", &detconst_defaults);", "isis");
}
