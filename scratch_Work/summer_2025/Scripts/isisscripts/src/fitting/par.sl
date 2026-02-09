%%! Author: Fritz-Walter Schwarm <fritz.schwarm@sternwarte.uni-erlangen.de>

%%! Filename of currently loaded parameter file
private variable par_file = "";
%%! Parameter file last modification
private variable par_mtime = 0;
%%! Parameter file stat struct
private variable par_stat;
%%! Lines of the last used parameter file
private variable par_lines = Array_Type[0];
%%! Names of all components in parameter file
private variable par_names = Array_Type[0];
%%! Number of components in parameter file
private variable par_N = 0;
%%! Index of current component
private variable par_idx = 0;
%%! Global list of renaming operations
private variable par_rename = 0;
%%! Regular expression for parameter from parameter listing
private variable par_regexp = "^ *\\([0-9]\+\\) \+\\([\^. ()]\+\\)" +
	"(\\([0-9]\+\\))\.\\([\^ ]\+\\) \+\\([0-9]\+\\) \+\\([0-9]\+\\) \+" +
	"\\([-+.eE0-9]\+\\) \+\\([-+.eE0-9]\+\\) \+\\([-+.eE0-9]\+\\) \+\\([\^ ]*\\)";

%%! Read a parameter file to an array of strings
private define par_read(fname)
{
	variable fp, lines;

	fp = fopen(fname, "r");

	if (fp == NULL) {
		throw OpenError, "fopen failed to open $fname for reading"$;
	}

	lines = fgetslines(fp);

	if (lines == NULL) {
		throw ReadError, "fgetslines failed to read lines from $fname"$;
	}

	() = fclose(fp);

	return lines;
}

%%! Get components from an array of strings
private define par_cmp(lines)
{
	variable i, pos, strs, len, first = 1, list = {};

	for (i = 0; i < length(lines); i++) {

		strs = string_matches(lines[i], "^#\[\(.*\)\]"R);

		if (NULL != strs) {

			list_append(list, strs[1]);

		} else if ((0 == string_match(lines[i], "^ *[\^#]"R)) and (1 == first)) {

			list_insert(list, "DEFAULT");
			first = 0;
		}
	}

	return list;
}

