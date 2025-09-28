%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_combined_data_model_residuals()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_combined_data_model_residuals}
%\synopsis{returns these 3 structures for a combination of data sets}
%\usage{(d, m, r) = get_combined_data_model_residuals(Integer_Type id[]);}
%\description
%   All \code{d}, \code{m} and \code{r} are \code{bin_lo, bin_hi, value, err} structures.
%   \code{d} and \code{m} are the sum of data and model counts of all data sets,
%   rebinned to the grid of the first data set id[0].
%   \code{d.err} is calculated from quadratic error propagation.
%   \code{r.value = (d.value-m.value)/d.err} contains the residuals
%   unless the \code{ratio} qualifier is set (see below).
%\qualifiers{
%\qualifier{ratio}{use ratio-residuals \code{r.value = d.value/m.value}}
%}
%\seealso{get_data_counts, get_model_counts, rebin}
%!%-
{
  if(_NARGS!=1)
  { help(_function_name()); return;
  }
  variable ids = (); ids = [ids];
  variable data = get_data_counts(ids[0]);
  variable model = get_model_counts(ids[0]);
  variable i;
  _for i (1, length(ids)-1, 1)
  { variable d = get_data_counts(ids[i]);
    variable m = get_model_counts(ids[i]);
    data.value += rebin(data.bin_lo, data.bin_hi,  d.bin_lo, d.bin_hi, d.value);
    data.err = sqrt( data.err^2 + rebin(data.bin_lo, data.bin_hi,  d.bin_lo, d.bin_hi, d.err^2) );
    model.value += rebin(model.bin_lo, model.bin_hi,  m.bin_lo, m.bin_hi, m.value);
  }
  variable res = @data;
  if(qualifier_exists("ratio"))
    res.value = data.value/model.value,
    res.err = data.err/model.value;
  else
    res.value = (data.value-model.value)/data.err,
    res.err = res.value*0+1;
  return (data, model, res);
}
