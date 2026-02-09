
% define default public variables
#if (__get_reference("APROPOS_FORMAT_NAME") == NULL)
variable APROPOS_FORMAT_NAME = "cyan";
#endif
#if (__get_reference("APROPOS_FORMAT_MATCH") == NULL)
variable APROPOS_FORMAT_MATCH = "bred";
#endif
#if (__get_reference("APROPOS_LINE_WIDTH") == NULL)
variable APROPOS_LINE_WIDTH = isatty(stdin)
  ? string_matches(
    fgetslines(popen("stty size", "r"))[0],
    `[0-9]* \([0-9]*\)\n`
  )
  : NULL;
APROPOS_LINE_WIDTH = APROPOS_LINE_WIDTH == NULL ? 80 : atoi(APROPOS_LINE_WIDTH[1]);
#endif
#if (__get_reference("APROPOS_ENABLE_SYNOPSIS") == NULL)
variable APROPOS_ENABLE_SYNOPSIS = 1;
#endif

% Helper function for printing the result of 'apropos_slang'
% taking the terminal's size into account. Input parameters
% are the _formatted_, i.e., highlighted function names
% (String_Type[]) and their _original_ string length
% (Integer_Type[]).
private define _print_apropos(s, len) {
  % calculate number of matches fitting into one line
  variable maxlen = max(len);
  variable cols = APROPOS_LINE_WIDTH / (maxlen + 2);
  % fill input with empty elements such that 'length(s) mod cols == 0'
  variable acol = length(s) mod cols;
  if (acol > 0) { acol = cols - acol; }
  s = [s, array_map(String_Type, &sprintf, "", ones(acol))];
  len = [len, Integer_Type[acol]];
  % define sprintf format ("%s" times cols)
  variable format = strjoin(array_map(String_Type, &sprintf, "%%s", ones(cols)));
  % since escape codes are used in the strings,
  % their individual string lengths are larger than the actual printed ones
  % -> move cursor manually back and forth
  variable i;
  _for i (0, length(s)-1, 1) {
    s[i] = sprintf("%s%s%s", s[i],
      ansi_escape_code(sprintf("%dback", len[i])),
      ansi_escape_code(sprintf("%dforward", maxlen + 2))
    );
  }
  % loop and print
  _for i (0, length(s)-1, cols) {
    vmessage(format, __push_array(s[[i:i+cols-1]]));
  }
}

% Helper function for printing the result of the synopsis
% search, within 'aproposer', taking the terminal's size into
% account. Input paramter are _formatted_ output lines to
% print (String_Type[]), their _original_ string length
% (Integer_Type[]), and the string length of the function
% (Integer_Type[]).
private define _print_aproposer(s, len, funlen) {
  variable n = length(s);
  vmessage("\nFound %d synopsis match%s:", n, n > 0 ? "es" : "");
  variable tmp, cslen, k;
  _for n (0, length(s)-1, 1) {
    tmp = s[n];
    % trim string of fit into the terminal
    if (len[n] > APROPOS_LINE_WIDTH) {
      % split into words
      tmp = strchop(tmp, ' ', 0);
      % cumsum length
      cslen = int(cumsum(array_map(Integer_Type, &strlen, tmp) + [0,ones(length(tmp)-1)]));
      % split at terminal width
      k = where(diff(int(cslen) / APROPOS_LINE_WIDTH));
      if (length(k) > 0) { % add line break and indent
	k++; if (k[-1] >= length(tmp)) { k = k[[:-2]]; }
	tmp[k] = tmp[k] + "\n";
	k++; if (k[-1] >= length(tmp)) { k = k[[:-2]]; }
	tmp[k] = sprintf(sprintf("%%%ds", funlen[n]+1), "") + tmp[k];
	   % +1 = +2 (': ') -1 (already existing space due to strjoin below)
      }
      % merge
      tmp = strjoin(tmp, " ");
    }
    % print
    vmessage(tmp);
  }
}

