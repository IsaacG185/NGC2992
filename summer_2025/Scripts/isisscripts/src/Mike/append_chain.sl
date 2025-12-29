private define compare_header (t1, t2)
{
	variable ii;
	variable field_names1=get_struct_field_names(t1);
	variable field_names2=get_struct_field_names(t2);
	if (length(field_names1) != length(field_names2))
	{
		return -1;
	}
	_for ii(0, length(field_names1)-1, 1)
	{
		if (field_names1[ii] != field_names2[ii])
		{
			return -1;
		} else {
			if (get_struct_field(t1, field_names1[ii]) != get_struct_field(t2, field_names2[ii]) )
			{
				return -1;
			}
		}
	}
	return 0;
}

private define check_chain_headers (t1, t2)
{
	variable field_names1=get_struct_field_names(t1);
	variable field_names2=get_struct_field_names(t2);
	variable ii;
	if (length(field_names1) != length(field_names2))
	{
		return -1;
	}
	_for ii(0, length(field_names1)-1, 1)
	{
		if (field_names1[ii] != field_names2[ii])
		{
			return -1;
		}
	}

	_for ii(0, length(field_names1)-1, 1)
	{
		if ( (field_names1[ii] != "NAXIS2") && (field_names1[ii] != "NSTEPS") )
		{
			if ( get_struct_field (t1, field_names1[ii]) != get_struct_field(t2, field_names1[ii]) )
				return -1;
		}
	}
	return 0;
}

private define check_parameters_headers (t1, t2)
{
	variable field_names1=get_struct_field_names(t1);
	variable field_names2=get_struct_field_names(t2);
	variable ii;
	if (length(field_names1) != length(field_names2))
	{
		return -1;
	}
	_for ii(0, length(field_names1)-1, 1)
	{
		if (field_names1[ii] != field_names2[ii])
		{
			return -1;
		}
	}

	_for ii(0, length(field_names1)-1, 1)
	{
		if ( field_names1[ii] != "NAXIS2")
		{
			if ( get_struct_field (t1, field_names1[ii]) != get_struct_field(t2, field_names1[ii]) )
				return -1;
		}
	}
	return 0;
}