%%%%%%%%%%%%%%%%%
define par_load()
%%%%%%%%%%%%%%%%%
%!%+
%\function{par_load}
%\synopsis{Loads fit function and parameters for given component from file}
%\usage{par_load(String_Type filename [, String_Type component]);}
%\qualifiers{
%    \qualifier{clean}{[=1]:   Remove temporary parameter files for individual
%                       components after calling load_par.}
%    \qualifier{dryrun}{[=0]:  Generate parameter file for component but
%                       do not load it, i.e., do not call load_par.
%                       Implies clean=0.}
%    \qualifier{iterate}{[=0]: Iterate through components. Returns the name of
%                       the current component or NULL if no more components
%                       are available.}
%}
%\description
%    Creates a copy of the given parameter file and modifies it such that only
%    the fit function associated with the given component is active. This file
%    is then loaded using the standart load_par function.
%    This way individual model components, or alternative fit functions, can
%    be defined in the same parameter file using the following format:
%    	#[name1] fitFunction1
%    	#[name2] fitFunction2
%    	defaultFitFunction
%    The rest of the file contains the parameters in the usual format used by
%    list_par. The name "DEFAULT" is reserved for the (uncommented) default
%    fit function. The function returns the name of the loaded component. It
%    returns NULL if the desired component does not exist or if no more
%    components are available during iteration.
%\seealso{par_save, load_par, list_par}
%!%-
{
	variable fname, cmp, active_cmps = NULL, cmp_pars, i, j, k, par, active, fp, buf, strs, fcmp, stat, first = 1;

	EXIT_BLOCK {
		if (par_idx < par_N) {
			return par_names[par_idx];
		} else {
			return NULL;
		}
	}

	%%! Check if component parameter was given
	if (_NARGS == 0 or _NARGS > 2) {

		usage("[cmp] = par_load(filename [, component])");

	} else if (_NARGS == 1) {

		fname = ();
		cmp = NULL;

	} else {
		cmp = ();
		fname = ();
	}

	par_stat = stat_file(fname);

	if (par_stat == NULL) {
		throw IOError, "Unable to stat $fname"$;
	}

	if ((0 == strcmp("", par_file)) or 
		(0 != strcmp(fname, par_file)) or 
			((par_stat != NULL) and (par_stat.st_mtime != par_mtime))) {

		vmessage("Loading file $fname ..."$);

		par_file = fname;

		par_lines = par_read(fname);

		par_names = par_cmp(par_lines);

		par_N = length(par_names);

		par_idx = 0;

		par_mtime = par_stat.st_mtime;

	} else if ((1 == qualifier_exists("iterate")) and (0 != qualifier("iterate", 0))) {

		par_idx++;
	}

	if (NULL != cmp) {
		par_idx = 0;

		while (strcmp(cmp, par_names[par_idx]) != 0 and par_idx < par_N) { par_idx++; }
	}

	if (par_idx >= par_N) {
		return;
	}

	cmp = par_names[par_idx];

	fcmp = sprintf("%s_%s", fname, cmp);

	fp = fopen(fcmp, "w");

	if (fp == NULL) {
		throw OpenError, "fopen failed to open $fcmp for writing"$;
	}

	for (i = 0; i < length(par_lines); i++) {

		strs = string_matches(par_lines[i], "^#\\[$cmp\\]\\(.*\\)"$);

		if (NULL != strs) {

			%%! This line contains the desired component -> uncomment
			if (-1 == fprintf(fp, "%s\n", strs[1])) {
				throw WriteError, "fprintf failed to write to $fcmp: "$ + errno_string(errno);
			}

			%%! Setting the fit function makes it possible to use get_fun_components
			fit_fun(strs[1]);

			%%! Obtain individual components
			active_cmps = get_fun_components();

		} else if ((0 == string_match(par_lines[i], "^ *[\^#]"R)) and (1 == first)) {

			%%! First non-comment line -> comment out unless DEFAULT component is requested
			if (0 == strcmp("DEFAULT", cmp)) {
				if (-1 == fprintf(fp, "%s", par_lines[i])) {
					throw WriteError, "fprintf failed to write to $fcmp: "$ + errno_string(errno);
				}

				%%! Setting the fit function makes it possible to use get_fun_components
				fit_fun(par_lines[i]);

				%%! Obtain individual components
				active_cmps = get_fun_components();
			} else {
				if (-1 == fprintf(fp, "#[DEFAULT] %s", par_lines[i])) {
					throw WriteError, "fprintf failed to write to $fcmp: "$ + errno_string(errno);
				}
			}

			first = 0;
		} else {
			%%! Either a comment, header, or parameter line
			par = string_matches(par_lines[i], "^ *\\([0-9]\+\\) \+\\([\^. ]\+\\)");

			if (NULL != par) {
				%%! Parameter line -> transfer only active parameters (otherwise ISIS throws an error on load_par)
				k = 0;
				active = 0;

				while ((NULL != active_cmps) and (k < length(active_cmps)) and (0 == active)) {
					if (0 == strcmp(par[2], active_cmps[k])) {
						active = 1;
					} else {
						k++;
					}
				}

				if (active) {
					%%! Parameter is needed for current component -> transfer unaltered
					if (-1 == fprintf(fp, "%s", par_lines[i])) {
						throw WriteError, "fprintf failed to write to $fcmp: "$ + errno_string(errno);
					}
				} else {
					%%! Parameter is not needed for current component -> comment out
					if (-1 == fprintf(fp, "# %s", par_lines[i])) {
						throw WriteError, "fprintf failed to write to $fcmp: "$ + errno_string(errno);
					}
				}

			} else {
				%%! Must be the a comment or header line -> transfer unaltered
				if (-1 == fprintf(fp, "%s", par_lines[i])) {
					throw WriteError, "fprintf failed to write to $fcmp: "$ + errno_string(errno);
				}
			}
		}
	}

	() = fclose(fp);

	if ((0 == qualifier_exists("dryrun")) or (0 == qualifier("dryrun", 0))) {

		load_par(fcmp);

		if ((0 == qualifier_exists("clean")) or (0 != qualifier("clean", 1))) {
			() = system("rm $fcmp"$);
		}
	}

	return;
}

