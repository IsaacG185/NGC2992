%%%%%%%%%%%%%%%%%%%%%%%%%%%
define path_realpath (path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{path_realpath}
%\synopsis{Get full path of specified path}
%\usage{String_Type realpath = path_realpath(String_Type path);}
%\description
%  Turn the given path into an asbolute path (replacing '..' and '.').
%\seealso{path_concat,path_is_absolut}
%!%-
{
  variable cwd = getcwd();
  variable realpath;

  if (path_is_absolute(path))
    realpath = path;
  else
    realpath = path_concat(cwd, path);

  % we utilize that path_dirname handles relative instructions at top level
  variable file = path_basename(realpath); % if it is a file we need this
  variable d = path_dirname(realpath);
  variable b = path_basename(d);
  variable trace = {file};

  while ("" != b) {
    list_append(trace, b);
    d = path_dirname(d);
    b = path_basename(d);
  }

  list_reverse(trace);
  variable t;
  realpath = d; % this is root
  foreach t (trace)
    realpath = path_concat(realpath, t);

  return realpath;
}
