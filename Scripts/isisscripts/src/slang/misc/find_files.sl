define find_files(path)
{
  variable files = String_Type[0];
  foreach (glob(path+"/*"))
  { variable f = ();
    variable stmode = stat_file(f).st_mode;
    if(stat_is("reg", stmode))  files = [files, f];
    if(stat_is("dir", stmode) && qualifier_exists("recursive"))  files = [files, find_files(f; recursive)];
  }
  return files;
}
