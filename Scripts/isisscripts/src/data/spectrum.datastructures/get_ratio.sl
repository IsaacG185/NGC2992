%%%%%%%%%%%%%%%%
define get_ratio()
%%%%%%%%%%%%%%%%
%!%+
%\function{get_ratio}
%\synopsis{calculates data/model ratios}
%\usage{Struct_Type rat[] = get_ratio(Integer_Type id[]);}
%\description
%    Each \code{rat[i]} is a \code{{ bin_lo, bin_hi, value, err }} structure
%    where \code{rat[i].value} contains the (data counts)/(model counts)
%    ratios obtained for the data set \code{id[i]}.\n
%    If only a scalar \code{id} is given, only a single structure is returned.
%\seealso{get_data_counts, get_model_counts, get_residuals}
%!%-
{
  variable bin_lo, bin_hi, data, data_err, model;
  variable rat = struct { bin_lo, bin_hi, value, err };
  switch(_NARGS)
  { case 1:
      variable ids = (), id, rats = Struct_Type[0];
      foreach id ([ids]);
      { data = get_data_counts(id);
        model = get_model_counts(id);
        data.value = data.value/model.value;
        data.err = data.err/model.value;
        rats = [rats, data];
      }
      if(length(rats)==1) { return rats[0]; } else { return rats; }
  }
  { case 5:
      (bin_lo, bin_hi, data, data_err, model) = ();
      rat.bin_lo = bin_lo;
      rat.bin_hi = bin_hi;
      rat.value = data/model;
      rat.err = data_err/model;
      return rat;
  }
  { case 8:
      variable data1, data1_err, model1, data2, data2_err, model2;
      (bin_lo, bin_hi, data1, data1_err, model1, data2, data2_err, model2) = ();
      rat.bin_lo = bin_lo;
      rat.bin_hi = bin_hi;
      rat.value = (data1+data2)/(model1+model2);
      rat.err = sqrt(data1_err^2+data2_err^2)/(model1+model2);
      return rat;
  }
  {%else:
      message("usage: rats = get_data_model_ratio(ids); % ids may be an array");
      message("   or: rats = get_data_model_ratio(bin_lo, bin_hi, data, data_err, model");
      return NULL;
  }
}
