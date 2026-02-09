%%%%%%%%%%%%%%%%%%%%%%%%
define hardnessratio_from_dataset()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{hardnessratio_from_dataset}
%\synopsis{calculates hardnessratios of the current model}
%\usage{Struct_Type hardnessratio_from_dataset(
%                  Integer_Type data-id, Integer_Type[2] soft_ch, hard_ch
%                );}
%\qualifiers{
%\qualifier{soft_en}{Double_Type[2]}
%\qualifier{hard_en}{Double_Type[2]}
%\qualifier{get_counts}{set to '&get_model_counts' if needed, default: get_data_counts}
%\qualifier{subtract_background}{subtract background from data. Only possible if get_counts is not set.}
%    additional qualifiers are passed to 'hardnessratio'
%}
%\description
%    - at least one dataset has to be defined (load_data)
%    - if energy bands are given, channels have to be set to [0,0]
%    - returns a structure containing: sc: soft counts, hc: hard counts, ratio: hardnessratio, err: error
%\seealso{hardnessratio}
%!%-
{
  variable id, soft_ch, hard_ch;
  switch (_NARGS)
    { case 3: (id,soft_ch,hard_ch) = (); }
    { help(_function_name()); return; }

  % check input
  if (length(soft_ch) != 2 || length(hard_ch) != 2) {
    vmessage("error (%s): channels must be arrays with 2 elements", _function_name);
    return;
  }
  if (length(id) != 1 || typeof(id) != Integer_Type) {
    vmessage("error (%s): 'data-id' must be a single integer", _function_name);
    return;
  }

  % get data or model counts
  variable getcounts = qualifier("get_counts", &get_data_counts);
  variable cts = _A(@getcounts(id));

  if (qualifier("subtract_background",1)) {
      if (qualifier_exists("get_counts")) {
	  vmessage("Cannot use subtract_background and get_counts qualifiers simultaneously", _function_name);
      }
      variable scale=get_back_data_scale_factor(id);
      variable backdata=get_back_data(id);

      cts.value-=scale*backdata;
  }


  % get the channels if energies are given
  % definition of no channels given: all array entries = 0
  if (all(soft_ch == 0) && all(hard_ch == 0)){
    % qualifiers have to be given in this case!
    variable soft_en = qualifier("soft_en", NULL);
    %variable mid_en = qualifier("mid_en", NULL);
    variable hard_en = qualifier("hard_en", NULL);
    if (soft_en == NULL || hard_en == NULL){
      vmessage("error (%s): energy-qualifiers have to be provided for each band", _function_name);
      return;
    }
    if (length(soft_en) != 2 || length(hard_en) != 2){
      vmessage("error (%s): energy-qualifiers must be arrays with 2 elements", _function_name);
      return;
    }
    % get corresponding channels
    soft_ch[0] = wherefirst(cts.bin_lo >= soft_en[0]);
    soft_ch[1] = wherelast(cts.bin_hi <= soft_en[1]);
    hard_ch[0] = wherefirst(cts.bin_lo >= hard_en[0]);
    hard_ch[1] = wherelast(cts.bin_hi <= hard_en[1]);
  }

  % sum counts up  
  variable sc = sum(cts.value[[soft_ch[0]:soft_ch[1]]]);
  variable hc = sum(cts.value[[hard_ch[0]:hard_ch[1]]]);
  variable ratio,err;
  (ratio,err) = hardnessratio(sc, hc;; __qualifiers);

  % return hardness,sc,hc
  variable hr=struct{sc=sc,hc=hc,ratio=ratio,err=err};
  %return (hardnessratio(sc, hc;; __qualifiers));%,sc,hc);
  return hr;
}
