define MAXI_lightcurve()
%!%+
%\function{MAXI_lightcurve}
%\usage{Struct_Type MAXI_lightcurve(String_Type source);}
%\description
%    The returned structure has the following fields:\n
%    - \code{time}: Modified Julian Date\n
%    - \code{rate}  , \code{err}  :  2-20 keV light curve [c/s/cm^2]\n
%    - \code{rate_a}, \code{err_a}:  2- 4 keV light curve [c/s/cm^2]\n
%    - \code{rate_b}, \code{err_b}:  4-10 keV light curve [c/s/cm^2]\n
%    - \code{rate_c}, \code{err_c}: 10-20 keV light curve [c/s/cm^2]\n
%\seealso{http://maxi.riken.jp/top/index.php?cid=000000000036, http://ads.nao.ac.jp/abs/2009PASJ...61..999M}
%!%-
{
  variable source;
  switch(_NARGS)
  { case 1: source = (); }
  { help(_function_name()); return; }

  variable path_to_data = NULL;
  try {
  foreach path_to_data ([local_paths.MAXI_lightcurves])
    if(stat_file(path_to_data)!=NULL) { break; }
  } catch NotImplementedError: { vmessage("warning (%s): local_paths.MAXI_lightcurves not defined",_function_name()); };
  if(_isnull(path_to_data) || stat_file(path_to_data)==NULL)
  { vmessage("error (%s): no path to MAXI lightcurves found", _function_name());
    return NULL;
  }

  variable lc = struct { time, rate, err, rate_a, err_a, rate_b, err_b, rate_c, err_c };
  set_struct_fields(lc, readcol(path_to_data+source+".txt", 1, 2,3, 4,5, 6,7, 8,9));
  return lc;
}
