%%%%%%%%%%%%%%%%%%%%%%%%%%
define merge_struct_arrays()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{merge_struct_arrays}
%\synopsis{creates a structure whose fields are merged from all structures' fields}
%\usage{Struct_Type merged_s = merge_struct_arrays(Struct_Type s[]);}
%\description
%    All elements of s have to be structures with the same fields.
%    The return value merged_s is another structure of this kind, and
%    merged_s.field = [s[0].field, s[1].field, ..., s[-1].field];
%    holds for every field. (If s[i].field is NULL, it is skipped
%    unless "keep_null" qualifier is set.)
%\qualifiers{
%\qualifier{remove_excess_fields}{: remove fields not present in all
%       structures.}
%\qualifier{reshape = Integer_Type dim}{: reshape the merged fields to the
%       dimensions of the original fields, using the sum of dimensiom 'dim'
%       to account for the increased array. Care has to be taken that the
%       other dimension need to have the same length in all structures. }
%\qualifier{keep_null}{: keep fields which contain NULL.}
%}
%\seealso{append_struct_arrays, get_intersection, reshape}
%!%-
{
  variable s;
  switch(_NARGS)
  { case 1: s = (); }
  { help(_function_name()); return; }

  variable resh = qualifier("reshape", -1) ;
  variable field, i;
  if(qualifier_exists("remove_excess_fields"))
  {
    variable fieldnames = get_struct_field_names(s[0]);
    _for i (1, length(s)-1, 1)
    { variable i1;
      (i1, ) = get_intersection(fieldnames, get_struct_field_names(s[i]));
      fieldnames = fieldnames[i1];
    }
    _for i (0, length(s)-1, 1)
    { variable new_s = @Struct_Type(fieldnames);
      foreach field (fieldnames)
	set_struct_field(new_s, field, get_struct_field(s[i], field));
      s[i] = new_s;
    }
  }

  variable merged_s = @(s[0]);
  variable dim;
  foreach field (get_struct_field_names(s[0]))
  {
    variable  findim = 0  ;
    variable a = get_struct_field(s[0], field);
    if(a!=NULL or qualifier_exists("keep_null")){  a = [a];
     (dim,,)= array_info(a) ;
    findim += dim[resh] ; 
    }
    _for i (1, length(s)-1, 1)
    { variable a_ = get_struct_field(s[i], field);
      if(a_!=NULL or qualifier_exists("keep_null")) { a = [a, a_];
	(dim,,)= array_info(a_) ;
	findim += dim[resh] ;
      }
    }
    if(resh>=0 && length(dim)>resh){
      dim[resh] = findim  ;
      reshape(a,dim) ;
    }
    set_struct_field(merged_s, field, a);
  }
  return merged_s;
}
