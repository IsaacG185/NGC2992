define find_directories()
{
  variable path = ".";
  switch(_NARGS)
  { case 0: path = "."; }
  { case 1: path = (); }
  { return; }

  variable f, dirs = String_Type[0];
  foreach f (glob(path+"/*"))
    if(stat_is("dir", stat_file(f).st_mode))
      dirs = [dirs, f, find_directories(f)];
  return dirs;
}
