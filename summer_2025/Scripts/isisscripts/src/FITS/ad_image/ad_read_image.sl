%%%%%%%%%%%%%%%%%%
% TD, 2010-06-08
%%%%%%%%%%%%%%%%%%
define ad_read_image() {
%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_read_image}
%\synopsis{reads the image and the alpha-beta-grid from the FITS-file
%created by ad_make_image}
%\usage{ad_read_image(filename);}
%\seealso{ad_make_image, ad_init_raw}
%!%-
   
   variable f;
   
   switch(_NARGS)
   {case 1: f = ();}
   {help(_function_name()); return; }
   
%  #1)  read the image
   variable img = fits_read_img(f);
				  

   
%  #2)  get the minimum and maximum values of alp and bet
   variable alp_min = fits_read_key(f,"CRVAL1");
   variable alp_delta = fits_read_key(f,"CDELT1");
   variable alp_naxis = fits_read_key(f,"NAXIS1");
   alp_min -= 0.5*alp_delta;  % xfig needs the edge of the bin, but the fits-file uses the middle of th bin
   variable alp_max = alp_min + (alp_naxis+1)*alp_delta;

   variable bet_min = fits_read_key(f,"CRVAL2");
   variable bet_delta = fits_read_key(f,"CDELT2");
   variable bet_naxis = fits_read_key(f,"NAXIS2");
   bet_min -= 0.5*bet_delta;  % xfig needs the edge of the bin, but the fits-file uses the middle of th bin
   variable bet_max = bet_min + (bet_naxis+1)*bet_delta;

   
%  #3) reconstruct alpha and beta grid
   variable nalp_lo = [0:alp_naxis-1]*1./(alp_naxis);
   variable nalp_hi = [1:alp_naxis]*1./(alp_naxis);
   variable alp_lo = (alp_max-alp_min)*nalp_lo + alp_min;
   variable alp_hi = (alp_max-alp_min)*nalp_hi + alp_min;
   
   
   variable nbet_lo = [0:bet_naxis-1]*1./(bet_naxis);
   variable nbet_hi = [1:bet_naxis]*1./(bet_naxis);
   variable bet_lo = (bet_max-bet_min)*nbet_lo + bet_min;
   variable bet_hi = (bet_max-bet_min)*nbet_hi + bet_min;
      
   %  #4) return image and alp, bet grid
   return img,alp_lo,alp_hi,bet_lo,bet_hi;
}
