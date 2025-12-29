%%%%%%%%%%%%%%%%%%%%%%%%
define keyinput ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{keyinput}
%\synopsis{reads input from the keyboard}
%\usage{String_Type = keyinput([String_Type message]);}
%\qualifiers{
%    \qualifier{silent}{characters are not echoed, e.g. useful for password input}
%    \qualifier{time}{read timout after given seconds. Returns an empty string}
%    \qualifier{nchr}{returns automatically after given number
%              of chars have been read}
%    \qualifier{prompt}{output the given string before reading}
%    \qualifier{default}{initial text to be read}
%}
%\description
%    Prompts the user to input a line, which is ended
%    with return. If a limited number of chars is given
%    using the `nchr' qualifier, the line is automatically
%    ended after reaching this number without pressing return. 
%    It is also possbile to limit the time for an input with the 
%    `time' qualifier and to disable echoing the input using 
%    the `silent' qualifier. The latter is useful, e.g., for password 
%    inputs or for single key events.
%    If `nchr==1', the returned keycode is
%    checked against special keys such as the arrow keys.
%    If one of these is detected, the returned string contains
%    the name if the pressed key.
%!%-
{
 if (_NARGS == 1) { variable ms = __pop_args(1); message(typecast(ms[0].value, String_Type)); }

 variable pp, inpt, cmd;
 % create command to be executed
 cmd="/bin/bash -c 'read -r"; % -r option disables \ as escape parameter
 if (qualifier_exists("silent")) cmd=cmd+" -s";
 if (qualifier_exists("time")) cmd=sprintf("%s -t %.1f",cmd,qualifier("time"));
 if (qualifier_exists("nchr")) cmd=sprintf("%s -n %d",cmd,qualifier("nchr"));
 if (qualifier_exists("prompt")) cmd=sprintf("%s -p \"%s\"",cmd,qualifier("prompt"));
 if (qualifier_exists("default")) cmd=sprintf("%s -e -i \"%s\"",cmd,qualifier("default"));
 cmd=cmd+" line; echo $line'";
 % execute command and store output in variable
 pp = popen(cmd,"r");
 inpt = fgetslines(pp);
 () = pclose(pp);
 % if nchr = 1 test on special keys
 if (qualifier("nchr", 0) == 1)
 {
   variable a;
   if (inpt[0] == "\x1B\n") % if a special key was hit, it consists of at least 3 bytes -> read missing 2 bytes
   {
     pp = popen("/bin/bash -c 'read -r -s -n 1 line; echo $line'", "r");
     a = fgetslines(pp);
     () = pclose(pp);
     if (a[0] == "[\n") % ARROWS, HOME, etc.
     {
       pp = popen("/bin/bash -c 'read -r -s -n 1 line; echo $line'", "r");
       a = fgetslines(pp);
       () = pclose(pp);
       if (a[0] == "1\n") % F5-F8 (5 bytes)
       {
         pp = popen("/bin/bash -c 'read -r -s -n 2 line; echo $line'", "r");
         a = fgetslines(pp);
         () = pclose(pp);
       }
     }
     else if (a[0] == "O\n") % F1-F4
     {
       pp = popen("/bin/bash -c 'read -r -s -n 1 line; echo $line'", "r");
       a = fgetslines(pp);
       () = pclose(pp);
     }
     if (a[0] == "2\n") % INS, F8-F12
     {
       pp = popen("/bin/bash -c 'read -r -s -n 1 line; echo $line'", "r");
       a = substr(a[0],1,strlen(a[0])-1) + fgetslines(pp);
       () = pclose(pp);
     }
     a = substr(a[0],1,strlen(a[0])-1);
     % transform to special key
     switch (a)
       { case "A": a = "UP_ARROW"; }
       { case "B": a = "DOWN_ARROW"; }
       { case "D": a = "LEFT_ARROW"; }
       { case "C": a = "RIGHT_ARROW"; }
       { case "5": a = "PAGE_UP"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); } % (4 bytes)
       { case "6": a = "PAGE_DOWN"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); }
       { case "H": a = "HOME"; }
       { case "F": a = "END"; }
       { case "3": a = "DEL"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); }
       { case "2~": a = "INS"; }
       { case "P": a = "F1"; }
       { case "Q": a = "F2"; }
       { case "R": a = "F3"; }
       { case "S": a = "F4"; }
       { case "5~": a = "F5"; }
       { case "7~": a = "F6"; }
       { case "8~": a = "F7"; }
       { case "9~": a = "F8"; }
       { case "20": a = "F9"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); }
       { case "21": a = "F10"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); }
       { case "23": a = "F11"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); }
       { case "24": a = "F12"; pp = popen("/bin/bash -c 'read -r -s -n 1 line;'", "r"); ()=pclose(pp); }
       { a = sprintf("UNKNOWN_%s", a); }
     inpt = [a + " "];
   }
 }
 % return this variable without line break
 return substr(inpt[0],1,strlen(inpt[0])-1);
}
