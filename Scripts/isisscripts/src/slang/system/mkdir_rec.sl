define mkdir_rec( )
%!%+
%\function{mkdir_rec}
%\synopsis{Create a new directory (recursively)}
%\usage{Int_Type mkdir_rec (String_Type dir [,Int_Type mode])}
%\description
%   Does the same as 'mkdir' with the exception that this
%   function creates also subdirectories.
%   See the help of 'mkdir' for a detailed description.
%\seealso{mkdir}
%!%-
{
  variable args = __pop_list(_NARGS);

  % Remember the current working directory
  variable cwd = getcwd;

  % Check if path is absolut or relative
  variable abrel = args[0][0] == '/' ? "/" : "";

  % Split the path into individual directories
  variable dirs = strtok(args[0],"/");
  dirs[0] = abrel + dirs[0];
  
  % Try to change into each (sub-)dir, in case of failure create that dir
  variable i, stat = 0;
  _for i ( 0, length(dirs)-1, 1 ){
    if( chdir( dirs[i] ) == -1 and stat == 0 ){
      args[0] = dirs[i];
      stat = mkdir( __push_list(args) );
    }
  }
  % change back to the original working directory
  () = chdir(cwd);
  
  return stat;
}
