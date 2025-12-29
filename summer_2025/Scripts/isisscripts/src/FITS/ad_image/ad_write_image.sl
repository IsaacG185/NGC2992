%%%%%%%%%%%%%%%%%%%%%
% TD, 2010-12-02
%%%%%%%%%%%%%%%%%%%%%
define ad_write_image() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_write_image}
%\synopsis{subroutine, which reads the data and the header of a
%      raw-redshift image (ad_make_image) and writes it into a
%      fits-image with the filename "image_*"}
%\usage{(img,alp,bet) = ad_write_image(filename,size [alp_extr,bet_extr]);}
%!%-

   variable filename,size,alp_extr,bet_extr,filename0;
   variable g, alp_lo, alp_hi, bet_lo, bet_hi;
   variable output = "_image";
   variable suff = ".FITS";
   
   if (qualifier_exists("cosne")) {output = "_cosne"+output;}
   else if (qualifier_exists("trff")) {output = "_trff"+output;}
   
   switch (_NARGS)
   {case 2:
	(filename,size) = ();
      filename0 = filename;
      filename = substr(filename,1,strlen(filename)-5);
      (g, alp_lo, alp_hi, bet_lo, bet_hi) = ad_make_image(filename0,size;; __qualifiers());
      
   }
   {case 4:
	(filename,size,alp_extr,bet_extr) = ();
      filename0 = filename;
      filename = substr(filename,1,strlen(filename)-5);
      (g, alp_lo, alp_hi, bet_lo, bet_hi) = ad_make_image(filename0,size,alp_extr,bet_extr;; __qualifiers());
   }
   {
      help(_function_name()); return;
   }
   
   variable alp = 0.5*(alp_lo+alp_hi);
   variable bet = 0.5*(bet_lo+bet_hi);
   fits_write_image(filename+output+suff,"alp_bet",g,alp,bet,"alpha","beta");

  return g,alp_lo,alp_hi,bet_lo,bet_hi;
}
