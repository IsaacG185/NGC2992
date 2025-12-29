
variable status = 0;

#if$BUILDCHECK
require("fswalk");

variable Touched = Assoc_Type[UChar_Type];

define file_callback(name, st)
{
  if (assoc_key_exists(Touched, name))
    return 1;

  Touched[path_dirname(name)] = 0;
  if (".check" == path_basename(name))
    Touched[path_dirname(name)] = 1;
  return 1;
}

fswalk_new(NULL, &file_callback).walk("src");

variable status = 0;
variable k,v;
foreach k,v (Touched)
{
  ifnot (v)
  {
    vmessage("Unchecked: %s", k);
    status = 1;
  }
}
#endif

exit(status);

