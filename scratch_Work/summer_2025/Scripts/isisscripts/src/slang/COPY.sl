% -*- mode: slang; mode: fold -*-

define COPY() %{{{
%!%+
%\function{COPY}
%\synopsis{makes a copy of a nested Struct/Array/List_Type}
%   \usage{Struct_Type copy = COPY(Struct_Type copyme);}
%\altusage{Array_Type  copy = COPY(Array_Type  copyme);}
%\altusage{List_Type   copy = COPY(List_Type   copyme);}
%\altusage{Assoc_Type  copy = COPY(Assoc_Type   copyme);}
%\description
%    \code{COPY} returns a properly dereferenced copy of an
%    arbitrarily nested \code{Struct/Array or List_Type} with
%    all its entries. 
%    Depending on the Data_Type of the initial given
%    copyme and the Data_Type of its entries, \code{COPY}
%    iteratively calls the  according sub-function
%    (\code{struct_copy}, \code{array_copy} or \code{list_copy}).
%    If the given Data_Type or one of its entries is not
%    one of previously mentioned ones, \code{COPY} returns
%    @(Data_Type) or respectively @(entry).
%    
%    NOTE: * Ref_Type entries will not be dereferenced, which
%            allows to copy XFIG-OBJECTS !!!
%          * Double_Type[] is an Array_Type
%
%\example
%    Array_Type:
%     s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%     s[0].a[[0]]=[0:9];
%     copy = COPY(s); copy[0].a[[0]] = ["modified"];
%     print(s[0].a);
%
%    List_Type:
%     s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%     s[0].a[[0]]=[0:9];
%     l = [{ array_copy(s), 1., [1:10] }, {"abs"}];
%     copy = COPY(l); copy[0][0][0].a[[0]] = ["modified"];
%     print(l[0][0][0].a);
%
%    Struct_Type:
%     s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%     s[0].a[[0]]=[0:9]; S = struct{ f=s };     
%     C = struct_copy(S); C.f[0].a[[0]] = ["modified"];
%     print(S.f[0].a);
%
%\seealso{struct_copy, array_copy, list_copy, assoc_copy}
%!%-
{
  variable copyme;
  switch(_NARGS)
  { case 1: copyme = (); }
  { help(_function_name()); return; }

  variable type = typeof(copyme);
  if( type  == Struct_Type )
    return struct_copy(copyme);
  else if( type == Array_Type )
    return array_copy(copyme);
  else if( type == List_Type )
    return array_copy(copyme);
  else if( type == Assoc_Type )
    return assoc_copy(copyme);
  else{
    vmessage("WARNING: <%s>: Unsupported Data_Type=%S, retruning @copyme",
	     _function_name,type);
    return @copyme;
  }
}
%}}}

define struct_copy() %{{{
%!%+
%\function{struct_copy}
%\synopsis{makes a copy of a struct with all its fields}
%\usage{Struct_Type copy = struct_copy(Struct_Type struct);}
%\description
%    \code{struct_copy} copies a \code{Struct_Type} with all its
%    fields, which can be of any Type! If a field is an Array_Type[]
%    \code{struct_copy} calls \code{array_copy} and if a field is
%    \code{Struct_Type}, \code{struct_copy} calls itself.
%    Further it copies Ref_Type, which allows copying XFIG-Objects.
%\example
%    s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%    s[0].a[[0]]=[0:9]; S = struct{ f=s };     
%    C = struct_copy(S); C.f[0].a[[0]] = ["modified"];
%    print(S.f[0].a);
%\seealso{array_copy, list_copy, COPY, assoc_copy}
%!%-
{
  variable table;
  switch(_NARGS)
  { case 1: table = (); }
  { help(_function_name()); return; }
  
  variable f, fieldnames = get_struct_field_names(table);
  variable field , ftype;
  variable copy = @Struct_Type(fieldnames);
  foreach f (fieldnames){
    field = get_struct_field(table, f);
    ftype = typeof(field);
    if( ftype == Struct_Type )
      set_struct_field(copy, f, struct_copy(field) );
    else if( ftype == Array_Type )
      set_struct_field(copy, f, array_copy(field) );
    else if( ftype == List_Type )
      set_struct_field(copy, f, list_copy(field) );
    else if( ftype == Assoc_Type )
      set_struct_field(copy, f, assoc_copy(field) );
    else if ( (ftype == String_Type) ||  (ftype == Ref_Type) )
      set_struct_field(copy, f, field );	
    else
      set_struct_field(copy, f, @field );
  }
  return copy;
}
%}}}
define array_copy() %{{{
%!%+
%\function{array_copy}
%\synopsis{makes a copy of a nested array}
%\usage{Array_Type copy = array_copy(Array_Type[] array);}
%\description
%    \code{array_copy} copies an \code{Array_Type[]} with all its
%    entries, which can be of any Type! If an entry is a Struct_Type
%    \code{array_copy} calls \code{struct_copy} and if an entrie is
%    an \code{Array_Type[]}, \code{array_copy} calls itself.
%\example
%    s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%    s[0].a[[0]]=[0:9];
%    copy = array_copy(s); copy[0].a[[0]] = ["modified"];
%    print(s[0].a);
%\seealso{struct_copy}
%!%-
{
  variable array;
  switch(_NARGS)
  { case 1: array = (); }
  { help(_function_name()); return; }
  
  variable type = typeof(array);
  ifnot( type == Array_Type ){
    if( type == Struct_Type )
      return struct_copy( array );
    if( type == List_Type )
      return list_copy( array );
    else if( type == Ref_Type || type == String_Type )
      return array;
    else
      return @array;
  }
  
  variable len  = length(array);
  variable dim  = array_shape(array);
  type = _typeof(array);
  variable copy = type[len];
  reshape( copy, dim );
  
  variable i;
  _for i ( 0, len-1, 1 ){
    copy[[i]] = array_copy( array[[i]][0] );
  }
  return copy;
}
%}}}

