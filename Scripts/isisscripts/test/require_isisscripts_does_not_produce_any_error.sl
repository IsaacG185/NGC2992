variable err = 0;
variable e;
try(e)
{
  require("./share/isisscripts.sl");
}
catch AnyError:
{
  vmessage(`"%s" exception:
%s
%s:%d`, e.descr, e.message, e.file, e.line);
  err=1;
}

exit(err);
