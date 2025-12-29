% -*- slang -*-

% Last Updated: July 22, 2016


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Public Functions in This File.  Usage message (almost always) when 
% function is called without arguments.

% eqw         : Calculate a line equivalent width in mA and eV
% data_flux   : Calculate the flux between two bounds, based upon the 
%               observed data (does not extend beyond data grid)
% model_flux  : Calculate the flux between two bounds, based upon the 
%               fitted model (does not extend beyond model grid)
% calc_flux   : Calculate the flux based upon the fitted model, using 
%               an arbitrary grid (full grid must be input)
% flux_err    : Monte Carlo estimate of model flux errors (probably
%               wrong in practice in most cases)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%

public define eqw()
{
   variable indx, par, pmin=0, lo=NULL, hi=NULL, eva, eve, bounds, unit;
   variable fv_hold = Fit_Verbose;

   switch(_NARGS)
   { case 2:
      (indx, par) = ();
   }
   {
      variable fp=stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
+" (ew_ma, ew_ev) = eqw(indx, par [; pmin=#, bounds={val,val}, unit=string, noeval, print]);\n"
+"\n"
+" Calculate the equivalent width for a model component, in milli-angstrom and eV.\n"
+"\n"
+"  Inputs:\n"
+"   indx  = Data set index to which the model is applied\n"
+"   par   = Number for, *or* string with the name of, the *normalization*\n"
+"           parameter for the model component for which the EW will be calculated\n"
+"\n"
+"  Optional Qualifier Inputs:\n"
+"   pmin  = For parameter par, the value to which it should be set when calculating\n"
+"           the continuum flux without the line (default = 0, but this allows \n"
+"           other parameter toggles to be used).\n"
+"   bounds= *Energy* ranges (in keV) over which to restrict the\n"
+"           evaluation of the equivalent width. (Otherwise, uses\n"
+"           the full energy range of the arf; see get_model_flux();)\n"
+"   unit  = Units (case insensitive string) for the values of bounds (default=\"kev\")\n"
+"   noeval- If exists, don't do the final eval_counts (parameters will be reset\n"
+"           to initial values, but not evaluated - i.e., plots won't show\n"
+"           the fit with the line, and may otherwise be screwy)\n"
+"   print - If exists, don't output the results, rather, print to screen\n"
+"\n"
+"  Outputs:\n"
+"   ew_ma, ew_ev : Equivalent widths in milli-angstrom and eV\n"); %%%}}}
      return;
   }

   pmin = qualifier("pmin",0.);
   bounds = qualifier("bounds",NULL);
   unit = qualifier("unit","kev");

   if(length(bounds)==2 && bounds[0] != NULL && bounds [1] != NULL)
   {
      if(unit_info(unit).is_energy)
      {
         lo = _A(max([bounds[0],bounds[1]])/unit_info(unit).scale);
         hi = _A(min([bounds[0],bounds[1]])/unit_info(unit).scale);
      }
      else
      {
         lo = min([bounds[0],bounds[1]])/unit_info(unit).scale;
         hi = max([bounds[0],bounds[1]])/unit_info(unit).scale;
      }
   }

   Fit_Verbose = -1;
   () = eval_counts;

   variable a = get_model_flux(indx);
   variable phold = get_par_info(par);

   set_par(par,pmin,0,min([0.,pmin,phold.min]),max([0,pmin,phold.max]));
   () = eval_counts;
   variable b = get_model_flux(indx);

   set_par(par,phold.value,phold.freeze,phold.min,phold.max);

   ifnot(qualifier_exists("noeval")) () = eval_counts;

   variable iw, iwa, iwe;
   if( lo != NULL && hi != NULL )
   {
      iw = where(a.bin_lo >= lo and a.bin_hi <= hi);
   }
   else
   {
      iw = [0:length(a.bin_lo)-1];
   }
   
   variable diff = a.value - b.value;
   variable bdena = b.value/(a.bin_hi-a.bin_lo);
   variable bdene = reverse(reverse(b.value)/(_A(a.bin_lo)-_A(a.bin_hi)));
   variable fdena = diff/(a.bin_hi-a.bin_lo);
   variable fdene = reverse(reverse(diff)/(_A(a.bin_lo) - _A(a.bin_hi)));
   variable flux = sum( diff[iw] );

   iwa = min(where( abs(fdena[iw]) == max(abs(fdena[iw])) ));
   iwe = min(where( abs(fdene[iw]) == max(abs(fdene[iw])) ));
   
   eva = flux/bdena[iw[iwa]]*1000.;
   eve = flux/bdene[iw[iwa]]*1000.;

   Fit_Verbose = fv_hold;

   ifnot(qualifier_exists("print"))
   {
      return eva, eve;
   }
   else
   {
      () = printf("\n Equivalent Width  (mA):  %8.4e ",eva);
      () = printf("\n Equivalent Width  (eV):  %8.4e \n\n",eve);
     }
  }

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define calc_eqw()
{
   variable i, indx, par, fpar, pars, pmin=0, lo=NULL, hi=NULL, eva, eve, bounds, unit;
   variable fv_hold = Fit_Verbose;

   switch(_NARGS)
   { case 4:
      (indx, par, fpar, pars) = ();
   }
   {
      variable fp=stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
+" ew = calc_eqw(indx, par, fpar, pars [; pmin=#, bounds={val,val}, unit=string]);\n"
+"\n"
+" Calculate a model component equivalent width, in milli-angstrom or eV (default),\n"
+" given a full set of model free-parameters.  Note: current model parameters will\n"
+" be overwritten with values from this function call.\n"
+"\n"
+"  Inputs:\n"
+"   indx  = Data set index for which the EW is calculated\n"
+"   par   = Number for, *or* string with the name of, the *normalization*\n"
+"           parameter for the model component for which the EW will be calculated\n"
+"   fpar  = Array of indices of free parameters\n"
+"   pars  = Array of values of free parameters\n"
+"\n"
+"  Optional Qualifier Inputs:\n"
+"   pmin  = For parameter par, the value to which it should be set when calculating\n"
+"           the continuum flux without the line (default = 0, but this allows \n"
+"           other parameter toggles to be used).\n"
+"   bounds= *Energy* ranges (in keV) over which to restrict the\n"
+"           evaluation of the equivalent width. (Otherwise, uses\n"
+"           the full energy range of the arf; see get_model_flux();)\n"
+"   unit  = Units (case insensitive string) for the values of bounds (default=\"kev\")\n"
+"   mA    - If exists, output the euivalent width in milliAngstrom\n"
+"\n"
+"  Outputs:\n"
+"   ew: Equivalent width in milli-angstrom or eV (default)\n"); %%%}}}
      return;
   }

   pmin = qualifier("pmin",0.);
   bounds = qualifier("bounds",NULL);
   unit = qualifier("unit","kev");

   if(length(bounds)==2 && bounds[0] != NULL && bounds [1] != NULL)
   {
      if(unit_info(unit).is_energy)
      {
         lo = _A(max([bounds[0],bounds[1]])/unit_info(unit).scale);
         hi = _A(min([bounds[0],bounds[1]])/unit_info(unit).scale);
      }
      else
      {
         lo = min([bounds[0],bounds[1]])/unit_info(unit).scale;
         hi = max([bounds[0],bounds[1]])/unit_info(unit).scale;
      }
   }

   Fit_Verbose = -1;

   _for i (0,length(fpar)-1,1)
   {
      set_par(fpar[i],pars[i]);
   }

   () = eval_counts;

   variable a = get_model_flux(indx);
   variable phold = get_par_info(par);

   set_par(par,pmin,0,min([0.,pmin,phold.min]),max([0,pmin,phold.max]));
   () = eval_counts;
   variable b = get_model_flux(indx);

   set_par(par,phold.value,phold.freeze,phold.min,phold.max);

   variable iw, iwa, iwe;
   if( lo != NULL && hi != NULL )
   {
      iw = where(a.bin_lo >= lo and a.bin_hi <= hi);
   }
   else
   {
      iw = [0:length(a.bin_lo)-1];
   }
   
   variable diff = a.value - b.value;
   variable bdena = b.value/(a.bin_hi-a.bin_lo);
   variable bdene = reverse(reverse(b.value)/(_A(a.bin_lo)-_A(a.bin_hi)));
   variable fdena = diff/(a.bin_hi-a.bin_lo);
   variable fdene = reverse(reverse(diff)/(_A(a.bin_lo) - _A(a.bin_hi)));
   variable flux = sum( diff[iw] );

   iwa = min(where( abs(fdena[iw]) == max(abs(fdena[iw])) ));
   iwe = min(where( abs(fdene[iw]) == max(abs(fdene[iw])) ));
   
   eva = flux/bdena[iw[iwa]]*1000.;
   eve = flux/bdene[iw[iwa]]*1000.;

   Fit_Verbose = fv_hold;

   ifnot(qualifier_exists("mA"))
   {
      return eve;
   }

   return eva;

  }

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define model_flux ( )
{
   variable id, lo, hi, bounds, unit, pc, m, e_avg, pflux, eflux, fp=stderr;

   switch(_NARGS)
   {
    case 3:
      (id,lo,hi) = ();
   }
   {
       () = fprintf(fp, "\n%s\n", %%%{{{
+" (photon_flux, energy_flux) = model_flux(indx,lo,hi [;unit=string, pc=#, print]);\n"
+"\n"
+"   Returns model fluxes for data set indx evaluated over the energy interval (keV)\n"
+"   bounded by lo, hi.  Outputs are units of: \n"
+"\n"
+"      photons/cm^2/sec, ergs/cm^2/sec  (if pc=NULL [DEFAULT])\n"
+"      photons/sec, ergs/sec            (if pc>0)\n"
+"\n"
+"   Optional qualifiers:\n"
+"\n"
+"      unit  = Units (case insensitive string) for the values of lo, hi (default=\"kev\")\n"
+"      pc    = distance, in parsec, to the source (default=NULL)\n"
+"      print - if present, print results to screen without returning values (default off)\n"
+"\n"
+"   See also:  data_flux, calc_flux\n"); %%%}}}
      return;
   }   

   m = get_model_flux(id);

   unit=qualifier("unit","kev");

   if(unit_info(unit).is_energy)
   {
      bounds = _A([min([lo,hi]),max([lo,hi])]/unit_info(unit).scale);
      if(bounds[1] > m.bin_hi[-1])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: lower energy bound is below that of model data.\n"
+"               *** Use calc_flux(); instead ***\n"); %%%}}}
      if(bounds[0] < m.bin_lo[0])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: upper energy bound is above that of model data.\n"
