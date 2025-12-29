define hardnessratio_simulate_grid()
%!%+
%\function{hardnessratio_simulate_grid}
%\synopsis{calculates hardnessratios of the current model}
%\usage{Struct_Type[] hardnessratio_simulate_grid(String_Type/Integer_Type par1name, par2name,
%		     Integer_Type[2] soft_ch1, hard_ch1, soft_ch2, hard_ch2);
% or Struct_Type[] hardnessratio_simulate_grid(
%      String_Type/Integer_Type par1name, Double_Type par1min, par1max, step1,
%      String_Type/Integer_Type par2name, Double_Type par2min, par2max, step2,
%      Integer_Type soft_ch1, hard_ch1, soft_ch2, hard_ch2
%    );}
%\qualifiers{
%\qualifier{dataindex}{Integer_Type, dataset index to use, default = 1}
%\qualifier{grid1scale}{0 = linear (default), 1 = logarithmic}
%\qualifier{grid2scale}{0 = linear (default), 1 = logarithmic}
%\qualifier{par1grid}{Double_Type[], override value grid of paramter 1}
%\qualifier{par2grid}{Double_Type[], override value grid of paramter 2}
%\qualifier{sample1}{Integer_Type, sampling-factor along each track, default 10}
%\qualifier{sample2}{Integer_Type, sampling-factor along each track, default 10}
%\qualifier{exposure}{Double_Type, default: 1e4}
%\qualifier{arf}{String_Type, file path of arf}
%\qualifier{rmf}{String_Type, file path of rmf}
%\qualifier{rsp}{String_Type, file path of rsp (arf and rmf combined)}
%\qualifier{soft_en1}{Double_Type[2], additional qualifier, soft band for all tracks in one direction}
%\qualifier{hard_en1}{Double_Type[2], additional qualifier, hard band for all tracks in one direction}
%\qualifier{soft_en2}{Double_Type[2], additional qualifier, soft band for all tracks in other direction}
%\qualifier{hard_en2}{Double_Type[2], additional qualifier, hard band for all tracks in other direction}
%    additional qualifiers are passed to 'hardnessratio_from_dataset' and 'hardnessratio'
%}
%\description
%    - at least one dataset has to be defined (load_data)
%    - a model must exist (fit_fun)
%    - soft_ch1, hard_ch1, soft_ch2, hard_ch2 are passed to 'hardnessratio_from_dataset'; if energy-bands
%      (soft_en1...)are given, the channels have to be set to [0,0] each.
%    - if logarithmic gridscale is chosen, be careful 'parmin' is not <= zero (be aware of the default
%      values of your model)
%    - the output consists of an array of structures of tracks, where each track contains the values of par1, par2 and the 
%     corresponding hardnessratios hr1 and hr2, and the errors hr1err and hr2err e.g. within one struct par1 is kept constant
%    - either give arf AND rmf; or ONLY give rsp
%\seealso{hardnessratio, hardnessratio_from_dataset, xfigplot_hardnessratio_grid}
%!%-
{
 variable par1name, par2name, par1min, par2min, par1max, par2max, step1 = 10, step2 = 10;
 variable soft_ch1, hard_ch1, soft_ch2, hard_ch2;
 switch(_NARGS)
 { case 6: (par1name, par2name, soft_ch1, hard_ch1, soft_ch2, hard_ch2) = (); }
 { case 12: (par1name, par1min, par1max, step1, par2name, par2min, par2max, step2, soft_ch1, hard_ch1, soft_ch2, hard_ch2) = (); }
 { help(_function_name()); return; }

 % get default values for parameter ranges (if not already set by user)
 variable finipar = merge_struct_arrays(get_params);
 variable par1type = typeof(par1name) == String_Type ? 1 : 0;
 variable par2type = typeof(par2name) == String_Type ? 1 : 0;
 variable par1ind = wherefirst((par1type ? finipar.name : finipar.index) == par1name);
 variable par2ind = wherefirst((par2type ? finipar.name : finipar.index) == par2name);
 if (__is_numeric(par1min) == 0) { par1min = finipar.min[par1ind]; }
 if (__is_numeric(par1max) == 0) { par1max = finipar.max[par1ind]; }
 if (__is_numeric(par2min) == 0) { par2min = finipar.min[par2ind]; }
 if (__is_numeric(par2max) == 0) { par2max = finipar.max[par2ind]; }
 variable sample1 = qualifier("sample1", 10);
 variable sample2 = qualifier("sample2", 10);
  
 % build parameter arrays
 variable par1grid=qualifier("par1grid",NULL);
 variable par2grid=qualifier("par2grid",NULL);
 variable par1arr, par2arr;

 if(par1grid == NULL){
   par1arr =  qualifier("grid1scale", 0) == 0
   ? 1. * par1min + (par1max-par1min)*[0:step1-1]/(step1-1.)
   : exp(1. * log(par1min) + (log(par1max)-log(par1min))*[0:step1-1]/(step1-1.));
 }else{
   par1arr = par1grid;
 }

 if(par2grid == NULL){
   par2arr = qualifier("grid2scale", 0) == 0
   ? 1. * par2min + (par2max-par2min)*[0:step2-1]/(step2-1.)
   : 1. * exp(log(par2min) + (log(par2max)-log(par2min))*[0:step2-1]/(step2-1.));
 }else{
   par2arr = par2grid;
 }

 % dataset index to get the model/data counts
 variable idat = qualifier("dataindex", 1);

 % set data exposure, ARF, RMF, or data-exposure?
 variable expt = qualifier("exposure", 1e4);
 variable arf = qualifier("arf", NULL);
 if (arf != NULL) {
   vmessage("assigning ARF");
   if (typeof(arf) == String_Type) { arf = load_arf(arf); }
   assign_arf(arf, idat);
   set_arf_exposure(arf, expt);
 }
 variable rsp = qualifier("rsp", NULL);
 if (rsp != NULL) {
   vmessage("loading RSP");
   if (typeof(rsp) == String_Type) { rsp = load_rmf(rsp); }
   arf=factor_rsp(rsp);
   vmessage("assigning RMF");
   assign_rmf(rsp, idat);
   vmessage("assigning ARF");
   assign_rmf(arf, idat);
 }
 if (all(all_data != idat)) {
   vmessage("creating dataset and setting exposure");
   set_data_exposure(idat, expt);
 }
 variable rmf = qualifier("rmf", NULL);
 if (rmf != NULL) {
   vmessage("assigning RMF");
   if (typeof(rmf) == String_Type) { rmf = load_rmf(rmf); }
   assign_rmf(rmf, idat);
 }

 % set qualifier-structures to be passed to hardnessratio_from_dataset
 variable qual1 = COPY(__qualifiers), qual2 = COPY(__qualifiers);
 if (qualifier_exists("soft_en1")) { qual1 = struct_combine(qual1, struct { soft_en = qualifier("soft_en1") }); }
 if (qualifier_exists("hard_en1")) { qual1 = struct_combine(qual1, struct { hard_en = qualifier("hard_en1") }); }
 if (qualifier_exists("soft_en2")) { qual2 = struct_combine(qual2, struct { soft_en = qualifier("soft_en2") }); }
 if (qualifier_exists("hard_en2")) { qual2 = struct_combine(qual2, struct { hard_en = qualifier("hard_en2") }); }
 qual1 = struct_combine(qual1, struct { subtract_background=0, get_counts = &get_model_counts });
 qual2 = struct_combine(qual2, struct { subtract_background=0, get_counts = &get_model_counts });

 % prepare output struct-array
 variable tracks = Struct_Type[0];
 variable x, y, len, track, ratio1, ratio2;
 % loop over parameter 1
 _for x (0, length(par1arr)-1, 1) {
   % prepare track structure
   len = length(par2arr)*sample2;
   track = struct {
     par1 = par1arr[x] * ones(len), par2 = [par2arr[0]:par2arr[-1]:#len],
     hr1 = Double_Type[len], hr2 = Double_Type[len],
     hr1err = Double_Type[len], hr2err = Double_Type[len],
     linetype = -1
   };
   % set parameters
   set_par(par1name, par1arr[x]);
   _for y (0, len-1, 1) {
     set_par(par2name, track.par2[y]);
     % evaluate model (fold with detector response)
     ()=eval_counts(; fit_verbose = -1);
     % calculate hardnesses
     ratio1=hardnessratio_from_dataset(idat, soft_ch1, hard_ch1;; qual1);
     ratio2=hardnessratio_from_dataset(idat, soft_ch2, hard_ch2;; qual2);
     track.hr1[y]=ratio1.ratio;
     track.hr2[y]=ratio2.ratio;
     track.hr1err[y]=ratio1.err;
     track.hr2err[y]=ratio2.err;
     %track.hr1[y] = hardnessratio_from_dataset(idat, soft_ch1, hard_ch1;; qual1);
     %track.hr2[y] = hardnessratio_from_dataset(idat, soft_ch2, hard_ch2;; qual2);
   }

   tracks = [tracks, track];
 }
 % loop over parameter 2
 _for x (0, length(par2arr)-1, 1) {
   % prepare track structure
   len = length(par1arr)*sample1;
   track = struct {
     par1 = [par1arr[0]:par1arr[-1]:#len], par2 = par2arr[x] * ones(len),
     hr1 = Double_Type[len], hr2 = Double_Type[len],
     hr1err = Double_Type[len], hr2err = Double_Type[len],
     linetype = 1
   };
   % set parameters
   set_par(par2name, par2arr[x]);
   _for y (0, len-1, 1) {
     set_par(par1name, track.par1[y]);
     % evaluate model (fold with detector response)
     ()=eval_counts(; fit_verbose = -1);
     % calculate hardnesses
     ratio1=hardnessratio_from_dataset(idat, soft_ch1, hard_ch1;; qual1);
     ratio2=hardnessratio_from_dataset(idat, soft_ch2, hard_ch2;; qual2);
     track.hr1[y]=ratio1.ratio;
     track.hr2[y]=ratio2.ratio;
     track.hr1err[y]=ratio1.err;
     track.hr2err[y]=ratio2.err;
     %track.hr1[y] = hardnessratio_from_dataset(idat, soft_ch1, hard_ch1;; qual1);
     %track.hr2[y] = hardnessratio_from_dataset(idat, soft_ch2, hard_ch2;; qual2);
   }

   tracks = [tracks, track];
 }

 return tracks;
}
