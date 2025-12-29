define ridge_line ()
%!%+
%\function{ridge_line}
%\synopsis{calculates the ridge line}
%\usage{Struct_Type ridge_line = ridge_line (Array_Type \code{img})}
%\qualifiers{
%\qualifier{ref_pix}{[=[y,x]] starting pixel of the ridge line (index convention: img[y,x])
%                 brightest pixel used by default}
%\qualifier{dr}{[=0.8] step size in pixels}
%\qualifier{steps}{number of steps (default is maximal length of dimensions)}
%}
%\description
%    This function calculates the ridge line in a (jet) image.
%    Starting from the brightest point (assumed to be the core),
%    or a point specified by the \code{ref_pix} qualifier, the ridge
%    line is calculated. The ridge line is given in different ways:
%    The brightest points at each distance (in steps of \code{dr} pixels)
%    from the reference pixel, are given by the fields \code{peak_x} and
%    \code{peak_y} of the returned structure. The field \code{peak_flux}
%    contains the corresponding pixel value.
%    As an alternative to the peak ridge line, a flux-centered ridge
%    line is provided. The fields \code{flux_cent_x} and \code{flux_cent_y}
%    specify the points, at which the integrated flux (along the same
%    distance from the refence pixel) to the left is equal to that on
%    the right side.
%\notes
%    - elliptical beams will create artifacts (wiggles in the ridge line),
%      in order to avoid this effect, obtain the ridge line from an
%      image convolved with a circular beam
%    - valid points can be obtained, e.g., by filtering the radii at which
%      the peak flux exceeds the map's noise level (fit_gauss_to_img_noise)
%    - currently no smoothing of the points is done (e.g., fit spline to
%      ridge line)
%    - there can be problems if the radius (used for ridge line calculation)
%      lies completely within the jet/beam, \code{ref_pix} qualifier can be
%      used to select another starting point (on the "jet axis")
%\example
%    variable mdl = struct {
%                   flux   = [0.3, 0.5, 0.1,  0.2, 0.3,  0.9,    3],
%                   ra     = [3.7, 2.8, 2.2,  1.4, 0.9,  0.5,    0],
%                   dec    = [1.2, 0.8, 0.8,  0.7, 0.6,  0.4,    0],
%                   smajor = [0.4, 0.2, 0.1, 0.03, 0.1, 0.01, 0.01],
%                   sminor = [0.4, 0.2, 0.1, 0.03, 0.1, 0.01, 0.01],
%                   pang   = [0,      0,   0,    0,   0,    0,    0] };
%    variable beam = [0.3, 0.3, 0.7];
%    variable img = radio_mod2img (mdl, beam);
%    variable r = ridge_line (img.img;);
%    struct_filter(r, where(r.peak_value>1e-4));
%    plot_image (log(img.img+1e-4));
%    color(4);  oplot(r.peak_x,r.peak_y);
%    color(13); oplot(r.flux_cent_x,r.flux_cent_y);
%\seealso{fit_gauss_to_img_noise, radio_mod2img, plot_vlbi_map}
%!%-
{
  switch(_NARGS)
  { case 1: variable img = (); }
  { help(_function_name()); return; }
  
  % reduce to 2D image (remove difmap FREQ and STOKES)
  variable shape = array_shape(img);
  shape = shape[ where( shape > 1 ) ];
  if ( length(shape) == 2 )
    reshape (img, shape);
  
  variable len_x = shape[1];
  variable len_y = shape[0];
  
  variable i = where_max(img)[0];
  variable ref_pix = qualifier( "ref_pix", [( i / len_x),(i mod len_x)]);
  variable ref_pix_x = ref_pix[1];
  variable ref_pix_y = ref_pix[0];
  
  variable pang = 0.0;
  
  variable dr = qualifier("dr", 0.8);
  
  variable len = qualifier("steps",nint(_max(len_x,len_y)/dr));
  variable d = [1:len];
  variable steps, phi, x, y, r, sel, peak_index, len_sel;
  
  variable ridge = struct {
    i = Integer_Type[len],
    peak_x      = Integer_Type[len],
    peak_y      = Integer_Type[len],
    peak_value  = Double_Type[len],
    flux_cent_x = Double_Type[len],
    flux_cent_y = Double_Type[len],
  };

  variable lx,ly,rx,ry,lsum,rsum,sum_diff;
  _for i (0,len-1,1)
  {
    r = d[i]*dr ;
    ridge.i[i]=i;
    steps = nint(ceil(2*PI*r* 2)); % *2 to cover for sure every pixel
    phi = [0:2*PI:#(steps+1)];
    x = nint ( ref_pix_x + sin(pang+phi)*r );
    y = nint ( ref_pix_y + cos(pang+phi)*r );
    sel = unique(len_x*y + x);
    x = x[sel];
    y = y[sel];
    sel = where(0 <= x < len_x and 0 <= y < len_y);
    if (length(sel)<1) break;
    x = x[sel];
    y = y[sel];
    peak_index = where_max (img[y*len_x + x])[0];
    ridge.peak_value[i] = max (img[y*len_x + x]);
    ridge.peak_x[i] = x [peak_index];
    ridge.peak_y[i] = y [peak_index];

    %%%% determine ridge line with integral method
    pang = atan2 (ref_pix_x - ridge.peak_x[i] , ridge.peak_y[i] - ref_pix_y ); % to get proper position angle
    steps = nint(ceil(1*0.5*PI*r* 2)); % to cover for sure every pixel
    phi = [0:1*0.5*PI:#(steps+1)];

    (lsum,rsum) = (0,0);
    do {
      sum_diff = lsum -rsum;
      (lx,ly) = ( nint ( ref_pix_x - sin(pang+phi)*r ) , nint ( ref_pix_y + cos(pang+phi)*r ) );
      (rx,ry) = ( nint ( ref_pix_x - sin(pang-phi)*r ) , nint ( ref_pix_y + cos(pang-phi)*r ) );
      sel = where(0<=lx<len_x and 0<=ly<len_y and 0<=rx<len_x and 0<=ry<len_y);
      (rx, ry, lx, ly) = (rx[sel], ry[sel], lx[sel], ly[sel]);
      (lsum , rsum)= ( sum(img[ly*len_x + lx]) , sum(img[ry*len_x + rx]) );
      if (lsum == rsum) break;
      if (lsum > rsum) pang += _min(0.1,dr/r);
      else pang -= _min(0.1,dr/r);
    } while (sum_diff*(lsum -rsum) >= 0);
    
    ridge.flux_cent_x[i] = (length(rx)>0 ? rx [0] : 0);
    ridge.flux_cent_y[i] = (length(ry)>0 ? ry [0] : 0);
    }
  
  return ridge;
}
