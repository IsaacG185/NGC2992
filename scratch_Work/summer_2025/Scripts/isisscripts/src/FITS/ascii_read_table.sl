define ascii_read_table()
%!%+
%\function{ascii_read_table}
%\synopsis{reads an ASCII table from a file into a structure}
%\usage{Struct_Type table = ascii_read_table(String_Type filename, String_Type formats[]);
%\altusage{Struct_Type table = ascii_read_table(String_Type filename, List_Type infos[]); with  infos[i] = { formats[i], columns[i] };}
%\altusage{(table, keys) = ascii_read_table(String_Type filename, List_Type infos[]);\n
%    % with  infos[i] = { formats[i], columns[i], units[i] };}
%}
%\description
%    The data format of the columns has to be specified as for sscanf; i.e.,
%    %s for strings, %d for decimal integers, %F for double precision floats, ...
%    Lines starting with a comment string ("#" by default; see below) are ignored.
%    The return value is a structure containing the table.
%    Therefore, the column names have to respect the conventions
%    for struct-field names (no special characters as "-"...).
%    If the column name is "", this column is skipped.
%    If a unit is given, the function ascii_read_table has a second return value,
%    namely a keys-structure which can be used for \code{fits_write_binary_table}.
%\qualifiers{
%\qualifier{comment}{string which indicates comments [default = "#"]}
%\qualifier{startline}{Only lines after this number are considered.}
%\qualifier{endline}{The file is not read after this line number.}
%\qualifier{verbose}{}
%}
%\examples
%    \code{variable tab1 = ascii_read_table(filename, [{"%s"}, {"%F"}, {"%F"}]);}\n
%    \code{%} reads \code{String_Type tab1.col1}, \code{Double_Type tab1.col2}, \code{Double_Type tab1.col3} from \code{filename}
%
%    \code{variable tab2 = ascii_read_table(filename, [{"%s","A"}, {"%F","B"}, {"%F","C"}]);}\n
%    \code{%} reads \code{String_Type tab2.A}, \code{Double_Type tab2.B}, \code{Double_Type tab2.C}
%
%    \code{variable tab3 = ascii_read_table(filename, [{"%s","A"}, {"%F",""}, {"%F","C"}]);}\n
%    \code{%} reads \code{String_Type tab3.A}, skips one \code{Double_Type} column and reads \code{Double_Type tab3.C}
%
%    \code{variable tab4, keys;}\n
%    \code{(tab4, keys) = ascii_read_table(filename, [{"%s","A"}, {"%F"}, {"%F","C","u"}]);}\n
%    \code{%} reads \code{String_Type tab4.A} and \code{Double_Type tab4.C} as before. With\n
%    \code{fits_write_binary_table(FITSfilename, "tab4", tab4, keys);}\n
%    \code{%} the unit "u" is assigned to the (second) column C.
%\seealso{sscanf, fits_read_table, fits_write_binary_table, readcol}
%!%-
{
  variable filename, infos;
  switch(_NARGS)
  { case 2: (filename, infos) = (); }
  { help(_function_name()); return; }

  infos = [infos];
  variable comment = qualifier("comment", "#");
  variable startline = qualifier("startline", 1);
  variable endline = qualifier("endline", -1);
  variable verbose = qualifier_exists("verbose");

  variable F = fopen(filename, "r");
  if(F==NULL)  { vmessage("error (%s): file %s cannot be read", _function_name(), filename); return; }

  variable formats, columns, units=NULL;
  variable i, n=length(infos);
  if(typeof(infos[0])==List_Type)
  { variable needunits = 0;
    _for i (0, n-1, 1)
      if(length(infos[i])>2)  { needunits = 1; break; }
    formats = String_Type[n];
    columns = String_Type[n];
    if(needunits)  units = String_Type[n];
    _for i (0, n-1, 1)
    { formats[i] = infos[i][0];
      variable length_infos_i = length(infos[i]);
      if(length_infos_i > 1)  columns[i] = infos[i][1];  else  columns[i] = "col"+string(i+1);
      if(needunits)
        if(length_infos_i > 2)  units[i] = infos[i][2];  else  units[i] = "";
    }
  }
  else
  { formats = infos;
    columns = "col" + array_map(String_Type, &string, [1:n]);
  }

  variable cols_to_use = where(columns != "");
  variable keys;
  if(units!=NULL)
  { variable key_fields = "TUNIT" + array_map(String_Type, &string, [1:length(cols_to_use)]);
    keys = @Struct_Type(key_fields);
    variable j = 1;
    _for i (0, n-1, 1)
      if(columns[i]!="")
      { set_struct_field(keys, key_fields[j-1], units[i]);
	j++;
      }
  }

  variable table = @Struct_Type(columns[cols_to_use]);

  variable line;
  variable line_nr = 0;
  while(fgets(&line, F)!=-1 && (endline<0 || line_nr<endline))
  {
    line_nr++;
    if(line_nr>=startline)
      if(string_match(line, "^"+comment, 1))
      { if(verbose)
	  vmessage("(%s): skipping line # %d starting with %s\n", _function_name(), line_nr, comment);
      }
      else
      { variable buffer = line;
        _for i (0, n-1, 1)
        { variable value=NULL;
	  variable fmt = formats[i]+"%[^\n]";
          if(sscanf(buffer, fmt, &value, &buffer)<2)
          {
	    variable fmtstr = strreplace(strreplace(fmt,
						    "\t", `\t`),
					 "\n", `\n`);
	    variable complete_fmtstr = strreplace(strreplace(strjoin(formats, ""),
							     "\t", `\t`),
						  "\n", `\n`);
	    vmessage(`error (%s): cannot read column %d in line %d,
"%s".
The complete format string is "%s". (comment="%s")
%s was scanning the remaining buffer "%s" for the format "%s".
`,
		     _function_name(), i+1, line_nr, line[[:-2]], complete_fmtstr, comment,
		     _function_name(), buffer, fmtstr);
            return;
          }
	  if(columns[i]!="")
	  {
	    variable a = get_struct_field(table, columns[i]);
	    if(a==NULL)
	      set_struct_field(table, columns[i], {value});
	    else
	      list_append(a, value);
	  }
        }
      }
  }
  ()=fclose(F);

  _for i (0, n-1, 1)
    if(columns[i]!="" && get_struct_field(table, columns[i])!=NULL)
      set_struct_field(table, columns[i], list_to_array(get_struct_field(table, columns[i])));

  return units==NULL ? table : (table, keys);
}
