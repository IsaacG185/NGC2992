% -*- mode: slang; mode: fold -*-

private variable fluxInCrab = 2.4e-8; % for 2--10 keV
private define get_simputfile_empty_struct(){ %{{{

   variable arr = ["Simput","Src_ID","Src_Name","RA","Dec",
		   "srcFlux","Elow","Eup","Estep",
		   "Nbins","logEgrid",
		   "plPhoIndex","plFlux","bbkT","bbFlux",
		   "flSigma","flFlux","rflSpin","rflFlux",
		   "NH","Emin","Emax",
		   "ISISFile","ISISPrep","XSPECFile","PHAFile",
		   "ASCIIFile","LCFile","MJDREF",
		   "PSDnpt","PSDfmin","PSDfmax","LFQ","LFrms",
		   "HBOf","HBOQ","HBOrms","Q1f","Q1Q","Q1rms",
		   "Q2f","Q2Q","Q2rms","Q3f","Q3Q","Q3rms","PSDFile",
		   "ImageFile","chatter","clobber","history"];

   return @Struct_Type(arr);
}
%}}}
private define set_simputfile_flux(){ %{{{

   variable emin = 2.0, emax = 10.;
   variable str,flux;
   switch(_NARGS)
   {case 2: (str,flux) = (); }
   {case 4: (str,flux,emin,emax) = (); }
   { help(_function_name()); return; }

   str.Emin=emin;
   str.Emax=emax;

   
   if (qualifier_exists("crab"))
     flux *= fluxInCrab;

   str.srcFlux=flux;

   return;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%
define get_simputfile_struct(Simput,RA,Dec,flux){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_simputfile_struct}
%\synopsis{get a very basic SIMPUT structure for further editing}
%\usage{get_simputfile_struct(filename, RA, Dec flux);}
%\description
%    Note: All parameters and there usage are according to the simputfile
%    routine of the SIMPUT package. E.g., flux is given in erg/cm^2/s.
%\qualifiers{
%\qualifier{crab}{flux is given in units of Crab}
%\qualifier{emin}{[2.0]: lower limit of the energy band of the given flux in keV}
%\qualifier{emax}{[10.0]: lower limit of the energy band of the given flux in keV}
%}
%\seealso{create_basic_simputfile,eval_simputfile,set_simputfile_model_grid,set_simputfile_flux}
%!%-
   variable str = get_simputfile_empty_struct();
   str.Simput=Simput;
   str.RA=RA;
   str.Dec=Dec;
   
   if (qualifier_exists("emin") && qualifier_exists("emax"))
     set_simputfile_flux(str,flux,qualifier("emin"),qualifier("emax") ;; __qualifiers);
   else
     set_simputfile_flux(str,flux ;; __qualifiers);

   if (not qualifier_exists("noclobber"))
     str.clobber="yes"; 
   
   return str;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%
define set_simputfile_model_grid(){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_simputfile_model_grid}
%\synopsis{set the model grid in the SIMPUT structure}
%\usage{set_simputfile_model_grid(Struct_Type str);}
%%\altusage{set_simputfile_model_grid(Struct_Type str, Elow, Eup, Estep);}
%\description
%    All energies are given in keV. By default, the spectrum is
%    evaluated from 0.05-24.0 keV in steps of 0.01 keV.
%\seealso{create_basic_simputfile,get_simputfile_struct,eval_simputfile,set_simputfile_flux}
%!%-

   variable str;
   variable emin=0.05,emax=25,estep=0.01;
   
   switch(_NARGS)
   {case 1: str = (); }
   {case 4: (str,emin,emax,estep) = (); }
   { help(_function_name()); return; }

   str.Elow=emin;
   str.Eup=emax;
   str.Estep=estep;
   
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%
define eval_simputfile(str){ 
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{eval_simputfile}
%\synopsis{evaluates the SIMPUT structure}
%\usage{Integer_Type sucess = eval_simputfile(Struct_Type str);}
%\description
%    This function evalutes the SIMPUT structure, created for example
%    with "get_simputfile_struct". Generally, all fields of the
%    structure == NULL are skipped.
%\qualifiers{
%\qualifier{quiet}{don't show any output}
%}
%\seealso{create_basic_simputfile,get_simputfile_struct,set_simputfile_model_grid,set_simputfile_flux}
%!%-

   variable cmd = "simputfile";

   variable sf,sfv;
   foreach sf(get_struct_field_names(str)){

      sfv = get_struct_field(str,sf);
      if (sfv !=NULL){
	 if (not (typeof(sfv) == String_Type))
	   sfv = string(sfv);
	 
	 cmd += sprintf(" %s=%s",sf,sfv);
      }
      
   }

   % for backwards compatibility...
   if (not (qualifier_exists("quite"))) {
       if (not (qualifier_exists("quiet"))) {
	   message("\n"+cmd);
       }
   }
   
   return system(cmd);
}

%%%%%%%%%%%%%%%%%%%%%%%
define create_basic_simputfile(Simput,RA,Dec,flux,nh,pl){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{create_basic_simputfile}
%\synopsis{creates a basic SIMPUT file}
%\usage{Struct_Type str = create_basic_simputfile(filename, RA, Dec, srcFlux, nH, powerLawIndex);}
%\description
%    This function creates a structure, which contains all necessary
%    info for a simple "simputfile" command to create a basic SIMPUT
%    file for a given point source. The flux is assumed to be given in
%    the 2-10 keV band by default. The file can be directly created by
%    adding the qualifier "eval". Otherwise a structure is returned.
%    This structure can be further modifed, and then evaluated with
%    the function "eval_simputfile".
%\qualifiers{
%\qualifier{crab}{flux is given in units of Crab}
%\qualifier{eval}{directly evalute the returned structure (similar to call eval_simputfile(str); }
%\qualifier{emin}{lower limit of the energy band of the given flux in keV}
%\qualifier{emax}{lower limit of the energy band of the given flux in keV}
%\qualifier{quite}{don't show any output}
%}
%\examples
%    \code{variable str = create_basic_simputfile("velaX-1.fits",135.528583,40.554722,100e-3,1.8,5.0;crab);}
%\seealso{eval_simputfile,get_simputfile_struct,set_simputfile_model_grid,set_simputfile_flux}
%!%-

   if (qualifier_exists("crab"))
     flux *= fluxInCrab;

   variable str = get_simputfile_struct(Simput,RA,Dec,flux);

   str.NH=nh;
   str.plPhoIndex=pl;
   str.plFlux = flux;
   
   set_simputfile_model_grid(str ;; __qualifiers);

   if(qualifier_exists("eval"))
     () = eval_simputfile(str);
   
   return str;
}
