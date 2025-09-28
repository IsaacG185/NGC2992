define transpose_table()
%!%+
%\function{transpose_table}
%\synopsis{transforms a structure of arrays into an array of structures and vice versa}
%\usage{Array_Type table_by_rows    = transpose_table(Struct_Type table_by_columns);
%\altusage{Struct_Type table_by_columns = transpose_table(Array_Type table_by_rows);}
%}
%\description
%    \code{table_by_columns.field[i] = table_by_rows[i].field;}  % for each \code{field} and index \code{i}
%!%-
{
  variable table;
  switch(_NARGS)
  { case 1: table = (); }
  { help(_function_name()); return NULL; }

  variable field, fields;
  if(typeof(table)==Struct_Type)
  { fields = get_struct_field_names(table);
    variable i, l = length(get_struct_field(table, fields[0]));
    variable rows = Struct_Type[l];
    _for i (0, l-1, 1)
    { rows[i] = @Struct_Type(fields);
      foreach field (fields)
        set_struct_field( rows[i], field,  get_struct_field(table, field)[i] );
    }
    return rows;
  }
  else
  { fields = get_struct_field_names(table[0]);
    variable cols = @Struct_Type(fields);
    foreach field (fields)
      set_struct_field(cols, field,  array_struct_field(table, field) );
    return cols;
  }
}
