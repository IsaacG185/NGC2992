%%%%%%%%%%%%%%%%%%%%%
% TD, 2010-06-07
%%%%%%%%%%%%%%%%%%%%%
define ad_init_raw(fitstable) {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_init_raw}
%\synopsis{subroutine, which reads the data and the header of a
%      raw-redshift image (used by ad_make_image) }
%\usage{(data,nre,ng,a,theta0grad) = ad_init_raw(filename);}
%!%-

   variable d = fits_read_table(fitstable);
   
   % nre is not the length of the table, but 2*nre , 
   % because here k=1 & 2 are displayed in one table
   variable nre = fits_read_key(fitstable,"nre");
   variable ng = fits_read_key(fitstable,"ng");
   variable a = fits_read_key(fitstable,"a");
   variable theta0grad = fits_read_key(fitstable,"theta0");  
  return d,nre,ng,a,theta0grad;
}
