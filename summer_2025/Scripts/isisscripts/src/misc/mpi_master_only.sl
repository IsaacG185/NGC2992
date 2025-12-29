#ifexists rcl_mpi_init
%%%%%%%%%%%%%%%%%%%%%%%%%
define mpi_master_only ()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{mpi_master_only}
%\synopsis{Use function with on one host only in an MPI job}
%\usage{mpi_master_only (Reference_Type function, arg1, arg2, ...)}
%\qualifiers{
%\qualifier{verbose}{show name of host which acts as MPI master}
%\qualifier{veryverbose}{show name of host which acts as MPI master, PID and parent PID (overwrites verbose)}
%}
%\description
%	Sometimes, for example by saving files, it is required that a function is only called once
%	in an MPI job. mpi_master_only does this for a function with an arbitrary number of arguments.
%	The function has to be passed by reference, the arguments simply as arguments.
%\example
%	mpi_master_only(&sprintf, "Pi is approximately %f and Eulers number is %f", PI, E);
%	output:
%		Pi is approximately 3.141593 and Eulers number is 2.718281828459045
%	But this only once
%!%-
{
	variable args = __pop_list(_NARGS);
	variable todo = args[0];
	list_delete (args, 0);
	rcl_mpi_init;
	if (rcl_mpi_master)
	{
		variable hostname = strchop(fgetslines(popen("hostname", "r"))[0], '\n', 0)[0];
		if (qualifier_exists("veryverbose"))
			vmessage("*** mpi_master_only on: "+hostname+" PID "+sprintf("%d", getpid)+" parent PID "+sprintf("%d", getppid));
		else if (qualifier_exists("verbose"))
			vmessage("*** mpi_master_only on: "+hostname);
		(@todo)(__push_list(args));
	}
	rcl_mpi_finalize;
}
#endif
