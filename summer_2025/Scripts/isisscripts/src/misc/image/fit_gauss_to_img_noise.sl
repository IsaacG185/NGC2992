define fit_gauss_to_img_noise ()
%!%+
%\function{fit_gauss_to_img_noise}
%\synopsis{fits a gaussian profile to the distribution of pixel values}
%\usage{mu,sigma = fit_gauss_to_img_noise(\code{img})}
%\qualifiers{
%\qualifier{grid_scale [="log"]}{change between fitting on "lin" or "log" grid}
%\qualifier{cut_nsig [=NULL]}{set to \code{N} in order to ignore values above
%                           \code{N} sigma after the first iteration}
%\qualifier{keep_data}{do not delete loaded data after fitting}
%}
%\description
%    This function fits a Gaussian profile to the distribution of
%    pixel values in an image (arrays of different dimensions can be
%    given) and returns the center \code{mu} and the width \code{sigma} of the
%    best fit profile.
%    If the majority of pixels in the image include only noise values,
%    the obtained \code{mu} and \code{sigma} values characterize the mean value
%    (base level) of the noise and its amplitude.
%
%    NOTE: If the data is kept and further fitting is performed, the following
%    relation has to be considered \code{mu=get_par("gauss(1).center")+min(img)-1e-5}
%    (necessary to provide a proper grid for fitting).
%\example
%    img = grand(500*500);    % image with random numbers around 0 with sigma=1
%    reshape(img,[500,500]);
%    (mu,sigma) = fit_gauss_to_img_noise (img);
%\seealso{plot_vlbi_map}
%!%-
{
  switch(_NARGS)
  { case 1:   variable map = (); }
  { help(_function_name()); return; }

  variable ad = all_data;
  variable ff = get_fit_fun();
  variable fs = get_fit_statistic();
  set_fit_statistic("chisqr");
  exclude(all_data);
  variable lo,hi;
  variable map_min = min(map);
  variable map_max = max(map);
  variable len = length(map);
  variable grid_len   = qualifier("grid_len",nint(sqrt(len)));
  variable grid_scale = qualifier("grid_scale","log");
  if (grid_scale == "lin")
    (lo,hi) = linear_grid( 1e-5 , map_max+(1e-5-map_min) , grid_len);
  else
    (lo,hi) = log_grid( 1e-5 , map_max+(1e-5-map_min) , grid_len);
  variable nr = histogram ( map-map_min + 1e-5 , lo,hi);
  variable px_dat = define_counts(lo , hi , nr , (nr)^(0.5)+1);
  fit_fun("gauss");
  set_par("gauss(1).center", median( map[where(isnan(map)==0)]-map_min + 1e-5) , 0 , -hi[-1], 5*hi[-1] ); % assuming mu is not far from value range
  set_par("gauss(1).area"  , 0.99*len                , 0 , 1   , 2*len);
  set_par("gauss(1).sigma" , quantile (0.84, _reshape(map[where(isnan(map)==0)]-map_min+1e-5,length(dup)))
	  - get_par("gauss(1).center") , 0 , 1e-10, hi[-1] ); % assuming sigma is smaller than value range
  set_fit_method("subplex");
  ()=fit_counts;
  set_fit_method("mpfit");
  variable cut_nsig = qualifier ("cut_nsig",NULL);
  if (cut_nsig != NULL ) {ignore (px_dat, get_par("gauss(1).center")+cut_nsig*get_par("gauss(1).sigma"));}
  ()=fit_counts;
  variable mu  = get_par("gauss(1).center") + map_min - 1e-5 ;
  variable sig = get_par("gauss(1).sigma");
  ifnot (qualifier_exists("keep_data"))
  {
    delete_data(px_dat);
    if (ad != NULL) include(ad);
    if (ff != NULL) fit_fun(ff);
    set_fit_statistic (fs);
  }
  return mu , sig;
}
