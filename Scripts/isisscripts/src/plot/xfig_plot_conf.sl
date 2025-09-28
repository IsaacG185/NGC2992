require( "xfig" );
require( "gcontour" );
require("gsl","gsl");

define xfig_plot_conf()
%!%+
%\function{xfig_plot_conf}
%\synopsis{plots contour levels stored with save_conf}
%\usage{XFig_Plot_Type pl = xfig_plot_conf(String_Type file[, XFig_Plot_Type pl])}
%\qualifiers{
%\qualifier{lvls}{specify the Delta chi-sqr values for the contour levels,
%            default: [2.30, 4.61, 9.21], i.e., 1 sigma, 90% and 99% CL}
%\qualifier{color}{specify the colors of the contour lines
%           The array's last value is used for the best fit's cross (if
%           length of array > number of levels).}
%\qualifier{line}{[=0] specify the line styles of the contour lines}
%\qualifier{width}{[=1] specify the width of the contour lines
%                  The array's last value is used for the best fit's cross.}
%\qualifier{smooth}{[=1] this integer>=1 specifies the interpolation factor
%                   for the image used to calculate the contours}
%\qualifier{W}{width of the plot if created by \code{xfig_plot_contours}}
%\qualifier{H}{height of the plot if created by \code{xfig_plot_contours}}
%\qualifier{worldXY}{any world qualifier to the xfig-plot will be passed,
%                    which requires an existing SLxfig plot object to be given}
%\qualifier{transpose}{transposes the countour map (exchange x- and y-values)}
%\qualifier{nocross}{do not plot best fit cross}
%\qualifier{noclip}{if used with a sltikz plot object, do not clip}
%}
%\description
%    If no SLxfig plot object \code{pl} is given, a new one is created
%    and its world coordinate system is defined according to the
%    ranges used to calculate the confidence map. x- and y-labels
%    are initialized with the parameter names, but can be changed
%    afterwards.
%\seealso{get_confmap, xfig_plot_new, enlarge_image}
%!%-
{
   % TODO: It should also be possible to use ISIS' conf_map structure
   %       as argument for this function, not only a save_conf'ed file.
   %       The values that are currently read from the FITS keywords
   %       can certainly also be derived from a load_conf'ed structure.
   %
   %       [Mh]

   variable file, pl=NULL;
   switch(_NARGS)
   { case 1:  file      = (); }
   { case 2: (file, pl) = (); }
   { help(_function_name()); return; }

   variable lvls = qualifier("lvls",[2.2957,4.6052,9.21034]);
   variable n_levels = length(lvls);
   variable col = qualifier("color", [1:n_levels]);
   variable line = qualifier("line", 0);
   variable width = qualifier("width", 1);
   variable fac = qualifier("smooth",1);
   variable clrmap = qualifier("colormap","ds9b");
   variable trns = qualifier_exists("transpose"); 
   variable cross = not(qualifier_exists("nocross"));
   variable qnames = get_struct_field_names(__qualifiers);
   variable world = qnames[where(
   array_map(String_Type, &substr, qnames, 1, 5) == "world")];

   if (qualifier_exists("noclip")) {
       world=struct_combine(world,"noclip");
   }
   
   if(n_levels>1)
   {
     if(length(col)==1)
     {
       variable cola = typeof(col)[n_levels];
       cola[*] = col;
       col = cola;
     }
     if(length(line)==1)  line += Integer_Type[n_levels];
     if(length(width)==1)  width += Integer_Type[n_levels];
   }

   % #1: read the file and get the information
   variable map = fits_read_img (file);
   if (trns) map = transpose(map);

   variable xmin = fits_read_key(file,trns ? "pymin" : "pxmin");
   variable xmax = fits_read_key(file,trns ? "pymax" : "pxmax");
   variable xnum = fits_read_key(file,trns ? "pynum" : "pxnum");

   variable ymin = fits_read_key(file,trns ? "pxmin" : "pymin");
   variable ymax = fits_read_key(file,trns ? "pxmax" : "pymax");
   variable ynum = fits_read_key(file,trns ? "pxnum" : "pynum");

   variable del_x = fits_read_key(file,trns ? "CDELT2P" : "CDELT1P");
   variable del_y = fits_read_key(file,trns ? "CDELT1P" : "CDELT2P");

   variable best_x = fits_read_key(file,trns ? "BEST_Y" : "BEST_X");
   variable best_y = fits_read_key(file,trns ? "BEST_X" : "BEST_y");

   % #1b: enlarge map and hence smooth contour
   if (qualifier_exists("smooth"))
   {
      map = enlarge_image(map,fac,fac);
      del_x /= fac;
      del_y /= fac;
   }

   % #2: compute the confidence levels
   variable gct  = gcontour_compute(map,lvls);
   variable dims = array_shape(map);

%   variable del_x = 1.*(xmax-xmin)/(dims[0]);
%   variable del_y = 1.*(ymax-ymin)/(dims[1]);


   % create a new plot object if none (or NULL) given
   if(pl==NULL)
   {
     pl = xfig_plot_new(qualifier("W", 14), qualifier("H", 10));
     pl.world(xmin, xmax-del_x, ymin, ymax-del_y);
     pl.xlabel(`\verb|`+fits_read_key(file,trns ? "CTYPE2P" : "CTYPE1P")+"|");
     pl.ylabel(`\verb|`+fits_read_key(file,trns ? "CTYPE1P" : "CTYPE2P")+"|");
   }

   % #3: plot the confidence levels
   variable i,j;
   _for i(0, n_levels-1, 1)
   {
      _for j(0,length(gct[i].x_list)-1,1)
      {
	 pl.plot(del_x*gct[i].x_list[j]+xmin,
	         del_y*gct[i].y_list[j]+ymin;; struct_combine(world,
                 struct { color=col[i], line=line[i], width=width[i] }
	 ));
      }
   }
  if(cross){
    pl.plot(best_x,best_y;; struct_combine(world,
      struct { color=length(col) > n_levels ? col[-1] : "black",
               width=width[-1], sym=4 }));
  }
#ifexists png_gray_to_rgb
   if (qualifier_exists("plot_map"))
    {
      if (qualifier_exists("crop_map")){
	 pl.plot_png(png_gray_to_rgb (map [ [1:2*(length(map[*,0])-1)]/2, [1:2*(length(map[0,*])-1)]/2 ] , clrmap));
      } else {
        pl.plot_png(png_gray_to_rgb (sqrt(map), clrmap);cmap=clrmap);
      }
    }
#endif
   return pl;
}

