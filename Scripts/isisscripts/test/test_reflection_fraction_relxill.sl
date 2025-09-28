require("./share/isisscripts.sl");

variable CONST_prec = 1e-2;

putenv("RELXILL_TABLE_PATH=");  %% make sure no env variable is set
variable path_to_reltable = "/userdata/data/dauser/relline_tables/";
variable table_name = "rel_lp_table_v0.5b.fits";


define test_reflfrac(a,h,rin,rout,ref_val){
    
  variable calc_value = reflection_fraction_relxill(a,h,rin,rout; path=path_to_reltable, table=table_name);
   
   variable equal = (abs(calc_value-ref_val)<CONST_prec)? 1 : 0;
   ifnot (equal)
     vmessage("failed: reference: %e != calculated: %e (within precision of %e)", ref_val, calc_value, CONST_prec);
  return equal;   
}


if (stat_file(path_to_reltable+table_name)!=NULL){

   variable tests_passed = [
			    test_reflfrac(0.998,6,kerr_rms(0.998),400,1.818),
			    test_reflfrac(0.998,3,kerr_rms(0.998),400,3.251),			 			 
			    test_reflfrac(0.998,3,-1,400,3.251),			 			 
			    test_reflfrac(0.998,-3,-1,400,3.035),
			    test_reflfrac(0,6,kerr_rms(0),400,1.112)			 			 
			   ];
   exit(all(tests_passed) ? 0 : 1);
} else {
   message(" skipping tests of reflection_fraction_relxill(), as table could not be found");
   exit(0);
}
