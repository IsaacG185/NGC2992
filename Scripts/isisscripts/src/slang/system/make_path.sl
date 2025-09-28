define make_path ()
%!%+
%\function{make_path}
%\synopsis{Recursively create multiple directories}
%\usage{make_path (dirs)}
%\description
%   This function creates multiple directory paths. It is
%   similar to mkdir_rec, but does not internally change
%   directories, allows multiple path specifications, and
%   individual modes.
%
%   The function throws an IO error if a path component exists
%   and is not a directory.
%
%\qualifiers{
%\qualifier{mode}{mode for the paths to be generated. If mode is an 
%                 array, it contains the mode for each individual path
%                 specified. Default: 0777}
%\qualifier{separator}{path separator. Default is /, so you will
%                  probably not have to use it...}
%}
%\example
% make_path(["./test1/test2","./test1/../test3"];mode=[0777,0700]);
%\seealso{mkdir,mkdir_rec}
%!%-
{
    variable pp=();
    variable mode=qualifier("mode",0777);

    % special case of one string argument
    if (typeof(pp)==String_Type) {
	pp=[pp];
    }

    % sanity check on mode
    if (length(mode)>1) {
	if (length(mode) != length(pp) ) {
	   throw UsageError,sprintf("%s: Must either give one mode or one per path.\n",_function_name());
	}
    } else {
        mode=mode+Integer_Type[length(pp)];
    }

    variable sep=qualifier("separator","/");

    variable i,j;
    _for i(0,length(pp)-1,1) {
	variable comp=strsplit(pp[i],sep);
	variable pa="";
	_for j(0,length(comp)-1,1) {
	    pa+=comp[j];

            % generate the directory. Catch
            % failures except for those where
            % a directory already exists

	    if (pa != "") {
		variable ret=mkdir(pa,mode[i]);
		if (ret==-1) {
		    if (errno!=EEXIST) {
			throw IOError,sprintf("mkdir %s failed: %s\n",pa,errno_string(errno));
		    } else {
			% give an error if the path component exists and
			% is NOT a directory
			variable st=stat_file(pa);
			if (stat_is("dir",st.st_mode)==0) {
			    throw IOError,sprintf("mkdir %s failed: path component exists and is not a directory",pa);
			}
		    }
		}
	    }
            % don't add the separator at the start of the j-loop:
            % this will cause the stat_file call above to fail
            pa+=sep; 
	}
    }
}
