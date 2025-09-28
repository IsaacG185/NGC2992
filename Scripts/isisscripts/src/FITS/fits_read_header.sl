%%%%%%%%%%%%%%%%%%%%%%
define fits_read_header()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Read a FITS header}
%\usage{Struct_Type fits_read_header(String_Type file or Fits_File_Type fp);}
%\description
%    This function reads the header of the fits file given by the
%    `file' argument and returns it as a structure.  If `file' is
%    a string, then the file will be opened, read-out, and closed
%    automatically. Otherwise, `file' should represent an already
%    opened FITS file (which will remain opened).
%\qualifiers{
%   \qualifier{lowercase}{return structure tags in lower case
%                           (default: upper case)}
%}
%\seealso{fits_read_records, fits_open_file}
%!%-
{
  variable fp;
  switch (_NARGS)
    { case 1: fp = (); }
    { help(_function_name); return; }

  % read the header of the FITS-file into an array of strings
  variable rec;
  if (typeof(fp) == String_Type) {
    if (string_matches(fp, "\[[-_A-Z0-9]*\]$"R, 1) == NULL) { fp += "[1]"; }
    fp = fits_open_file(fp, "r");
    rec = fits_read_records(fp);
    fits_close_file(fp);
  } else {
    rec = fits_read_records(fp);
  }

  % loop over all records
  variable head = NULL, n, key, value, extr, sub;
  _for n (0, length(rec)-1, 1) {
    sub = substr(rec[n], 1, 8);
    % check on continued string field
    if (sub == "CONTINUE") {
      value = get_struct_field(head, key);
      set_struct_field(head, key, sprintf("%s%s",
	substr(value, 1, strlen(value)-1), % remove '&'
	string_matches(rec[n], "'\(.*\)'"R)[1]
      ));
    }
    % check on comment or history
    else ifnot (any(sub == ["COMMENT ", "HISTORY "])) {
      % split the string at the first = into key and value
      key = strchop(rec[n], '=', 0);
      if (length(key) > 1) {
        value = strjoin(key[[1:]], "=");
        key = key[0];
        % check on HIERARCH
        if (sub == "HIERARCH") { key = substr(key, 9, strlen(key)); }
	% replace illegal characters
	key = strreplace(key, "-", "_");
	key = strreplace(key, " ", "");
	if (qualifier_exists("lowercase")) {
	    key=strlow(key);
	}
	% distinguish between numbers and strings
        extr = string_matches(value, "'\(.*\)'"R);
	if (extr == NULL)  { % number
	  value = strtrim(strchop(value, '/', 0)[0]);
	  % empty value?
	  if (strlen(value) == 0) { value = NULL; }
	  % logical 'true'
	  else if (value == "T") { value = '\1'; }
	  % logical 'false'
	  else if (value == "F") { value = '\0'; }
	  % float or integer?
	  else {
            value = is_substr(value, ".") ? atof(value) : atoi(value);
	  }
	} else { % string
	  value = strtrim_end(extr[1]);
	}
	% add to output header structure
	head = head == NULL ? struct_combine(key) : struct_combine(head, key);
        set_struct_field(head, key, value);
      }
    }
  }

  return head;
}
