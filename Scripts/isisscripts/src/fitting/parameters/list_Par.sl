define list_Par()
%!%+
%\function{list_Par}
%\synopsis{lists parameters of the current fit-function as ISIS-commands}
%\usage{list_Par([ pars[] ]);}
%\qualifiers{
%\qualifier{fit_fun}{lists also the fit-function}
%\qualifier{fmt}{format statement for min/max/value}
%}
%!%-
{
  variable pars;
  switch(_NARGS)
  { case 0: pars = freeParameters(); }
  { % else:  % collect all arguments
      pars = __pop_list(_NARGS);
  }

  % convert String_Type arguments to indices of matching parameters
  variable p, par, param, params = get_params();
  variable n = length(params);
  variable list_of_pars = {};
  foreach par (pars)
    switch(_typeof(par))
    { case String_Type:
	foreach p ([par])
          foreach param (params)
            if(string_match(param.name, glob_to_regexp(p), 1))
              list_append(list_of_pars, param.index);
    }
    { case Integer_Type:
	foreach p (par)
	  if(0 < p <= n)
            list_append(list_of_pars, p);
          else
            vmessage("warning (%s): ignoring parameter %d", _function_name(), p);
    }
    { % else:
        vmessage("warning (%s): ignoring %S argument %S", _function_name(), typeof(par), par);
    }

  variable fit_fun = get_fit_fun();
  if(qualifier_exists("fit_fun"))
    vmessage(`fit_fun( "%s" );`, (fit_fun==NULL ? "" : fit_fun));

  n = length(list_of_pars);
  if(n==0 || fit_fun==NULL)  return;

  variable fmt = qualifier("fmt", "%.8g");

  variable names = String_Type[n],  values  = String_Type[n],
           freezes = Char_Type[n],
           mins = String_Type[n],  maxs = String_Type[n],
           steps = String_Type[n], relsteps = String_Type[n],
           ties = String_Type[n],  funs = String_Type[n],
           indxs = String_Type[n],  units = String_Type[n];
  _for p (0, n-1, 1)
  { variable info = get_par_info(list_of_pars[p]);
      names[p] = info.name;
     values[p] = sprintf(fmt, info.value);
    freezes[p] = info.freeze;
       mins[p] = (info.min==-DOUBLE_MAX ? "-DOUBLE_MAX" : sprintf(fmt, info.min));
       maxs[p] = (info.max== DOUBLE_MAX ?  "DOUBLE_MAX" : sprintf(fmt, info.max));
      steps[p] = sprintf(fmt, info.step);
   relsteps[p] = sprintf(fmt, info.relstep);
       ties[p] = (info.tie==NULL ? "" : info.tie);
       funs[p] = (info.fun==NULL ? "" : info.fun);
      indxs[p] = sprintf("%d", info.index);
      units[p] = info.units;
  }

  variable max_chars_name    = max(array_map(Integer_Type, &strlen, names));
  variable max_chars_value   = max(array_map(Integer_Type, &strlen, values));
  variable max_chars_min     = max(array_map(Integer_Type, &strlen, mins));
  variable max_chars_max     = max(array_map(Integer_Type, &strlen, maxs));
  variable max_chars_step    = max(array_map(Integer_Type, &strlen, steps));
  variable max_chars_relstep = max(array_map(Integer_Type, &strlen, relsteps));
  variable max_chars_unit    = max(array_map(Integer_Type, &strlen, units));
  variable max_chars_indx    = max(array_map(Integer_Type, &strlen, indxs));
  _for p (0, n-1, 1)
  {
    vmessage(`set_par( "%s",%s %s%s,  %d,  %s%s, %s%s; step=%s%s, relstep=%s%s); %% %s%s %s(par # %s)`,
              names[p], multiple_string(max_chars_name-strlen(names[p]), " "),
              multiple_string(max_chars_value-strlen(values[p]), " "), values[p],
              freezes[p],
              multiple_string(max_chars_min-strlen(mins[p]), " "), mins[p],
              multiple_string(max_chars_max-strlen(maxs[p]), " "), maxs[p],
              multiple_string(max_chars_step-strlen(steps[p]), " "), steps[p],
              multiple_string(max_chars_relstep-strlen(relsteps[p]), " "), relsteps[p],
              units[p], multiple_string(max_chars_unit-strlen(units[p]), " "),
              multiple_string(max_chars_indx-strlen(indxs[p]), " "), indxs[p]
	     );
    if(ties[p]!="")  vmessage(`tie( "%s", "%s");`, ties[p], names[p]);
    if(funs[p]!="")  vmessage(`set_par( "%s", "%s");`, names[p], funs[p]);
  }
}
