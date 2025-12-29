%%%%%%%%%%%%%%%%%%%%%
% TD & Fabi Brod, 2013-08-12
%%%%%%%%%%%%%%%%%%%%%
define ad_init_raw_timing(fitstable) {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_init_raw_timing}
%\synopsis{subroutine, which reads the data and the header of a
%      raw-redshift image FOR TIMING (used by ad_make_image) }
%\usage{(data,nre,ng,a,theta0grad) = ad_init_raw_timing(filename);}
%!%-

   variable d = fits_read_table(fitstable);

   variable dim;
   (dim, , ) = array_info (d.xdisc);
   
   variable nr = dim[0];
   variable nphi = dim[1];
   return d,nr,nphi;
}
