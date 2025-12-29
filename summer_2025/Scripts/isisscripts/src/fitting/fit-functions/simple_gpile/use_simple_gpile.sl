%%%%%%%%%%%%%%%%%%%%%%%
define use_simple_gpile()
%%%%%%%%%%%%%%%%%%%%%%%
{
  variable data1, arf2=NULL, arf3=NULL;
  switch(_NARGS)
  { case 1:  data1 = (); }
  { case 2: (data1, arf2) = (); }
  { case 3: (data1, arf2, arf3) = (); }
  { message("usage: use_simple_gpile(data1[, arf2[, arf3]]);"); return; }

  if(arf2!=NULL)
  { arf2 = [arf2];
    if(length(arf2)!=length(data1)) { message("error (use_simple_gpile): arrays data1 and arf2 have different length"); return; }
  }
  if(arf3!=NULL)
  { arf3 = [arf3];
    if(length(arf3)!=length(data1)) { message("error (use_simple_gpile): arrays data1 and arf3 have different length"); return; }
  }

  variable simple_gpile_fun = "simple_gpile2";
  variable fitFun = get_fit_fun();
  if(substr(fitFun, 1, strlen(simple_gpile_fun)) != simple_gpile_fun)
    fit_fun(simple_gpile_fun + "(Isis_Active_Dataset, " + fitFun + ")");

  % assign model parameters
  variable i;
  foreach i (all_data)
  {
    variable simple_gpile_instance = simple_gpile_fun + "(" + string(i) + ")";
    set_par(simple_gpile_instance + ".beta", 0, 1);
    set_par(simple_gpile_instance + ".data_indx", 0, 1);
    set_par(simple_gpile_instance + ".arf2_indx", 0, 1);
    set_par(simple_gpile_instance + ".arf3_indx", 0, 1);
  }
  _for i (0, length([data1])-1, 1)
  {
    variable id = [data1][i];
    simple_gpile_instance = simple_gpile_fun + "(" + string(id) + ")";
    set_par(simple_gpile_instance + ".beta", 0.05, 0);
    set_par(simple_gpile_instance + ".data_indx", id, 1);
    if(arf2!=NULL)  set_par(simple_gpile_instance + ".arf2_indx", arf2[i], 1);
    if(arf3!=NULL)  set_par(simple_gpile_instance + ".arf3_indx", arf3[i], 1);
  }
}