+"               *** Use calc_flux(); instead ***\n"); %%%}}}
   }
   else
   {
      bounds = [min([lo,hi]),max([lo,hi])]/unit_info(unit).scale;
      if(bounds[0] < m.bin_lo[0])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: lower wavelength bound is below that of model data.\n"
+"               *** Use calc_flux(); instead ***\n"); %%%}}}
      if(bounds[1] > m.bin_hi[-1])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: upper wavelength bound is above that of model data.\n"
+"               *** Use calc_flux(); instead ***\n"); %%%}}}
   }

   pflux = rebin (bounds[0], bounds[1], m.bin_lo, m.bin_hi, m.value)[0];   

   e_avg = _A(1.)*(1./m.bin_hi+1./m.bin_lo)/2.*Const_eV*1.e3;
   eflux = rebin (bounds[0], bounds[1], m.bin_lo, m.bin_hi, m.value*e_avg)[0];  

   pc = qualifier("pc",NULL);

   variable phot_string=" photons/cm^2/sec";
   variable e_string=" ergs/cm^2/sec";

   if( pc != NULL && pc > 0)
   { 
      variable scl = 4*PI*(3.08568025e18*pc)^2;
      pflux *= scl;
      eflux *= scl;
      phot_string=" photons/sec";
      e_string=" ergs/sec";
   }

   if(qualifier_exists("print"))
   {
      () = printf("\n Photon Flux:  %8.4e "+phot_string,pflux);
      () = printf("\n Energy Flux:  %8.4e "+e_string+"\n\n",eflux);
      return;
   }
   else
   {
      return pflux, eflux;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define data_flux ( )
{
   variable id, lo, hi, bounds, unit, pc, m, e_avg, pflux, pflux_err, eflux, eflux_err, fp=stderr;

   switch(_NARGS)
   {
    case 3:
      (id,lo,hi) = ();
   }
   {
      () = fprintf(fp, "\n%s\n", %%%{{{ 
+" (photon_flux, pflux_err, energy_flux, eflux_err) = data_flux(indx,lo,hi [; unit=string, pc=value, print]);\n"
+" \n"
+"   Returns data fluxes (via flux_corr/get_data_flux) for data set indx evaluated over\n"
+"   energy interval (keV) bounded by lo, hi. Error is error of the mean value of the flux.\n"
+"   Outputs are units of: \n"
+"\n"
+"      photons/cm^2/s, photons/cm^2/s, ergs/cm^2/s, ergs/cm^2/s  (if pc=NULL [DEFAULT])\n"
+"      photons/s, photons/s, ergs/s, ergs/s                      (if pc>0)\n"
+"\n"
+"   Optional qualifiers:\n"
+"\n"
+"      unit  = Units (case insensitive string) for the values of lo, hi (default=\"kev\")\n"
+"      pc    = distance, in parsec, to the source (default=NULL)\n"
+"      print - if exists, print results to screen without returning values (default off)\n"
+"\n"
+"   See also:  model_flux, calc_flux\n"); %%%}}}
      return;
   }   

   flux_corr(id);
   m = get_data_flux(id);

   unit=qualifier("unit","kev");

   if(unit_info(unit).is_energy)
   {
      bounds = _A([min([lo,hi]),max([lo,hi])]/unit_info(unit).scale);
      if(bounds[1] > m.bin_hi[-1])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: lower energy bound is below that of data.\n"
+"               *** Flux is lower limit estimate ***\n"); %%%}}}
      if(bounds[0] < m.bin_lo[0])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: upper energy bound is above that of data.\n"
