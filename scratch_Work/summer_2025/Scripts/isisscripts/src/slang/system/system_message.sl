define message_system()
%!%+
%\function{message_system}
%\usage{Integer_Type message_system(String_Type cmd)}
%\description
%    \code{message(cmd);}\n
%    \code{system(cmd);}
%!%-
{
  variable cmd;
  switch(_NARGS)
  { case 1: cmd = (); }
  { help(_function_name()); return; }

  message(cmd);
  return system(cmd);
}
