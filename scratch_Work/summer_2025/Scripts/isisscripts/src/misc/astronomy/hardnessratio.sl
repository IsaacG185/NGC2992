require("gsl" , "gsl");
% don't ask me why but it wont work otherwise. The machine knows! - M. Scott
%
%
%
define behr()
%!%+
%\function{behr}
%\synopsis{calculates fractional difference hardness ratio thorugh bayesian estimation}
%\usage{Double_Type (HR , HR_err_max , HR_err_min) =  behr(Double_Type soft_count, Double_Type hard_count);}
%\qualifiers{
%  \qualifier{scale_s}{Scaling factor for soft_count;  soft_count = scale_s*soft_count  (default = 1)}
%  \qualifier{scale_h}{Scaling factor for hard_count;  hard_count = scale_h*hard_count  (default = 1)}
%  \qualifier{back_s}{background counts in the soft band}
%  \qualifier{back_h}{background counts in the hard band}
%  \qualifier{bkg_scale_s}{Scaling factor for source background to observed background counts in the soft band.
%             Expected background in source region is ~ back_s/bkg_scale_s.}
%  \qualifier{bkg_scale_h}{Scaling factor for source background to observed background counts in the hard band.
%             Expected background in source region is ~ back_h/bkg_scale_h.}
%  \qualifier{aprox_n}{= run aproximation which keeps powers of bkg_scale_h^i*bkg_scale_s^j, with i+j <= n}
%  \qualifier{significance}{significance of calculated uncertainties in percent (default = 68 per cent)}
%  \qualifier{fulloutput}{if present function will additionally return the Grid used (2000 color values ranging from -0.999 to 0.999), and the
%             normalized probability distribution}
%}
%\description
%  This function gives a bayesian estimation for the so-called fractional difference hardness ratio according to (H-S)/(H+S),
%  assuming that soft_count and hard_count are the *intrinsic* counts.
%  Optionally, scaling factors for the indiviudal channels can be set.
%  If given, background counts are taken into account presuming a separate measurement of a Poisson background.
%  If the background counts are given a scaling factor for the source background has to be provided as well.
%  An approximative approach can be used as well, by only keeping up to the n-th power in the expansion in terms of
%  the scaling factor of the source background.
%
%  The hardness ratio estimation and the respecitive uncertainties are returned by default. 
%  Use qualifier if also the grid used (2000 color values ranging from -0.999 to 0.999), and the
%  normalized probability distribution are desired.
%
%  Based on Park et al., 2006, ApJ, 652, 610. Based on original isis-code by Mike Nowak.
%
%\seealso{hardnessratio;}
%!%-
{   
    variable A , B;
    switch(_NARGS)
    { case 2: (B , A) = (); }
    { help(_function_name()); return; }

    if (typeof(A) == Double_Type){
        A = [A];
                                 }
    if (typeof(B) == Double_Type){
        B = [B];
                                 }                             
 
    variable setlength = length(A);                             

    variable _EA = qualifier("scale_h" , 1.);
    variable _EB = qualifier("scale_s" , 1.);
    variable EA = Double_Type[setlength];
    variable EB = Double_Type[setlength];
    if (typeof(_EA) == Double_Type){
        EA[*] = _EA;
                                  }
    else{EA = _EA;}                              
    if (typeof(_EB) == Double_Type){
        EB[*] = _EB;
                                   }
    else{EB = _EB;}                               
              
    variable _DA = qualifier("back_h" , 0.0);
    variable _DB = qualifier("back_s" , 0.0);
    variable DA = Double_Type[setlength];
    variable DB = Double_Type[setlength];
    if (typeof(_DA) == Double_Type){
        DA[*] = _DA;
                                   }
    else{DA = _DA;}                               
    if (typeof(_DB) == Double_Type){
        DB[*] = _DB;
                                   }
    else{DB = _DB;}                               

    variable _GA = qualifier("bkg_scale_h" , 0.0);
    variable _GB = qualifier("bkg_scale_s" , 0.0);
    variable GA = Double_Type[setlength];
    variable GB = Double_Type[setlength];
    if (typeof(_GA) == Double_Type){
        GA[*] = _GA;
                                   }
    else{GA = _GA;}                                  
    if (typeof(_GB) == Double_Type){
        GB[*] = _GB;
                                   }
    else{GB = _GB;}

    variable n = qualifier("aprox" , 0.0);
    n = int(abs(n));

    variable pval = qualifier("significance" , 68.);
    pval = pval/100.;

    variable xx;

    variable grids = {};
    variable dists = {};

    variable fin_HRs = Double_Type[setlength];
    variable fin_HRs_up = Double_Type[setlength];
    variable fin_HRs_down = Double_Type[setlength];

    _for xx(0 , length(A) - 1 , 1){ 

        variable a = A[xx];
        variable b = B[xx];
        variable ea = EA[xx];
        variable eb = EB[xx];
        if (ea <= 0){ea = 1;}
        if (eb <= 0){eb = 1;}
        variable da = DA[xx];
        variable db = DB[xx];
        variable ga = GA[xx];
        variable gb = GB[xx];

        variable ngrid = int(2000*30);
        variable bhr_lo, bhr_hi;
        (bhr_lo,bhr_hi) = linear_grid(-1,1,ngrid);
        variable bhr = (bhr_lo+bhr_hi)/2.;
        variable dbhr = (bhr_hi-bhr_lo);
    
        variable pjk, j, k, psum;
    
        if (qualifier_exists("back_h") and qualifier_exists("back_s") and qualifier_exists("bkg_scale_h") and qualifier_exists("bkg_scale_s")){
            psum = 0;
            variable max_j, max_k;
            max_j = int(a);
            if (qualifier_exists("aprox")){
                max_j = min([int(a) , n]);
                                          }
            max_k = int(b);
            _for j (0,max_j,1){
                if (qualifier_exists("aprox")){
                    max_k = min([int(b) , n - j]);
                                              }
                _for k (0,max_k,1){
                    pjk = gsl->lngamma(da + j + 1) + gsl->lngamma(db + k + 1) - gsl->lngamma(da + 1) - gsl->lngamma(db + 1)
                          - j*log(ga + 1.) - k*log(gb + 1) + gsl->lngamma(a + b + 2 - j - k)
                          - gsl->lngamma(a - j + 1) - gsl->lngamma(b - k + 1) - gsl->lngamma(j + 1) - gsl->lngamma(k + 1)
                          + (a - j)*log(1 + bhr) + (b - k)*log(1 - bhr)
                          - (a + b + 2 - j - k)*log(ea + eb + (ea - eb)*bhr);
                    psum += exp(__tmp(pjk));
                                  }
                              }
            psum = psum/sum(psum*dbhr);
                                                                                                                                              }
        else{
            variable ph = gsl->lngamma(a + b + 2) + log(2.) - gsl->lngamma(a + 1) - gsl->lngamma(b + 1)
                          + (a + 1)*log(ea) + (b + 1)*log(eb) + a*log(1 + bhr)
                          + b*log(1 - bhr) - (a + b + 2)*log(ea + eb + (ea - eb)*bhr);
            psum = exp(__tmp(ph));
            }
    
        variable bhr_max = bhr[ where(psum == max(psum)) ];
    
        variable phsum = cumsum(psum*dbhr);
        variable iwa = where(phsum <= pval/2.);
        variable iwb = where(phsum >= 1-pval/2.);
        variable HR_fin, err_up, err_do;
        if ((length(bhr[iwb]) == 0) or (length(bhr[iwa]) == 0)){
            print(sprintf("%s: Ranges for uncertainties are empty.",_function_name()));
            print(sprintf("%s: Will only return best value and _NaN for uncertanties.",_function_name()));
            HR_fin = bhr_max[0]; 
            err_up = _NaN; 
            err_do = _NaN;
                                                               }
        else{                                                       
            variable bhrmin = max(bhr[iwa]);
            variable bhrmax = min(bhr[iwb]);
            variable result_struct;
    
            if ((bhr_max[0] > 0.0) and (bhr_max[0] >= bhrmax[0])){
                result_struct = round_conf(bhrmin[0] , bhr_max[0] , 1.0);
                                                                 }
            else if ((bhr_max[0] < 0.0) and (bhr_max[0] <= bhrmin[0])){
                result_struct = round_conf(-1.0 , bhr_max[0] , bhrmax[0]);
                                                                      }
            else{
                result_struct = round_conf(bhrmin[0] , bhr_max[0] , bhrmax[0]);
                }
            
            HR_fin = result_struct.value[0];
            err_up = result_struct.err_hi[0];
            err_do = result_struct.err_lo[0];
            }

        fin_HRs[xx] = HR_fin;
        fin_HRs_up[xx] = err_up;
        fin_HRs_down[xx] = err_do;

        list_append(grids , bhr);
        list_append(dists , psum);

        }

    if (qualifier_exists("fulloutput")){
        return (fin_HRs , fin_HRs_up , fin_HRs_down , grids , dists);
                                       }
    else{
        return (fin_HRs , fin_HRs_up , fin_HRs_down);
        }    
}
%
%
%
define hardnessratio()
%!%+
%\function{hardnessratio}
%\synopsis{calculates various X-ray hardness ratio from given count rates}
%\usage{Double_Type (HR , HR_err) = hardnessratio(Double_Type soft_count, Double_Type hard_count);}
%\altusage{Double_Type (HR , HR_err_up , HR_err_down) = hardnessratio(Double_Type soft_count, Double_Type hard_count ; bayesian);}
%\qualifiers{
%  \qualifier{color}{calculate the hardness ratio according to color=log10(S/H)}
%  \qualifier{hardness}{calculate the hardness ratio according to hardness=(H-S)/(H+S)}
%  \qualifier{ratio}{calculate the hardness ratio according to ratio=S/H (the default)}
%  \qualifier{bayesian}{returns hardness calculated using the bayesian estimation, calling 
%                         the function behr()}
%  \qualifier{back_s}{background counts in the soft band}
%  \qualifier{back_h}{background counts in the hard band}
%  \qualifier{backscale}{ratio between the extraction regions for the source and the background}
%  \qualifier{exposure}{Exposure per bin in seconds. If given, interpret soft_count, hard_count and t
%                         he backgrounds as rates. Multiply the rates with exposure to get the counts.}
%  \qualifier{backexposure}{if given, the background exposure. Only taken into
%               account if exposure is also set. If not given, it is assumed that
%               the source and background exposures are identical.}
%  \qualifier{ratio_type}{(DEPRECATED) Integer_Type, for hr=s/h choose 1,
%             for hr=(h-s)/(h+s) choose 2, for hr=log(s/h) choose 3, default = 1}
%  \qualifier{err_s}{Array containing the uncertainties of the soft light curve}
%  \qualifier{err_h}{Array containing the uncertainties of the hard light curve}
%      additional qualifiers are passed to 'behr' for bayesian estimation
%}
%\description
%  This function calculates the so-called hardness ratio or color according to 
%  the three common prescriptions used in X-ray astronomy: S/H, (H-S)/(H+S), and log10(S/H).
%  If given, background counts are subtracted before the calculation, taking into account
%  different source and background extraction regions and different source and background exposure
%  times if necessary (if counts are given but the background exposure was different, set the
%  source exposure to 1 and the background exposure to the ratio of the source and background exposure
%  times. If rates are given, give the exposure times.
%
%  Error bars are calculated using Gaussian error propagation. Contrary to earlier versions of
%  this routine they are ALWAYS calculated!
%
%  The bayesian approach or the function behr() should be used in low count regime.
%  If they qualifier "bayesian" is present the hardness is calcualted using the bayesian estimation 
%  implemented in the function behr(). If the background should be taken into account the function also requires 
%  the background scaling factors used in behr().
%  Requires gsl, make sure module is loaded!
%
%\seealso{behr;}
%!%-
{
    variable s,h;

    switch(_NARGS)
    { case 2: (s,h) = (); }
    { help(_function_name()); return; }

    if (__is_numeric(s)!=2) {
	s=typecast(s,Double_Type);
    }
    if (__is_numeric(h)!=2) {
	h=typecast(h,Double_Type);
    }

    %
    % backwards compatibility
    %
    variable type=0;
    if (qualifier_exists("ratio_type")) {
	if (qualifier_exists("color") or qualifier_exists("ratio") or qualifier_exists("hardness")) {
	    throw UsageError,sprintf("%s: ratio_type cannot be used with the color, ratio, or hardness qualifiers.",_function_name());

	}
    }
    if ((qualifier_exists("bayesian") and qualifier_exists("ratio")) or (qualifier_exists("bayesian") and qualifier_exists("color"))){
        throw UsageError,sprintf("%s: The bayesian approach is only available for the calculation of the hardness,",_function_name());
                                                                                                                                     }
    
    variable bs=qualifier("back_s",0.);
    variable bh=qualifier("back_h",0.);

    variable r=qualifier("backscale",1.);


    % Gehrels (1986) uncertainties
    variable sig_s = qualifier("err_s", sqrt(s+0.75)+1.);
    variable sig_h = qualifier("err_h", sqrt(h+0.75)+1.);

  
    %
    % exposure is given: convert rates to counts
    %
    if (qualifier_exists("exposure")) {
	variable expo=qualifier("exposure");
	s=s*expo;
	h=h*expo;

	variable backexpo=qualifier("backexposure",expo);
	bs=bs*backexpo;
	bh=bh*backexpo;

	r=r*expo/backexpo;

      % convert uncertainties from rates to counts
        if (qualifier_exists("err_s")){
	  sig_s = sig_s * expo;
        } else {
	  sig_s = sqrt(s+0.75)+1.;
          }

        if (qualifier_exists("err_h")){
          sig_h = sig_h * expo;
        } else {
	  sig_h = sqrt(h+0.75)+1.;
          }
     }
    
    % Gehrels (1986) uncertainties part 2
    variable sig_bs = (bs>0.) ? sqrt(bs+0.75)+1. : 0.;
    variable sig_bh = (bh>0.) ? sqrt(bh+0.75)+1. : 0.;

  
  
    variable dsbs=s-bs/r;
    variable dhbh=h-bh/r;

    variable sigs_sum=sqrt( sig_s^2.+(sig_bs/r)^2.);
    variable sigh_sum=sqrt( sig_h^2.+(sig_bh/r)^2.);

    % color: log10(S/H)
    if (qualifier_exists("color") || type==3) {
	variable color=log10(dsbs/dhbh);
	variable sig_color=sqrt( (sigs_sum/dsbs)^2. + (sigh_sum/dhbh)^2. )/log(10.);

	return (color,sig_color);
    }
    
    if (qualifier_exists("hardness") || type==2) {
	% hardness (H-S)/(H+S)
        variable hard;
        if (qualifier_exists("bayesian")){
            variable hard_u , hard_d;
            (hard , hard_u , hard_d) = behr(s , h ;; __qualifiers);
            return (hard , hard_u , hard_d);
                                         }
        else{                                 
	        hard=(h-s)/(h+s);
    	    variable sig_hard=2.*sqrt((dhbh*sigs_sum)^2.+(dsbs*sigh_sum)^2.)/(dhbh+dsbs)^2.;
	        return (hard,sig_hard);
            }
    }

    % default: S/H
    variable ratio=dsbs/dhbh;
    variable sig_ratio=ratio*sqrt( (sigs_sum/dsbs)^2. + (sigh_sum/dhbh)^2. );
    return (ratio,sig_ratio);

}



