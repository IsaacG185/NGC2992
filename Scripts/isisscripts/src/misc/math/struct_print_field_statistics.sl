define struct_print_field_statistics()
%!%+
%\function{struct_print_field_statistics}
%\usage{struct_print_field_statistics(Struct_Type s);}
%\seealso{moment}
%!%-
{
  variable s;
  switch(_NARGS)
  { case 1: s = (); }
  { help(_function_name()); return; }

  variable fieldnames = get_struct_field_names(s);
  variable fmt = sprintf("%%%ds: ",  max(array_map(Integer_Type, &strlen, fieldnames)));
  variable fieldname;
  foreach fieldname (fieldnames)
  {
    ()=printf(fmt, fieldname);
    variable a = get_struct_field(s, fieldname);
    variable dims, type;  (dims, , type) = array_info(a);
    foreach $1 (dims) { ()=printf("%d x ", $1); }
    ()=printf("%S", type);
    if( __is_datatype_numeric(type) )
    { variable m = moment(a);
      ()=printf(" [min=%g, av=%g, sdev=%f, max= %g]", m.min, m.ave, m.sdev, m.max);
    }
    ()=printf("\n");
  }
}
