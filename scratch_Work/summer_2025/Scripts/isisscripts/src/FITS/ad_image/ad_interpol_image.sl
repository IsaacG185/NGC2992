%%%%%%%%%%%%%%%%%%
% TD, 09/06/2010
%%%%%%%%%%%%%%%%%%
define ad_interpol_image(g,alp_lo,bet_lo,sz_max,rmin){
%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_interpol_image}
%\synopsis{interpolates the image maximal sz_max times beyond rmin}
%\usage{image = ad_interpol_image(image,alp_lo,bet_lo,sz_max,rmin);}
%\seealso{ad_make_image, ad_init_raw, ad_read_image}
%!%-

   
   
   variable size = [length(alp_lo),length(bet_lo)];
   % +1 is needed, as alp_lo is only 
   variable num = Integer_Type[size[1],size[0]];   
   num[*,*] = 1;
   num[where(g == 0)] = 0;

   variable i,j;
   variable sz = 1;
   
   for (j = 1; j < size[1]; j++) {
      for (i = 0; i < (size[0]); i++) {
	 if ( sqrt(alp_lo[i]^2+bet_lo[j]^2) > rmin &&  (num[j,i] == 0) &&  (num[j,i-1] != 0)) {
	    sz = 1;
	    while ( (sz  <= sz_max) && ( i+sz < size[0]) && (num[j,i+sz] ==  0) ) {
	       sz++;
	    }
	    if (sz < sz_max and i+sz < size[0]){
	       g[j,i] = 1./(sz+1)*g[j,i-1] + sz/(sz+1.)*g[j,i+sz];
	       num[j,i] = 1;
	    } else {
	       g[j,i] = g[j,i-1];
	    }
	 }
	 
      }
   }
   for (i = 0; i < size[0]; i++) { 
      for (j = 1; j < (size[1]); j++) { 
	 if ( sqrt(alp_lo[i]^2+bet_lo[j]^2) > rmin &&  (num[j,i] == 0) &&  (num[j-1,i] != 0)) {
	    sz = 1;
	 while ( (sz  <= sz_max) && ( j+sz < size[1]) && (num[j+sz,i] ==  0) ) {
	    sz++;
	 }
	    if (sz < sz_max and j+sz < size[1]){
	       g[j,i] = 1./(sz+1)*g[j-1,i] + sz/(sz+1.)*g[j+sz,i];
	       num[j,i] = 1;
	    } else {
	       g[j,i] = g[j-1,i];
	    }
      }
	 
      }
   }
   

   
   return g;
}

