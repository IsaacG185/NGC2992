define init_jet_fit()
%!%+
%\function{init_jet_fit}
%\synopsis{inititialize the fit function for the speed of jet components}
%\usage{init_jet_fit (Ref_Type jet_component_structure);}
%\qualifiers{
%\qualifier{pa}{[=90] position angle of the jet in degrees (required)}
%\qualifier{recalc_distance}{set to 1 in order to recalculate the distance
%                 of each component based on deltax and deltay}
%}
%\description
%    This function initializes the fit function \code{jet_speed}, which
%    can fit a linear function of the form:
%        dist (t)  = (t - t_0) * v
%    to each component, where t_0 is the ejection time of the component in
%    MJD and v is its speed in mas/year. For each epoch an offset (in mas)
%    can be fitted, allowing to correct for shifts of the image (along the
%    line in which the distance is measured).
%    For the initialization a structure with the name "jet_speed_struct"
%    is REQUIRED, which has to contain the fields \code{time} (date of epoch in MJD),
%    \code{distance} (in mas),  \code{derr} (uncertainty of the distance), and
%    \code{component} (integer values identifying the components).
%    The function extends this structure, and sets the initialized fit function.
%\example
%    variable jet_speed_struct = struct {
%      mjd       = [55500, 55550, 55600, 55650, 55500, 55600, 55650],
%      deltax    = [  0.2,   0.4,   0.5,   0.7,   0.6,   1.2,   1.5],
%      deltay    = [  0.0,   0.0,   0.0,   0.0,   0.0,   0.0,   0.0],
%      derr      = [ 0.01,  0.05,  0.01,   0.1,  0.02,   0.1,   0.1],
%      component = [    1,     1,     1,     1,     2,     2,     2],
%      };
%    init_jet_fit(&jet_speed_struct; pa = 90);
%    ()=fit_counts;
%    list_par;
%    plot_jet_speed ( jet_speed_struct );
%\seealso{plot_jet_speed}
%!%-
%
{
  % use a pointer to the jet_speed_struct, this allows the function to
  % change the structure permanently (add fields)
  variable jet_speed_struct_pointer;
  variable pa = qualifier("pa",90.);
  variable recalc_dist = qualifier("recalc_distance",0);
  
  switch(_NARGS)
  { case 1: jet_speed_struct_pointer = ();}
  { help(_function_name()); return; }

  % check if required fields are available and add further required ones
  variable req_fields = ["mjd", "derr", "comp", "deltax", "deltay"];
  variable fn         = get_struct_field_names ( @jet_speed_struct_pointer );
  variable f;
  foreach f (req_fields) if (all ( f != fn)) {
    vmessage("error: %s\tprovided structure does not include field: %s", _function_name, f);
    return;
  }
  variable length_sp_str = length((@jet_speed_struct_pointer).mjd);
  variable used_fields   = ["xshift","yshift","t0", "speed"];
  foreach f (used_fields) if (all ( f != fn)) {
    @jet_speed_struct_pointer = struct_combine (@jet_speed_struct_pointer, f);
    set_struct_field (@jet_speed_struct_pointer, f, Double_Type[length_sp_str]);
%    vmessage("%s: Adding field %s to jet_speed_struct",_function_name(),f);
  }
  if (all ( "distance" != fn) or recalc_dist) { @jet_speed_struct_pointer =
      struct_combine (@jet_speed_struct_pointer, struct{distance = hypot((@jet_speed_struct_pointer).deltax, (@jet_speed_struct_pointer).deltay)}); }
  % if (all ( "x" != fn)) { @jet_speed_struct_pointer =
  %     struct_combine (@jet_speed_struct_pointer, struct{x =get_struct_field (@jet_speed_struct_pointer,"distance")*sin(pa*PI/180) }); }
  % if (all ( "y" != fn)) { @jet_speed_struct_pointer =
  %     struct_combine (@jet_speed_struct_pointer, struct{y =get_struct_field (@jet_speed_struct_pointer,"distance")*cos(pa*PI/180) }); }

  % check if required structure is readable in the namespace for the function
  % MB: this could probably improved. If the variable is defined within a script
  %     then jss_status=-2 and it is seen by the function, if defined in the
  %     interactive shell jss_status=0 and it works in namespace "isis".
  %     Global variables???
  variable jss_status = is_defined("jet_speed_struct");
  if (jss_status == 0){
    try { eval("if(typeof(jet_speed_struct)==Struct_Type and Fit_Verbose == 1) message(\"jet_speed_struct initialized correctly\");","isis");}
    catch AnyError: { message("error: init_jet_fit!\n\trequired structure with name jet_speed_struct not initilized"); return; }
    ; % to terminate the try-block
  }

  % initialize the fit function
  variable def_str = `define jet_speed_fit (bin_lo, bin_hi, par) % "private define" causes namespace problem?!
{
  variable pa = par[0];
  variable sin_pa = sin(pa*PI/180);
  variable cos_pa = cos(pa*PI/180);
  variable t_indx   = unique( jet_speed_struct.epoch );
  variable n_epochs = length (t_indx);
  variable used_cmp = where(jet_speed_struct.comp > 0);
  variable cmpindx  = used_cmp[unique(jet_speed_struct.comp[used_cmp])];
  variable n_comps = length ( cmpindx );
  variable i,l;
  _for i(0, n_epochs-1, 1) {jet_speed_struct.xshift[where(jet_speed_struct.epoch == jet_speed_struct.epoch[t_indx[i]])] =
                            sin_pa*par[2*i+1] + cos_pa*par[2*i+2];}
  _for i(0, n_epochs-1, 1) {jet_speed_struct.yshift[where(jet_speed_struct.epoch == jet_speed_struct.epoch[t_indx[i]])] =
                            cos_pa*par[2*i+1] - sin_pa*par[2*i+2];}
  _for i(0, n_comps-1, 1)
    {
      l = where(jet_speed_struct.comp == jet_speed_struct.comp[cmpindx[i]]);
      jet_speed_struct.speed[l] = par[1+2*n_epochs+ 2*i +1];
      jet_speed_struct.t0   [l] = par[1+2*n_epochs+ 2*i ];
    }
  variable dist = (jet_speed_struct.mjd - jet_speed_struct.t0)*0.002737803091986241*jet_speed_struct.speed ;
  variable ret = hypot( sin_pa*dist + jet_speed_struct.xshift, cos_pa*dist + jet_speed_struct.yshift)*
         sign(atan2(sin_pa*dist + jet_speed_struct.xshift, cos_pa*dist + jet_speed_struct.yshift));
  return ret[used_cmp];
  % 0.002737803091986241 is one day in units of sidereal years
}

private define jet_speed_default(i)
{ switch(i)
`;
  variable sin_pa = sin(pa*PI/180);
  variable cos_pa = cos(pa*PI/180);
  variable n_epochs = length (unique( (@jet_speed_struct_pointer).epoch));
  variable epindx  = unique((@jet_speed_struct_pointer).epoch);
  epindx = epindx[array_sort ( (@jet_speed_struct_pointer).epoch[epindx] )];
  variable used_cmp = where((@jet_speed_struct_pointer).comp > 0);
  variable cmpindx  = used_cmp[unique((@jet_speed_struct_pointer).comp[used_cmp])];
  variable n_comps = length ( cmpindx );
  variable j;
  def_str = def_str + sprintf(" { case 0: return (%.6f , 1, -180,  180 ); }\n",pa);
  _for j(0,n_epochs-1,1) def_str = def_str + sprintf(" { case %d: return (%.4f , 1, -10,  10 ); }\n { case %d: return (%.4f , 1, -10,  10 ); }\n",
						     2*j+1, sin_pa*(@jet_speed_struct_pointer).xshift[epindx[j]] + cos_pa*(@jet_speed_struct_pointer).yshift[epindx[j]],
						     2*j+2, -cos_pa*(@jet_speed_struct_pointer).xshift[epindx[j]] + sin_pa*(@jet_speed_struct_pointer).yshift[epindx[j]]);
  _for j(0,n_comps-1,1) def_str = def_str +
    sprintf(" { case %d: return (5e4 , 0, 4e4, 7e4 ); }\n { case %d: return (0.0 , 0, -20,  20 ); }\n",j*2 + 2*n_epochs+1,j*2 + 2*n_epochs+2);
  def_str = def_str+
    `}

add_slang_function("jet_speed", ["pos_angle [deg]",
`;
  _for j(0,n_epochs-1,1) def_str = def_str + sprintf(" \"shft_ep_%s [mas]\",\n \"shftorth_ep_%s [mas]\",\n",
						     string((@jet_speed_struct_pointer).epoch[epindx[j]]),dup);
  _for j(0,n_comps-1,1) def_str = def_str +
    sprintf(" \"t0_%s [MJD]\",\n \"v_%s [mas/yr]\",\n",string((@jet_speed_struct_pointer).comp[cmpindx[j]]),dup);
  def_str = def_str+
    `  ]);
set_param_default_hook("jet_speed", "jet_speed_default");
`;

  if (jss_status == 0) eval(def_str, "isis");
  else eval(def_str);

  % define the "counts"
  variable jss_id =define_counts ([1:length((@jet_speed_struct_pointer).comp)], dup+1,
				  (@jet_speed_struct_pointer).distance, (@jet_speed_struct_pointer).derr);
  ignore(jss_id);
  notice_list(jss_id , used_cmp);

  fit_fun("jet_speed(1)");
}
