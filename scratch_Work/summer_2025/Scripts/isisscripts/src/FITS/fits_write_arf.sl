%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_write_arf()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_write_arf}
%\synopsis{Write a FITS ancilliary response matrix file}
%\usage{fits_write_arf(arfname,arf;qualifiers);}
% \qualifiers{
% \qualifier{telescope}{telescope for the ARF}
% \qualifier{instrument}{instrument for the ARF}
% \qualifier{filter}{filter of the instrument}
% \qualifier{detnam}{name of the detector}
% \qualifier{exposure}{exposure time associated with the ARF}
% \qualifier{chantype}{see FITS ARF specification (default: PI)}
% \qualifier{origin}{who write this file (default: ECAP)}
%}
%\description
% Write a FITS compliant ancilliary response matrix
%    arfname: name of the file to be written
%    arf: structure containing the following fields:
%       bin_lo, bin_hi: energy bounds (keV)
%       area: array of length(ebounds.bin_lo) containing the effective
%              area in cm^2
%    note: the energies given MUST be the same as the input energies
%          of the corresponding response matrix!
%\seealso{fits_write_rmf}
%!%-
{
    variable arfname;
    variable arf;

    switch(_NARGS)
    { case 2: (arfname,arf)=(); }
    { help(_function_name()); return;}
    
    % add some more sanity checking here eventually
    % (e.g., energy ordering...)
    if (length(arf.bin_lo) != length(arf.bin_hi) ) {
	throw RunTimeError,"Energy bins have different length.";
    }
    if (length(arf.bin_lo) != length(arf.area) ) {
	throw RunTimeError,"Area and Energy bins have different length.";
    }

    variable arf_data=struct{ 
	ENERG_LO=arf.bin_lo, 
	ENERG_HI=arf.bin_hi, 
	SPECRESP=arf.area 
    };

    variable arf_keys=struct{
	EXTNAME ="SPECRESP",
	TELESCOP=qualifier("telescope","dummy"),
	INSTRUME=qualifier("instrument","dummy"),
	FILTER  =qualifier("filter","none"),
	DETNAM=qualifier("detnam","none"),
	HDUCLASS="OGIP",
	HDUCLAS1="RESPONSE",
	HDUCLAS2="SPECRESP",
	HDUVERS ="1.1.0",
	ORIGIN  =qualifier("origin","ECAP"),
	VERSION ="1.1.1",
	TUNIT1  ="keV",
	TUNIT2  ="keV",
	TUNIT3  ="cm**2"
    };

    if (qualifier_exists("exposure")) {
	arf_keys=struct_combine(arf_keys,
  	         struct{EXPOSURE=qualifier("exposure")});
    }

    variable hist=struct{
	history=["file written by fits_write_arf.sl"]
    };

    variable fitsfile=fits_open_file(arfname, "c");
    fits_write_binary_table(fitsfile, "SPECRESP", arf_data, arf_keys, hist);
    fits_write_chksum(fitsfile);
    fits_close_file(fitsfile);
}
