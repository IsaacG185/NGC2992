define logging()
%!%+
%\function{logging}
%
%\synopsis{write a log file}
%\usage{logging ("filename.log", "Log message");}
%
%\description
%    This function writes output to a log file (which will be created if it does
%    not exist. It can also handle input in the sprintf format (see example).
%    By default all input to logging is also printed to stdout.
%    Repeated calls to the function add the new message at the end of the file. It
%    is therefore recommended to specify the date and time in the name of the log
%    file.
%    
%\qualifiers{
%\qualifier{v}{verbosity: [default: 1] print output also to stdout, set this
%                              qualifier to 0 for no output to stdout}
%}
%
%\example
%    isis> variable cutime = strftime("%Y-%m-%d_%H:%M:%S");
%    isis> variable l = cutime+".log";
%    isis> logging(l, "* Found %.u observations for %s", length(src_info), src);
%    isis> logging(l, "***Error in function %s", _function_name() );
%
%\seealso{strftime, _function_name()}
%!%-
{

    if (_NARGS < 2)
    { 
	help(_function_name()); return; 
    }


    variable filename, msg;
    variable v = qualifier("v", 1);
    
    variable args;
    args=__pop_args(_NARGS);
    
    filename = __push_args(args[0]);
    msg = __push_args(args[1]);
 
    variable args2 = array_remove(args,0);
    args2 = array_remove(args2,0);

    variable a = sprintf(msg, __push_args(args2) );

    if (v == 1)
    {
	message(a);
    }

    variable F = fopen(filename, "a+");
    () = fwrite(a,F);
    () = fwrite ("\n",F);
    () = fclose(F);
}
