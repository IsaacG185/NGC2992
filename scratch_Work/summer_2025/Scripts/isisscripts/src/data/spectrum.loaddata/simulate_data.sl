%%%%%%%%%%%%%%%%%%%%
define simulate_data()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{simulate_data}
%\synopsis{fakes a spectrum}
%\usage{Integer_Type id = simulate_data(String_Type RSPfile, Double_Type exposure);}
%\description
%    The currently defined fit-function is used to fake the spectrum.
%\seealso{fakeit}
%!%-
{
  variable RMFfile, exposure;
  switch(_NARGS)
  { case 2: (RMFfile, exposure) = (); }
  { help(_function_name()); return; }

  variable data_index;
  if(all_data==NULL) { data_index = 1; } else { data_index = max(all_data)+1; }
  variable r = load_rmf(RMFfile);
  variable a = factor_rsp(r);
  assign_arf(a, data_index);
  assign_rmf(r, data_index);
  set_arf_exposure(a, exposure);
  fakeit;
  return data_index;
}