% a modified clone of the intrinsic slang 'apropos' (from cmds.sl),
% which highlights the matching substrings
private define apropos_slang()
{
  if (_NARGS != 1) { help(_function_name); return; }

  % substring to search for
  variable what = ();
  what = str_delete_chars(what, ";\"");
  variable wlen = strlen(what);
  variable owhat = strlow(what); % remember original search keyword
  if (0 == is_substr (what, "\\")) { what = "\\C" + what; } % case insensitive search

  % define namespaces and masks
  variable namespaces = [_isis->Isis_Public_Namespace_Name, current_namespace()];
  variable masks = Assoc_Type[];
  masks["function"] = 1|2;
  masks["variable"] = 4|8;

  % prepare output structure
  variable s = struct_array(length(masks)*length(namespaces), struct {
    section = "", % section's title
    output = String_Type[0], % matches in each section
    length = Integer_Type[0] % string length of matches
  });
 
  % loop over types and namespaces
  variable ns, type, list, n, i, pos, k = 0;
  foreach type (["function", "variable"]) {
    foreach ns (namespaces) {
      % find variables or functions within the namespace
      list = _apropos (ns, what, masks[type]);
      n = length(list);
      if (n == 0) { continue; }
      s[k].output = String_Type[n];
      s[k].length = Integer_Type[n];
      % add matches to output
      s[k].section = sprintf("%sFound %d %s match%s in namespace %S:",
	length(s) > 0 ? "\n" : "",
        n, type, n>1 ? "es" : "", ns
      );
      list = list[array_sort(list, &strcmp)];
      _for i (0, n-1, 1) {
	pos = is_substr(strlow(list[i]), owhat); % need to use original keyword here!
	s[k].length[i] = strlen(list[i]);
	s[k].output[i] = sprintf("%s%s%s",
	  ansi_escape_code(APROPOS_FORMAT_NAME, substr(list[i], 1, pos-1)),
	  ansi_escape_code(APROPOS_FORMAT_MATCH, substr(list[i], pos, wlen)),
	  ansi_escape_code(APROPOS_FORMAT_NAME, substr(list[i], pos+wlen, -1))
        );
      }
      k++;
    }
  }

  %%% print matches
  _for i (0, length(s)-1, 1) {
    if (length(s[i].output) > 0) {
      vmessage(s[i].section);
      _print_apropos(s[i].output, s[i].length);
    }
  }
}

