%  ===  get scripts  ===  %
require("../share/isisscripts.sl");
require("rand");

Fit_Verbose=-1;

%  === Routines for checking the status  === %
private define test_fsf() %{{{
{
   variable dummy_name = "dummy.fits";
   variable dummy_str = fits_save_fit_struct(;silent);
   fits_save_fit(dummy_name;silent);
   () = remove(dummy_name);
   return dummy_str;
}
%}}}
private define check_stat(status) %{{{
{ 
   message(" ---> "+ (status?"passed":"FAILED!" ));
   return ;
}
%}}}
private define fake_simple_data(mn,mx,n,alp) %{{{
{
   variable lo,hi; (lo,hi) = log_grid(mn,mx,n);
   variable val = lo^(-alp)*(10+rand_uniform(n));
   variable err = sqrt(val)*0.25;
   variable dat = _A(struct{bin_lo=lo,bin_hi=hi,value=val,err=err});
   return define_counts(dat);
}
%}}}

%  === Test the Funcionality  === %
private define test_without_data() %{{{
{
  % #1: 
  message("#### 1 ####  Testing without any data loaded ... ");
  variable dummy_str = test_fsf();
  
  if(dummy_str.fit_fun[0] != "") {vmessage("Empty String expected, but we got: %s",dummy_str.fit_fun[0]); return 0;}
  else return 1;
}

%}}}
private define test_only_data() %{{{
{
   message("#### 2 ####  Testing with only data loaded (no model) ... ");
   variable id1 = fake_simple_data(0.1,10,100,2);
   () = test_fsf();   
   delete_data(all_data);
   return 1;
}
%}}}
private define test_data_and_model() %{{{
{
   message("#### 3 ####  Testing data and model ... ");
   variable id1 = fake_simple_data(0.1,10,100,2);
   fit_fun("powerlaw");
   () = fit_counts();
   () = test_fsf();   
   delete_data(all_data);
   return 1;
}
%}}}
private define test_multiple_data_and_model_and_grouping() %{{{
{
   message("#### 4 ####  Testing multiple datasets, grouping and systematics ... ");
   variable id1 = fake_simple_data(0.1,10,100,2);
   variable id2 = fake_simple_data(0.1,15,100,2.5);
   
   variable sys_err = 0.01;
   set_sys_err_frac(id1,sys_err);
   
   group(id1;min_sn=4);
   group(id2;min_sn=1.5);
   
   
   fit_fun("powerlaw(Isis_Active_Dataset)");
   () = fit_counts();
   variable dummy_str = test_fsf();
      
   variable status = 1;
   ifnot( (dummy_str.sys_err[0,0] - sys_err) < 1e-6 && dummy_str.sys_err[0,1]==0) 
   {
      print(dummy_str.sys_err);
      status = 0;
      vmessage(" Systematic Errors not as expected! orig: %.8f, restored: %.8f",sys_err,dummy_str.sys_err[0,0]);
   }
   
   delete_data(all_data);
   return status;
}
%}}}
private define test_two_datasets_loaded_but_only_one_noticed() %{{{
{
   message("#### 5 ####  Testing to save_fit when datasets are excluded or no bins noticed ... ");
   variable id1 = fake_simple_data(0.1,10,100,2);
   variable id2 = fake_simple_data(0.1,15,100,2.5);
   
   exclude(id2);
   variable dummy_str = test_fsf();
   include(id2);
   
   xnotice(id1,0,0);
   dummy_str = test_fsf();
      
   delete_data(all_data);
   return 1;
}
%}}}
private define test_loading_saved_file() %{{{
{
   message("#### 6 ####  Testing to load saved file  ... ");
   variable id1 = fake_simple_data(0.1,10,100,2);
   fit_fun("powerlaw");
   () = fit_counts();
   variable dummy_name="dummy.fits";
   fits_save_fit(dummy_name;silent);

   () = fits_load_fit_struct(dummy_name);
   
   () = remove(dummy_name);
   
   delete_data(all_data);
   return 1;
}
%}}}


%  === Run the tests === %
variable fun, test_funs = [
			   &test_without_data, &test_only_data, &test_data_and_model,
			   &test_multiple_data_and_model_and_grouping,
			   &test_two_datasets_loaded_but_only_one_noticed,
			   &test_loading_saved_file
			  ];

foreach fun(test_funs)
{
   check_stat(@fun);
}