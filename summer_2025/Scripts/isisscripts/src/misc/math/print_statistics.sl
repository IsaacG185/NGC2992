define print_statistics()
%!%+
%\function{print_statistics}
%\synopsis{shows statistical information on an array of numbers}
%\usage{print_statistics(Double_Type a[]);
%\altusage{print_statistics(Struct_Type s);}
%}
%\description
%    If the argument of \code{print_statistics} is an array \code{a},
%    its minimum, average, standard deviation and maximum 
%    are shown. If \code{a} contains irregular numbers (\code{nan} or \code{+/-inf}),
%    the same quantities are also shown for the regular numbers only.
%
%    If \code{print_statistics} is called with a structure argument,
%    the above mentioned task is performed on all array fields.
%\seealso{moment}
%!%-
{
  variable a;
  switch(_NARGS)
  { case 1: a = (); }
  { help(_function_name()); return; }

  variable m, i;
  if(typeof(a)==Struct_Type)
  {
    variable field = get_struct_field_names(a);
    foreach field (field)
    {
      ()=printf("%s=", field);  % field name
      field = get_struct_field(a, field);  % field value
      ()=printf("%S", _typeof(field));
      if(typeof(field)==Array_Type)
      {
	()=printf("[%s]", strjoin(array_map(String_Type, &string, array_shape(field)), ","));
	if(0<__is_numeric(field)<3)
	{
	  m = moment(field);
	  ()=printf(" {min=%g, av=%g, sdev=%g, max=%g}", m.min, m.ave, m.sdev, m.max);
	  i = wherenot(isnan(field) or isinf(field));
	  if(length(i)<length(field))
	  {
	    m = moment(field[i]);
	    ()=printf(" (%d regular numbers {min=%g, av=%g, sdev=%g, max=%g})", length(i), m.min, m.ave, m.sdev, m.max);
	  }
	}
      }
      ()=printf("\n");
    }
    return;
  }

  variable dims = array_shape(a);
  ()=printf("\n       %d", dims[0]);
  _for i (1, length(dims)-1, 1)  ()=printf(" x %d", dims[i]);
  if(length(dims)>1)  ()=printf(" = %d", length(a));
  m = moment(a);
  i = wherenot(isnan(a) or isinf(a));  % regular numbers
  if(length(i)<length(a))  % there are irregular numbers
  { variable mreg = moment(a[i]);
    ()=printf("  (%d regular numbers)\n", length(i));
    ()=printf("min  = %-20g (%g)\n", m.min,  mreg.min);
    ()=printf(" av  = %-20g (%g)\n", m.ave,  mreg.ave);
    ()=printf("sdev = %-20g (%g)\n", m.sdev, mreg.sdev);
    ()=printf("max  = %-20g (%g)\n", m.max,  mreg.max);
  }
  else  % there are no irregular numbers
  { ()=printf("\n");
    ()=printf("min  = %g\n", m.min);
    ()=printf(" av  = %g\n", m.ave);
    ()=printf("sdev = %g\n", m.sdev);
    ()=printf("max  = %g\n", m.max);
  }
}