%%%%%%%%%%%%%%%%%%%%%%%%%
define append_chain  ()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{append_chain}
%\synopsis{Append a chain fits file to another chain fits file}
%\usage{append_chain(String_Type chainfile1, String_Type chainfile2, String_Type chainoutfile)}
%\qualifiers{
%\qualifier{verbose}{show progress}
%}
%\description
%       This function takes two chains stored in chainfile1 and chainfile2 written with the write_chain function
%       (or by emcee itself) and appends the second one to the first one, again writing a fits file.
%       This function does not make use of read_chain or write_chain, it's consisting only of
%       fits routines. The function itself does perform some sanity and safety checks (same data, same fit_fun)
%       but you have to make sure that you use the correct chains in the correct order.
%\seealso{combine_chain, read_chain, write_chain, emcee}
%!%-
{
	variable name1, name2, fname;
	switch(_NARGS)
	{ case 3: (name1, name2, fname) = (); }
	{ help(_function_name()); return; }
	if ( qualifier_exists("verbose") )
		vmessage("Analysing ...");
%TESTS
	%Starting for the first extension, PARAMETERS, which should basically be the same
	variable ii, jj;
	
	try {
		variable hp1 = fits_read_header(name1+"[1]");
	} catch AnyError: {
		sprintf("Error opening "+name1, stderr);
		throw OpenError;
	}
	try{
		variable hp2 = fits_read_header(name2+"[1]");
	} catch AnyError: {
		sprintf("Error opening "+name2, stderr);
		throw OpenError;
	}
	if ( compare_header(hp1, hp2) != 0 )
	{
		sprintf("*** Error: Header 1 (PARAMETERS) of "+name1+" and "+name2+" are not the same, apparently not the same model or data was used", stderr);
		return -1;
	} 

	%Second extension, MCMCCHAIN
	variable hm1 = fits_read_header(name1+"[2]");
	variable hm2 = fits_read_header(name2+"[2]");
	if (check_chain_headers(hm1, hm2) != 0)
	{
		sprintf("Error: Header 2 (MCMCCHAIN) of "+name1+" and "+name2+" are not the same, chains not from the same MCMC configuration", stderr);
		return -1;
	}
	variable nfree = hm1.NFREEPAR;
	variable nw = hm1.NWALKERS;
	%That's the offset


	%Third extension, CHAINSTATS
	variable hc1 = fits_read_header(name1+"[3]");
	variable hc2 = fits_read_header(name2+"[3]");
	if (check_parameters_headers (hc1, hc2) != 0)
	{
		sprintf("*** Error: Header 3 (CHAINSTATS) of "+name1+" and "+name2+" are not the same", stderr);
	}



%Reading first extensions
	variable sp1 = fits_read_table(name1+"[1]");
	variable sp2 = fits_read_table(name2+"[1]");
	_for ii(0, length(sp1.free_par)-1, 1)
	{
		if (sp1.free_par[ii] != sp2.free_par[ii])
		{
			sprintf("*** Error: Free parameters inconsistent", stderr);
			return -1;
		}
	}
	
	variable ff=fits_open_file(fname, "c");
%Writing first extensions
	if (qualifier_exists("verbose"))
		vmessage("***First Extension");
	variable extname = "PARAMETERS";
	variable colname = ["FREE_PAR"];
	variable nrows = nfree;
	variable ttype = ["J"];
	variable tunit = [" parameter indices"];
	fits_create_binary_table(ff, extname, nrows, colname, ttype, tunit);
	fits_update_key (ff, "PFILE", hp1.PFILE, "");
	fits_update_key (ff, "MODEL", hp1.MODEL, "");
	variable hist_comment =
	["This file was created by merging the results",
	"of two seperate emcee runs using the mcmc routine for isis, written by",
	"Mike Nowak, assuming that the first part was used as the init_chain",
	"qualifier for the second one. A variety of checks for sanity",
	"of the datasets are performed but the user has still to be careful.",
	"This extension contains information about the model",
	"PFILE are the parameter files that started the chain",
	"MODEL is the fit function that was applied to the data",
	"FREE_PAR are the parameter indices of the free parameters"];
	array_map(Void_Type, &fits_write_comment, ff, hist_comment);
	if (qualifier_exists("verbose"))
		vmessage("\tWriting parameters");
	if(_fits_write_col(ff,fits_get_colnum(ff,"FREE_PAR"),1,1,sp1.free_par))
		throw IOError;

%Reading second extensions
	if (qualifier_exists("verbose"))
		vmessage("***SecondExtension");
	extname = "MCMCCHAIN";
	colname = ["FITSTAT","UPDATE"], ttype = ["D","J"],
	tunit =  [" fit statistics"," update indicator"];
	nrows = hm1.NAXIS2 + hm2.NAXIS2;
	variable nsteps = hm1.NSTEPS + hm2.NSTEPS ;
	_for ii(0, nfree-1, 1)
	{
		colname = [colname,"CHAINS"+string(sp1.free_par[ii])];
		ttype = [ttype,"D"];
		tunit = [tunit, " parameter values"];
	}

	fits_create_binary_table(ff, extname, nrows, colname, ttype, tunit);
	
	fits_update_key(ff, "NWALKERS", nw, "");
	fits_update_key(ff, "NFREEPAR", nfree, "");
	fits_update_key(ff, "NSTEPS", nsteps, "");
	fits_update_key(ff, "CDF_SCL_LO", hm1.CDF_SCL_LO, "");
	fits_update_key(ff, "CDF_SCL_HI", hm1.CDF_SCL_HI, "");
	hist_comment =
	["A Markov chain generated by the emcee hammer subroutine",
	"NWALKERS is the number of walkers *per* free parameter",
	"NFREEPAR is the number of free parameters",
	"NSTEPS is the number of iterations for each walker",
	"CDF_SCL_LO: The step amplitude distribution goes as 1/sqrt(z),",
	"CDF_SCL_HI: bounded by z = 1/CDF_SCL_LO -> CDF_SCL_HI","",
	"The following file columns are the results unpacked",
	"as 1D vectors of length NWALKERS*NFREEPAR*NSTEPS:","",
	"FITSTAT contains the vector of walker fit statistics",
	"UPDATE is a yes/no answer as to whether a walker updated",
	"CHAINS# are the values for the free parameter given by",
	"parameter index #"
	];

	array_map(Void_Type, &fits_write_comment, ff, hist_comment);

	variable curr_col;
	variable fo = hm1.NAXIS2 + 1;
	variable COLS = String_Type [nfree+2];
	COLS[0] = "FITSTAT";
	COLS[1] = "UPDATE";
	_for ii (0, nfree-1) {
		COLS[ii+2] = "CHAINS"+string(string(sp1.free_par[ii]));
		}

	_for ii(0, length(COLS)-1, 1) {
		if ( qualifier_exists("verbose") )
			vmessage("\tReading "+COLS[ii]+", 1. chain");
		curr_col = fits_read_col (name1+"[2]", COLS[ii]);
		if ( qualifier_exists("verbose") )
			vmessage("\tWriting "+COLS[ii]+", 1. chain");
		if(_fits_write_col(ff,fits_get_colnum(ff,COLS[ii]),1,1,curr_col))
			throw IOError;

		if ( qualifier_exists("verbose") )
			vmessage("\tReading "+COLS[ii]+", 2. chain");
		curr_col = fits_read_col (name2+"[2]", COLS[ii]);
		if ( qualifier_exists("verbose") )
			vmessage("\tWriting "+COLS[ii]+", 2. chain");
		if(_fits_write_col(ff,fits_get_colnum(ff,COLS[ii]),fo,1,curr_col))
			throw IOError;
		}

%Writing third extension
	if (qualifier_exists("verbose"))
		vmessage("***Third Extension");
	COLS=["FRAC_UPDATE", "MIN_STAT", "MED_STAT", "MAX_STAT"];
	extname = "CHAINSTATS";
	colname = ["FRAC_UPDATE","MIN_STAT","MED_STAT","MAX_STAT"];
	nrows   = hc1.NAXIS2 + hc2.NAXIS2;
	fo = hc1.NAXIS2 + 1;
	ttype   = ["D","D","D","D"];
	tunit   = [" fraction"," chi2"," chi2"," chi2"];

	fits_create_binary_table(ff, extname, nrows, colname, ttype, tunit);
	hist_comment =
	["This extension contains some useful summary information",
	"for the individual chain steps",
	"FRAC_UPDATE is the fraction of walkers that updated",
	"MIN_STAT: minimum chi2 for a given step",
	"MED_STAT: median chi2 for a given step",
	"MAX_STAT: maximum chi2 for a given step"
	];
	array_map(Void_Type, &fits_write_comment, ff, hist_comment);

	_for ii(0, length(COLS)-1, 1) {
		if (qualifier_exists("verbose"))
			vmessage("\tReading "+COLS[ii]+", 1. chain");
		curr_col = fits_read_col(name1+"[3]", COLS[ii]);
		if (qualifier_exists("verbose"))
			vmessage("\tWriting "+COLS[ii]+", 1. chain");
		if (_fits_write_col(ff, fits_get_colnum(ff,COLS[ii]),1,1,curr_col))
			throw IOError;

		if (qualifier_exists("verbose"))
			vmessage("\tReading "+COLS[ii]+", 2. chain");
		curr_col = fits_read_col(name2+"[3]", COLS[ii]);
		if (qualifier_exists("verbose"))
			vmessage("\tWriting "+COLS[ii]+", 2. chain");
		if (_fits_write_col(ff, fits_get_colnum(ff, COLS[ii]),fo,1,curr_col))
			throw IOError;
	}

	fits_close_file(ff);
	return ;
}


