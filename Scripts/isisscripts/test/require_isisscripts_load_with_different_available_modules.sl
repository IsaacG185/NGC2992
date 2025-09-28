variable file = "./share/isisscripts.sl";

variable FP = fopen(file,"r");

variable buf,mat,si,s;

variable modules = String_Type[0];

while (-1 != fgets (&buf, FP))
{
   mat = string_matches(buf,"try[ ]*{[ ]*\(require.*\)}"R);
   if (length(mat) > 1)
     {
	si = strchop(mat[1],';',0);
	foreach s(si)
	  {
	     mat = string_matches(s,".*require(.*\"\(.*\)\".*)"R);
	     if (length(mat) > 1)
	       {
		  if ( wherefirst( modules == mat[1]) == NULL )	       
		    modules = [modules, mat[1]];
	       }
	     
	  }
	
     }
   
}

message("Testing different Module combinations ... ");

variable m;
variable ilp = get_isis_load_path();
variable err = 0;
variable e;
variable m_available;

foreach m(modules) {
  set_isis_load_path(ilp);
  m_available = 1;
  try{require(m,m);} catch AnyError: {m_available = 0;};
  if (m_available) {
    use_namespace(m);
    message(m);
    set_isis_load_path("");
    try(e) {
      require(file);
    }
    catch AnyError: {
      vmessage("if only module %s available:\n\"%s\" exception:\n%s\n%s:%d",
	       m, e.descr, e.message, e.file, e.line);
      err=1;
    }
    
    if (err!=0)
      exit(err);
  }
}

message("... done!");

exit(err);

