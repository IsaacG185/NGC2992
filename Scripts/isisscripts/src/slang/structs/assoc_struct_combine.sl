%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define assoc_struct_combine()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{assoc_struct_combine}
%\synopsis{associate structure fields, combine structures and fill entries}
%\usage{Struct_Type \code{comb} = assoc_struct_combine(Struct_Type \code{s1}, Struct_Type \code{s2}, String_Type \code{f1}, String_Type \code{f2});}
%\qualifiers{
%\qualifier{double_fill [=_NaN]}{: filler for missing entries in Double_Type fields of \code{s2}}
%\qualifier{float_fill [=_NaN]}{:  filler for missing entries in Float_Type fields of \code{s2}}
%\qualifier{integer_fill [=_0]}{:  filler for missing entries in Integer_Type fields of \code{s2}}
%\qualifier{string_fill [=""]}{:   filler for missing entries in String_Type fields of \code{s2}}
%\qualifier{flag_field_name  [="both_struct_flag"]}{: additional field name for \code{comb}}
%}
%\description
%    This function combines two structures. It uses the field with name \code{f1} of the
%    structure \code{s1} and that with name \code{f2} of \code{s2} to associate the entries with the function
%    get_intersection. The fields of the returned structure \code{comb} have the length of the
%    field \code{f1}. The entries in these fields are filled according to the qualifiers, if
%    there is no association found for this entry.
%    Fields of a type for which no fill qualifier is given are filled with NULL and
%    returned as a list. Fillers can be defined via qualifiers for all variable types.
%    The suffix _fill is required, i.e., for example the qualifier to define a filler
%    for Complex_Type is \code{complex_fill}.
%    WARNING: This function fails for more dimensional fields. If there are fields with
%    the same name in both structures, the field of \code{s2} is used, as it is done by
%    struct_combine. The field \code{f2} is not included.
%    The function adds a field (name can be indentified via qualifier \code{flag_field_name}),
%    which indicates if the entry was found in both structures (1) or if it exists
%    only in \code{f1} (0).
%    
%\examples
%    a = struct{source = ["1", "2", "3"], flux=[0.1, 2.5, 0.7]};
%    b = struct{source = ["3", "2"], redshift=[0.65, 0.03], opt_id = ["Quasar","BL Lac"]};
%    c = assoc_struct_combine (a,b,"source", "source");
%    print_struct(c);
%
%    % without filling fields, but using just common fields this corresponds to:
%    (i1,i2) = get_intersection(a.source,b.source);
%    struct_filter(a,i1); 
%    struct_filter(b,i2);
%    d = struct_combine(a,b);
%    print_struct(d);
%\seealso{get_intersection, struct_combine, struct_filter}
%!%-
{
  variable s1, s2, f1, f2;
  switch(_NARGS)
  { case 4: (s1, s2, f1, f2) = (); }
  { help(_function_name()); return; }

  variable field = NULL;
  field = get_struct_field (s1,f1);
  if (field == NULL) return NULL;

  variable f, i1, i2;
  variable l     = length(field);
  variable flag  = qualifier ("flag_field_name",   "both_struct_flag");
  variable fill   = Assoc_Type[];
  fill["double"]  = _NaN;
  fill["float"]   = _NaN;
  fill["integer"] =    0;
  fill["string"]  =   "";
  variable qlfr = __qualifiers();
  if (qlfr != NULL) {
    foreach f (get_struct_field_names(qlfr))
    { fill[strlow(string(f)[[:-6]])] = get_struct_field(qlfr, f); }  }
  variable fn2 = get_struct_field_names (s2);
  fn2 = fn2[where(fn2 != f2)];
  variable r   = struct_combine (s1, [fn2, flag]);
  (i1, i2) = get_intersection (field, get_struct_field(s2,f2));
  variable t = Integer_Type[l];
  t[i1] = 1;
  set_struct_field(r, flag, t);
  foreach f (fn2)
  {
    variable type = _typeof( get_struct_field(s2, f) );
    variable type_string = strlow(string(type)[[:-6]]);
    if ( all( type_string != assoc_get_keys (fill)) )
    { t = {NULL}; t = t [ Integer_Type[l] ] ; }
    else
    { t = type[l]; t[*] = fill[type_string]; }
    t[i1] = get_struct_field(s2,f)[i2];
    set_struct_field(r, f, t);
  }
  return r;
}

