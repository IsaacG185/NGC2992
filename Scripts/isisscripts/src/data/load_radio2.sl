define load_radio2()
%%%%%%%%%%%%%%%%
%!%+
%\function{load_radio2}
%
%\synopsis{reads and loads radio data}
%\usage{Integer_Type data_id = load_radio (String_Type filename);}
%
%\description
%    Takes data an ASCII file , comprised of three  columns: 
%    Frequency[Hz], Flux density [mJy], Error [mJy], and loads
%    the data as a dataset.
%    WARNING: The standard bin width is set to 10%
%
%    It can be changed with the qualifier binwidth (given in
%    fraction of the frequency). Since a log frequency grid is
%    used, it will not be exactly the size given.
%    WARNING: Bins cannot overlap, as grid needs to be continuous!
%    
%\qualifiers{
%\qualifier{binwidth}{   specify bin width}
%\qualifier{use_struct}{ use an ISIS structure with the
%                          following fields: freq[Hz],
%                          bandwidth[Hz], flux[mJy], err[mJy];
%                          with full bandwidth given}
%}
%
%\example
%    isis> variable data_file = "/some/path/radio_file.txt";
%    isis> variable radio_data = load_radio2(data_file);
%
%    example using a textfile that includes bin widths:
%
%    isis> variable abc = ascii_read_table ("radio_dat.txt",[{"%F","freq"},{"%F", "bandwidth"},{"%F","flux"},{"%F","err"}]);
%    isis> variable radio_data = load_radio2(abc; use_struct);
%
%\seealso{read_radio, load_radio}
%!%-
{
    variable in_fil;
    switch(_NARGS)
    { case 1: in_fil  = (); }
    { help(_function_name()); return; }

    variable binwidth = qualifier("binwidth", NULL);
    variable usestruct = qualifier("use_struct", NULL);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1. Try loading the user specified file

    if (not qualifier_exists("use_struct"))
    {
	try
	{
	    variable load_ascii = ascii_read_table(in_fil,[{"%F", "freq"},{"%F", "flux"},{"%F","err"}]);
	}
	catch AnyError:
	{
	    vmessage("*** Error: File %s could not be opened", in_fil);
	}
    }
    else
    {
	load_ascii = @in_fil;
    }

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2. Units: Flux density mJy -> ph/cm^2/s/Hz

    variable mjy2cgs = 1.0e-26;
    load_ascii.flux = load_ascii.flux/Const_h/load_ascii.freq*mjy2cgs;
    load_ascii.err = load_ascii.err/Const_h/load_ascii.freq*mjy2cgs;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3. Units: Frequency -> Angstrom & sort

    if (qualifier_exists("use_struct"))
    {
	%Get fractional bin width
	variable bin_w_struct = load_ascii.bandwidth/load_ascii.freq;
    }

    variable wavelength = Const_c/load_ascii.freq*1e8;
    load_ascii = struct_combine(load_ascii,struct{wave = wavelength});
    variable sorted = sort_struct_arrays(load_ascii, "wave");

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 4. Make lo & hi grid

    variable lo_grid, hi_grid;

    if (qualifier_exists("use_struct"))
    {
	lo_grid = sorted.wave-bin_w_struct*sorted.wave/2.;	
	hi_grid = 10^(log10(sorted.wave-lo_grid))+sorted.wave;
    }
    else if (not qualifier_exists("binwidth") && 
    not qualifier_exists("use_struct"))
    {
	binwidth=0.1;
	lo_grid = sorted.wave-binwidth*sorted.wave/2.;
	hi_grid = 10^(log10(sorted.wave-lo_grid))+sorted.wave;
    }
    else if (qualifier_exists("binwidth") )
    {
	lo_grid = sorted.wave-binwidth*sorted.wave/2.;
	hi_grid = 10^(log10(sorted.wave-lo_grid))+sorted.wave;
    }

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 5. Make continuous grid

    variable full_grid_lo = Double_Type[0];
    variable full_grid_hi = Double_Type[0];
    variable full_flux = Double_Type[0];
    variable full_err = Double_Type[0];

    variable i;
    _for i(0, length(lo_grid)-1,1)
    {
	if (i<length(lo_grid)-1)
	{
	    full_grid_lo=[full_grid_lo,lo_grid[i]];
	    full_grid_hi=[full_grid_hi,hi_grid[i]];
	    full_flux = [full_flux,sorted.flux[i]];
	    full_err = [full_err,sorted.err[i]];

	    % Check if bins are continuous
	    %if not add empty bin

	    if (lo_grid[i+1] != hi_grid[i])
	    {
		full_grid_lo=[full_grid_lo,hi_grid[i]];
		full_grid_hi=[full_grid_hi,lo_grid[i+1]];
		full_flux = [full_flux,0.];
		full_err = [full_err,0.];
	    }
   	}
	else
	{
	    full_grid_lo=[full_grid_lo,lo_grid[i]];
	    full_grid_hi=[full_grid_hi,hi_grid[i]];
	    full_flux = [full_flux,sorted.flux[i]];
	    full_err = [full_err,sorted.err[i]];
	}
    }
    


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 6. Integrate flux and make final structure

    variable flux_int, err_int, final_struct;
    
    flux_int = full_flux*Const_c*1.e8*(full_grid_hi-full_grid_lo)/full_grid_lo/full_grid_hi;
    err_int = full_err*Const_c*1.e8*(full_grid_hi-full_grid_lo)/full_grid_lo/full_grid_hi;

    final_struct = struct{bin_lo = full_grid_lo, bin_hi = full_grid_hi, value=flux_int, err = err_int};

    variable radio_id = define_counts(final_struct);
    set_data_exposure(radio_id,1.);
    ignore_list(radio_id, where (final_struct.value == 0.));

    return radio_id; 
}
