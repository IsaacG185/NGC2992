define get_modelcomponents()
%!%+
%\function{get_modelcomponents}
%\synopsis{load binned model component values}
%\usage{Struct_Type[] mc = get_modelcomponent( Integer_Type hist_index);}
%\altusage{Struct_Type[] mc = get_modelcomponent( );}
%\qualifiers{
%\qualifier{fct [=NULL]:}{ NULL:    Using 'get_model' (default)
%                  "counts": Using 'get_model_counts'
%                  "flux":   Using 'get_model_flux'
% }
%}
%\description
%     For each model component (see 'get_fun_components') within the given
%     dataset 'hist_index' this funtion returns a stucture with three array
%     fields, bin_lo [Angstrom], bin_hi [Angstrom] and value, containging
%     only the contribution of this component to the overall model.
%     If 'hist_index' isn ot given all included datasets are used!
%
%     The model contribution of each component is obtained by setting all
%     the norm parameters (get_par_info: is_a_norm=1) of all other components
%     to zero and evaluating the model. NOTE THAT for each component an
%     'eval_counts' is called!
%
%     The 'fct' qualifier determines which function should be used to
%     obtain the model components.
%     
%                                              
%\seealso{get_fun_components, get_model, get_model_counts, get_model_flux}
%!%-
{
  %%% Grep excluded/included datasets
  variable exc_data = merge_struct_arrays(get_data_info(all_data)).exclude;
  variable inc_data = wherenot(exc_data)+1;
  exc_data = where(exc_data)+1;
  
  variable id;
  switch(_NARGS)
  { case 0 : id = inc_data; }
  { case 1 : id = ();
    %% exclude all other datasets but 'id'
    include (all_data);
    exclude (all_data[complement( all_data, id )]);
  }
  { help(_function_name); return;}

  %% Set get_model method according qualifier
  variable fct = qualifier("fct",NULL);
  variable get_model_fct = &get_model;
  ifnot( _isnull(fct) ){
    if( fct == "counts" ){
      get_model_fct = &get_model_counts;
    }
    else if( fct == "flux" ){
      get_model_fct = &get_model_flux;
    }
    else{ help(_function_name); return; }
  }
  
  %% Store the original parameters
  variable PARAMETERS = get_params;
  
  %% get fit fun component names
  variable cnames = get_fun_components;
  variable ncomp  = length(cnames);
  variable normid = Array_Type[ncomp];
    
  variable ii, p;
  _for ii ( 0, ncomp-1 ){ % loop over all components of the current dataset
    p = get_params( cnames[ii]+"*" );
    % find the indices of all norm parameter of the current component
    normid[ii] = where( array_map( Integer_Type, &get_struct_field, p, "is_a_norm" ) );
    normid[ii] = array_map( Integer_Type, &get_struct_field, p[normid[ii]], "index" );
  }

  %% unset 'set_par_fun' of norm parameter, otherwise it is not possible to set those Zero later
  array_map( Void_Type, &set_par_fun, array_flatten(normid), NULL );

  %% make sure min/max range of norm parameters includes 0!
  p = get_params( array_flatten(normid) );
  array_map( Void_Type, &set_struct_field, p, "min", 0 );
  set_params(p);
  
  %% number of norms per component
  variable nnorm = array_map( Integer_Type , &length, normid ); 

  %% Prepare structure containing model component data
  variable MC = struct_array( length(where(nnorm)),
			      struct{
				name,
				nnorm,
				bin_lo,
				bin_hi,
				value,
				err = NULL				
				}
			    );

  variable nind = where(nnorm);
  variable f;
  _for ii ( 0, length(MC)-1 ){
    MC[ii].name = cnames[nind[ii]];
    MC[ii].nnorm = nnorm[nind[ii]];

    %% store parameter
    p = get_params;
   
    %% set all norms to ZERO but that/those of the current component
    array_map( Void_Type, &set_par, array_flatten( array_remove(normid,nind[ii]) ), 0 );

    %% obtain model component data
    () = eval_counts();
    f = @get_model_fct(id);
    MC[ii] = struct_combine( MC[ii], f );
    
    %% reset parameter values
    set_params(p);
  }
  

  % reverse all changes
  set_params( PARAMETERS ); % IMPORTANT execute with the same included/excluded datasets

  include( all_data );
  exclude( exc_data );

  return MC;
}
