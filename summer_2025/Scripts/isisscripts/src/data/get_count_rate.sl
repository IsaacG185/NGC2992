%%%%%%%%%%%%%%%%
define cut_dataset_range()
%%%%%%%%%%%%%%%%
%!%+
%\function{cut_dataset_range}
%
%\synopsis{Get get_data_counts-struct clipped to energy range}
%\usage{Struct_Type = cut_dataset_range (hist_index , E_min , E_max);}
%\description
%       This function will return a structre just as get_data_counts
%       but clipped to the energy range from E_min up to E_max (energies in keV).
%\example
%       isis>id = load_data("data.fits");
%       isis>variable cut_spectrum = cut_dataset_range (id , 0.2 , 2.3);
%\seealso{get_data_counts}
%!%-
{
    variable setid , e_min , e_max;
    switch(_NARGS)
    { case 3: (setid , e_min , e_max) = (); }
    { return help(_function_name()); }

    variable data = _A(get_data_counts(setid));
    variable ind = where(data.bin_lo >= e_min and data.bin_hi < e_max);
    variable cnt_kev_flt = struct_filter(data , ind ; copy);
    return cnt_kev_flt;

}

private define __counts_from_dataset(id) {
  variable dat = _A(get_data_counts(id));
  variable E_range = qualifier("E_range", NULL);
  if ( E_range != NULL ) {
    variable ind = where(dat.bin_lo >= E_range[0] and dat.bin_hi <= E_range[1]);
    struct_filter(dat, ind);
  }
  return sum(dat.value);
}

private define __get_background_counts(id) {
  variable back_id = -1;
  try {
    back_id = load_data(get_data_info(id).bgd_file);
    if ( back_id == -1 ) {
      throw RunTimeError, sprintf("Something went wrong loading %s", get_data_info(id).bgd_file);
    }
    return __counts_from_dataset(back_id; E_range = qualifier("E_range", NULL));
  } finally {
    if ( back_id != -1 ) {
      delete_data(back_id);
    }
  }
}


%%%%%%%%%%%%%%%%
define get_count_rate(dset)
%%%%%%%%%%%%%%%%
%!%+
%\function{get_count_rate}
%
%\synopsis{Get different variants of countrates and counts}
%\usage{Double_Type CR = get_count_rate (hist_index);
%or
%Double_Type (CR , CR_err) = get_count_rate (hist_index ; err);}
%\description
%
%       Use this function to retrive background subtracted
%       countrates (default), countrates, background rates, or counts
%       and respective uncertainties for spectra that have been loaded.
%       Errors are estimated using the methode described by Gehrels 1986,
%       see \code{gehrels_error} for details. If the err_asym qualifier is not
%       specified the average of both errors is returned. If it is, an array
%       is returned which contains the lower error in the first entry and the
%       upper error as the second entry. The default confidence level for the
%       error is 0.9, but can be changed using the err_conf qualifier within
%       the possibilities offered by \code{gehrels_error}.
%
%\qualifiers{
%    \qualifier{tex}{additional TeXoutput of CRs, choose this if you need
%         values and uncertainties in LaTeX-format (only printed in terminal)}
%    \qualifier{bkg}{0 (default: background subtracted CR), 1 (count rates),
%         2 (background count rate)}
%    \qualifier{fake}{Set this qualifier if you have a faked spectrum and a
%          faked background (which has not been deleted!);
%          Assumption: hist_index(bkg) = hist_index(dset) +1 !!}
%    \qualifier{fake_expo}{set exposure time of fake spectrum, in case
%               set_data_exposure was not used when faking}
%    \qualifier{bkg_id}{set hist_index(bkg) if background is loaded or faked, if set to 0, no background
%            is subtracted. Will overrule the id-setting made by fake-qualifier}
%    \qualifier{E_range}{Set this qualifier if you want the countrate within
%             a certain energy range. Use E_range = [E_min , E_max].
%             If not given full energy range is used. (Energy in keV!)}
%    \qualifier{counts}{if present function will only return counts instead
%             of countrates}
%    \qualifier{err}{if present function will return CR and
%             respective uncertainty}
%    \qualifier{err_conf}{Confidence limit for the error estimation}
%    \qualifier{err_asym}{Return asymmetric errorbars as an array}
%}
%
%\example
%       isis> xray = load_data("data.pha");
%       isis> variable countrate = get_count_rate (1 ;tex, bkg=1 , E_range = [0.2 , 2.3]);
%       isis> variable counts , counts_err;
%       isis> (counts , counts_err) = get_count_rate (1 ;tex, bkg=1 , E_range = [0.2 , 2.3] , counts , err);
%
%\seealso{get_data_counts; TeX_value_pm_error; cut_dataset_range;}
%!%-
{
  variable E_range = qualifier("E_range", NULL);
  variable bkg = qualifier("bkg", 0);
  variable counts_data, back_file, counts_back, counts_err,
	   counts_back_err, counts_sub, counts_sub_err, expos;
  variable bkg_id = qualifier("bkg_id", NULL);
  variable err = qualifier_exists("err");
  variable err_conf = qualifier("err_conf", 0.9);
  variable err_asym = qualifier_exists("err_asym");

  if ( qualifier_exists("fake") || qualifier_exists("bkg_id") ) {
    back_file = qualifier("bkg_id", dset + 1);
    if (back_file == 0) {
      counts_back = 0.0;
    } else {
      counts_back = __counts_from_dataset(back_file ; E_range = E_range);
    }
  } else {
    counts_back = __get_background_counts(dset; E_range = E_range);
  }

  counts_back *= get_data_backscale(dset) / get_back_backscale(dset);
  counts_data = __counts_from_dataset(dset ; E_range = E_range);
  counts_sub = counts_data - counts_back;

  if ( err ) {
    counts_back_err = gehrels_error(counts_back, err_conf);
    counts_err = gehrels_error(counts_data, err_conf);
    counts_sub_err = sqrt(counts_err^2 + counts_back_err^2);
  }

  ifnot ( qualifier_exists("counts") ) {
    expos = qualifier("fake_expo", get_data_exposure(dset));
    counts_data /= expos;
    counts_back /= expos;
    counts_sub /= expos;
    if ( err ) {
      counts_err /= expos;
      counts_back_err /= expos;
      counts_sub_err /= expos;
    }
  }

  variable ret, ret_err;
  if ( bkg == 0 ) {
    ret = counts_sub;
    ret_err = counts_sub_err;
  } else if ( bkg == 1 ) {
    ret = counts_data;
    ret_err = counts_err;
  } else if ( bkg == 2 ) {
    ret = counts_back;
    ret_err = counts_back_err;
  } else {
    throw UsageError, "Wrong Input for Bkg qualifier!";
  }

  if ( qualifier_exists("tex") ) {
    vmessage(TeX_value_pm_error(ret, ret-ret_err, ret+ret_err));
  }
  if ( err ) {
    ifnot ( err_asym ) {
      ret_err = 0.5 * sum(ret_err);
    }
    return ret, ret_err;
  }
  return ret;
}
