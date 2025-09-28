define table_print_TeX()
%!%+
%\function{table_print_TeX}
%\synopsis{prints certain columns of a structure as a TeX table}
%\usage{table_print_TeX(Struct_Type tab[, String_Type cols[]]);}
%\description
%    If no columns are specified by the string-array \code{cols},
%    all columns of the table tab are used.
%\qualifiers{
%\qualifier{align}{alignment of all columns: "l", "c", "r" [default: "l"]}
%\qualifier{heading}{[=\code{cols}]: headings for TeX table}
%\qualifier{output}{[=stdout]: output can be written in a file by stating
%                       a File_Type or the filename (String_Type)}
%}
%!%-
{
  variable tab, cols;
  switch(_NARGS)
  { case 1: tab = (); cols = get_struct_field_names(tab); }
  { case 2: (tab, cols) = (); }
  { help(_function_name()); return; }

  variable x, y, nx = length(cols);
  variable heading = qualifier("heading", cols);
  variable out = qualifier("output");
  out = ( typeof(out) == File_Type ? out  : ( typeof(out)==String_Type ? fopen(out,"w") : stdout));
  
  ()=fprintf(out,"\\begin{tabular}{");
  loop (nx)  ()=fprintf(out,"%s", qualifier("align", "l"));
  ()=fprintf(out,"}\n");

  ()=fprintf(out," \\hline\n \\hline\n");
  ()=fprintf(out," %s", heading[0]);
  _for x (1, nx-1, 1)  ()=fprintf(out," & %s", heading[x]);
  ()=fprintf(out," \\\\\n \\hline\n");

  _for y (0, length(get_struct_field(tab, cols[0]))-1, 1)
  { ()=fprintf(out," %S", get_struct_field(tab, cols[0])[y]);
    _for x (1, nx-1, 1)  ()=fprintf(out," & %S", get_struct_field(tab, cols[x])[y]);
    ()=fprintf(out," \\\\\n");
  }
  ()=fprintf(out," \\hline\n");
  ()=fprintf(out,"\\end{tabular}\n");
  
  if (out != stdout) ()=fclose (out);
}
