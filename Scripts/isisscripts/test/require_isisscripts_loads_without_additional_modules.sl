variable err = 0;
variable e;
try(e)
{
   variable lp = get_isis_load_path();
   set_isis_load_path("");
   require("./share/isisscripts.sl");
   set_isis_load_path(lp);
}
catch AnyError:
{
  vmessage(`"%s" exception:
%s
%s:%d`, e.descr, e.message, e.file, e.line);
  err=1;
}

exit(err);
