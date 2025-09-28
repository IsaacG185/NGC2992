%%%%%%%%%%%%%%%%%%%%
define get_residuals()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_residuals}
%\synopsis{calculates (data-model)/error residuals}
%\usage{Struct_Type res = get_residuals(Integer_Type id[]);}
%\description
%    Each \code{res[i]} is a \code{{ bin_lo, bin_hi, value, err }} structure
%    where \code{res[i].value} contains the (data counts - model counts)/error
%    residuals obtained for the data set \code{id[i]}.\n
%    If only a scalar \code{id} is given, only a single structure is returned.
%\qualifiers{
%\qualifier{noticed}{restrict to noticed bins}
%\qualifier{keV}{convert Angstrom-bins to keV-bins}
%}
%\seealso{get_data_counts, get_model_counts, get_ratio}
%!%-
{
  variable ids;

  switch(_NARGS)
  { case 1: ids = (); }
  { help(_function_name()); return; }

  variable id, res = Struct_Type[0];
  foreach id (ids)
  { variable data = get_data_counts(id);
    variable model = get_model_counts(id);
    data.value = (data.value-model.value)/data.err;
    data.err = data.err*0+1;
    if(qualifier_exists("noticed"))
      struct_filter(data, get_data_info(id).notice_list);
    if(qualifier_exists("keV"))
      data = _A(data);
    res = [res, data];
  }
  if(length(res)==1) { return res[0]; } else { return res; }
}
