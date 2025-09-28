% pack format from input object type
private define _pack_obj_fmt(obj) {
  switch (typeof(obj))
    { case Int16_Type:  return "j"; } % 16bit == [Short_Type]
    { case Int32_Type:  return "k"; } % 32bit == [Integer_Type, Int_Type]
    { case Int64_Type:  return "q"; } % 64bit == [Long_Type]
    { case UInt16_Type: return "J"; } % 16bit
    { case UInt32_Type: return "K"; } % 32bit == [UInteger_Type, UInt_Type]
    { case UInt64_Type: return "Q"; } % 64bit == [ULong_Type, ULLong_Type]
    { case Char_Type:   return "c"; }
    { case UChar_Type:  return "C"; }
    { case Float_Type:  return "f"; } % 32bit == [Float32_Type]
    { case Double_Type: return "d"; } % 64bit == [Float64_Type]
    { case String_Type: return sprintf("s%d", strlen(obj)); }
  return NULL;
}
% object type from input pack format
private define _unpack_obj_fmt(fmt) {
  switch (fmt)
    { case "j": return Int16_Type; }
    { case "k": return Int32_Type; }
    { case "q": return Int64_Type; }
    { case "J": return UInt16_Type; }
    { case "K": return UInt32_Type; }
    { case "Q": return UInt64_Type; }
    { case "c": return Char_Type; }
    { case "C": return UChar_Type; }
    { case "f": return Float_Type; }
    { case "d": return Double_Type; }
    { case "s": return String_Type; }
  return NULL;
}

define pack_obj();
%%%%%%%%%%%%%%%%%%%%
define pack_obj()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pack_obj}
%\synopsis{converts an SLang object into a binary string}
%\usage{BString_Type[] pack_obj(Any_Type obj);}
%\description
%    Uses the `pack' function to convert a single SLang object into
%    an array of binary strings (BString_Type). The format specifier
%    is included as first character of the strings.
%    
%    If the object is a single number or string then the returned
%    array consists of a single item only. In case the given object
%    is an array or a structure, the returned array starts with the
%    type of the input array and its length or the field structure
%    definition, respectively. The remaining items are the input
%    array items or the structure items. For structures, the
%    contained objects are converted recursively.
%
%    The following data-types are supported:
%    Int16_Type, Int32_Type, Int64_Type, Float_Type, Double_Type,
%    Char_Type, String_Type, Array_Type, Struct_Type
%    and its aliases.
%\example
%#v+
%#p+
%    s = pack_obj(PI);        % s[0] = "d\030-DT\373!\011@"
%
%    s = pack_obj([1:3] + 4); % s[0] = "ak\003\000\000\000"
%                             % s[1] = "\005\000\000\000"
%                             % s[2] = "\006\000\000\000"
%                             % s[3] = "\007\000\000\000"
%
%    variable obj = struct {
%      number = 598105,
%      float  = 341.12e8,
%      more   = struct {
%        msg    = "hello"
%      }
%    };
%    s = pack_obj(obj);
%    print(s);
%#p-
%#v-
%\seealso{unpack_obj, pack, unpack}
%!%-
{
  variable obj;
  switch (_NARGS)
    { case 1: obj = (); }
    { help(_function_name); return; }

  % check input type
  variable type = typeof(obj), fmt, s, len, i;
  switch (type)
  % array type
  { case Array_Type:
    % item type and its format
    type = _typeof(obj);
    fmt = _pack_obj_fmt(obj[0]);
    if (fmt == NULL) {
      vmessage("error(%s): array of %s not supported", _function_name, string(type));
      return;
    }
    % array length
    len = length(obj);
    % init string array
    s = BString_Type[len+1];
    % array specification in first item: array indicator 'a', item format, length
    s[0] = pack("ccK", 'a', fmt[0], len);
    % pack all items
    _for i (1, len, 1) {
      s[i] = type == String_Type ? obj[i-1] : pack(fmt, obj[i-1]);
    }
  }
  % struct type
  { case Struct_Type:
    % fieldnames and number of fields
    variable fields = get_struct_field_names(obj);
    len = length(fields);
    % init string array with field names
    s = BString_Type[len+1];
    % struct field specification in first item: struct indicator 't', (empty), number of fields
    s[0] = pack("cK", 't', len);
    % insert field names
    s[[1:]] = fields;
    % recursively add field values
    _for i (0, len-1, 1) {
      s = [s, pack_obj(get_struct_field(obj, fields[i]))];
    }
  }
  % all other types, i.e., basic items
  {
    fmt = _pack_obj_fmt(obj);
    s = [pack(sprintf("c%s", fmt), fmt[0], obj)];
  }
  
  return s;
}


define unpack_obj();
%%%%%%%%%%%%%%%%%%%%
define unpack_obj()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{unpack_obj}
%\synopsis{converts a binary string back into an SLang object}
%\usage{Any_Type pack_obj(BString_Type obj);}
%\description
%    An input array of binary strings (BString_Type), which has
%    been created by the `pack_obj' function, is converted back
%    into an SLang object using the `unpack' function.
%
%    See the documentation of `pack_obj` for more details.
%\example
%#v+
%#p+
%    s = pack_obj(PI);        % s[0] = "d\\030-DT\\373!\\011@"
%
%    a = unpack_obj(s);       % a = 3.141592653589793;
%#p-
%#v-
%\seealso{pack_obj, unpack, pack}
%!%-
{
  variable s; % input array of strings
  variable q = 0;  % current item index of s
  variable p = &q; % and its pointer
  % process arguments
  switch (_NARGS)
    { case 1: s = (); }
    { case 2: (s,p) = (); }
    { help(_function_name); return; }

  % sanity checks
  if (typeof(s) != Array_Type) { s  = [s]; }
  if (_typeof(s) != BString_Type) {
    vmessage("error(%s): input has to be of BString_Type", _function_name);
    return;
  }
  variable obj, fmt, len;

  % extract format specification (first character)
  fmt = substr(s[@p], 1, 1);

  switch (fmt)
  % array
  { case "a":
    % format and length of the array
    (,fmt,len) = unpack("ccK", s[@p]);
    (@p)++;
    fmt = sprintf("%c", fmt);
    variable form = _unpack_obj_fmt(fmt);
    variable i;
    % init array
    obj = form[len];
    % fill array
    _for i (0, len-1, 1) {
      obj[i] = unpack_obj(fmt + s[@p+i]);
    }
    (@p) += len;
  }
  % struct
  { case "t":
    % get struct field names
    (,len) = unpack("cK", s[@p]);
    (@p)++;
    variable fields = s[[@p:@p+len-1]];
    (@p) += len;
    % init struct
    obj = @Struct_Type(fields);
    % fill struct
    _for i (0, length(fields)-1, 1) {
      set_struct_field(obj, fields[i], unpack_obj(s, p));
    }
    return obj;
  }
  % string
  { case "s":
    obj = substr(s[@p], 2, -1);
    (@p)++;
  }
  % all the other formats, i.e., basic formats
  {
    (,obj) = unpack(sprintf("c%s", fmt), s[@p]);
    (@p)++;
  }

  return obj;
}