define combine_chain ()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{combine_chain}
%\synopsis{Combine several mcmc chains generated with the same configuration}
%\usage{combine_chain(Array_Type chaininfiles, String_Type chainoutfile)}
%\qualifiers{
%\qualifier{verbose}{show progress}
%}
%\description
%       This function takes mcmc chains stored in files passed as an array of strings in chaininfiles,
%	written with the write_chain function (or by emcee itself) and combines them to one chain file,
%	again writing a fits file.
%       This function does not make use of read_chain or write_chain, it's consisting only of
%       fits routines. The function itself does perform some sanity and safety checks (same data, same fit_fun)
%       but you have to make sure that you use the correct chains in the correct order.
%\seealso{read_chain, write_chain, emcee, append_chain}
%!%-
{
	variable names, fname;
	switch(_NARGS)
	{ case 2: (names, fname) = (); }
	{ help(_function_name()); return; }
%What we need
	variable ii, jj;
	variable nf = length(names);
	variable hp = Struct_Type [nf];
	variable hm = @hp;
	variable hc = @hp;
%Reading all files headers of all extensions
	if (qualifier_exists("verbose"))
		vmessage("Reading headers ...");
	_for ii(0, nf-1, 1) {
		try {
			hp[ii] = fits_read_header(names[ii]+"[1]");
			hm[ii] = fits_read_header(names[ii]+"[2]");
			hc[ii] = fits_read_header(names[ii]+"[3]");
		} catch AnyError: {
			vmessage("*** Error opening "+names[ii]);
			throw OpenError;
		}
	}
%Testing for consistency
	if (qualifier_exists("verbose"))
		vmessage("Analysing ...");
	_for ii(1, nf-1, 1) {
		if (compare_header(hp[0], hp[ii]) != 0) {
			sprintf("*** Error: Header 1 (PARAMETERS) of "+names[ii]+" not the same as others, apparently not the same model or data was used", stderr);
			throw DataError;
		}
	}
	_for ii(1, nf-1, 1) {
		if (check_chain_headers(hm[0], hm[ii]) != 0) {
			sprintf("*** Error: Header 2 (MCMCCHAIN) of "+names[ii]+" not the same as others, apparently chains not from the same mcmc configuration", stderr);
			throw DataError;
		}
	}
	_for ii(1, nf-1, 1) {
		if (check_parameters_headers(hc[0], hc[ii]) != 0) {
			sprintf("*** Error: Header 3 (CHAINSTATS) of "+names[ii]+" not the same as others, apparently chains not from the same mcmc configuration", stderr);
			throw DataError;
		}
	}
	variable sp = Struct_Type[nf];
	_for ii(0, nf-1, 1) {
		try {
			sp[ii] = fits_read_table(names[ii]+"[1]");
		} catch AnyError: {
			sprintf("*** Error reading extension 1 (PARAMETERS) from "+names[ii], stderr);
			throw OpenError;
		}
	}
	variable nfree = hm[0].NFREEPAR;
	variable nw = hm[0].NWALKERS;
	_for ii(1, nf-1, 1) {
		_for jj(0, length(sp[0].free_par)-1, 1) {
			if (sp[0].free_par[jj] != sp[ii].free_par[jj]) {
				sprintf("*** Error: Free parameters of "+names[ii]+" differ from others", stderr);
				throw DataError;
			}
		}
	}
%Actually writing the file
%First extension
	variable ff=fits_open_file(fname, "c");
	if (qualifier_exists("verbose"))
		vmessage("***First Extension");
	variable extname = "PARAMETERS";
	variable colname = ["FREE_PAR"];
	variable nrows = nfree;
	variable ttype = ["J"];
	variable tunit = [" parameter indices"];
	fits_create_binary_table(ff, extname, nrows, colname, ttype, tunit);
	fits_update_key (ff, "PFILE", hp[0].PFILE, "");
	fits_update_key (ff, "MODEL", hp[0].MODEL, "");
	variable hist_comment =
	["This file was created by merging the results",
	"of several emcee runs using the mcmc routine for isis, written by",
	"Mike Nowak, assuming that the first part was used as the init_chain",
	"qualifier for the second one. A variety of checks for sanity",
	"of the datasets are performed but the user has still to be careful.",
	"This extension contains information about the model",
	"PFILE are the parameter files that started the chain",
	"MODEL is the fit function that was applied to the data",
	"FREE_PAR are the parameter indices of the free parameters"];
	array_map(Void_Type, &fits_write_comment, ff, hist_comment);
	if (qualifier_exists("verbose"))
		vmessage("\tWriting parameters");
	if(_fits_write_col(ff,fits_get_colnum(ff,"FREE_PAR"),1,1,sp[0].free_par))
		throw IOError;

%Second extension
	if (qualifier_exists("verbose"))
		vmessage("***Second extension");
	extname = "MCMCCHAIN";
	colname = ["FITSTAT","UPDATE"], ttype = ["D","J"],
	tunit =  [" fit statistics"," update indicator"];
	variable starts = Integer_Type [nf];
	variable nsteps = 0;
	nrows = 0;
	_for ii(0, nf-1, 1) {
		starts [ii] = nrows + 1;
		nrows += hm[ii].NAXIS2;
		nsteps += hm[ii].NSTEPS;
	}
	_for ii(0, nfree-1, 1)
	{
		colname = [colname,"CHAINS"+string(sp[0].free_par[ii])];
		ttype = [ttype,"D"];
		tunit = [tunit, " parameter values"];
	}
	fits_create_binary_table(ff, extname, nrows, colname, ttype, tunit);
	
	fits_update_key(ff, "NWALKERS", nw, "");
	fits_update_key(ff, "NFREEPAR", nfree, "");
	fits_update_key(ff, "NSTEPS", nsteps, "");
	fits_update_key(ff, "CDF_SCL_LO", hm[0].CDF_SCL_LO, "");
	fits_update_key(ff, "CDF_SCL_HI", hm[0].CDF_SCL_HI, "");
	hist_comment =
	["A Markov chain generated by the emcee hammer subroutine",
	"NWALKERS is the number of walkers *per* free parameter",
	"NFREEPAR is the number of free parameters",
	"NSTEPS is the number of iterations for each walker",
	"CDF_SCL_LO: The step amplitude distribution goes as 1/sqrt(z),",
	"CDF_SCL_HI: bounded by z = 1/CDF_SCL_LO -> CDF_SCL_HI","",
	"The following file columns are the results unpacked",
	"as 1D vectors of length NWALKERS*NFREEPAR*NSTEPS:","",
	"FITSTAT contains the vector of walker fit statistics",
	"UPDATE is a yes/no answer as to whether a walker updated",
	"CHAINS# are the values for the free parameter given by",
	"parameter index #"
	];
	
	array_map(Void_Type, &fits_write_comment, ff, hist_comment);

	variable curr_col;
	_for jj(0, nf-1, 1) {
		_for ii(0, length(colname)-1, 1) {
			if (qualifier_exists("verbose"))
				vmessage("\tReading "+colname[ii]+" "+string(jj+1)+".chain");
			curr_col = fits_read_col(names[jj]+"[2]", colname[ii]);
			if (qualifier_exists("verbose"))
				vmessage("\tWriting "+colname[ii]+" "+string(jj+1)+".chain");
			if(_fits_write_col(ff,fits_get_colnum(ff,colname[ii]),starts[jj],1,curr_col))
				throw IOError;
		}
	}

%Third extension
	if (qualifier_exists("verbose"))
		vmessage("***Third Extension");
	extname = "CHAINSTATS";
	colname = ["FRAC_UPDATE","MIN_STAT","MED_STAT","MAX_STAT"];
	nrows = 0;
	starts [*] = 0;
	_for ii (0, nf-1, 1) {
		starts[ii] = nrows+1;
		nrows += hc[ii].NAXIS2;
	}
	ttype   = ["D","D","D","D"];
	tunit   = [" fraction"," chi2"," chi2"," chi2"];

	fits_create_binary_table(ff, extname, nrows, colname, ttype, tunit);
	hist_comment =
	["This extension contains some useful summary information",
	"for the individual chain steps",
	"FRAC_UPDATE is the fraction of walkers that updated",
	"MIN_STAT: minimum chi2 for a given step",
	"MED_STAT: median chi2 for a given step",
	"MAX_STAT: maximum chi2 for a given step"
	];
	array_map(Void_Type, &fits_write_comment, ff, hist_comment);

	_for jj(0, nf-1, 1) {
		_for ii(0, length(colname)-1, 1) {
			if (qualifier_exists("verbose"))
				vmessage("\tReading "+colname[ii]+" "+string(jj+1)+".chain");
			curr_col = fits_read_col(names[jj]+"[3]", colname[ii]);
			if (qualifier_exists("verbose"))
				vmessage("\tWriting "+colname[ii]+" "+string(jj+1)+".chain");
			if(_fits_write_col(ff,fits_get_colnum(ff,colname[ii]),starts[jj],1,curr_col))
				throw IOError;
		}
	}

	fits_close_file(ff);
	return ;
}
