%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_data_counts_with_tot_err()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_data_counts_with_tot_err}
%\synopsis{returns spectral data, taking systematic errors into account}
%\usage{Struct_Type data = get_data_counts_with_tot_err(Integer_Type id);}
%\description
%    \code{data.err = sqrt( stat_err^2 + [sys_err_frac * data.value]^2 );}
%\seealso{get_data_counts, get_sys_err_frac}
%!%-
{
  variable id;
  switch(_NARGS)
  { case 1: id = (); }
  { help(_function_name()); return; }

  variable dc = get_data_counts(id);
  variable sys_err_frac = get_sys_err_frac(id);
  if(length(sys_err_frac)>0)
    dc.err = sqrt( dc.err^2 + (sys_err_frac*dc.value)^2 );
  return dc;
}
