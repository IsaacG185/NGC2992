%%%%%%%%%%%%%%%%%%%%%
%
% array2image.sl
% A function to produce a 2D image from three 1D arrays (e.g, measurements at a
% set of x and y coordinates).
% 
% version 0.9
% Author: Paul Hemphill (pbh)
%
% Changelog:
% 2018-09-10: Added "help" qualifier
% 2018-09-08: Added some error handling, updated documentation and version number, added changelog (pbh)
% 2017-04-10: Added version number, updated documentation (pbh)
% 2017-04-03: Improved handling of user-defined pixel functions (pbh)
% 2017-03-31: Initial commit
%
%%%%%%%%%%%%%%%%%%%%%

% Version info
% Numerical version is <major>*1e5 + <minor>*1e3 + <patch>*1e1
% (so, e.g., version 1.2.3 would be 10203)
private variable _array2image_versionString = "0.9.0";
private variable _array2image_version = 900;

%%%%%%%%%%%%%%%%%%%%%
% Generic wrapper for user-defined functions for assigning pixel values
private define array2image_pixel(rev,z,quals)
{
  quals = struct_combine(@quals,"ndx");
  set_struct_field(quals,"ndx",rev);
  variable func = quals.func;
  return (@func)((@z)[rev];;quals);
}

%%%%%%%%%%%%%%%%%%%%%
define array2image()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{array2image}
%\synopsis{Converts three x, y, z arrays into a 2D array}
%\usage{image[,] = array2image(x,y,z)}
%\qualifiers{
%\qualifier{nbinx}{number of bins along x-axis}
%\qualifier{nbiny}{number of bins along y-axis}
%\qualifier{xgrid}{1D array containing grid of values for x-axis. Ignores nbinx.}
%\qualifier{ygrid}{1D array containing grid of values for y-axis. Ignores nbiny.}
%\qualifier{func}{reference to a single-parameter S-Lang function used to determine pixel values from z-values (see below).}
%\qualifier{func_quals}{struct containing additional qualifiers to be passed to the function defined in func}
%\qualifier{include_inf}{include points where x, y, or z are inf or -inf}
%\qualifier{include_nan}{Note that this means the returned 2D array is of the form
%   im[y,x]. By default this ignores any points with infinite or NaN values
%   (this can be turned off with the include_inf and include_nan switches).}
%}
%\description
%   The x-y grid is determined automatically from the ranges of the data, or
%   can be defined by the "xgrid" and "ygrid" qualifiers. If "xgrid" or "ygrid"
%   is a reference to a local variable, the automatically-determined grids will
%   be stored in these variables. This function uses histogram2d() to bin the
%   data and figure out which points fall into which bins, so see that
%   function's documentation for how the grids are handled.
%
%   Notes regarding coordinate grids: 
%   * histogram2d() uses the last bin as an "overflow" bin, so user-supplied
%     binning should have their last bin be SMALLER than the largest x- or
%     y-value (otherwise you will have a column or a row with no points
%     included).
%   * The grids define the EDGES of the bins used by histogram2d(). I think
%     (although I am not sure) that plot_image() and plot_contour() use any
%     supplied coordinate grid to define the CENTERS of the pixels. Check the
%     documentation of PGPLOT's PGIMAG routine to be sure.
%   * Finally, I have no idea what histogram2d() does when it gets a
%     pathologically-designed grid (e.g., bins with zero width, overlapping
%     bins, or bins with lower bounds larger than their upper bounds). Please
%     only use monotonically-increasing bins.
%
%   The value of each pixel is, by default, the average of all points which
%   fall into that bin. This can be changed by passing a reference to a
%   function via the "func" qualifier. 
%
%   The "func" qualifier must be a reference to an S-Lang function which takes
%   a single array as input and outputs a single value, e.g., mean(), sum(), or
%   length(). The input to this function is an array containing all z-values
%   that fall into the current pixel. However, this function also receives a
%   set of qualifiers. By default, this gives @func access to the data, the
%   coordinate grids, and the list of points in the current pixel via the
%   following qualifiers:
%   qualifier("x"), qualifier("y"), qualifier("z"): x, y, and z data coordinates
%   qualifier("xgrid"), qualifier("ygrid"): x and y coordinate grids
%   qualifier("ndx"): array of data indices in the current pixel
%
%   Extra qualifiers can be supplied via the func_quals qualifier, which
%   should be set to a structure containing any additional qualifiers you need.
%   This will be merged with the above set of qualifiers using struct_combine()
%   with user-defined qualifiers taking precedence over the defaults in cases
%   where the names are the same.
%
%   As an example, to set each pixel's value to the innner product of the
%   z-values and some other array of numbers (which we'll call "z2"), one could
%   define:
%   \code{
%   define arr2im_dotprod(zValues) {
%     variable z2 = qualifier("extra_array");
%     variable ndx = qualifier("ndx");
%     return inner_product(zValues,z2[ndx])[0];
%   }
%   }
%   
%   and then after reading in or defining x, y, z, and z2 arrays, do:
%   \code{
%   variable im = array2image(x,y,z;func=&arr2im_dotprod,func_quals=struct{extra_array=z2});
%   }
%
%   By default this function removes infinite and NaN values from the x, y, and
%   z arrays before doing anything; the include_inf and include_nan switches
%   disable this behavior. Note that including infinite and/or NaN values will
%   cause problems for the default grids and pixel value assignment, so
%   include_inf and include_nan are best used with user-defined functions and
%   grids.
%
%   This script is under development; please contact Paul Hemphill
%   (pbh@space.mit.edu) regarding bugs or missing features (please do not
%   report missing bugs; any bugs that are not present are missing
%   intentionally).
%
%   \seealso{histogram2d, plot_image}
% 
%!%-
{
  variable x,y,z;
  if(_NARGS == 0 || qualifier_exists("help")) {
    help(_function_name);
    return;
  } else if(_NARGS != 3) {
    usage("im[,] = array2image(x,y,z);");
  } else {
    (x,y,z) = ();
  }
  %%%%%%%%%%%%%%%%%%%%%
  % Arrays need to be equal lengths
  ifnot(length(x) == length(y) == length(z)) {
    error("Error: arrays must be equal length");
  }

  variable include_nan = qualifier("include_nan",0);
  variable include_inf = qualifier("include_inf",0);

  variable nbinx = qualifier("nbinx",32);
  variable nbiny = qualifier("nbiny",32);

  variable func = qualifier("func",&mean);
  variable is_simple = qualifier_exists("func") ? 0 : 1;

  %%%%%%%%%%%%%%%%%%%%%
  % If not specifically told not to, strip not-a-number and infinite values
  variable ndx;
  ifnot(include_nan) {
    ndx = where(not(isnan(x)) and not(isnan(y)) and not(isnan(z)));
    x = x[ndx];
    y = y[ndx];
    z = z[ndx];
  }
  ifnot(include_inf) {
    ndx = where(not(isinf(x)) and not(isinf(y)) and not(isinf(z)));
    x = x[ndx];
    y = y[ndx];
    z = z[ndx];
  }
  variable xgrid,ygrid,xgridRef,ygridRef;
  %%%%%%%%%%%%%%%%%%%%%
  % If there are no user-provided grids, figure out default grids for x and y
  % coordinates. If xgrid/ygrid are given as Ref_Type, we store the created
  % grid in the referenced variable.
  if(not(qualifier_exists("xgrid")) || typeof(qualifier("xgrid")) == Ref_Type) {
    %%%%%%%%%%%%%%%%%%%%%
    % histogram2d() uses the last bin as an "overflow" bin. This means if we
    % make the grid end at max(x), the final bin will always have zero elements
    % in it. So, instead, we place the last bin one bin-width lower than max(x).
    xgrid = [min(x):max(x)-(1.0/nbinx)*(max(x)-min(x)):#nbinx];
    if(qualifier_exists("xgrid")) {
      xgridRef = qualifier("xgrid");
      @xgridRef = xgrid;
    }
  } else {
    %%%%%%%%%%%%%%%%%%%%%
    % If xgrid is given and is NOT a Ref_Type, use it for the X grid.
    xgrid = qualifier("xgrid");
  }
  %%%%%%%%%%%%%%%%%%%%%
  % Repeat for Y.
  if(not(qualifier_exists("ygrid")) || typeof(qualifier("ygrid")) == Ref_Type) {
    %%%%%%%%%%%%%%%%%%%%%
    % See note for xgrid above
    ygrid = [min(y):max(y)-(1.0/nbiny)*(max(y)-min(y)):#nbiny];
    if(qualifier_exists("ygrid")) {
      ygridRef = qualifier("ygrid");
      @ygridRef = ygrid;
    }
  } else {
    ygrid = qualifier("ygrid");
  }
  nbinx = length(xgrid);
  nbiny = length(ygrid);

  %%%%%%%%%%%%%%%%%%%%%
  % histogram2d()'s reverse-index (fifth argument of histogram2d()) tells us
  % which points are in which bin
  variable rev;
  () = histogram2d(y,x,ygrid,xgrid,&rev);
  %%%%%%%%%%%%%%%%%%%%%
  % Turn rev into a 1D array so we can loop over it more easily. After this,
  % rev[i] contains the indices of all points falling into the i-th bin, so
  % z[rev[i]] gives us all z-values in that bin.
  reshape(rev,[nbinx*nbiny]);

  %%%%%%%%%%%%%%%%%%%%%
  % Now we just apply array2image_pixel() to each pixel. array2image_pixel() in
  % turn calls whatever function the user provided (by default this is mean()).
  variable defaultQuals = struct{x=x,y=y,z=z,xgrid=xgrid,ygrid=ygrid,func=func};
  variable userQuals = qualifier("func_quals");
  if(typeof(userQuals) != Struct_Type)
    throw InvalidParmError,"func_quals must be a Struct_Type",userQuals;
  variable quals = struct_combine(defaultQuals,userQuals);
  variable im = array_map(Double_Type,&array2image_pixel,rev,&z,&quals);
  %%%%%%%%%%%%%%%%%%%%%
  % The image is now stored in "im", but at the moment it's a 1D array, so the
  % last step is to reshape it into a 2D array
  reshape(im,[nbiny,nbinx]);

  return im;
}
