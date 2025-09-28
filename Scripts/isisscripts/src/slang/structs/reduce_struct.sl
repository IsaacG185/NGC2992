%%%%%%%%%%%%%%%%%%%%
define reduce_struct()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{reduce_struct}
%\synopsis{remove one or more fields from a strucure}
%\usage{Struct_Type reduced_struct = reduce_struct(Struct_Type s, String_Type fieldsnames[]);}
%\qualifiers{
%\qualifier{extract:}{If given, the returned struct does only contain the fields 'fieldnames'!}
%}
%\description
%  Either removing the fields 'fieldnames' from the given structure 's' (if they even exist) or
%  if the qualifier 'extract' is given removing all other fields but those given with 'fieldnames'!
%!%-
{
  variable s, removeFields;
  switch(_NARGS)
  { case 2: (s, removeFields) = (); }
  { help(_function_name()); return; }
  
  variable fields = get_struct_field_names(s);
  variable ind;
  if( qualifier_exists("extract") ){
    ind = intersection(fields,removeFields);
  }
  else{
    ind = complement(fields,removeFields);
    ind = ind[array_sort(ind)];
  }
  fields = fields[ind];
  
  variable new_s = @Struct_Type(fields);
  variable field;
  foreach field (fields){
    set_struct_field(new_s, field, get_struct_field(s, field) );
  }
  return new_s;
}
