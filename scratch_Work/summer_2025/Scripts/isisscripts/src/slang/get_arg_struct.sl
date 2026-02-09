define get_arg_struct() %{{{
%!%+
%\function{get_arg_struct}
%\synopsis{obtains the arguments/options the current isis instances was called with.}
%\usage{Struct_Type = get_arg_struct( );}
%\altusage{Struct_Type = get_arg_struct( String_Type[] name, type);}
%\qualifiers{
%\qualifier{delim}{[="="] Delimeter between argument name and value (e.g., also, "=.,").}
%\qualifier{prefix}{[="--"] Argument prefix. Arguments missing this prefix are ignored.}
%}
%\description
%   This function returns a Struct_Type with fields corresponding to
%   the names of those arguments/options the current isis instance
%   was called with, which have the given 'prefix'. Thereby the 'name'
%   is defined as the string enclosed by the 'prefix' and the 'delimeter'.
%
%   Expected SYNTAX: <prefix>"argname"<delimeter>"value"
%
%   It is possible to give several 'delimeter' as a string-chain (e.g.,
%   "=,.-"). If an argument/option contains several delimeters, only the
%   string between the 1st and 2nd delimeter is taken as value for the
%   corresponding name.
%
%   This function can be given an string array 'name' and 'type', assigning
%   a Data_Type to the argument 'name'. Thereby 'type' can be:
%
%         "d" : Integer_Type
%         "f" : Double_Type
%
%   Otherwise, if used without arguments ('name' & 'type'), the
%   values are returned as String_Type.
%
%   If an argument has no value given, i.e. does not contain a delimeter
%   the corresponding field of the returned structure is equal NULL.
%\example
%   /> isis -g --arg --arg1=1e-3 --arg2=1.01 --arg3=abcd --arg4=1=bla
%
%   isis> print( get_arg_struct );
%   {arg=NULL,
%    arg1="1e-3",
%    arg2="1.01",
%    arg3="abcd",
%    arg4="1"}
%
%   isis> print( get_arg_struct("arg1","f") );
%   {arg=NULL,
%    arg1=0.001,
%    arg2="1.01",
%    arg3="abcd",
%    arg4="1"}
%
%   isis> print( get_arg_struct(["arg1","arg2","arg4"],["f","f","d"]) );
%   {arg=NULL,
%    arg1=0.001,
%    arg2=1.01,
%    arg3="abcd",
%    arg4=1}
%
%\seealso{atof, atoi, strreplace, strtok, set_struct_field, array_map, is_substr}
%!%-
{
  variable delim  = qualifier("delim","=");
  variable prefix = qualifier("prefix","--");

  variable name = NULL, type;
  switch(_NARGS)
  { case 2 : (name,type)=(); name = [name]; type=[type]; }


  % Get arguments with prefix 'prefix'
  variable opt = __argv[ where( is_substr( __argv, prefix ) == 1) ];
  % remove prefix
  opt = array_map( String_Type, &strreplace, opt, prefix, "" );
  % split these arguments at 'delimeter'
  opt = array_map( Array_Type, &strtok, opt, delim );

  variable nopt = length(opt);
  if( nopt == 0 )
  { vmessage("WARNING: <%s>: No argument(s) with prefix=%s found!",  _function_name, prefix ); }

  variable args = @Struct_Type(String_Type[0]);  % Ideally, one would first collect all fields and then construct the struct...
  variable i;
  _for i (0, nopt-1, 1 ){
    variable field = opt[i][0];
    args = struct_combine(args, field);

    variable val = NULL;
    if( length(opt[i]) > 1 ) {
      val = opt[i][1];

      variable j = wherefirst(name == field);
      if( j != NULL ){
	if( type[j]=="d" ){
	  val = atoi(val);
	}
	else if( type[j]=="f" ){
	  val = atof(val);
	}
      }
    }
    set_struct_field(args, field, val);
  }
  return args;
}
%}}}