+"               *** Flux is lower limit estimate ***\n"); %%%}}}
   }
   else
   {
      bounds = [min([lo,hi]),max([lo,hi])]/unit_info(unit).scale;
      if(bounds[0] < m.bin_lo[0])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: lower wavelength bound is below that of data.\n"
+"               *** Flux is lower limit estimate ***\n"); %%%}}}
      if(bounds[1] > m.bin_hi[-1])
         () = fprintf(fp, "\n%s\n", %%%{{{
+"***WARNING***: upper wavelength bound is above that of data.\n"
+"               *** flux is lower limit estimate ***\n"); %%%}}}
   }

   pflux = rebin(bounds[0], bounds[1], m.bin_lo, m.bin_hi, m.value)[0];   
   pflux_err = sqrt( rebin(bounds[0], bounds[1], m.bin_lo, m.bin_hi, m.err^2)[0]);

   variable n = length( where(m.bin_lo >= bounds[0] and m.bin_hi <= m.bin_hi) );
   if(n<=1) {  n=2; message("\n ***WARNING***: only one data flux bin in interval. \n"); }

   e_avg = _A(1.)*(1./m.bin_hi+1./m.bin_lo)/2.*Const_eV*1.e3;
   eflux = rebin (bounds[0], bounds[1], m.bin_lo, m.bin_hi, m.value*e_avg)[0];  
   eflux_err = sqrt( rebin(bounds[0], bounds[1], m.bin_lo, m.bin_hi, (m.err*e_avg)^2)[0]);

   pc = qualifier("pc",NULL);

   variable phot_string=" photons/cm^2/sec";
   variable e_string=" ergs/cm^2/sec";

   if( pc != NULL && pc > 0)
   { 
      variable scl = 4*PI*(3.08568025e18*pc)^2;
      pflux *= scl;
      pflux_err *= scl;
      eflux *= scl;
      eflux_err *= scl;
      phot_string=" photons/sec";
      e_string=" ergs/sec";   }

   if(qualifier_exists("print"))
   {
      () = printf("\n Photon Flux:  %8.4e +/- %8.4e"+phot_string,pflux,pflux_err);
      () = printf("\n Energy Flux:  %8.4e +/- %8.4e"+e_string+"\n\n",eflux,eflux_err);
      return;
   }
   else
   {
      return pflux, pflux_err, eflux, eflux_err;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define calc_flux ( )
{
   variable id, lo, hi, bin_lo, bin_hi, unit, pc, m, e_avg, pflux, eflux,  fp=stderr;

   switch(_NARGS)
   {
    case 3:
      (id,lo,hi) = ();
   }
   {
      () = fprintf(fp, "\n%s\n", %%%{{{
+"(photon_flux, energy_flux) = calc_flux(indx,bin_lo,bin_hi [; unit=string, pc=value, print]);\n"
+"\n"
+"   Returns model flux for data set indx evaluated over the grid defined by bin_lo, bin_hi.\n"
+"   Outputs are units of: \n"
+"\n"
+"      photons/cm^2/sec, ergs/cm^2/sec  (if pc=NULL [DEFAULT])\n"
+"      photons/sec, ergs/sec            (if pc>0)\n"
+"\n"
+"   Optional qualifiers:\n"
+"\n"
+"      unit  = Units (case insensitive string) for the values of lo, hi (default=\"kev\")\n"
+"      pc    = distance, in parsec, to the source (default=NULL)\n"
+"      print - if exists, print results to screen without returning values (default off)\n"
+"\n"
+"   See also:  model_flux, data_flux\n"); %%%}}}
      return;
   }   

   unit = qualifier("unit","kev");

   if(unit_info(unit).is_energy)
   {
      bin_lo = _A(hi/unit_info(unit).scale);
      bin_hi = _A(lo/unit_info(unit).scale);
   }
   else
   {
      bin_lo = lo/unit_info(unit).scale;
      bin_hi = hi/unit_info(unit).scale;
   }

   Isis_Active_Dataset=id;
   m = eval_fun(bin_lo,bin_hi);

   pflux = sum(m);

   e_avg = _A(1.)*(1./bin_hi+1./bin_lo)/2.*Const_eV*1.e3;
   eflux = sum(m*e_avg);  

   pc = qualifier("pc",NULL);

   variable phot_string=" photons/cm^2/sec";
   variable e_string=" ergs/cm^2/sec";

   if( pc != NULL && pc > 0)
   { 
      variable scl = 4*PI*(3.08568025e18*pc)^2;
      pflux *= scl;
      eflux *= scl;
      phot_string=" photons/sec";
      e_string=" ergs/sec";
   }

   if(qualifier_exists("print"))
   {
      () = printf("\n Photon Flux:  %8.4e "+phot_string,pflux);
      () = printf("\n Energy Flux:  %8.4e "+e_string+"\n\n",eflux);
      return;
   }
   else
   {
      return pflux, eflux;
   }
}

#iftrue
%%%%%%%%%%%%%%%%%

% Right now, this only use the diagonal elements of the covariance
% matrix (i.e., the single parameter errors).  With changes to the
% ISIS internals, could probably get access to estimates of the other
% values


define flux_err()
{
   variable indx, lo, hi, file, nloop, nbin, delt, pflux, eflux, fp=stderr;

   switch(_NARGS)
   {
    case 3:
      (indx,lo,hi) = ();
   }
   {
      () = fprintf(fp, "\n%s\n", %%%{{{
+" (pflux, eflux) = flux_err(indx,lo,hi [;unit=val, nloop=val, nbin=val,\n"
+"                                        sigma=val, file=string]);\n"
+" \n"
+"   Generates Monte Carlo evaluations of the model flux by varying the\n"
+"   input parameters (assuming gaussian statistics) between lower and\n"
+"   upper bounds for *all* unfrozen and untied parameters.  By default,\n"
+"   the parameter bounds are presumed to be 90% confidence  limits, i.e.,\n"
+"   sigma=+/-sqrt(2.71).  All parameters are also presumed to be statistically\n"
+"   independent (probably a bad assumption in many cases). The parameter\n"
+"   ranges are taken from the min/max limits of the current model parameters,\n"
+"   unless another input file is specified (e.g., the save file from a conf_loop\n"
+"   run).  Results are returned as a structure variable which contains the\n"
+"   fluxes from the individual evaluations, as well as histograms of the values,\n"
+"   statistical properties (mean and standard deviation)\n"
%+"   If the GSL module has been loaded, then results from fitting the histogram\n"
%+"   with a gaussian are also provided.\n"
+"\n"
+"   Inputs: \n"
+"\n"
+"      indx            - Data set index for which the flux will be evaluated\n"
+"      lo, hi          - Low/high unit boundaries for the flux evaluation\n"
+" \n" 
+"   Outputs: \n"
+"\n"
+"    pflux.value     - Photon fluxes in units of photons/cm^2/s\n"
+"    pflux.mean      - Mean value of the photon fluxes in units of photons/cm^2/s\n"
+"    pflux.sdev      - Photon flux standard deviation in units of photons/cm^2/s\n"
+"    pflux.bin_lo    - Array for lower bounds of photon flux histogram\n"
+"    pflux.bin_hi    - Array for upper bounds of photon flux histogram\n"
+"    pflux.hist_val  - Array for histogram values\n"
%+"    pflux.hist_mean - Fitted histogram mean\n"
%+"    pflux.hist_sigma- Fitted histogram sigma\n"
+"\n"
+"    eflux           - Structure variable with the same fields as pflux, but in\n"
+"                      units of ergs/cm^2/sec\n"
+"   Optional qualifiers:\n"
+"\n"
+"    unit  = units of the lo, hi bounds  (default=\"kev\")\n"
+"    nloop = Number of Monte Carlo evaluations to perform (default=1000)\n"
+"    nbin  = Number of histogram bins to use (default=nloop/100)\n"
+"    sigma = The sigma to which the min/max parameter values correspond (default=sqrt(2.71))\n"
+"    file  = The name of the file containing the parameter min/max bounds (default=NULL)\n"
+"\n"
+"   See also:  model_flux, data_flux, calc_flux, conf_loop\n"); %%%}}}
      return;
   }   

   pflux = struct{ value, mean, sdev, bin_lo, bin_hi, hist_vals, hist_mean, hist_sigma };
   eflux = struct{ value, mean, sdev, bin_lo, bin_hi, hist_vals, hist_mean, hist_sigma };

   save_par("/tmp/temp.par");

   if(qualifier_exists("file"))
      load_par(qualifier("file"));

   nloop=qualifier("nloop",1000);
   nbin=qualifier("nbin",nloop/100);
   delt=qualifier("sigma",sqrt(2.71));

   variable fv_hold = Fit_Verbose;
   Fit_Verbose=-1;

   variable i, ii, x, puse, aindx=Integer_Type[0];
   variable par=Double_Type[0], min_par=Double_Type[0], max_par=Double_Type[0];

   _for ii (1,get_num_pars,1)
   {
      puse = get_par_info(ii);
      if(puse.freeze==0 && puse.tie==NULL)
      {
         aindx = [aindx,ii];
         par = [par,puse.value];
         min_par = [min_par,puse.min];
         max_par = [max_par,puse.max];
      }
   }

   pflux.value = Double_Type[nloop];
   eflux.value = Double_Type[nloop];

   _for i (0,nloop-1,1)
   {
      _for ii (0,length(par)-1,1)
      {
         forever
         {
            x = grand(1);
            if(abs(x[0]) < delt) break;
         }
         if( x[0] <= 0 )
         {
            puse = par[ii]+x*(par[ii]-min_par[ii])/delt;
         }
         else
         {
            puse = par[ii]+x*(max_par[ii]-par[ii])/delt;
         }
         set_par(aindx[ii],puse);
      }
      () = eval_counts;
      (pflux.value[i], eflux.value[i]) = model_flux(indx,lo,hi;;__qualifiers);
   }
   load_par("/tmp/temp.par");
   () = eval_counts;
   Fit_Verbose = fv_hold;

   variable stats = moment(pflux.value);
   pflux.mean = stats.ave;
   pflux.sdev = stats.sdev;

   stats = moment(eflux.value);
   eflux.mean = stats.ave;
   eflux.sdev = stats.sdev;

   (pflux.bin_lo,pflux.bin_hi) = linear_grid(min(pflux.value),max(pflux.value),nbin);
   pflux.hist_vals = histogram(pflux.value,pflux.bin_lo,pflux.bin_hi);

   (eflux.bin_lo,eflux.bin_hi) = linear_grid(min(eflux.value),max(eflux.value),nbin);
   eflux.hist_vals = histogram(eflux.value,eflux.bin_lo,eflux.bin_hi);

   return pflux, eflux;
}
#endif
