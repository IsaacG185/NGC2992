
%%%%%%%%%%%%%%%%%%
% TD, 2010-06-07
%%%%%%%%%%%%%%%%%%
define ad_make_image() {
%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_make_image}
%\synopsis{creates a redshift image from the raw data by sorting with
%respect to alpha and beta}
%\usage{(img, alp_lo, alp_hi, bet_lo, bet_hi) = ad_make_image(filename);}
%\qualifiers{
%\qualifier{sho_minmax}{show the extrem values of alpha and beta?}
%\qualifier{timing}{read a Brod-Timing-FITS-Table}
%\qualifier{field}{specify which values are plotted}
%\qualifier{disk}{kuse intrinsic x and y instead of alpha and beta (only working for timing yet)}
%}
%!%-

   variable fitstable,size;

   variable alp_extr = [0,0];
   variable bet_extr = [0,0];
   
   
   switch(_NARGS) 
   {case 2: (fitstable,size) = ();}
   {case 4: (fitstable,size, alp_extr,bet_extr) = (); }
   {help(_function_name()); return; }
   
   variable i,j,k,l,ind;
   variable d,nre,ng,nr,nphi;
   variable alp,bet;
   
   if (qualifier_exists("timing"))
   {
     (d,nr,nphi) = ad_init_raw_timing(fitstable);
      if (qualifier("disk"))
      {
	alp = d.xdisc;
	bet = d.ydisc;
      }
      else
      {
	alp = d.aproj;
	bet = d.bproj;	 
      }
   }
   else
   {
      (d,nre,ng,,) = ad_init_raw(fitstable);
      nr = 2*nre;
      nphi = ng;
      alp = d.alp;
      bet = d.bet;
   }

   % which value should be sorted
   variable val;   
   if (qualifier_exists("cosne"))
   {
      val = d.cosne;
   }
   else if (qualifier_exists("trff"))
   {
      val = d.trff;
   }
   else if (qualifier_exists("field"))
   {
      val = get_struct_field( d, qualifier("field") );
   }
   else
   {
      val = d.g;
   }
   

   
   
   if ((alp_extr[0] == alp_extr[1]) or (bet_extr[0] == bet_extr[1])){
      bet_extr = [min(bet),max(bet)];
      alp_extr = [min(alp),max(alp)];
   }
   
   if (qualifier_exists("sho_minmax")){
      message("\nalp = ["+sprintf("%.2f",alp_extr[0])+","+sprintf("%.2f",alp_extr[1])+
	      "] and bet = ["+sprintf("%.2f",bet_extr[0])+","+sprintf("%.2f",bet_extr[1])+"]");
   }
   
   variable bet_lo,bet_hi,alp_lo,alp_hi;
   (alp_lo,alp_hi) = linear_grid(alp_extr[0],alp_extr[1],size[0]);
   (bet_lo,bet_hi) = linear_grid(bet_extr[0],bet_extr[1],size[1]);
   
   variable g = Double_Type[size[1],size[0]];
   variable num = Integer_Type[size[1],size[0]];
   variable lum = Double_Type[size[1],size[0]];
   
   %  ++++++++++++++      SORT      +++++++++++++++++
   %  sort the arrays for ascending alpha in order to
   %  make reduce the final steps of sorting
   %  
   %  sort alpha in r-direction (I), by stepping through 
   %  the array in phi-direction (J)
   
   for (l=0; l < nphi;l++ ) {
      
      ind = array_sort(alp[[:-1],l]);
      
      alp[[:-1],l] = alp[ind,l];
      bet[[:-1],l] = bet[ind,l];
      val[[:-1],l] = val[ind,l];
   }
   
   %  ++++++++++++++   WRITE THE IMAGE     +++++++++++++++++
   
   %  ---- BEGIN: LOOP over the GRID -----
   %  remember: the array is already sorted
   %  
   %% define a starting value for each value of J
   variable start_I = Integer_Type[nphi]; 
   
   message("Calculating image:");
   for (i = 0; i < size[0]; i++) {             % ALPHA-LOOP  
      for(l = 0;l < nphi; l++) {                          % J-LOOP
	 for (k = start_I[l]; k < nr; k++) {             % I-LOOP
	    
	    % count only values that are in the correct bin
	    if (alp_lo[i] <= alp[k,l] < alp_hi[i]) {  
	       
	       for (j = 0; j < size[1]; j++) { 	            % BETA-LOOP
		  if (bet_lo[j] <= bet[k,l] < bet_hi[j]) {
		     % calculate the redshift for this grid-point
		     g[j,i] = g[j,i]*(num[j,i])/(num[j,i]+1.) 
		       + 1/(num[j,i]+1.)*val[k,l];	  
		     
		     %	    lum[j,i] += d.lum[k,l];
	     
		     num[j,i]++; 
		  }
	       }
	       
	       
	    } else if (alp_hi[i] <= alp[k,l]){  
	       start_I[l] = k; %set start_I to minimize efforts
	       break; % jump out of the loop if alpha is too large (sorted!)
	    }
	    
	 }
      } 
      if ((int((10000*(i+1)/size[0])) mod 500) == 0) {
	 message(string(int((100./size[0]*(i+1))))+"%");
      }
      
   }
   return g, alp_lo, alp_hi, bet_lo, bet_hi;
}