%%%%%%%%%%%%%%%
define aproposer()
%%%%%%%%%%%%%%%
%!%+
%\function{aproposer}
%\synopsis{recall object names and the documentation satisfying a regular expression}
%\usage{aproposer("s")}
%\description
%  This is an extended version of S-Lang's 'apropos' function,
%  which may be used to get a list of all defined objects
%  whose name matches the regular expression "s". In addition,
%  the SYNOPSIS of all functions described in the documentation
%  files is checked on matches as well. Finally, the output is
%  formatted such that the matching substring and the object's
%  name are printed in different colors (see below for format
%  options).
%
%  In order to use this function instead of the intrinsic 'apropos'
%  function, you can put
%    alias("aproposer", "apropos");
%  into, e.g., your .isisrc file.
%
%  Further variables can be defined within the .isisrc file for
%  more control options:
%    APROPOS_ENABLE_SYNOPSIS - 0 = turn off the synopsis search
%    APROPOS_FORMAT_NAME     - format string for the object's name
%    APROPOS_FORMAT_MATCH    - format string for the substring match
%    APROPOS_LINE_WIDTH      - number of columns of the terminal,
%        which is needed to format the output (default: output of
%        `stty size` or 80 if the first attempt fails)
%  Read the documentation of 'ansi_escape_code' for details about
%  the format string.
%\seealso{apropos, .apropos, help, who,
%    get_doc_files, ansi_escape_code}
%!%-
{
  if (_NARGS != 1) { help(_function_name); return; }

  % substring to search for
  variable what = ();
  what = strlow(str_delete_chars(what, ";\""));
  variable wlen = strlen(what);

  % call old apropos
  apropos_slang(what);

  ifnot (APROPOS_ENABLE_SYNOPSIS) { return; }
  
  % init data structure
  variable s = struct {
    function = String_Type[0], % function's name
    output   = String_Type[0], % output string (formatted)
    length   = Integer_Type[0] % original string length
  };
  % loop over all documentation files
  variable file, in_synopsis, in_function, i, content, pos, match, synops, funname;
  variable docfiles = get_doc_files();
  foreach file (docfiles) {
    % loop over the whole content of the file
    content = fgetslines(fopen(file, "r"));
    in_synopsis = 0; in_function = 0; match = "";
    _for i (0, length(content)-1, 1) {
      if (in_function) {
	% extract and check synopsis
        if (in_synopsis == 1) {
	  % check on end of synopsis (CAPITAL word at beginning)
	  if (string_match(content[i], "^ [A-Z]*\n"R)) {
            % check for a match in synopsis	    
            pos = is_substr(strlow(synops), what);
	    % match in synopsis found
	    if (pos) {
	      % add function's name (if not done below already) ...
	      if (match == "") {
		% ... to data structure
		s.function = [s.function, funname];
		% ... and to prepared output
		match = ansi_escape_code(
		  APROPOS_FORMAT_NAME, funname
		);
		% ... and add the string length
		s.length = [s.length, strlen(funname)];
	      }
	      % add and highlight synopsis
	      s.length[-1] = s.length[-1] + strlen(synops) + 2;
	      match = sprintf("%s: %s", match, sprintf("%s%s%s",
	        substr(synops, 1, pos-1),
	        ansi_escape_code(APROPOS_FORMAT_MATCH, substr(synops, pos, wlen)),
		substr(synops, pos+wlen, -1)
	      ));
	    }
	    % no match found, but match in function's name already
	    % -> add synopsis
	    else if (match != "") {
	      match = sprintf("%s: %s", match, synops);
	      s.length[-1] = s.length[-1] + strlen(synops) + 2;
	    }
	    % close synopsis section
	    in_synopsis = 2;
	  }
	  % add current line to synopsis string
	  else {
	    if (strlen(synops) > 0) { synops += " "; }
	    if (content[i] != "\n") {
              synops += str_delete_chars(strtrim_beg(content[i]), "\n");
	    }
	  }
	}
	else {
          % check for a match in function's name
	  if (in_function == 1) {
	    funname =  str_delete_chars(content[i-1], "\n");
	    synops = ""; % reset synopsis
            pos = is_substr(strlow(funname), what);
	    % match in name found
            if (pos) {
	      % add function's name and its length to data structure
	      s.function = [s.function, funname];
	      s.length = [s.length, strlen(funname)];
	      % prepare formatted output string, i.e., highlight match in function's name
	      match = sprintf("%s%s%s",
	        ansi_escape_code(APROPOS_FORMAT_NAME, substr(funname, 1, pos-1)),
	        ansi_escape_code(APROPOS_FORMAT_MATCH, substr(funname, pos, wlen)),
		ansi_escape_code(APROPOS_FORMAT_NAME, substr(funname, pos+wlen, -1))
	      );
	    }
	    in_function = 2;
	  }
	  % check on an opening synopsis section
	  if (in_synopsis == 0) {
            in_synopsis = string_match(content[i], "^ SYNOPSIS\n"R);
	  }
	  % check on end of function's documentation
	  if (string_match(content[i], "^-+\n"R) || i == length(content)-1) {
	    % synopsis section is not provided for this function
	    if (in_synopsis != 2) {
	      if (length(s.function) == length(s.output)+1) {
                s.function = s.function[[:-2]];
	        s.length = s.length[[:-2]];
	      }
	    }
            % * add prepared match to output
	    else if (match != "") {
	      s.output = [s.output, match]; match = "";
	    }
	    % reset
	    in_function = 0;
	    in_synopsis = 0;
	  }
	}
      }
      % check on beginning of a function's documentation
      else {
	in_function = string_match(content[i], "^[a-zA-Z].*\n"R);
      }
    }
  }

  %%% print matches
  if (length(s.function) > 0) {
    % remove multiple occurences of the same function and sort
    struct_filter(s, unique(s.function));
    struct_filter(s, array_sort(s.function, &strcmp));
    _print_aproposer(s.output, s.length, strlen(s.function));
  }
}