define list_copy() %{{{
%!%+
%\function{list_copy}
%\synopsis{makes a copy of a nested list}
%\usage{List_Type copy = list_copy(List_Type list);}
%\description
%    \code{list_copy} returns a properly dereferenced copy of an
%    arbitrarily nested \code{List_Type} with all its entries. 
%    Depending on the Data_Type of the entries, \code{list_copy}
%    iteratively calls the according sub-function
%    (\code{struct_copy}, \code{array_copy} or \code{list_copy}).
%    If the Data_Type of one of its entries is not
%    one of privouse mentioned ones, \code{list_copy} returns
%    @(Data_Type) or respectively @(entry).
%\example
%     s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%     s[0].a[[0]]=[0:9];
%     l = [{ array_copy(s), 1., [1:10] }, {"abs"}];
%     copy = COPY(l); copy[0][0][0].a[[0]] = ["modified"];
%     print(l[0][0][0].a);
%\seealso{COPY, struct_copy, array_copy, assoc_copy}
%!%-
{
  variable list;
  switch(_NARGS)
  { case 1: list = (); }
  { help(_function_name()); return; }
  
  variable type = typeof(list);
  ifnot( type == List_Type ){
    if( type == Struct_Type )
      return struct_copy( list );
    else if( type == Array_Type )
      return array_copy( list );
    else if( type == Assoc_Type )
      return assoc_copy( list );
    else if( type == Ref_Type || type == String_Type )
      return list;
    else
      return @list;
  }
  
  variable len  = length(list);
  variable copy = {};
  
  variable i;
  _for i ( 0, len-1, 1 ){
    list_append( copy, list_copy(list[i]) );
  }
  return copy;
}
%}}}

define table_copy() %{{{
%!%+
%\function{table_copy}
%\synopsis{makes a copy of all columns of a table}
%\usage{Struct_Type copy = table_copy(Struct_Type table);}
%\description
%    \code{copy.field = @(table.field);  %} for every \code{field}
%    NOTE: This also works for XFIG-PLOT-OBJECTS
%!%-
{
  variable table;
  switch(_NARGS)
  { case 1: table = (); }
  { help(_function_name()); return; }
  
  vmessage("<%s> is deprecated! Use <struct_copy> instead!",_function_name);
  return struct_copy(table);
}
%}}}

define assoc_copy()
%!%+
%\function{assoc_copy}
%\synopsis{makes a copy of an associated array}
%\usage{Assoc_Type copy = assoc_copy(Assoc_Type list);}
%\description
%    \code{assoc_copy} returns a properly dereferenced copy of an
%    arbitrarily nested \code{Assoc_Type} with all its entries. 
%    Depending on the Data_Type of the entries, \code{assoc_copy}
%    iteratively calls the according sub-function
%    (\code{struct_copy}, \code{array_copy} or \code{list_copy}).
%    If the Data_Type of one of its entries is not
%    one of previously mentioned ones, \code{assoc_copy} returns
%    @(Data_Type) or respectively @(entry).
%\example
%     s = Struct_Type[1]; s[0]=struct{ a=Array_Type[1,2] };
%     s[0].a[[0]]=[0:9];
%     l = [{ array_copy(s), 1., [1:10] }, {"abs"}];
%     copy = COPY(l); copy[0][0][0].a[[0]] = ["modified"];
%     print(l[0][0][0].a);
%\seealso{COPY, struct_copy, array_copy, list_copy}
%!%-
{
    variable copyme;
    switch(_NARGS)
    { case 1: copyme = (); }
    { help(_function_name()); return; }

    variable new=Assoc_Type[];
    
    variable s=assoc_get_values(copyme);
    variable key;
    foreach key ( s ) {
        new[key]=COPY(s[key]);
    }
    return new;
}



