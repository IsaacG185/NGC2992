%%%%%%%%%%%%%%%%%%%
define print_struct()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{print_struct}
%\synopsis{prints the fields of a structure as columns of a table}
%\usage{print_struct([File_Type F,] Struct_Type s);}
%\description
%    If \code{s} is a structure of arrays or lists,
%    these are displayed as columns of a table.
%    The output is written to \code{stdout} unless another \code{F}
%    is specified, which may either be a file pointer
%    or a string containing the filename.
%\qualifiers{
%\qualifier{i}{array of rows which are to be shown at all}
%\qualifier{mark}{array of rows which are to be marked}
%\qualifier{fields}{array of fieldnames (columns) which are to be shown}
%\qualifier{fmt}{format string(s) for the columns, see \code{help("sprintf");}}
%\qualifier{sep}{string separator between the columns (default = \code{"   "})}
%\qualifier{initial}{initial separator on a line (default = \code{""})}
%\qualifier{final}{final separator on a line (default = \code{""})}
%\qualifier{html}{set \code{sep}, \code{initial} and \code{final} such that an HTML table is produced}
%\qualifier{tex}{set \code{sep}, \code{initial} and \code{final} such that a TeX table is produced}
%\qualifier{nohead}{don't show head line with field names}
%}
%\examples
%    \code{print_struct(   s);                       %} The fields of \code{s} are printed.\n
%    \code{print_struct(F, s);                       %} The fields of \code{s} are printed to the file \code{F}.\n
%    \code{print_struct( , s; fmt="%.2f");           %} The fields are floats which are printed with 2 decimals.\n
%    \code{print_struct( , s; fmt="%.2f", sep=" ");  %} As before, but with smaller separation between the columns.
%\seealso{writecol, sprintf}
%!%-
{
  variable F=stdout, s;
  switch(_NARGS)
  { case 1:     s  = (); }
  { case 2: (F, s) = (); }
  { help(_function_name()); return; }

  variable fcloseF = 0;
  if(typeof(F)==String_Type)  (F, fcloseF) = (fopen(F, "w"), 1);

  % find fields to be shown
  variable fields = qualifier("fields");
  if(fields==NULL)
  { fields = String_Type[0];
    variable field;
    foreach field ( get_struct_field_names(s) )
      if(any([Array_Type, List_Type]==typeof(get_struct_field(s, field))))
	fields = [fields, field];
  }
  if(length(fields)==0)  % no array or list fields found
    fields = get_struct_field_names(s);  % print scalar fields instead
  variable nFields = length(fields);

  % get arrays
  variable arrays = Array_Type[nFields];
  variable col;
  _for col (0, nFields-1, 1)
  {
    variable val = get_struct_field(s, fields[col]);
    if(typeof(val)==List_Type)  val = list_to_array(val);
    arrays[col] = [ val ];
  }

  % formats
  variable fmt, fmt0 = qualifier("fmt", "%S");
  if(typeof(fmt0)==Array_Type && length(fmt0)==nFields)
    fmt = fmt0;
  else
  { fmt = String_Type[nFields];
    if(typeof(fmt0)!=Array_Type)
      fmt[*] = fmt0;
    else
    { vmessage("warning (%s): %d format(s) given for %d field(s)", _function_name(), length(fmt0), nFields);
      fmt = String_Type[nFields];
      if(length(fmt0)<nFields)
      { fmt[[0:length(fmt0)-1]] = fmt0;
	fmt[[length(fmt0):]] = "%S";
      }
      else
        fmt = fmt0[[0:nFields-1]];
    }
  }
  variable mark = qualifier("mark", Integer_Type[0]);
  variable indices = qualifier("i", [0:length(arrays[0])-1]);

  % format table values
  variable row, nRows = length(arrays[0][indices]);
  ifnot(qualifier_exists("nohead"))  nRows++;
  variable str = String_Type[nRows, 1+nFields];
  variable y = 0;
  ifnot(qualifier_exists("nohead"))
  { str[y,0] = "";
    _for col (1, nFields, 1)  str[y,col] = fields[col-1];
    y++;
  }
  foreach row (indices)
  { if( any(mark==row) )  str[y,0] = "*";  else  str[y,0] = "";
    _for col (1, nFields, 1)  str[y,col] = sprintf(fmt[col-1], arrays[col-1][row]);
    y++;
  }

  % fill up with spaces
  variable max_len = Integer_Type[1+nFields];
  _for col (0, nFields, 1)
  { max_len[col] = max( array_map(Integer_Type, &strlen, str[*,col]) );
    _for y (0, nRows-1, 1)
      str[y,col] = multiple_string(max_len[col]-strlen(str[y,col]), " ") + str[y,col];
  }

  % print table
  variable sep = qualifier("sep", "   ");
  variable cols = where(max_len>0);
  variable initial = qualifier("initial", "");
  variable final = qualifier("final", "");
  variable text_after_table = "";
  if(qualifier_exists("html"))
  { (initial, sep, final) = ("<TR><TD> ", " </TD><TD> ", " </TD></TR>");
    ()=fprintf(F, "<TABLE>\n");
    text_after_table = "</TABLE>\n";
  }
  else
    if(qualifier_exists("tex"))
    { (initial, sep, final) = ("", " & ", ` \\`);
      variable align = qualifier("tex");
      if(align==NULL)  align = "l";
      ()=fprintf(F, `\begin{tabular}{` + multiple_string(length(cols), align) + "}\n");
      text_after_table =  "\\end{tabular}\n";
    }
  _for y (0, nRows-1, 1)
    ()=fprintf(F, "%s%s%s\n", initial, strjoin(str[y, cols], sep), final);
  ()=fprintf(F, text_after_table);
  if(fcloseF)  ()=fclose(F);
}
