define table_add_row()
%!%+
%\function{table_add_row}
%\usage{table_add_row(table, ...);}
%!%-
{
  if(_NARGS<2) { help(_function_name()); return; }

  variable values = __pop_list(_NARGS-1);
  variable t = ();

  variable fieldnames, i, n = length(values);
  switch(typeof(t))
  { case Struct_Type:
      fieldnames = get_struct_field_names(t);
      if(length(fieldnames) == n)
        _for i (0, n-1, 1)
          set_struct_field(t, fieldnames[i], [get_struct_field(t, fieldnames[i]), values[i] ]);
      else
        vmessage("error (%s): The table is a structure of %d arrays, but %d values have been given.", _function_name(), length(fieldnames), n);
  }
  { case Array_Type:
      vmessage("warning (%s): The array cannot be modified, pass a reference to it (&) instead.", _function_name());
  }
  { case Ref_Type:
      if(typeof(@t)!=Array_Type)
      { vmessage("warning (%s): Table has to be a reference to an array (of structures).", _function_name());
        return;
      }
      variable s = (@t)[0];
      if(typeof(s) == Struct_Type)
      { s = @s;
        fieldnames = get_struct_field_names(s);
        if(length(fieldnames) == n)
        { _for i (0, n-1, 1) { set_struct_field(s, fieldnames[i], values[i]); }
          @t = [@t, s];
        }
        else
        { vmessage("error (%s): The table is an array of structures with %d fields, but %d values have been given.", _function_name(), length(fieldnames), n); }
      }
      else
      { if(n==1)
          @t = [@t, values[0]];
        else
          vmessage("error (%s): The table is just an array, but %d values have been given.", _function_name(), n);
      }
  }
  { % else:
      vmessage("error (%s): The table is neither a structure of arrays nor an array of structures, but a %S.", _function_name(), typeof(t));
  }
}
