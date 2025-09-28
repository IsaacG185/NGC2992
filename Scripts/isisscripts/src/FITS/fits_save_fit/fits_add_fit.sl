define fits_add_fit()
%!%+                                                                                                      
%\function{fits_add_fit}
%\synopsis{adds different saved models and observation info togethter in one FITS table}
%\usage{Struct_Type str = fits_add_fit(String_Type filename, String_Type save1
%                         [,String_Type save2] [, ...);
% or Struct_Type str = fits_add_fit(String_Type filename, Struct_Type save1
%                      [, Struct_Type save2] [, ...);}
% or Struct_Type str = fits_add_fit(String_Type filename, Array_Type);
%\description
%
%   This function is based on fits_save_fit and fits_load_fit_struct.
%   If called with String_Type filenames, these files are loaded with
%   fits_load_fit_struct, merged, and saved to the (new) file
%   "filename".
%   If called with Struct_Type, these structure should have been
%   created with fits_save_fit_struct, which will then be merged and
%   saved to "filename".
%   If called with Array_Type, the entries of the array should either
%   be strings loadable with fits_load_fit_struct or structures
%   created with fits_save_fit_struct.
%   It returns the merged structure.
%                                                                                                         
%\seealso{fits_load_fit_struct,fits_save_fit_struct,fits_write_fits_struct,fits_save_fit,merge_struct_arrays}
%!%-
{
  variable fil ;
  %return help only when no or only one argument (the file name) is given
  switch (_NARGS) 
  { case 0 or case 1 : help(_function_name()); return; }
  { case 2 : fil = () ;} %could be already an array, so we don't need to create one
  { 
    
    %last argument determines the type of all arguments: String (files)
    %or Structure?
    
    variable i, fil0 = () ;
    fil = [fil0][Integer_Type[_NARGS-1]] ;
    
    _for i (1, _NARGS-2, 1)
      fil[i] = () ;
    
    %reverse entries so that the order in the FITS file corresponds to
    %the order given as arguments
    fil = reverse(fil) ;
  }
  variable name = () ;

  variable nfits = length(fil);
  variable stru = Struct_Type[nfits] ;
  
  %if files, read them and merge them
  if (typeof(fil[0]) == String_Type)
  {
    _for i (0, length(fil)-1, 1)
    {
      if(qualifier_exists("verbose")){
	()=printf("Loading saved fit %s...\n", fil[i]) ; 
      }
      stru[i] = fits_load_fit_struct(fil[i]) ;
    }
      }
  %if already structures only merge them
  else if (typeof(fil[0]) == Struct_Type)
  {
    stru = fil;
    %	stru = merge_struct_arrays(fil ; reshape = 0) ;
    %	stru = merge_struct_arrays(fil) ;
  }
  %if any other type, return help message ;
  else
  {
    vmessage(`error (%s): arguments have to be either Struct_Type or String_Type`, _function_name() ); return() ;
  }


  %% ---- initialize structure to save data in ----
  
  %%loop over all elements of stru
  variable len = 0;
  _for i (0, length(stru)-1, 1){    
    %%len = maximum number of data set loaded so far
    len = max([len,length(stru[i].exposure)]);    
  }    

  %% --- create info fields ---
  variable lenfields = ["tstop","tstart_mjd","tstop_mjd","exposure","mjdref","exposure",
			"tfirst_mjd","tlast_mjd"];

  variable dummy_nfits_len = Double_Type[nfits,len];
  dummy_nfits_len[*,*] = _NaN;
  variable allinone = struct {fit_fun=String_Type[nfits],
    tstart=@dummy_nfits_len,
    tstop=@dummy_nfits_len,
    tstart_mjd=@dummy_nfits_len,
    tstop_mjd=@dummy_nfits_len,
    exposure=@dummy_nfits_len,
    data=String_Type[nfits],
    bkg=String_Type[nfits],
    instrument=String_Type[nfits],
    target=String_Type[nfits],
    telescope=String_Type[nfits],
    filter=String_Type[nfits],
    date_obs=String_Type[nfits],
    date_end=String_Type[nfits],
    obs_id=String_Type[nfits],
    rebin=String_Type[nfits],
    notice_list=String_Type[nfits],
    chi_red=Double_Type[nfits],
    chi=Double_Type[nfits],
    dof=UInteger_Type[nfits],
    fit_statistic=String_Type[nfits],
    cwd=String_Type[nfits],
    mjdref=@dummy_nfits_len,
    sys_err=String_Type[nfits],
    tfirst_mjd=@dummy_nfits_len,
    tlast_mjd=@dummy_nfits_len};

  %% --- set other fields & fill up special fields with values ---
  
  variable diff,j,temprow,names,row,n;
  variable dims, num_dims, data_type;

  if(qualifier_exists("verbose")){
    ()=printf("Creating template for combined structure") ;
  }
  
  %% ----------- start loop over all elements of stru
  _for i (0, length(stru)-1, 1){

    names = get_struct_field_names(stru[i]);
    diff = complementary_array(names,get_struct_field_names(allinone));

    %% if field names not yet in allinone exist, create such a field
    %% in the allinone structure and intialize it to defauls values
    if (length(diff) != 0) {

      %%create new fields in allinone
      allinone = struct_combine(allinone, diff);
      
      %%set all new entries in the new fields to defauls values
      _for j (0,length(diff)-1,1) {
	(dims, num_dims, data_type) = array_info(get_struct_field(stru[i],diff[j]));       
	%%depending of number of dimensions (1D or 2D) of the array
	%%constiting a row of the structre ...
	switch (num_dims)
	%% -- 1D array --
	{ num_dims == 1 :
	    set_struct_field(allinone,diff[j],data_type[nfits]);
	  %% -- different data types for 1D arrays --
	  switch (data_type)
	  {data_type == Double_Type :
	      temprow = get_struct_field(allinone,diff[j]); temprow[*] = _NaN;
	    set_struct_field(allinone,diff[j],temprow);
	  }
	  {data_type == String_Type :
	      temprow = get_struct_field(allinone,diff[j]); temprow[*] = "";
	    set_struct_field(allinone,diff[j],temprow);}
	  {data_type == Integer_Type :
	      temprow = get_struct_field(allinone,diff[j]); temprow[*] = INT_MIN;
	    set_struct_field(allinone,diff[j],temprow);}
	  {vmessage(`error (%s): Structure fiels of other types than Double_Type, String_Type \nand Integer_Type not implemented`, _function_name() ); return();}
	}	
	%% -- 2D array --
	{ num_dims == 2 :
	    set_struct_field(allinone,diff[j],data_type[nfits,dims[1]]);
	  %% -- different data types for 2D arrays --
	  switch (data_type)
	  {data_type == Double_Type :
	      temprow = get_struct_field(allinone,diff[j]); temprow[*,*] = _NaN;
	    set_struct_field(allinone,diff[j],temprow);
	  }
	  {data_type == String_Type :
	      temprow = get_struct_field(allinone,diff[j]); temprow[*,*] = "";
	    set_struct_field(allinone,diff[j],temprow);}
	  {data_type == Integer_Type :
	      temprow = get_struct_field(allinone,diff[j]); temprow[*,*] = INT_MIN;
	    set_struct_field(allinone,diff[j],temprow);}
	  {vmessage(`error (%s): Structure fiels of other types than Double_Type, String_Type \nand Integer_Type not implemented`, _function_name() ); return();}
	}
	%%error message for arrays with other number of dimensions
	{vmessage(`error (%s): Structure fiels with more than two dimensions not implemented`, _function_name() ); return();};
      }    
    }
  }
  %% ----------- end loop over all elements of stru

  
  %% ----------- start loop over all fields of allinone
  variable temparr,allnames;
  allnames = get_struct_field_names(allinone);
  foreach row (allnames) {
    
    if(qualifier_exists("verbose")){
      ()=printf("Working on row %s ...\n", row) ; 
    }
    
    temparr = get_struct_field(allinone,row);
    
    %% -- now loop over all elements of stru
    _for i (0, length(stru)-1, 1){
      
      names = get_struct_field_names(stru[i]);
      if(length(where(names == row)) == 0) {
	%%if row does not exist in this fits, skip it
	continue;
	
      } else {

	%%if row exists, take care of whether it's 1D or 2D
	(dims, num_dims, data_type) = array_info(get_struct_field(stru[i],row));
	
	%%everything that is not 1 or 2 should already have been
	%%caught in the last step
	switch (num_dims)
	{num_dims == 1 :
	    temparr[i] = get_struct_field(stru[i],row)[0];
	}
	{num_dims == 2 :
	    
	    %%we expect a field to be an array of type
	    %%Some_Type[1,n], i.e. dims = [1,n], therefore:
	    _for n (0,dims[1]-1,1) {
	      temparr[i,n] = get_struct_field(stru[i],row)[0,n];
	    }	 	  
	};	
      }            
    }    
    set_struct_field(allinone,row,temparr);    
  }    

  fits_save_fit_write(name, allinone) ;
  
  %%% TO DO
  % * instruments should be aphabetically sorted; sort all data in
  % respective places
    
  return allinone ;
}
