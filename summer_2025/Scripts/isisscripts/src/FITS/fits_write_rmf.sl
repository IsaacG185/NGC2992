define fits_write_rmf()
%!%+
%\function{fits_write_rmf}
%\synopsis{Write a FITS response matrix file}
%\usage{fits_write_rmf(rmfname,rmf;qualifiers);}
% \qualifiers{
% \qualifier{telescope}{telescope for the response}
% \qualifier{instrument}{instrument for the response}
% \qualifier{filter}{filter of the instrument}
% \qualifier{detnam}{name of the detector}
% \qualifier{effarea}{effective area of the detector (default: 1cm**2)}
% \qualifier{lo_thresh}{lower threshold of the matrix, i.e., values below
%       this number have been set to zero. Default: 0.}
% \qualifier{chantype}{see FITS RMF specification (default: PI)}
% \qualifier{channel}{array of channel numbers for the ebounds extension 
%     (default: channels are assumed to start at 1)}
% \qualifier{origin}{who write this file (default: ECAP)}
% \qualifier{constantwidth}{write data with width constantwidth around 
%       maximum of the matrix.}
%}
%\description
% Write a FITS compliant response matrix
%    rmfname: name of the file to be written
%    rmf: structure containing the following fields:
%       ebounds (bin_lo, bin_hi): channel energies of the response matrix
%       energy (bin_lo, bin_hi): input energies of the response matrix
% The response matrix can be given in two ways. For most decent resolution
% instruments, define the matrix as
%       matrix[energy,channel]: with dimensions matrix[length(energy),length(ebounds)]
% If this does not work (this is the case once the total array size exceeds
% the limits imposed by s-lang), then define matrix as an Array of Arrays:
%       matrix=Array_Type[length(energy)];
% and assign an Array_Type[length(ebounds)] to each element of matrix
% 
% Note: High resolution matrices can be VERY large. This code does not yet 
% write variable length arrays due to time reasons. As a work around it
% is possible just to write information around the diagonal using the
% constantwidth qualifier.
%\seealso{fits_write_arf,fits_read_rmf}
%!%-
{
    variable rmfname;
    variable rmf;

    switch(_NARGS)
    { case 2: (rmfname,rmf)=(); }
    { help(_function_name()); return;}
    
    % add some sanity checking here eventually...

    variable nch=length(rmf.ebounds.bin_lo);
    variable nin=length(rmf.energy.bin_lo);

    variable channel=qualifier("channel",[1:nch]);
    
    if (length(channel)!=nch) {
	throw RunTimeError,"Channel must have same length as number of channels.";
    }

    variable masiz=array_shape(rmf.matrix);
    variable is2d=(length(masiz)==2);
    if (is2d) {
	% 2D matrix
	if (masiz[0] !=nin) {
	    throw RunTimeError,"Matrix: 1st dimension has wrong length";
	}
	if (masiz[1] != nch) {
	    throw RunTimeError,"Matrix: 2nd dimension has wrong length";
	}
    } else {
	% rmf.matrix is an array of arrays
	if (masiz[0] != nin) {
	    throw RunTimeError,"Matrix: Number of input channels is wrong";
	}
	% checking of the number of channels is deferred to below
    }
    
    %
    % build the EBOUNDS extension
    %

    variable eb_data=struct{
	CHANNEL=channel,
	E_MIN=rmf.ebounds.bin_lo,
	E_MAX=rmf.ebounds.bin_hi
    };

    variable eb_keys=struct{
	EXTNAME ="EBOUNDS",
	TELESCOP=qualifier("telescope","dummy"),
	INSTRUME=qualifier("instrument","dummy"),
	FILTER  =qualifier("filter","none"),
	CHANTYPE=qualifier("chantype","PI"),
	DETCHANS=nch,
	HDUCLASS="OGIP",
	HDUCLAS1="RESPONSE",
	HDUCLAS2="EBOUNDS",
	HDUVERS ="1.2.0",
	ORIGIN  =qualifier("origin","ECAP"),
	VERSION ="1.1.1",
	TUNIT2  ="keV",
	TUNIT3  ="keV"
    };
	
    %
    % build the RMF extension
    %

    variable rmf_keys=struct{
	EXTNAME ="MATRIX",
	TELESCOP=qualifier("telescope","dummy"),
	INSTRUME=qualifier("instrument","dummy"),
	FILTER  =qualifier("filter","none"),
	CHANTYPE=qualifier("chantype","PI"),
	DETCHANS=nch,
	LO_THRES=qualifier("lo_thresh",0.),
	DETNAM=qualifier("detnam","none"),
	EFFAREA=qualifier("effarea","1."),
	NUMGRP=-1,
	NUMELT=-1,
	HDUCLASS="OGIP",
	HDUCLAS1="RESPONSE",
	HDUCLAS2="RSP_MATRIX",
	HDUCLAS3="REDIST",
	HDUVERS ="1.3.0",
	ORIGIN  =qualifier("origin","ECAP"),
	VERSION ="1.1.1",
	TLMIN4  =min(channel),
	TLMAX4  =max(channel),
	TUNIT1  ="keV",
	TUNIT2  ="keV"
    };

	
    variable rmf_data;

    % if maxwidth exists, then 
    if (qualifier_exists("constantwidth")) {
	% constant width response matrix

	if (qualifier("constantwidth")<=0) {
	    throw RunTimeError,"constantwidth must be positive";
	}

	% make sure that width does not exceed the full matrix
        variable maxwidth=min([qualifier("constantwidth"),nch]);

	% set the optimized matrix
	rmf_data=struct{
	    ENERG_LO=rmf.energy.bin_lo,
	    ENERG_HI=rmf.energy.bin_hi,
	    N_GRP   =Integer_Type[nin],
	    F_CHAN  =Integer_Type[nin],
	    N_CHAN  =Integer_Type[nin],
	    MATRIX  =Double_Type[nin,maxwidth]
	};

	% cut out data around the maximum of the matrix
	variable ii;
	for(ii=0;ii<nin;ii++) {
	    variable row;
	    if (is2d) {
		row=rmf.matrix[ii,*];
	    } else {
		row=rmf.matrix[ii][*];
	    }
	    variable ndx=wherefirstmax(row);
	    variable istart=max([ndx[0]-maxwidth/2,0]);
	    variable iend=istart+maxwidth-1;
	    if (iend>=nch) {
		iend=nch-1;
		istart=iend-maxwidth+1;
	    }
	    rmf_data.N_GRP[ii]=1;
	    rmf_data.F_CHAN[ii]=channel[istart];
	    rmf_data.N_CHAN[ii]=maxwidth;
	    rmf_data.MATRIX[ii,*]=row[[istart:iend]];
	}

    } else {
	% write the unoptimized matrix
	if (not is2d) {
	    % this will probably fail - in the case we use an array of arrays
	    % we really should write the matrix row by row...
	    % but then, people who write unoptimized matrices should be punished
	    % anyway...
	    variable mat=Double_Type[nin,nch];
	    for (ii=0; ii<nin;ii++) {
		mat[ii,*]=rmf.matrix[ii][*];
	    }
	    rmf_data=struct{
		ENERG_LO=rmf.energy.bin_lo,
		ENERG_HI=rmf.energy.bin_hi,
		N_GRP   =Integer_Type[nin]+1,
		F_CHAN  =Integer_Type[nin]+channel[0],
		N_CHAN  =Integer_Type[nin]+nch,
		MATRIX  =rmf.matrix
	    };
	    
	} else {
	    rmf_data=struct{
		ENERG_LO=rmf.energy.bin_lo,
		ENERG_HI=rmf.energy.bin_hi,
		N_GRP   =Integer_Type[nin]+1,
		F_CHAN  =Integer_Type[nin]+channel[0],
		N_CHAN  =Integer_Type[nin]+nch,
		MATRIX  =rmf.matrix
	    };
	}
    }

    variable hist=struct{
	history=["file written by fits_write_rmf.sl"]
    };

    rmf_keys.NUMGRP=sum(rmf_data.N_GRP);
    rmf_keys.NUMELT=sum(rmf_data.N_CHAN);

    % Store the RMF in a FITS file.
    variable fitsfile=fits_open_file(rmfname, "c");
    fits_write_binary_table(fitsfile, "EBOUNDS", eb_data, eb_keys, hist);
    fits_write_chksum(fitsfile);
    fits_write_binary_table(fitsfile, "MATRIX", rmf_data, rmf_keys, hist);
    fits_write_chksum(fitsfile);
    fits_close_file(fitsfile);
}
