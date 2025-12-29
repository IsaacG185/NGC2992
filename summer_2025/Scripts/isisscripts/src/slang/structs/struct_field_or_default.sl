define struct_field_or_default(s,tag,def) {
%!%+
%\function{struct_field_or_default}
%\synopsis{return value of a structure field or a default value}
%\usage{value=struct_field_or_default(Struct_Type s, String_Type tag, default);}
%\description
%    return s.tag if it exists, otherwise default
%!%-
return struct_field_exists(s,tag) ? get_struct_field(s,tag) : def;
}
