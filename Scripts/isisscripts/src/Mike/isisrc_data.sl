% -*- slang -*-

% Safe guarding against dependencies from other Remeis scripts

try{
   require("bin_corr_factor.sl");
}
catch AnyError: {}

% Last Updated: April 25, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Public Functions in This File.  Usage message (almost always) when 
% function is called without arguments.

% list_all          : List all the data, arfs, and rmfs
% load_scaled_data  : Load data with non-unity AREASCAL
% pha2_bkg          : Assign background from pha2 file
% read_radio        : Read radio data from an ascii file, load to struct
% load_radio        : Take the structure above, and load it into data
% read_optical      : Read (optical) data from file where the units are 
%                     A_lo, A_hi, mJy, Delta mJy
% clear_all         : Wipe out all data, arfs, and rmfs
% load_data_integral: load INTEGRAL data
% fits_write_pha    : Write a fits pha file; stolen from Manfred Hanke

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define list_all() 
{ 
   list_data;
   list_rmf;
   list_arf; 
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

static variable ascal_data = {};

static define areascale_post_model_hook(lo,hi,c,b)
{
   return ascal_data[Isis_Active_Dataset-1]*c+b;
}

private define read_ascl(file)
{
   variable ascl, ascl_key=NULL, ascl_col=NULL;
   
   % First try to read it as a keyword
   try{
      ascl_key = fits_read_key(file,"AREASCAL");
   }
   catch AnyError:
   {
      ascl_key = NULL;
   }
   
   % Next try to read it as a column
   try{
      ascl_col = fits_read_col(file+"[1]","AREASCAL");
   }
   catch AnyError:
   {
      ascl_col = NULL;
   }
   
   % Column supersedes keyword
   if(ascl_col==NULL){ ascl=ascl_key; } else { ascl=ascl_col; }
   
   if(ascl_key==NULL && ascl_col==NULL) return -1;

   return ascl;
}

public define load_scaled_data()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_scaled_data}
%\synopsis{Loads a dataset with a non-unity AREASCAL keyword or column}
%\usage{id = load_scaled_data( String_Type file);}
%\qualifiers{
%\qualifier{rmf}{[="rmf.fits", response file if not in data header]}
%\qualifier{arf}{[="arf.fits", effective area file if not in data header]}
%\qualifier{bkg}{[="bkg.fits", background file if not in data header]}
%}
%\description
%    Load a data file with a non-unity AREASCAL, rewrite the
%    data/background to undo the ISIS default application of this value,
%    create a post_model_hook to properly apply it, and rewrite the data
%    and background backscales to properly apply it.  The data itself
%    must either reference a set of responses/backgrounds, or these must
%    be entered via qualifiers upon initial loading of the data.
%\seealso{load_data, _define_back, set_data_backscale}
%!%-
%%%%%%%%%%%%%%%%%%%%%%%%
{
   switch(_NARGS)
   {
    case 1:
      variable file = ();
      variable id = load_data(file);
   
      variable dascl = read_ascl(file);
      if(dascl[0] < 0) { message(" No data AREASCAL found."); return -1; }

      if(qualifier_exists("arf"))
      {
         variable aid = load_arf(qualifier("arf","unknown.arf"));
         assign_arf(aid, id);
      }
   
      if(qualifier_exists("rmf"))
      {
         variable rid = load_rmf(qualifier("rmf","unknown.rmf"));
         assign_rmf(rid, id);
      }

      if(qualifier_exists("bkg"))
      {
         variable bid = load_rmf(qualifier("bkg","unknown.bkg"));
         if( define_back(id,bid) ) { message(" Failed to load background."); return -1; }
      }
   
      % Everything should now be loaded, so get its information
      variable farf, garf, dinf = get_data_info(id), 
        data = get_data_counts(id), rb = dinf.rebin, did_rb=0;

      % If data.value and rb are the same length, no automatic
      % rebinning has happened, so no need to undo it, and no need to
      % "correct" the data errors

      if(length(data.value)!= length(rb))
      {
         did_rb=1;
         rebin_data(id,0);
         data = get_data_counts(id);
      }
         

      % Who the hell knows what order the energy bounds are stored in.
      % Read that information from the RMF.
   
      variable emin, emax, alo, ahi, rvrs=0;
      try{
         (emin, emax) = fits_read_col(get_rmf_info(dinf.rmfs[0]).arg_string+"[EBOUNDS]",
                                      "e_min","e_max");

         % Energy order is ascending, wavelength descending: reverse
         % the AREASCAL
         if(emin[1]>emin[0])
         {
            (alo,ahi) = _A(emin,emax);
            if(length(dascl)>1)             
            { 
               reverse(dascl); 
               rvrs=1;
            }
            else
            { dascl = dascl*ones(length(alo)); }
	 }
         % Energy order is descending, wavelength ascending: AREASCAL
         % is in the correct order
         else
         {
            alo = array_map(Double_Type, &_A, emax);
            ahi = array_map(Double_Type, &_A, emin);
	    if(length(dascl)==1) { dascl = dascl*ones(length(alo)); }
         }

         if(length(dascl) != length(alo))
         {
            message(" Incommensurate AREASCAL and EBOUNDS lengths");
            return -1;
         } 

         % Undo the effects of AREASCAL on the data

         if(length(dascl) != length(data.value))
         {
            message(" Incommensurate AREASCAL and data lengths");
            return -1;
         } 

         data.value *= dascl;
         if(did_rb) data.err *= dascl;
         put_data_counts(id,data);
      }
      catch AnyError:
      {
         message(" Failed to read energy bounds from RMF."); 
         return -1;
      }

      % Use the AREASCAL to alter the calculated model counts, via
      % set_post_model_hook

      % Set the list to contain the AREASCAL information
      variable i, lascal_data=length(ascal_data);
      if(lascal_data<id)
      {
         _for i (lascal_data+1,id-1,1) { list_append(ascal_data,1); }
         list_append(ascal_data,dascl);
      }
      else
      {
         ascal_data[id-1]=dascl;
      }

      set_post_model_hook(id, &areascale_post_model_hook);
   
      % Now check to see if there is a background
      if(dinf.bgd_file!="")
      {
         variable bascl = read_ascl(file);
         if(bascl[0] < 0) { message(" No background AREASCAL found."); return -1; }

         % Assume same ordering as data file
         if(rvrs) bascl = reverse(bascl);
   
         try{
            % ISIS doesn't give background directly, only scaled
            % background, so get the pieces to undo that.
            variable bbs = get_back_backscale(id);
            variable be  = get_back_exposure(id);
            variable bs  = get_back(id);

            variable dbs = get_data_backscale(id);
            variable de  = get_back_exposure(id);

            variable inz = where(de*dbs > 0);
       
            % Reconstruct the measured background
            variable bm = @bs;
            bm[inz] = (be*bbs[inz])/(de*dbs[inz])*bascl[inz]*bs[inz];

            % Set the new background, with the proper areascales
            % applied
            () = _define_back(id, bm, bbs*bascl, be);
            set_data_backscale(id,dbs*dascl);
         }
         catch AnyError:
         {
            message(" Failed to update background."); 
            return -1;
         }
      }
 
      if(did_rb) rebin_data(id,rb);

      return id;
   }

   variable fp = stderr;

   () = fprintf(fp,  "%s\n", %{{{
`
  id = load_scaled_data(file;rmf="rmf.fits", arf="arf.fits", bkg="bkg.fits");
  
  Load a data file with a non-unity AREASCAL, rewrite the
  data/background to undo the ISIS default application of this value,
  create a post_model_hook to properly apply it, and rewrite the data
  and background backscales to properly apply it.  The data itself
  must either reference a set of responses/backgrounds, or these must
  be entered via qualifiers upon initial loading of the data.
`
                       );        %%%}}}
}
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define pha2_bkg( )
{
   variable id, fname, dinfo, dexp, bsc_up, bsc_down, bup, bdown, blo, cnum;
   switch(_NARGS)
   { 
    case 2:
      (id, fname) = ();
   }
   {
      variable fp=stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
`  pha2_bkg(data_id, "pha2_file");

   Reads the appropriate background_up/_down columns from the
   file "pha2_file", along with the BACKSCUP and BACKSCDN 
   keywords, and assigns the appropriate background to the
   data set signified by data_id.  Presumes the usual 12-dataset
   (HEG/MEG, -3 -> +3) pha2 file.
`                              ); %%%}}}
      return;
   }
   dinfo = get_data_info(id);
   dexp = get_data_exposure(id);
   (bsc_up,bsc_down) = fits_read_key(fname,"backscup","backscdn");
   (bup,bdown,blo) = fits_read_col(fname,"background_up","background_down","bin_lo");

   cnum = 6*(dinfo.part-1)+dinfo.order+3; 
   if(dinfo.order>0) cnum--;

   % Check that things really are wavelength descending from the file
   if(blo[cnum,1] < blo[cnum,0])
   {
      () = _define_back( id, reverse(bup[cnum,*]+bdown[cnum,*]),
                         bsc_up+bsc_down, get_data_exposure(id) );
   }
   else
   {
      () = _define_back( id, (bup[cnum,*]+bdown[cnum,*]),
                         bsc_up+bsc_down, get_data_exposure(id) );
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
% Stolen from John Houck & Glenn Allen
%

static variable c_cgs = Const_c;
static variable h_cgs = Const_h;
static variable mjy2cgs = 1.0e-26;

public define read_radio( )
{
   variable in_fil, nbin;
   switch(_NARGS)
   { 
    case 2:
      (in_fil, nbin) = ();
   }
   {
      variable fp=stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
+" radio_data = read_radio(radio_file,nbins);\n"
+"\n"
+"   WARNING: THIS FUNCTION IS DEPRECATED! USE load_radio2!\n"
+"   Takes data in the ASCII file `radio_file', comprised of three\n"
+"   columns: Hz, mJy, \Delta mJy, and places them in a data structure\n" 
+"   suitable for loading via `load_radio'.  nbins gives the\n"
+"   number of logarithmically spaced wavelength bins to cover the\n"
+"   radio data."); %%%}}}
      return;
   }

   variable in_filp = fopen ( in_fil, "r" ); 

   if ( in_filp == NULL )
   {
      verror ( "\n  ***** Error: Unable to open file %s.\n", in_fil );
   }

   variable frequency, flux_density, flux_density_err;

   ( frequency, flux_density, flux_density_err ) = readcol ( in_fil, 1, 2, 3 );

   () = fclose ( in_filp ); 

   variable n_data_pnts = length ( frequency );

   % Turn Hz into Angstrom, & make sure data is sorted

   variable wavelength = c_cgs / frequency * 1.e8; 

   variable sort_indices = array_sort( wavelength );
   wavelength = wavelength[ sort_indices ]; 

   % Convert to ph cm^-2 s^-1 Hz^-1

   variable flux_differential = flux_density*mjy2cgs/h_cgs/frequency;
   variable flux_differential_err = flux_density_err*mjy2cgs/h_cgs/frequency;

   flux_differential = flux_differential[ sort_indices ];
   flux_differential_err = flux_differential_err[ sort_indices ];

   % Create wavelength grid

   variable wavelength_lo, wavelength_hi;
   variable n_wavelength_bins = nbin;
   variable scal_factor = 1. + (10./double(n_wavelength_bins));

   ( wavelength_lo, wavelength_hi ) = linear_grid( 
                                         log10(min(wavelength)/scal_factor),
                                         log10(max(wavelength)*scal_factor),
                                         n_wavelength_bins 
                                                 );
                                               
   wavelength_lo  = 10.0^wavelength_lo;
   wavelength_hi  = 10.0^wavelength_hi;

   variable flux_integrated     = Double_Type [ n_wavelength_bins ];
   variable flux_integrated_err = Double_Type [ n_wavelength_bins ];

   variable i1min = 0; 
   variable i1max = n_data_pnts;
   variable i1, i2;

   for ( i1 = i1min; i1 < i1max; i1++ )
   {
      i2 = where ( (wavelength_lo <= wavelength[i1]) and
                     (wavelength[i1] < wavelength_hi) );
        
      if( length(i2) > 0 )
      {
        
         %  ph cm^-2 s^-1 (in bin)	     

	flux_integrated[i2] =  flux_differential[i1] * c_cgs * 1.e8 *
	                       (wavelength_hi[i2] - wavelength_lo[i2]) 
                               / wavelength_lo[i2] / wavelength_hi[i2];

	flux_integrated_err[i2] =  flux_differential_err[i1] * c_cgs * 1.e8 *
	                       (wavelength_hi[i2] - wavelength_lo[i2]) 
                               / wavelength_lo[i2] / wavelength_hi[i2];
      }
   }

   % Remove unnecessary bins

   variable flag  = 1;
   i1    = -1;
   variable index = 0;

   while (flag)
   {
      i2 = where ( flux_integrated[[i1+1:]] > 0.0 ) + i1 + 1;
      if ( length(i2) > 0 )
      {
         if ( i2[0] > i1+1 )
	 {
            flux_integrated[index]     = 0.0;
            flux_integrated_err[index] = 0.0;
            wavelength_lo[index]       = wavelength_lo[i1+1];
            wavelength_hi[index]       = wavelength_hi[i2[0]-1];

            i1 = i2[0] - 1;
            index++;
         }
         else
         {
            flux_integrated[index]     = flux_integrated[i2[0]];
            flux_integrated_err[index] = flux_integrated_err[i2[0]];
            wavelength_lo[index]       = wavelength_lo[i2[0]];
            wavelength_hi[index]       = wavelength_hi[i2[0]];

            i1 = i2[0];
            index++;
         }
      }
      else flag = 0;
   }

   i1max = index - 1;
   i1min = where( flux_integrated > 0.0 )[0];
   variable n_out_pnts = i1max - i1min + 1;

   variable radio_data = struct{ bin_lo, bin_hi, value, err };

   radio_data.bin_lo = Double_Type [ n_out_pnts ];
   radio_data.bin_lo = wavelength_lo[[i1min:i1max]];

   radio_data.bin_hi = Double_Type [ n_out_pnts ];
   radio_data.bin_hi = wavelength_hi[[i1min:i1max]];

   radio_data.value  = Double_Type [ n_out_pnts ];
   radio_data.value  = flux_integrated[[i1min:i1max]];

   radio_data.err    = Double_Type [ length(wavelength_lo) ];
   radio_data.err    = flux_integrated_err[[i1min:i1max]];

   radio_data.value = radio_data.value;
   radio_data.err = radio_data.err;

   return radio_data;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define load_radio()
{
    vmessage("WARNING! THIS FUNCTION IS DEPRECATED! USE load_radio2!");
    switch(_NARGS)
    {
	case 1:
	variable radio_struct;
	radio_struct = ();
	variable radio_id = define_counts(radio_struct);
	set_data_exposure(radio_id,1.);
	ignore_list(radio_id, where ( radio_struct.value == 0.));
	return radio_id;
    }
    {
	variable fp=stderr;
	() = fprintf(fp, "\n%s\n", %%%{{{
	    +"radio_id = load_radio(radio_struct);\n"
	    +" \n"
	    +"   WARNING THIS FUNCTION IS DEPRECATED! USE load_radio2! \n"
	    +"   Takes the structure output from `read_radio();' and loads\n"
	    +"   it up for fitting.  Also ignores all the zero count\n"
	    +"   channels.  (Note: Those could come back if any further filters\n"
	    +"   are applied.)\n"); %%%}}}
	    return;
	}
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define read_optical( )
{
   variable in_fil, nbin;
   switch(_NARGS)
   { 
    case 1:
      (in_fil) = ();
   }
   {
      variable fp=stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
+" id = read_optical(optical_file);\n"
+" \n"
+"   Takes data in the ASCII file `optical_file', comprised of four\n"
+"   columns: A_lo, A_hi, mJy, \Delta mJy, and defines a data set with\n"
+"   identification id.  This will fail horribly for overlapping data bins.\n"); %%%}}}
      return;
   }

   variable in_filp = fopen ( in_fil, "r" ); 

   if ( in_filp == NULL )
   {
      verror ( "\n  ***** Error: Unable to open file %s.\n", in_fil );
   }

   variable alo, ahi, flux_density, flux_density_err;

   ( alo, ahi, flux_density, flux_density_err ) = readcol ( in_fil, 1,2,3,4 );

   () = fclose ( in_filp ); 

   variable isort = array_sort(alo);

   variable f_conv = 1.50918896;

   alo = alo[isort];
   ahi = ahi[isort];
   flux_density = flux_density[isort];
   flux_density_err = flux_density_err[isort];

   variable i=0, lalo = length(alo), lotemp, hitemp;
   loop(lalo-1)
   {
      if(alo[i+1] != ahi[i]);
      {
        lotemp = [alo[[0:i]],ahi[i],alo[[i+1:]]];
        hitemp = [ahi[[0:i]],alo[i+1],ahi[[i+1:]]];
	alo = lotemp;
        ahi = hitemp;
        flux_density = [flux_density[[0:i]],0.,flux_density[[i+1:]]];
        flux_density_err = [flux_density_err[[0:i]],0.,flux_density_err[[i+1:]]];
        i++;
      }
      i++;
   }

   variable flux = flux_density * f_conv * log( ahi/alo );
   variable eflux = flux_density_err * f_conv * log( ahi/alo);
   variable id = define_counts(alo,ahi,flux,eflux);
   set_data_exposure(id,1);
   ignore_list(id, where ( flux == 0.));
   return id;
}

%%%%%%%%%%%%%%%%%%%%%%%%%

public define clear_all()
%!%+
%\function{clear_all}
%\synopsis{Deletes data & corresponding ARFs and RMFs}
%\usage{clear_all();}
%\qualifiers{
%\qualifier{noprompt}{avoid the prompt in scripts}
%}
%\description
%    Deletes all data, the corresponding ARFs and RMFS, as well
%    as the intrinsic correction factors used for Fermi spectra.
%    This function removes the indicated spectra from the internal
%    list; it does not affect the disk files containing the spectra.
%
%
%\seealso{delete_data}
%!%-
{
   ifnot (qualifier_exists ("noprompt"))
   {
      variable fp =stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
		   +" Clearing all data & responses after the pause.\n"
		   +" ^C^C now if this isn't what you want!!!\n"); %%%}}}
      plot_pause;
   }
   delete_data(all_data);
   delete_arf(all_arfs);
   delete_rmf(all_rmfs);

% The following exists in other Remeis scripts, but won't exist if
% these functions are used outside of the Remeis scripts

#ifexists unfold_corr_factor
   unfold_corr_factor = Assoc_Type[Array_Type]; 
#endif

}


%%%%%%%%%%%%%%%%%%%%%%%%%%%

