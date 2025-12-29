%%%%%%%%%%%%%%%%%%%%%%
define show_slang_code()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{show_slang_code}
%\usage{show_slang_code(String_Type function);}
%\description
%    The function \code{show_slang_code} reads all \code{.sl} files
%    in the directories contained in the S-Lang load path,
%    and *tries* to find the definition of \code{function}
%    by parsing the code for {}-brackets and comments.
%    In its current version, \code{show_slang_code} gets confused, e.g.,
%    from {}-brackets and % characters in strings.
%!%-
{
  variable function;
  switch(_NARGS)
  { case 1: function = (); }
  { help(_function_name()); return; }

  variable show_slang_code_code = "";  % could be made a private global variable
  variable show_slang_code_len = 0;    % could be made a private global variable

  if(show_slang_code_code=="")
  {
    variable dir, slfile;
    foreach dir (strtok(get_slang_load_path(), ":"))
      foreach slfile (glob(dir+"/*.sl"))
      { % message(slfile);
	variable F = fopen(slfile, "r");
	if (typeof(F) == File_Type) {
          show_slang_code_code += strjoin(fgetslines(F), "");
          ()=fclose(F);
	}
      }
    show_slang_code_len = strlen(show_slang_code_code);
  }
  variable code = show_slang_code_code;
  variable len =  show_slang_code_len;

  variable startpos = 0;
  forever
  {
    startpos = string_match(code, "define +"+function+" *\(", startpos+1);
    if(startpos==0)  break;
    variable pos=startpos;
    variable comment = 0;
    while(pos<len)
    { if(code[pos]=='%')  comment = 1;
      if(code[pos]=='\n') comment = 0;
      if(code[pos]=='{' and not comment)  break;
      pos++;
    }
    variable brackets = 1;
    pos++;
    while(brackets>0 && pos<len)
    { if(code[pos]=='%')  comment = 1;
      if(code[pos]=='\n') comment = 0;
      if(code[pos]=='{' && not comment)  brackets++;
      if(code[pos]=='}' && not comment)  brackets--;
      pos++;
    }
    if(pos<len)
      message("\n"+code[[startpos-1:pos-1]]+"\n");
  }
}
