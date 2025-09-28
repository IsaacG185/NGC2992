private define get_params_and_stepsize()
{
  variable params = get_params();
  if(params==NULL)
    return Struct_Type[0], Integer_Type[0];

  variable stepsize = array_struct_field(params, "step");
  stepsize[where(stepsize==0)] = 1e-3;
  return params, nint(log10(stepsize));
}

%%%%%%%%%%%%%%%%%%%%%
define fit_interactive()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fit_interactive}
%\synopsis{Interactivly change parameters and evaluate the model}
%
%\usage{fit_interactive(Ref_Type plotfunction[, Any_Type arg0, arg1, ...]}
%\description
%    The Ref_Type 'plotfunction' is a reference to
%    the plot function, which has to be used (see
%    example below). Any additional arguments are
%    passed to this function as well as given
%    qualifiers.
%    The user may changes the parameters interactivly
%    by the following keys:
%      LEFT/RIGHT: increase/decrease value of active
%                  parameter by one stepsize
%      UP/DOWN   : change active parameter
%      PGUP/PGDN : increase/decrease stepsize by one
%                  order
%      t         : freeze/thaw active parameter
%      r         : change range of active parameter
%      v         : set value of active parameter
%      z         : set the internal step size used by
%                  fit_counts
%      m         : modify fit function
%      f         : perform a fit by running fit_counts
%      s         : show/hide frozen parameter
%      p/P       : load/save parameters in 'parfile'
%      q         : quit interactive mode
%    Every time the value of a parameter is changed,
%    the model is evaluated automatically and the
%    given plot function is called.
%    Actual parameter values and the reduced chi-
%    square are printed out to the plot window.
%    The active parameter is shown in red, thawed
%    ones in black and frozen ones in gray. If the
%    parameter turns blue, one of the borders of the
%    range is reached.
%\qualifiers{
%    \qualifier{parfile}{filename, which is used to save or load
%              the fit parameters using 'save_par' or
%              'load_par', respectively. The user will
%              be asked for if 'parfile' is not set.}
%    \qualifier{plotscript}{filename, used to load in a user-defined 
%                 plotting script. If not set, function
%                 reverts to Ref_Type 'plotfunction'.}
%}
%\example
%    variable id = load_data("example.pha");
%    fit_fun("cutoffpl");
%    fit_interactive(&plot_data, id; res=1);
%
%    The appearing plot window then is internaly
%    called by
%    plot_data(id; res=1);
%\seealso{eval_counts, open_plot, keyinput}
%!%-
{
 if (_NARGS < 1) { help(_function_name()); return; }

 variable args = __pop_list(_NARGS-1); % get given parameters
 variable plotfun = (); % get given plot function
 variable params, stepsize; (params, stepsize) = get_params_and_stepsize();
 variable actpar = 0, stat, i, j, showf = 1, isfrz, update = 1, istart = 0, iend = min([4, length(params)-1]), y0;
 variable parfile = qualifier("parfile", "");
 variable plotscript = qualifier("plotscript", "");

 % prepare plot window
 (@plotfun)(__push_list(args) ;; __qualifiers);
 variable vs_w, vs_a;
 (,vs_w,,vs_a) = _pgqvsz(1); vs_a /= vs_w; % current window dimensions (view surface), width (inch) and aspect
 variable pwin = open_plot;
 variable nvs_w = 6., nvs_a = .31; % new window dimensions
 variable chz = 2.8; % default char size
 _pgscr(16, 0.8, 0.8, 0.8);

 % MAIN LOOP
 forever
 {
   % eval model
   if (update == 1)
   {
     % check on min/max values
     _for i (0, length(params)-1, 1)
     {
       params[i].value = _max(params[i].min, params[i].value);
       params[i].value = _min(params[i].max, params[i].value);
     }
     set_params(params);
     ()=eval_counts(&stat; fit_verbose=-1);
   }

   % parameter plot
   window(pwin);
   xlin; ylin;
   _pgpap(nvs_w, nvs_a); % set view surface dimensions
   color(1);
   xrange(0,1); yrange(0,1); label("", "", ""); erase();
   charsize(1.4*chz); xylabel(0.5,1.02,"Interactive Fit",0,0.5);
   charsize(.8*chz); xylabel(1.02,-0.1,"press 'h' for help",0,1);
   charsize(chz); xylabel(-.02, .88, sprintf(`\gx\u2\d\d\bred\u = %.1f / %d = %.2f`,
					     stat.statistic, stat.num_bins - stat.num_variable_params,
					     stat.statistic/(stat.num_bins - stat.num_variable_params)
					    ));
   xylabel(-.02, .76, sprintf("%s %d to %d:", (showf ? "Parameter" : "Free parameter"), istart+1, iend+1));
   j = 0;
   _for i (istart, iend, 1)
   {
       isfrz = (params[i].freeze || params[i].tie != NULL || params[i].fun != NULL);  % frozen parameter?
       % set color
       variable fcol = (i == actpar) ? 2 : (isfrz ? 16 : 1);
       % print parameter
       if (isfrz == 0 || showf)
       {
	 y0 = .64 - .12*(i-j-istart);
	 color(fcol);
         xylabel(.0, y0, params[i].name);
	 if (params[i].value == params[i].max || params[i].value == params[i].min) color(4);
         xylabel(.3, y0, sprintf("= %S", params[i].value));
	 color(fcol);
         xylabel(.8, y0, sprintf(`stepsize = 10\u%d\d`, stepsize[i]));
       }
       else j++;
   }
   charsize(1);
   % model plot
   if (update)
   {
     window(1);
     _pgpap(vs_w, vs_a); % set view surface dimensions
    if (plotscript == "")
    {
      (@plotfun)(__push_list(args) ;; __qualifiers);
    }
    else
    {
      if (access(plotscript, F_OK) == 0)
      {
        evalfile(plotscript);
        print("Plotting script successfully loaded...");
      }
      else
      {
        vmessage("error: file '%s' does not exist", plotscript);
        (@plotfun)(__push_list(args) ;; __qualifiers);
      }
    } 
      update = 0;
   }

   % user input
   variable newpar, f;
   switch (keyinput(;nchr=1, silent))
     % increase parameter value
     { case "RIGHT_ARROW": if (length(params) > 0) params[actpar].value += 10.^stepsize[actpar]; update = 1; }
     % decrease parameter value
     { case "LEFT_ARROW": if (length(params) > 0) params[actpar].value -= 10.^stepsize[actpar]; update = 1; }
     % select parameter above
     { case "UP_ARROW":
       if (length(params) > 0 && actpar > 0)
       {
	 newpar = actpar;
	 do % check on freeze state
	   newpar--;
         while (showf == 0 && newpar > 0 && (params[newpar].freeze || params[newpar].tie != NULL || params[newpar].fun != NULL));
         if (showf || (params[newpar].freeze == 0 && params[newpar].tie == NULL && params[newpar].fun == NULL)) actpar = newpar;
       }
       if (actpar < istart) % update index of shown parameter
       {
	 istart = actpar; iend = istart; f = [0,0];
	 if (showf) iend += 4;
	 else
	 {
	   do
	   {
	     iend++;
             ifnot(   iend >= length(params)-1
		   || params[iend].freeze || params[iend].tie != NULL || params[iend].fun != NULL)
	       f = [f[0]+1, iend];
	   } while (iend < length(params)-1 && f[0] < 4);
           if (f[1] == 0) f[1] = istart;
           if (f[0] < 4) iend = f[1];
	 }
	 if (iend > length(params)-1) iend = length(params)-1;
       }
     }
     % select parameter below
     { case "DOWN_ARROW":
       if (length(params) > 0 && actpar < length(params)-1)
       {
	 newpar = actpar;
	 do % check on freeze state
	   newpar++;
	 while (showf == 0 && newpar < length(params)-1 && (params[newpar].freeze || params[newpar].tie != NULL || params[newpar].fun != NULL));
         if (showf || (params[newpar].freeze == 0 && params[newpar].tie == NULL && params[newpar].fun == NULL)) actpar = newpar;
       }
       if (actpar > iend) % update index of shown parameter
       {
	 iend = actpar; istart = iend; j = 0;
	 if (showf) istart -= 4;
	 else
	   do
	   {
	     istart--;
	     ifnot (   istart <= 0
		    || params[istart].freeze || params[istart].tie != NULL || params[istart].fun != NULL)
	       j++;
	   } while (istart > 0 && j < 4);
         if (istart < 0) istart = 0;
       }
     }
     % increase parameter stepsize
     { case "PAGE_UP": if (length(params)) stepsize[actpar]++; }
     % decrease parameter stepsize
     { case "PAGE_DOWN": if (length(params)) stepsize[actpar]--; }
     % switch freeze state of parameter
     { case "t": params[actpar].freeze = not params[actpar].freeze; set_params(params); }
     % change range of parameter
     { case "r": window(pwin);
       vmessage("parameter range of %s:", params[actpar].name);
       erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "enter new parameter range into console", 0, 0.5);
       variable newmin = atof(keyinput(; prompt = "  min = ", default = sprintf("%S",params[actpar].min)));
       variable newmax = atof(keyinput(; prompt = "  max = ", default = sprintf("%S",params[actpar].max)));
       if (newmin > newmax) message("error: minimum value larger than maximum value");
       else if (newmin < params[actpar].value < newmax) { params[actpar].min = newmin; params[actpar].max = newmax; set_params(params); }
       else vmessage("error: actual parameter value %S not enclosed by given range", params[actpar].value);
     }
     % set parameter value explicitely
     { case "v": window(pwin);
       vmessage("value of %s:", params[actpar].name);
       erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "enter new parameter value into console", 0, 0.5);
       variable newval = atof(keyinput(; prompt = " value = ", default = sprintf("%S",params[actpar].value)));
       if (params[actpar].min <= newval <= params[actpar].max) { params[actpar].value = newval; set_params(params); update = 1; }
       else vmessage("error: given parameter value not enclosed by given range (%S to %S)", params[actpar].min, params[actpar].max);
     }
     % set fitting stepsize
     { case "z": window(pwin);
       vmessage("fitting stepsize of %s:", params[actpar].name);
       erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "enter new fitting stepsize into console", 0, 0.5);
       variable newstep = atof(keyinput(; prompt = " stepsize = ", default = sprintf("%S",params[actpar].relstep)));
       params[actpar].relstep = newstep; set_params(params);
     }
     % toggle printing of frozen parameter
     { case "s": showf = not showf;
       % set actual parameter index
       newpar = actpar;
       do
       {
	 isfrz = (params[newpar].freeze || params[newpar].tie != NULL || params[newpar].fun != NULL);
	 if (showf == 0 && isfrz) newpar++;
	 if (newpar > length(params)-1) newpar = 0;
       } while (isfrz && actpar != newpar);
       actpar = newpar;
       % update first and last shown parameter
       istart = actpar; iend = istart; f = [0,0];
       if (showf) iend += 4;
       else
       {
	 do
         {
           iend++;
	   ifnot (   iend >= length(params)-1
		  || params[iend].freeze || params[iend].tie != NULL || params[iend].fun != NULL)
	     f = [f[0]+1, iend];
         } while (iend < length(params)-1 && f[0] < 4);
	 if (f[1] == 0) f[1] = istart;
         if (f[0] < 4) iend = f[1];
       }
       if (iend > length(params)-1) iend = length(params)-1;
     }
     % modify fit function
     { case "m": window(pwin);
       erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "enter fit function into console", 0, 0.5); charsize(1);
       fit_fun(keyinput(; prompt = "fit function = ", default = get_fit_fun));
       (params, stepsize) = get_params_and_stepsize();
       update = 1;
     }
     % perform a fit
     { case "f": window(pwin);
       erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "performing a fit...", 0, 0.5); charsize(1);
       ()=fit_counts(&stat; fit_verbose=-1);
       (params, ) = get_params_and_stepsize();  % get_params would give NULL for empty fit_fun
       update = 2;
     }
     % load parameter
     { case "p": if (parfile == "") {
         window(pwin);
         erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "enter parameter filename into console", 0, 0.5);
         parfile = keyinput(; prompt = "parameter filename: ");
       }
       if (access(parfile, F_OK) == 0) { load_par(parfile); params = get_params(); update = 1; message("parameters loaded"); }
       else { vmessage("error: file '%s' does not exist", parfile); parfile = ""; }
     }
     % save parameter
     { case "P": if (parfile == "") {
         window(pwin);
         erase; charsize(1.4*chz); color(1); xylabel(0.5, 0.5, "enter parameter filename into console", 0, 0.5);
         parfile = keyinput(; prompt = "parameter filename: ");
       }
       save_par(parfile);
       message("parameters saved"); 
     }
     % quit
     { case "q": close_plot(pwin); window(1); return; }
     % help
     { case "h": window(pwin);
       erase; charsize(chz); color(1);
       xylabel(-0.02,1.05,"keyboard commands:");
       y0 = .95;
       variable txt;
       foreach txt ([
		     {"Up/Down",     "- change active parameter"},
		     {"Left/Right",  "- decrease/increase active parameter value by stepsize"},
		     {"PgUp/PgDown", "- increase/decrease stepsize of active parameter"},
		     {"t",           "- freeze/thaw active parameter"},
		     {"r",           "- change range of active parameter"},
		     {"v",           "- set value of active parameter"},
		     {"z",           "- set the internal step size used by fit_counts"},
		     {"m",           "- modify fit function"},
		     {"f",           "- perform a fit by running fit_counts"},
		     {"s",           "- show/hide frozen parameters"},
		     {"p/P",         "- load/save fit parameters"},
		     {"q",           "- quit"}
		    ])
       {
	 xylabel(.09, y0, txt[0], 0, 0.5);
	 xylabel(.2,  y0, txt[1]);
	 y0 -= .095;
       }
       ()=keyinput(;nchr=1, silent);
     }
  } % main loop
}
