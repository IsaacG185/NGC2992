% -*- slang -*-

% Last Updated: July 27, 2015

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Public Functions in This File.  Usage message (almost always) when 
% function is called without arguments.

% sep_grid           : Set the eval method to SEPARATE_GRID
% mrg_grid           : Set the eval method to MERGED_GRID
% usr_grid           : Set up logarithmically spaced USER_GRIDs
% fstat_mod          : Set the fit statistic to sigma=model
% fstat_gehr         : Set the fit statistic to sigma=gehrels
% fstat_norm         : Set the fit statistic to sigma=data
% lmdif              : Set the fit method to lmdif 
% mpfit              : Set the fit method to mpfit 
% minim              : Set the fit method to minim
% subplex            : Set the fit method to subplex
% marq               : Set the fit method to marquardt
% conf_map_fail_hook : Switch between subplex/lmdif when doing
%                      error contours, and the fit fails
% conf_map           : Call conf_map_counts with conf_map_fail_hook
% corback            : Set the data background to have a fittable 
%                      normalization, using the back_fun utility
% fcorback_fit       : The fit function used by corback
% corfile            : In addition to the data background, set another
%                      background subtracted file as a background with
%                      fittable normalization
% fcorfile_fit       : The fit function used by corfile
% bayes_nconf        : Bayesian estimate of lower/upper counts bound
%                      given observed counts & significance
% bayes_sconf        : Bayesian estimate of lower/upper significance bound
%                      given observed counts & desired lower/upper bounds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define param_default_structure(value,freeze,pmin,pmax,
                                             hmin,hmax,pstep,prstep)
{
   variable param_def = struct{value, freeze, min, max,
                               hard_min, hard_max, step, relstep};
   param_def.value=value;
   param_def.freeze=freeze;
   param_def.min=pmin;
   param_def.max=pmax;
   param_def.hard_min=hmin;
   param_def.hard_max=hmax;
   param_def.step=pstep;
   param_def.relstep=prstep;
   return param_def;
}

