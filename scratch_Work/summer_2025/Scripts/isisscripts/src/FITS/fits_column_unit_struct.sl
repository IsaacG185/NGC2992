define fits_column_unit_struct()
%!%+
%\function{fits_column_unit_struct}
%\synopsis{creates a structure of FITS header keywords containing the units of columns}
%\usage{Struct_Type fits_column_unit_struct(Struct_Type data; field1=unit1, field2=unit2)}
%\example
%    \code{variable data = struct { time, rate };}\n
%    \code{fits_write_binary_table("lc.fits", "lightcurve", data, fits_column_unit_struct(data; time="MJD", rate="counts/s/PCU") );}
%\seealso{fits_write_binary_table}
%!%-
{
  variable data;
  switch(_NARGS)
  { case 1: data = (); }
  { help(_function_name()); return; }

  variable fields = get_struct_field_names(data);

  variable keywords = String_Type[0];
  data = String_Type[0];
  variable q, qs = get_struct_field_names(__qualifiers());
  foreach q (qs)
  { variable i = where(fields==q);
    if(length(i)>0)
    { keywords = [keywords, "TUNIT"+string(i[0]+1)];
      data = [data, qualifier(q)];
    }
    else
      vmessage(`warning (%s): column "%s" does not exist in the data`, _function_name(), q);
  }
  variable keys = @Struct_Type(keywords);
  set_struct_fields(keys, __push_array(data));
  return keys;
}
