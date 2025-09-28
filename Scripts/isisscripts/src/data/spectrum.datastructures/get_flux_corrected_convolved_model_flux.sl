%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_flux_corrected_convolved_model_flux(id)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_flux_corrected_convolved_model_flux}
%\synopsis{computes the model flux which can be compared with a flux-corrected spectrum}
%\usage{Struct_Type get_flux_corrected_convolved_model_flux(Integer_Type hist_index)}
%\description
%    The flux-corrected convolved model flux is computed as\n
%      \code{            int K(R(h,E), A(E), S(E)) dE  }\n
%      \code{ F(h)  =  --------------------------------} ,\n
%      \code{            int K(R(h,E), A(E),  1  ) dE  }\n
%    where \code{S(E)} is the flux model, \code{A(E)} is the effective area (the ARF),
%    \code{R(h,E)} is the redistribution function (the RMF),
%    and the kernel \code{K} defaults to \code{K(R,A,S) = R*A*S}.
%
%    The flux-corrected convolved model fluxes is defined in such a way
%    that a folded model is "unfolded" in the same way as the data are
%    by virtue of \code{flux_corr}. It can thus be compared with flux-corrected data.
%\seealso{flux_corr, get_model_counts, get_model_flux, get_convolved_model_flux}
%!%-
{
  variable data_info = get_data_info(id);
  variable FitVerbose = Fit_Verbose;

  rebin_data(id, 0);
  Fit_Verbose = -1;
  ()=eval_counts;
  variable m = get_model_counts(id);
  m.err = sqrt(m.value);
  variable new_id = define_counts(m);
  set_data_exposure(new_id, get_data_exposure(id));
  if(length(data_info.arfs))  assign_arf(data_info.arfs[0], new_id);  % How to treat multiple ARFs?
  if(length(data_info.rmfs))  assign_rmf(data_info.rmfs[0], new_id);  % How to treat multiple RMFs???
  % TODO: worry about background
  % TODO: probably insert  rebin_data(new_id, data_info.rebin);
  flux_corr(new_id);
  m = get_data_flux(new_id);
  delete_data(new_id);

  rebin_data(id, data_info.rebin);
  ignore(id); notice_list(id, data_info.notice_list);
  Fit_Verbose = FitVerbose;
  return m;
}
