require("create_struct_field.sl");

define add_hist(){
%!%+
%\function{add_hist}
%\synopsis{add histograms}
%\usage{Struct_Type specs = add_hist([hist1,hist2,...]);}
%\usage{Struct_Type specs = add_hist(hist1,hist2,...);}
%\description
%    Add histogram structures with fields bin_lo, bin_hi, value, and
%    err. The function just assumes that the histograms are on the
%    same grid. It copies the grid from the very first structure in
%    the array, then adds the values of the subsequent structures.
%    Uncertainties (err) are added in quadrature. 
%\seealso{scale_hist, shift_hist, stretch_hist}
%!%-   
   variable structs, ii;
   if(_NARGS==0)  { help(_function_name()); return; }
   else if(_NARGS==1){ structs = ();}
   else{ 
	  structs = __pop_list(_NARGS);
	  _for ii(0,_NARGS-1,1){
		 if( typeof( structs[ii] ) != Struct_Type ){ 
			help(_function_name()); return;
		 }
	  }
	  structs = list_to_array(structs);
   }
   	  
   
   variable nb = length(structs);
   variable ns = @structs[0];
   if(struct_field_exists(ns, "err")){
	  ns.err = ns.err^2;
   }else{
	  if(struct_field_exists(ns, "value")){
		 ns = create_struct_field(ns, "err", Double_Type[length(ns.value)] );
	  }else{
		 print("First struct missing 'value' field. Abort.");
		 return;
	  }
   }
   variable i;
   _for i (1,nb-1,1){
	  ifnot(struct_field_exists(structs[i], "value")){
		 print(sprintf("Struct #%d is missing the 'value' field. Skipping."));
		 continue;
	  }
	  ns.value += structs[i].value;
	  
	  if(struct_field_exists(structs[i],"err")){
		 ns.err += structs[i].err^2;
	  }
   }
   ns.err = sqrt(ns.err);
   
   return ns;
}
