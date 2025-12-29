%%%%%%%%%%%%%%%%%%%%%%%%
define find_correlations()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{find_correlations}
%\synopsis{calculates all correlations between columns of a table}
%\usage{Struct_Type info = find_correlatins(Struct_Type s);}
%\description
%    \code{info.corr[i] = correlation_coefficient(s.<info.x[i]>, s.<info.y[i]>);}
%\seealso{correlation_coefficient}
%!%-
{
  variable s;
  switch(_NARGS)
  { case 1: s = (); }
  { help(_function_name()); return; }

  variable fields = get_struct_field_names(s);
  variable n_fields = length(fields);

  variable i, j, info = struct { x=String_Type[0], y=String_Type[0], corr=Double_Type[0] };
  _for i (0, n_fields-2, 1)
    _for j (i+1, n_fields-1, 1)
    { info.x = [info.x, fields[i]];
      info.y = [info.y, fields[j]];
      info.corr = [info.corr,
		   correlation_coefficient(get_struct_field(s, fields[i]),
					   get_struct_field(s, fields[j])
				          )
		  ];
    }
  struct_filter(info, array_sort(1-abs(info.corr)));
  return info;
}