private define par_array_idx(array, element) {
	variable i;

	for (i = 0; i < length(array); i++) {
		if (array[i] == element) {
			return i;
		}
	}

	return -1;
}

private define par_format_text(str) {

	variable i, buffer, match, tmp, left, right, last = {};
	variable strs;
	variable pos;
	variable greek = [ "alpha", "beta", "gamma", "delta", "epsilon", "zeta",
	                   "eta", "theta", "iota", "kappa", "lambda", "mu", "nu",
	                   "xi", "pi", "rho", "sigma", "tau", "upsilon", "phi",
	                   "chi", "psi", "omega" ];
	variable words = [ "para",       "perp",   "PhoIndex", "nH",   "area", "center", "cutoffE", "foldE"    ];
	variable syms  = [ "\\parallel", "\\perp", "\\Gamma",  "$N_H$", "A",   "E",      "$E_cut$", "$E_fold$" ];

	%%! Copy input string to buffer
	buffer = str;

	%%! User defined renaming
	for (i = 0; i < length(par_rename); i++) {
		buffer = strreplace(buffer, par_rename[i][0], par_rename[i][1]);
	}

	%%! Replace greek letter words by greek symbols
	for (i = 0; i < length(greek); i++) {
		buffer = strreplace(buffer, greek[i], sprintf("$\\%s$", greek[i]));
	}

	%%! Replace common words by symbols
	for (i = 0; i < length(words); i++) {
		buffer = strreplace(buffer, words[i], sprintf("$%s$", syms[i]));
	}

	%%! Replace underscore with subscription
	while (match = string_matches(buffer, "\\(\$?\\)\\([\\\\a-zA-Z0-9]\+\\)\\(\\1\\)_\\(\$?\\)\\([\\\\a-zA-Z0-9]\+\\)\\(\\4\\)"), NULL != match) {

		if ("" == match[1] and "" == match[3]) {
			left = sprintf("\\mathrm{%s}", match[2]);
		} else {
			left = match[2];
		}
	
		if ("" == match[4] and "" == match[6]) {
			right = sprintf("\\mathrm{%s}", match[5]);
		} else {
			right = match[5];
		}
	
%		if (("$" == match[1] and "" == match[3]) or ("" == match[4] and "6" == match[6])) {
		buffer = sprintf("${%s}_{%s}$", left, right);
%%!FS: Currently only one subscripted variable is supported per input string
%		buffer = strreplace(buffer, match[0], sprintf("${%s}_{%s}$", left, right));
	}

	%%! Replace carret with superscription
	while (match = string_matches(buffer, "\\(\$?\\)\\([\\\\a-zA-Z0-9]\+\\)\\(\$?\\)\^\\(\$?\\)\\([\\\\a-zA-Z0-9]\+\\)\\(\$?\\)"), NULL != match) {

		if ("" == match[1] and "" == match[3]) {
			left = sprintf("\\mathrm{%s}", match[2]);
		} else {
			left = match[2];
		}
	
		if ("" == match[4] and "" == match[6]) {
			right = sprintf("\\mathrm{%s}", match[5]);
		} else {
			right = match[5];
		}
	
		buffer = strreplace(buffer, match[0], sprintf("${%s}^{%s}$", left, right));
	}

	return buffer;
}

private define par_format_number(number) {

	variable order = int(floor(log10(number)));
	variable places, str, value;

	if (number == 0.0) {
		return sprintf("0");
	}

	if ((-1 <= order and order < 2) or (0.0 == number - round(number))) {
		value = number;
	} else {
		value = number / 10^order;
	}

	if (0.0 == number - round(number)) {
		places = 0;

		str = sprintf("%.*lf", places, value);
	} else {
		places = 2;

		str = sprintf("%.*lf", places, value);

		if (0.0 == atof(str)) {
			return "0";
		}

		while (0 == strcmp("0", substr(str, strlen(str), 1))) {
			str = substr(str, 1, strlen(str)-1);
		}
	}

	if ((-1 <= order and order < 2) or (0.0 == number - round(number))) {
		return sprintf("%s", str);
%		return sprintf("%.*lf", places, number);
	}

	if (order < -1) {
		return sprintf("%s \\times 10^{%d}", str, order);
%		return sprintf("%.*lf \\times 10^{%d}", places, number / 10^order, order);
	}

	return sprintf("%s \\times 10^{%d}", str, order);
%	return sprintf("%.*lf \\times 10^{%d}", places, number / 10^order, order);
}

%%%%%%%%%%%%%%%%%
define par_save()
%%%%%%%%%%%%%%%%%
%!%+
%\function{par_save}
%\synopsis{Save fit function and parameters to labeled component in file}
%\usage{Int_Type par_save(String_Type filename [, String_Type component]);}
%\qualifiers{
%    \qualifier{dryrun}{[=0]: generate parameter file for component but
%                      do not load it, i.e., do not call load_par.
%                      Implies clean=0.}
%}
%\description
%    Saves the current fit function and parameter list
%    to the given parameter file. If a component name is given, the current fit
%    function will be saved as a named and commented out component, which can
%    loaded using par_load. Otherwise the main difference to save_par is that
%    comment lines, which are only loaded if par_load is used, are saved to the
%    parameter file as well. Calling this function is equivalent to calling
%    save_par if no comment lines are present or if the parameter file has been
%    loaded using load_par.
%    The function returns the number of components written to the file, or -1
%    upon error.
%\seealso{par_load, save_par, load_par, list_par}
%!%-
{
	variable fname, cmp, fp, strs, par, buf, buf_lines, i, k, active_cmps, active, written = 0, found = 0, first = 1;

	vmessage("WARNING: Do not use this function at the moment!\n");

	%%! Check if component parameter was given
	if (_NARGS == 0 or _NARGS > 2) {

		usage("status = par_save(filename [, component])");

	} else if (_NARGS == 1) {

		fname = ();
		cmp = NULL;

	} else {
		cmp = ();
		fname = ();
	}

	fp = fopen(fname, "w");

	if (fp == NULL) {
		throw OpenError, "fopen failed to open $fname for writing"$;
	}

	buf = get_fit_fun();

	if ((NULL != cmp) and (NULL != buf)) {
		%%! Write current fit function to commented out named component
		if (-1 == fprintf(fp, "#[%s] %s\n", cmp, buf)) {
			throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
		}

		written++;
	}

	%%! Obtain individual components of current fit function
	active_cmps = get_fun_components();

	%%! Write comment lines loaded via par_load
	for (i = 0; i < length(par_lines); i++) {

		strs = string_matches(par_lines[i], "^#\\[$cmp\\]\\(.*\\)"$);

		if (NULL != strs) {

			if (written < 1) {
				%%! This line contains the old component with the given name -> ignore if overwritten already
				if (-1 == fprintf(fp, "%s\n", strs[1])) {
					throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
				}
	
				%%! Setting the fit function makes it possible to use get_fun_components
				fit_fun(strs[1]);

				%%! Obtain individual components
				active_cmps = get_fun_components();
	
				written++;
			}

		} else if (0 < string_match(par_lines[i], "^ *#\\[.*\\]")) {

			%%! Commented out component line with other name -> transfer unaltered
			if (-1 == fprintf(fp, "%s", par_lines[i])) {
				throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
			}

			written++;

		} else if (0 < string_match(par_lines[i], "^ *#")) {

			%%! Comment line -> transfer unaltered but do not count
			if (-1 == fprintf(fp, "%s", par_lines[i])) {
				throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
			}

		}
	}

	%%! Read current parameter listing to buffer
	list_par(&buf);
	buf_lines = strtok(buf, "\n");

	for (i = 0; i < length(buf_lines); i++) {

		if ((0 == string_match(buf_lines[i], "^ *[\^#]"R)) and (1 == first)) {

			%%! First non-comment line -> save to file as default component
			if (-1 == fprintf(fp, "%s\n", buf_lines[i])) {
				throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
			}

			first = 0;
			written++;
		} else {
			%%! Either the header or a parameter line
			par = string_matches(buf_lines[i], "^ *\\([0-9]\+\\) \+\\([\^. ]\+\\)");

			if (NULL != par) {
				%%! Parameter line -> transfer only active parameters (otherwise ISIS throws an error on load_par)
				k = 0;
				active = 0;

				while ((k < length(active_cmps)) and (0 == active)) {
					if (0 == strcmp(par[2], active_cmps[k])) {
						active = 1;
					} else {
						k++;
					}
				}

				if (active) {
					%%! Parameter is needed for current component -> transfer unaltered
					if (-1 == fprintf(fp, "%s\n", buf_lines[i])) {
						throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
					}
				} else {
					%%! Parameter is not needed for current component -> comment out
					if (-1 == fprintf(fp, "# %s\n", buf_lines[i])) {
						throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
					}
				}

			} else {
				%%! Must be the header line -> transfer unaltered
				if (-1 == fprintf(fp, "%s\n", buf_lines[i])) {
					throw WriteError, "fprintf failed to write to $fname: "$ + errno_string(errno);
				}
			}
		}
	}

	() = fclose(fp);

	return written;
}

%%%%%%%%%%%%%%%%%
define par_list()
%%%%%%%%%%%%%%%%%
%!%+
%\function{par_list}
%\synopsis{Print a parameter file listing}
%\usage{Int_Type par_list([String_Type filename | Ref_Type buffer | File_Type fd]);}
%\qualifiers{
%    \qualifier{tex}{[=0]: Format parameter listing in form of a LATEX tabular
%                       environment. This does currently not work for a Ref_Type
%                       argument.}
%    \qualifier{pdf}{[=0]: Compile a pdf file containing the parameter listing
%                       as a table.}
%    \qualifier{all}{[=0]: Add all parameters to tex and pdf file. By default
%                       parameters with the following name - value combinations
%                       are excluded:
%                           norm    1}
%    \qualifier{exclude}{[=0]: Array or list of parameters to be excluded in
%                       tex and pdf listings. These are even excluded if the
%                       "all" qualifier above is set.}
%    \qualifier{include}{[=0]: Array or list of additional parameters to be
%                       included in tex and pdf listings.}
%}
%\description
%    Prints all internally stores parameter file lines to screen. This includes
%    out-commented fit functions and parameter lines, which are only loaded if
%    par_load is used instead of load_par. Writes parameter listing to file if
%    a String_Type parameter is given, which will be interpreted as filename.
%    If a File_Type parameter is given the listing will be written to this
%    file. If the argument is of Ref_Type, the listing will be returned in this
%    buffer. This argument functionality works analog to the default list_par
%    function.
%\seealso{par_load, par_save, save_par, load_par, list_par}
%!%-
{
	variable i, j, fpar = NULL, buffer, line, idx, modname, modinst, parname, tie, freeze, parval, parmin, parmax, parunit, strs, fp = stdout, written = -1, total = 0, tex = 0, pdf = NULL, pdftex_fp, all = 0;

	variable exclude_name  = [ "norm" ];
	variable exclude_value = [  1.0   ];
	variable exclude_idx, exclude_user, include_user = {};

	%%! Check if component parameter was given
	if (_NARGS > 1) {
		usage("par_list([filename|buffer|fp])");
	}

	if ((1 == qualifier_exists("tex")) and (0 != qualifier("tex", 0))) {
		tex = 1;
	}

	if ((1 == qualifier_exists("all")) and (0 != qualifier("all", 0))) {
		all = 1;
	}

	if (1 == qualifier_exists("exclude")) {
		exclude_user = qualifier("exclude", {});
	}

	if (1 == qualifier_exists("rename")) {
		par_rename = qualifier("rename", {});
	}

	if (1 == qualifier_exists("include")) {
		include_user = qualifier("include", {});
	}

	if (_NARGS == 1) {

		fpar = ();

		if (String_Type == typeof(fpar)) {

			fp = fopen(fpar, "w");
		
			if (fp == NULL) {
				throw OpenError, "fopen failed to open $fpar for writing"$;
			}

		} else if (File_Type == typeof(fpar)) {

			fp = fpar;

		} else if (Ref_Type == typeof(fpar)) {
			@fpar = "";
		}
	}

	if (pdf = qualifier("pdf", NULL), NULL != pdf) {

		pdftex_fp = fopen("$pdf.tex"$, "w");

		if (NULL == pdftex_fp) {
			throw OpenError, "fopen failed to open $pdf.tex for writing"$;
		}
	
		buffer = par_format_text("\\documentclass{article}\n\\usepackage{booktabs}\n\\begin{document}\n\\begin{table}\n\\centering\n");

		if (-1 == fprintf(pdftex_fp, "%s", buffer)) {
			throw WriteError, "printf failed to write to $pdf.tex: "$ + errno_string(errno);
		}
	}

	buffer = par_format_text("\\begin{tabular}[b]{ccc}\n\\toprule\nParameter & Value & Unit \\\\\n\\midrule\n");

	if (NULL != pdf) {
		if (-1 == fprintf(pdftex_fp, "%s", buffer)) {
			throw WriteError, "printf failed to write to $pdf.tex: "$ + errno_string(errno);
		}
	}

	if (tex) {

		if (Ref_Type == typeof(fpar)) {
			@fpar += buffer;
		} else {
			if (written = fprintf(fp, "%s", buffer), written == -1) {
				throw WriteError, "printf failed to write to $fp: "$ + errno_string(errno);
			}
	
			total += written;
		}
	}

	for (i = 0; i < length(par_lines); i++) {

		strs = string_matches(par_lines[i], par_regexp);

		if (NULL != strs) {

			line    = strs[0];
			idx     = integer(strs[1]);
			modname = strs[2];
			modinst = integer(strs[3]);
			parname = strs[4];
			tie     = integer(strs[5]);
			freeze  = integer(strs[6]);
			parval  = atof(strs[7]);
			parmin  = atof(strs[8]);
			parmax  = atof(strs[9]);

			strs = string_matches(strs[0], ".* \+\\([\^ ]\+\\)$");

			if (length(strs) > 1) {
				parunit = strs[1];
			} else {
				parunit = "";
			}

			%%! Exclude parameters from exclude list
			if (0 <= par_array_idx(exclude_user, parname)) {
				continue;
			}

			%%! Excluded parameter/value combinations
			if (exclude_idx = par_array_idx(exclude_name, parname),
				(not all) and (exclude_idx >= 0) and
				(parval == exclude_value[exclude_idx])) {
				continue;
			}

			%%! Exclude enflux E_min/E_max (included in enflux parameter below)
			if ((0 == strcmp("enflux", modname)) and
				((0 == strcmp("E_min", parname)) or (0 == strcmp("E_max", parname)))) {
				continue;
			}

			%%! Show enflux model parameter in one row
			if (0 == strcmp("enflux", parname)) {

				variable tmp, tmp2, tmp_unit;
				variable E_min = NULL, E_max = NULL;
				variable E_min_unit = NULL, E_max_unit = NULL;

				for (j = 0; j < length(par_lines); j++) {
					tmp = string_matches(par_lines[j], par_regexp);

					if (tmp != NULL) {

						if ((0 == strcmp(modname, tmp[2])) and
							(modinst == integer(tmp[3]))) {

							tmp2 = string_matches(tmp[0], ".* \+\\([\^ ]\+\\)$");

							if (length(tmp2) > 1) {
								tmp_unit = tmp2[1];
							} else {
								tmp_unit = "";
							}

							if (0 == strcmp("E_min", tmp[4])) {

								E_min = atof(tmp[7]);
								E_min_unit = tmp_unit;

							} else if (0 == strcmp("E_max", tmp[4])) {

								E_max = atof(tmp[7]);
								E_max_unit = tmp_unit;
							}

							if ((NULL != E_min) and (NULL != E_max)) {
								break;
							}
						}
					}
				}

				parname = sprintf("$F_{%s\\,\\mathrm{%s}}^{%s\\,\\mathrm{%s}}$",
					par_format_number(E_min), par_format_text(E_min_unit),
					par_format_number(E_max), par_format_text(E_max_unit));
			}

			buffer = sprintf("%s & $%s$ & %s \\\\\n", par_format_text(parname),
				par_format_number(parval), par_format_text(parunit));

			if (NULL != pdf) {
				if (-1 == fprintf(pdftex_fp, "%s", buffer)) {
					throw WriteError, "printf failed to write to $pdf.tex: "$ + errno_string(errno);
				}
			}
		} else {
			buffer = NULL;
		}

		if (tex and (NULL != buffer)) {
			if (Ref_Type == typeof(fpar)) {
				@fpar += buffer;
			} else {
				if (written = fprintf(fp, "%s", buffer), written == -1) {
					throw WriteError, "printf failed to write to $fp: "$ + errno_string(errno);
				}
			}
		} else if (not tex) {
			if (Ref_Type == typeof(fpar)) {
				@fpar += par_lines[i];
			} else {
				if (written = fprintf(fp, "%s", par_lines[i]), written == -1) {
					throw WriteError, "printf failed to write to $fp: "$ + errno_string(errno);
				}
			}
		}

		total += written;
	}

	for (i = 0; i < length(include_user); i++) {

		buffer = sprintf("%s & $%s$ & %s \\\\\n", par_format_text(include_user[i][0]),
			par_format_number(include_user[i][1]), par_format_text(include_user[i][2]));

		if (NULL != pdf) {
			if (-1 == fprintf(pdftex_fp, "%s", buffer)) {
				throw WriteError, "printf failed to write to $pdf.tex: "$ + errno_string(errno);
			}
		}

		if (tex and (NULL != buffer)) {
			if (Ref_Type == typeof(fpar)) {
				@fpar += buffer;
			} else {
				if (written = fprintf(fp, "%s", buffer), written == -1) {
					throw WriteError, "printf failed to write to $fp: "$ + errno_string(errno);
				}
			}
		}

		total += written;
	}

	buffer = par_format_text("\\bottomrule\\end{tabular}\n");

	if (NULL != pdf) {
		if (-1 == fprintf(pdftex_fp, "%s", buffer)) {
			throw WriteError, "printf failed to write to $pdf.tex: "$ + errno_string(errno);
		}
	}

	if (tex) {
		if (Ref_Type == typeof(fpar)) {
			@fpar += buffer;
		} else {
			if (written = fprintf(fp, "%s", buffer), written == -1) {
				throw WriteError, "printf failed to write to $fp: "$ + errno_string(errno);
			}
		}

		total += written;
	}

	if (NULL != pdf) {
		buffer = par_format_text("\\end{table}\n\\end{document}");

		if (-1 == fprintf(pdftex_fp, buffer)) {
			throw WriteError, "printf failed to write to $pdf.tex: "$ + errno_string(errno);
		}
	}

	if (String_Type == typeof(fpar)) {
		() = fclose(fp);
	}

	if (NULL != pdf) {
		() = fclose(pdftex_fp);
		vmessage("pdflatex --shell-escape $pdf"$);
		() = system("pdflatex --shell-escape $pdf.tex"$);
		() = system("rm $pdf.log $pdf.aux");
	}

	if (Ref_Type == typeof(fpar)) {
		total = strlen(@fpar);
	}

	if (fpar != NULL) {
		return total;
	} else {
		return;
	}
}
