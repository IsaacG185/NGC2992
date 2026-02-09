%%%%%%%%%%%%%%%
define fread_struct()
%%%%%%%%%%%%%%%
%!%+
%\function{fread_struct}
%\synopsis{Read binary data from a file into a pre-defined structure}
%\usage{fread_struct(Struct_Type s, File_Type fp);}
%\qualifiers{
%    \qualifier{char_to_string}{convert fields of an array of chars (Char_Type[])
%                     with length greater one into strings}
%    \qualifier{chatty}{be verbose}
%}
%\description
%    This function uses `fread' to reads binary data from a file into
%    the fields of a structure. All fields have to have a defined
%    data type! That is at least each field value has to be set to a
%    certain `DataType_Type'. In case field values are arrays, the
%    corresponding amount of objects of the array's data type are read
%    from the file. The fields have to be defined in the same order as
%    their corresponding objects should be read from the file. Note
%    that the function does not return anything, but the fields of the
%    given structure are updated instead! Finally, make sure to use
%    the correct number of bits to be read for each field. In doubt
%    always use, e.g., Int32_Type instead of Integer_Type as the
%    latter might depend on how S-lang was compiled.
%\example
%    % define the structure to be read
%    variable s = struct {
%      count = Int16_Type, % first, read one 16-bit integer
%      list = Float32_Type[10], % secondly, read 10x 32-bit floats
%      msg = Char_Type[64] % finally, read 64x characters
%    };
%    % read the file
%    variable fp = fopen("mybinaryformat.file", "r");  
%    fread_struct(s, fp; char_to_string);
%    ()=fclose(fp);
%    % print the message, which will be a string due to the
%    % char_to_string-qualifier
%    message(s.msg);  
%\seealso{fread}
%!%-
{
  variable s, fp;
  switch (_NARGS)
    { case 2: (s, fp) = (); }
    { help(_function_name); return; }

  % define variables and loop over all fields of the structure
  variable fieldnames = get_struct_field_names(s);
  variable fieldname;
  variable chatty = qualifier_exists("chatty");
  foreach fieldname (fieldnames) {
    % determine data type and size of the field
    variable field = get_struct_field(s, fieldname);
    variable type = typeof(field) == DataType_Type ? field : typeof(field);
    variable size = 1;
    if (type == Array_Type) {
      type = _typeof(field);
      size = length(field);
    }
    % print infos
    if (chatty) {
      ()=fprintf(stdout, "reading %d objects of %s into '%s'... ", size, string(type), fieldname);
      ()=fflush(stdout);
    }
    % read the data!
    variable num = fread(&field, type, size, fp);
    % print infos
    if (chatty) {
      if (num == -1) {
	()=fprintf(stdout, "failed");
	()=fflush(stdout);
	throw ReadError, "fread failed";
      } else {
        ()=fprintf(stdout, "got %d", num);
      }
    }
    % convert character array into string
    if (type == Char_Type && size > 1 && qualifier_exists("char_to_string")) {
      if (chatty) { ()=fprintf(stdout, " -> to string"); }
      field =  pack(sprintf("c%d", size), field);
    }
    if (chatty) { ()=fprintf(stdout, "\n"); ()=fflush(stdout); }
    % set the field to the read data
    set_struct_field(s, fieldname, field);
  }
}
