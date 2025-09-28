%%%%%%%%%%%%%%%%%%%%%%%%%
define factorized_arf_rmf(arf, rmf)
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{factorized_arf_rmf}
%\synopsis{changes an ARF/RMF pair into factorized ARF/normalized RMF}
%\usage{(newARF, newRMF) = factorized_arf_rmf(ARF, RMF);}
%\seealso{factor_rsp}
%!%-
{
  variable arf_factor = factor_rsp(rmf);
%  ()=printf("# max arf_factor = %g\n", max(get_arf(arf_factor).value));
  if(arf==NULL)
  { arf = arf_factor; }
  else
  { variable arfData = get_arf(arf);
    arfData.value *= get_arf(arf_factor).value;
    delete_arf(arf_factor);
    put_arf(arf, arfData);
  }
  return (arf, rmf);
}