public define sep_grid()
{
   switch(_NARGS)
   {
    case 1:
      variable a = ();
      set_eval_grid_method(SEPARATE_GRID,a);
      return;
   }
   {
      variable fps=stderr;
      () = fprintf(fps, "\n%s\n", %%%{{{           
+" sep_grid(a);\n"
+"\n"
+"   Equivalent to set_eval_grid_method(SEPARATE_GRID,a);\n"); %%%}}}
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%

public define fstat_mod()
{
      set_fit_statistic("chisqr;sigma=model");
      return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define fstat_gehr()
{
      set_fit_statistic("chisqr;sigma=gehrels");
      return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define cash()
{
      set_fit_statistic("cash");
      return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define fstat_norm()
{
      set_fit_statistic("chisqr;sigma=data");
      return;
}

alias("fstat_norm","fstat_data");
alias("fstat_norm","fstat_dat");

%%%%%%%%%%%%%%%%%%%%%%%%

public define mrg_grid()
{
   switch(_NARGS)
   {
    case 1:
      variable a = ();
      set_eval_grid_method(MERGED_GRID,a);
      return;
   }
   {
      variable fps=stderr;
      () = fprintf(fps, "\n%s\n", %%%{{{           
+" sep_grid(a);\n"
+" \n"
+"   Equivalent to set_eval_grid_method(MERGED_GRID,a);\n"); %%%}}}
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

static variable lgh_lb = Double_Type[1000], lgh_ub = @lgh_lb, lgh_scl = @lgh_lb;

public define log_grid_hook(id,s)
{
    s.bin_lo = _A(10^[lgh_lb[id]:lgh_ub[id]:lgh_scl[id]]);
    s.bin_hi = make_hi_grid(s.bin_lo);
    return s;
}


public define usr_grid()
{ 
   variable a,lb,ub,scl,cache,i,id;
   switch(_NARGS)
   {
    case 4:
      (a,lb,ub,scl) = ();
      cache = 0;
   }
   {
    case 5:
      (a,lb,ub,scl,cache) = ();
      if(cache!=0){cache = 1;}
   }
   {
      variable fps=stderr;
      () = fprintf(fps, "\n%s\n", %%%{{{           
` usr_grid(a,lb,ub,scl [,cache]; pileup, pile_opts=string);
 
   Create a USER_GRID for each dataset, a[i], such that there is a
   logarithmic energy grid running over keV energies:

      10^[lb[i]:ub[i]:scl[i]]

   Called via set_eval_grid_method(USER_GRID, a, &log_grid_hook [,cache]);
   *Also* sets the kernel to: 
 
      set_kernel(a, \"std;eval=all\");

   *unless* the pileup kernel is also set, in which case it is set to

      set_kernel(a, "pileup"+pile_opts);

   (e.g., use pile_opts=";nterms=10;fracexpo=0.5"). 

   If using a pileup kernel, *do not* set caching and *do not* set
   more than one dataset at a time.

 Inputs:
   a    : Vector indices for which the USER_GRID will be applied
   lb   : Vector of log10 of lower keV bounds
   ub   : Vector of log10 of upper keV bounds
   scl  : Uniform log step size of the grid
   cache: (Optional) If non-zero, cache the model evaluation
`); %%%}}}
      return;
   }

   a = [a]; lb = [lb]; ub = [ub]; scl = [scl];

   if(qualifier_exists("pileup") && 
      (length(a) >1 || cache==1)   )
   {
      variable fpsp = stderr;
      () = fprintf(fps, "\n%s\n", %%%{{{           
` Attempt to mix pileup kernel with caching or multiple datasets.
  See help message for usr_grid.
`); %%%}}}
   }

   variable la = length(a), lbz = lb[0], ubz = ub[0], sclz = scl[0];
   variable llb = length(lb);
   variable lub = length(ub);
   variable lscl = length(scl);
   variable pile_opts = qualifier("pile_opts","");

   if(cache==0)
   {
      if(llb < la)
      {
         lb = [lb,ones(la-llb)*lbz];
      }
      if(lub < la)
      {
         ub = [ub,ones(la-lub)*ubz];
      }
      if(lscl < la)
      {
         scl = [scl,ones(la-lscl)*sclz];
      }
   }
   else
   {
      lb = Double_Type[la]; ub = @lb; scl = @lb;
      lb[*] = lbz;
      ub[*] = ubz;
      scl[*] = sclz;
   }

   i = 0;
   foreach(a)
   {
      id = ();
      lgh_lb[id] = lb[i];
      lgh_ub[id] = ub[i];
      lgh_scl[id] = scl[i];
      i++;
   }

   set_eval_grid_method (USER_GRID, a, &log_grid_hook, cache);
   if(qualifier_exists("pileup"))
   {
      set_kernel(a, "pileup"+pile_opts);
   }
   else
   {
      set_kernel(a, "std;eval=all");
   }
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%

public define subplex()
{
   set_fit_method("subplex");
   return;
}

%%%%%%%%%%%%%%%%%%%%

public define marq()
{
   set_fit_method("marquardt");
   return;
}

%%%%%%%%%%%%%%%%%%%%

public define lmdif()
{
   set_fit_method("lmdif");
   return;
}

%%%%%%%%%%%%%%%%%%%%

public define mpfit()
{
   set_fit_method("mpfit");
   return;
}

%%%%%%%%%%%%%%%%%%%%

public define minim()
{
   set_fit_method("minim");
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define conf_map_fail_hook(p1, p2, best_pars, try_pars,fit_info)
{
   variable save_method = get_fit_method ();
                  
   variable meth = strchop(save_method,';',0)[0];

   if(meth=="marquardt" or meth=="lmdif")
   {
      subplex;
   }
   else
   {
      lmdif;
   }

   () = fit_counts (&fit_info);
                  
   set_fit_method (save_method);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

static variable conf_map_info=struct{fail};
conf_map_info.fail = &conf_map_fail_hook;

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define conf_map(x,y)
{
   return conf_map_counts(x,y,conf_map_info);
}

private variable bkg_data = {};   
private variable bkg_exp = {};
private variable bkg_area = {};
private variable bkg_scl = {};
private variable corfile_data = {};   
private variable corfile_app = {};   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define create_backscale(hist_index)
{
   variable scl;
   variable dscl = get_data_backscale(hist_index);
   variable dexp = get_data_exposure(hist_index);
   variable bscl = get_back_backscale(hist_index);
   variable bexp = get_back_exposure(hist_index);

   if(dscl==NULL || dexp == NULL || bexp == NULL || bscl == NULL || 
      bexp == 0 || min([bscl]) == 0)
   {
      scl = 1.;  % Throw our hands up and concede defeat
   }
   else 
   {
      scl = (dexp*dscl)/(bexp*bscl);
      if(1 < length(dscl)==length(scl)) % if dscl is an array
        scl[where(dscl==0)] = 0;        %   fix possible 0/0 = NaN elements
   }
   return scl, dexp, dscl, bexp, bscl;
}   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define create_back(hist_index)
{
   rebin_data(hist_index,0);

   variable b = get_back(hist_index);
   if(hist_index > length(bkg_data)-1)
   {
      loop(hist_index-length(bkg_data)+1)
      {
         list_append(bkg_data,NULL);
         list_append(bkg_exp,NULL);
         list_append(bkg_area,NULL);
         list_append(bkg_scl,NULL);
      }
   }

   if( b==NULL )
   {
      bkg_data[hist_index] = 
      Double_Type[length(get_data_counts(hist_index).bin_lo)];
      bkg_exp[hist_index] = 1.;
      bkg_area[hist_index] = 1.;
      bkg_scl[hist_index] = 1.;
   }
   else
   {
      bkg_data[hist_index] = b;
      bkg_exp[hist_index] = get_back_exposure(hist_index);
      bkg_area[hist_index] = get_back_backscale(hist_index);
      (bkg_scl[hist_index],,,,) = create_backscale(hist_index);
   }

}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Defining fit function for the background %%%

public define fcorback_fit(lo,hi,par)
{
   return par[0]*bkg_data[int(par[1])];
}
	
add_slang_function("fcorback",["norm","id"]);

% The id parameter of fcorback should always be frozen to an 
% integer value.  It's default value is 2 but it should be 
% set to be the id of the dataset it describes and remain 
% frozen there. 

%%%%%%%%%%%%%%%%%%%%%%%%%%

define fcorback_default(i)
{
   switch(i)
   {
    case 0:
    return param_default_structure(1,0,0,2,0,1.e10,1.e-3,1.e-3);
   }
   {
    case 1:
    return param_default_structure(1,1,1,100,1,1000,1,1);
   }
}

set_param_default_hook("fcorback","fcorback_default");

%%%%%%%%%%%%%%%%%%%%%%%

public define corback()
{
   variable fps=stderr;
   variable hist_index=0,wipe=1,b,rb,n;
   switch(_NARGS)
   {
    case 1:
      hist_index=();
   }
   {
    case 2:
      (hist_index,wipe)=();
   }
   {
      ()=__pop_list(_NARGS);
   }

   variable ahist = abs(int(hist_index));

   if(get_data_info(ahist)!=NULL && (hist_index<0 || wipe==NULL))
   {
      back_fun(ahist,NULL);
      
      if(get_data_info(ahist).bgd_file=="#_define_bgd()")
      {
         % Save the binning of the data, wipe it out, and then read
         % back in the existing background for these data, and then
         % rebin.
	      
         rb=get_data_info(ahist).rebin;
         n=get_data_info(ahist).notice_list;

         () = fprintf(fps, "\n%s\n", %%%{{{           

` Background errors are being restored to the data variance via any
 previously stored values.
`); %%%}}}
         rebin_data(ahist,0);
         () = _define_back(ahist, bkg_data[ahist], 
                                  bkg_area[ahist], bkg_exp[ahist]);
         rebin_data(ahist,rb);
         ignore(ahist);
         notice_list(ahist,n);
      }

      return;
   }
   else if(get_data_info(ahist)!=NULL)
   {
      % Save the binning of the data, wipe out any background
      % fit function, create a background for the data, rebin
	      
      rb=get_data_info(ahist).rebin;
      n=get_data_info(ahist).notice_list;

      back_fun(ahist,NULL);
      create_back(ahist);
 
      rebin_data(ahist,rb);
      ignore(ahist);
      notice_list(ahist,n);

      if(qualifier_exists("no_bkg_err"))
      {
         () = define_back(ahist,NULL);
         () = fprintf(fps, "\n%s\n", %%%{{{           
` Background errors will *not* be included in the data variance.
`); %%%}}}
      }

      back_fun(ahist,"fcorback("+string(ahist)+")");    
      set_par("fcorback("+string(ahist)+").id",ahist);
      return;
   }

   () = fprintf(fps, "\n%s\n", %%%{{{           
` corback(hist_index [; no_bkg_err]);

   Sets the background associated with data set hist_index as a
   correction file which can be scaled via a constant using the
   automatically defined function:

      fcorback(hist_index)  
 
   The background errors continue to be applied, presuming a unit
   scaling of the correction file (i.e., the errors do not update
   with fits of the correction normalization constant).

   Background errors can be turned off (i.e., excluded from the data
   variance) by setting the qualifier: no_bkg_err.

   To clear the background correction do:

      isis> corback(hist_index,NULL); ---or--- corback(-hist_index);

   If the background errors previously had been turned off via the 
   no_bkg_err qualifier, undoing the corback call will reset the 
   background via the _define_back(#) function. That is, the name of 
   the original data background file (if any) will no longer be listed; 
   however, the previously stored values for the background will be 
   restored.  (Background errors will then also be included in the data
   variance.)
`); %%%}}}
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define fcorfile_fit(lo,hi,par)
{
   return par[0]*bkg_data[int(par[2])] +
          par[1]*corfile_data[int(par[2])];
}
	
add_slang_function("fcorfile",["norm","cornorm","id"]);

%%%%%%%%%%%%%%%%%%%%%%%%%%

define fcorfile_default(i)
{
   switch(i)
   {
    case 0:
    return param_default_structure(1,0,0,2,0,1000,1.e-3,1.e-3);
   }
   {
    case 1:
    return param_default_structure(1,0,0,10,0,1000,1.e-3,1.e-3);
   }
   {
    case 2:
    return param_default_structure(1,1,1,100,1,1000,1,1);
   }
}

set_param_default_hook("fcorfile","fcorfile_default");

%%%%%%%%%%%%%%%%%%%%%%%

public define corfile()
{
   variable indx, wipe, cindx, rscl, rb, n;
   switch(_NARGS)
   {
    case 2:
      (indx, wipe) = ();

      if(wipe==NULL)
      {
         indx = int(abs(indx));
         back_fun(indx,NULL);

         % Make sure info really exists for background, and 
         % that you are not overwriting a file background
         % (latter should only happen if you've accidentally
         % invoked the correction, or you've overwritten the
         % data file; screwups still possible)

         if(length(bkg_data)>indx && bkg_data[indx]!=NULL &&
            length(corfile_app)>indx && corfile_app[indx]==1 &&
            get_data_info(indx).bgd_file=="#_define_bgd()")
         {
            rb=get_data_info(indx).rebin;
            n=get_data_info(indx).notice_list;
            rebin_data(indx,0);
            () = _define_back(indx,bkg_data[indx]/bkg_scl[indx],
                              bkg_area[indx],bkg_exp[indx]);
            corfile_app[indx]=0;
            rebin_data(indx,rb);
            ignore(indx);
            notice_list(indx,n);
         }
         return;
      }
   }
   {
    case 3:
      (indx, cindx, rscl) = ();

      indx = int(abs(indx));
      cindx = int(abs(cindx));
      rscl = abs(rscl);

      % Minimal check that background & corfile data are sanely
      % defined, and a check to make sure that a corfile isn't already
      % defined

      if(get_data_info(indx)!=NULL && get_data_info(cindx)!=NULL && rscl>0.
         && (length(corfile_app)<indx+1 || corfile_app[indx]!=1)            )
      {
         % Wipe out any existing background function
         back_fun(indx,NULL);

         % The correction file data & background, unbinned, and scale
         rb=get_data_info(cindx).rebin;
         n=get_data_info(cindx).notice_list;
         rebin_data(cindx,0);
         variable cdata = get_data_counts(cindx);
         variable cbgd = get_back(cindx);
         variable cscl;
         (cscl,,,,) = create_backscale(cindx);

         % Even though this will be excluded, set the corfile data
         % binning and noticing back to what it was originally
         rebin_data(cindx,rb);
         ignore(cindx);
         notice_list(cindx,n);

         % If there is no defined background, set it to zero
         if(cbgd==NULL) cbgd = Double_Type[length(cdata.value)];

         % Square of the errors on the correction data, allowing for
         % the fact that we might not be including the background
         % errors in the variance of the correction data.
         variable cbkg_err = qualifier("cbkg_err_scl",1);
         variable cbkg_sys = qualifier("cbkg_sys_frac",0);
         variable cerr2 = cdata.value + cbkg_err*cscl*cbgd 
                                      + (cbkg_sys*cbgd)^2;

         % These are the pieces that will be used in the
         % definition of the back_fun function

         % Make sure there are list elements to store the data

         if(indx > length(corfile_data)-1)
         {
            loop(indx-length(corfile_data)+1)
            {
               list_append(corfile_data,NULL);
               list_append(corfile_app,0);
            }
         }

         corfile_data[indx] = (cdata.value-cbgd);
         corfile_app[indx] = 1;
         exclude(cindx);

         % The background part...

         variable bscl, dexp, darea, bexp, barea;
         (bscl, dexp, darea, bexp, barea)  = create_backscale(indx);
         rb=get_data_info(indx).rebin;
         n=get_data_info(indx).notice_list;
         create_back(indx); 

         % The above defines the back_fun function.  However, we 
         % must redefine the data background so that errors are 
         % properly propagated in the fit.  (The data for dataset
         % indx, however, does not get redefined.  It is still the
         % total counts for the that dataset.)

         % Define the new scaled background as: (old scaled background
         % + corfile scale*[corfile data-scaled corfile background]
         % Define new (back error)^2 as: (old scale*old scaled
         % background + (corfile scale)^2 *[corfile data+corfile
         % backscale*corfile background])

         variable bkg_err = qualifier("bkg_err_scl",1);
         variable bkg_sys = qualifier("bkg_sys_frac",0);
         variable nback = bkg_data[indx] + rscl*(cdata.value-cbgd);
         variable nberr2 = bkg_err*bscl*bkg_data[indx] + 
                           (bkg_sys*bkg_data[indx])^2 + rscl^2*cerr2;

         % But in propagating errors, we need to have an unscaled
         % background (A) and scale (x) so that xA = new background
         % and (x^2*A) = (new backround error)^2. So, define the
         % background as A = (new back)^2/(new back error)^2, x = (new
         % back error)^2/(new back)

         variable dback=nback^2/nberr2;

         % but remember that ISIS will then scale the background by
         % the data area and exposure.  For simplicity, set the
         % background exposure equal to the data exposure, and then
         % define the background area scale so the backscale = x

         variable dscal=darea*nback/nberr2;

         % Help avoid 0/0 : background -> 0 here should take care of
         % these points, since that goes to 0 as nback^2.
         dscal[where(dscal==0.)]=1.;
         dscal[where(nberr2==0.)]=1.;
         dback[where(nberr2==0.)]=0.;
         
         () = _define_back(indx,dback,dscal,dexp);

         % Finish the job...
         
         back_fun(indx,"fcorfile("+string(indx)+")");    
         set_par("fcorfile("+string(indx)+").id",indx);
         set_par("fcorfile("+string(indx)+").cornorm",rscl);

         % Rebin the data back to its original binning

         rebin_data(indx,rb);
         ignore(indx);
         notice_list(indx,n);

         return;
      }
   }
   variable fps=stderr;
   () = fprintf(fps, "\n%s\n", %%%{{{     
` corfile(data_indx, corr_indx, scale [; bkg_err_scl, bkg_sys_frac, 
                                        cbkg_err_scl, cbkg_sys_frac]);
 
   Create new, scalable backgrounds for the dataset represented by
   data_indx that is comprised of its current background file plus the
   scaled, background subtracted data represented by dataset
   corr_indx.  Thus, this function can be used to create difference
   spectra between datasets data_indx and corr_indx.  (For example,
   data_indx could be spectra from a faint Galactic LMXB, while
   corr_indx is an observation of diffuse Galactic ridge emission.)

   Dataset data_indx is to be fitted, while dataset corr_indx is
   automatically excluded.

   scale is used to scale the background subtracted data, and is
   usually the ratio of exposure times for dataset data_indx divided
   by that for dataset corr_indx.

   Thus, the new dataset becomes:

        T_d - F_d*B_d - F_c*(T_c-B_c)

   with F_d and F_c being fittable constants via the newly defined
   function: fcorfile(data_indx).  (T=total counts, B=scaled
   background counts, d=data_indx, c=corr_indx).

   The errors for both background components will be added in
   quadrature and incorporated into the data variance presuming F_d=1
   and F_c=scale.  (I.e., the errors are not updated as the fit
   function normalization constants are updated.)

   This latter behavior can be modified by setting the bkg_err_scl,
   bkg_sys_frac, cbkg_err_scl, and/or the cbkg_sys_frac qualifiers.
   These qualifiers alter the data variance due to the data and
   correction file backgrounds and allow for systematic (i.e.,
   fractional) errors in these backgrounds.  Specifically, the data
   variance is taken as:

        T_d + b_d*s_d*B_d + (f_d*B_d)^2 + 
              scale*( T_c + b_c*s_c*B_c + (f_c*B_c)^2 )

   where s are the usual scaling factors for the scaled backgrounds,
   b_d/b_c (defaults of 1) are set by bkg_err_scl/cbkg_err_scl, and
   f_d/f_c (defaults of 0) are set by bkg_sys_frac/cbkg_sys_frac.  For
   example, bkg_err_scl=cbkg_err_scl=bkg_sys_frac=ckg_sys_frac=0
   yields a data variance that is only dependent upon the measured
   counts. bkg_err_scl=cbkg_err_scl=0, bkg_sys_frac=ckg_sys_frac=0.01
   yields a data variance that incorporates a 1% systematic error in
   both the data background and correction file background counts.

   Systematic data errors (if any) will be continued to be applied to
   dataset data_indx, but will not be incorporated for dataset
   corr_indx.

   No error checking is done to make sure that the corr_indx dataset is 
   compatible with the dataset from data_indx.

   To clear the background correction do:

      isis> corfile(data_indx, NULL);

   The original data background will be restored as a defined
   background via the _define_back(#) function.  The original
   background file name will no longer be seen in a list_data call.
   The background file can be re-read via define_back to restore the
   original file name. (This is not strictly necessary, as
   _define_back(#) will restore all of the original information from
   this file.)
`); %%%}}}
   return;
}

%%%%%%%%%%%%%%%%%%%%

define bayes_nconf()
{
   switch(_NARGS)
   {
    case 2:
       variable n,sig;
      (n,sig) = ();
   }
   {
      variable fps=stderr;
      () = fprintf(fps, "\n%s\n", %%%{{{     
` (nlow,nhigh) = bayes_nconf(nobs,sig);
 
   Given an observed number of counts and a desired significance level
   return the Bayesian prediction for the true model counts, using
   symmetric bounds [i.e., P(n<nlow) = P(n>nhhigh)].
 
 Inputs:
   nobs : The observed counts.
   sig  : The desired significance
 
 Outputs:
   nlow : Lower predicted bound
   nhigh: Upper predicted bound
`); %%%}}}
      return;
   }
   % We'll search 10^-4 to 63
   variable x = 10.^([-4000:1800]/1000.);
   variable ser=0.,fac=1.,lser,ub,wl,wu;
   variable i=0;
   loop(n+1)
   {
      ser = ser + x^i/fac;
      i++;
      fac = fac*i;
   }

   ub = -x+log(ser);

   wl = x[ max( where(ub > log((sig+1)/2.)) ) ];
   wu = x[ min( where(ub < log((1-sig)/2.)) ) ];

   return wl, wu;
}

%%%%%%%%%%%%%%%%%%%%

define bayes_sconf()
{
   switch(_NARGS)
   {
    case 3:
       variable n,xl,xu;
      (n,xl,xu) = ();
   }
   {
      variable fps=stderr;
      () = fprintf(fps, "\n%s\n", %%%{{{     
` (sig_low,sig_high) = bayes_sconf(nobs,nlow,nhigh);

   Given an observed number of counts and a lower counts bound and an
   upper counts bound, return the Bayesian estimate of the associated
   significance level, assuming symmetric bounds for the significance
   [i.e., P(n<nlow) = P(n>nhhigh)].

 Inputs:
   nobs    : The observed counts.
   nlow    : The desired lower counts bound
   nhigh   : The desired upper counts bound

 Outputs:
   sig_low : Estimated significance of lower counts
   sig_high: Estimated significance of upper counts
`); %%%}}}
      return;
   }
   % We'll search 10^-4 to 63
   variable sig = [-13000:0]/1000.; % log(1-sig)
   variable esig = log(2.-exp(sig));
   variable lser=0.,user=0.,fac=1.,lb,ub,wl,wu;
   variable i=0;
   loop(n+1)
   {
      lser = lser + xl^i/fac;
      user = user + xu^i/fac;
      i++;
      fac = fac*i;
   }

   lb = -xl+log(lser);
   ub = -xu+log(user);

   wl = 1.-exp(sig[ min( where(lb > esig - log(2.)) ) ]);
   wu = 1.-exp(sig[ max( where(ub > sig - log(2.)) ) ]);

   return wl,wu;
}

%%%%%%%%%%%%%%%%%%%%
