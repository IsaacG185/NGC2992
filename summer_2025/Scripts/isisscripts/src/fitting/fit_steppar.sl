private define append_interpol_table(interpol_table, info, i1, i2, i, min_improvement)
{
  variable improvement = info.stat[i] - interpol(info.par[i], info.par[[i1,i2]], info.stat[[i1,i2]]);
  if(improvement > min_improvement)
  { interpol_table.i1 = [interpol_table.i1, i1];
    interpol_table.i2 = [interpol_table.i2, i2];
    interpol_table.i  = [interpol_table.i , i ];
    interpol_table.improvement = [interpol_table.improvement, improvement];
  }
}


private define improvement_by_interpolation(info, i1, i2, i, parname, parfiles)
{
  variable verbose = qualifier("verbose", 1);
  variable doplots = qualifier_exists("plot");
  variable fit = qualifier("fit", 1);
  if(verbose)
    vmessage("interpolation %s = %10g < %10g < %10g  (expected improvement: %f)",
  	     parname, info.par[i1], info.par[i], info.par[i2],
	     info.stat[i] - interpol(info.par[i], info.par[[i1,i2]], info.stat[[i1,i2]])
	    );
  set_params( interpol_params(info.params[i1], info.params[i2], parname, info.par[i]) );
  variable s, stat0 = info.stat[i];
  ()=eval_counts(&s);
  if(s.statistic < info.stat[i])
  { if(verbose)  vmessage( "  improvement: statistic = %g < %g", s.statistic, info.stat[i]);
    save_par(parfiles[i]);
     info.stat[i] = s.statistic;
     info.params[i] = get_params();
    if(doplots)  oplot(info.par, info.stat);
    if(fit)
    {
      if(verbose)  { ()=printf("   fitting..."); ()=fflush(stdout); }
      ()=fit_counts(&s);
      if(verbose)  vmessage(": statistic = %g", s.statistic);
      save_par(parfiles[i]);
       info.stat[i] = s.statistic;
       info.params[i] = get_params();
    }
    if(verbose)  message("");
    return stat0 - info.stat[i];
  }
  return 0;
}


%%%%%%%%%%%%%%%%%%
define fit_steppar()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{fit_steppar}
%\synopsis{tries to obtain better fits for a stepped parameter}
%\usage{Struct_Type result = fit_steppar(String_Type parname, parfiles[]);}
%\qualifiers{
%\qualifier{method}{"optimize", "interpol_guess", or "eval_all"}
%\qualifier{extrapol}{allows for extrapolation as well}
%\qualifier{fit [=1]}{}
%\qualifier{min_improvement}{}
%\qualifier{plot}{}
%\qualifier{verbose [=1]}{}
%}
%\description
%!%-
{
  variable parname, parfiles;
  switch(_NARGS)
  { case 2: (parname, parfiles) = (); }
  { help(_function_name()); return; }

  % qualifiers
  variable method = qualifier("method", "optimize");
  if(all(method!=["optimize", "interpol_guess", "eval_all"]))
  { vmessage(`error (%s): method="%s" unknown`, _function_name(), method);
    return;
  }
  variable extrapol = qualifier_exists("extrapol");
  variable min_improvement = qualifier("min_improvement", 0);
  variable doplots = qualifier_exists("plot");
  variable verbose = qualifier("verbose", 1);

  variable FitVerbose = Fit_Verbose;
  Fit_Verbose = -1;
  variable n = length(parfiles);
  variable info = struct { par = Double_Type[n],
                           stat0 = Double_Type[n],
                           stat,
                           params= Array_Type[n]
                         };
  parfiles = parfiles[array_sort(parfiles)];
  variable i, s;
  _for i (0, n-1, 1)
  { load_par(parfiles[i]);
    info.params[i] = get_params();
    info.par[i] = get_par(parname);
    ()=eval_counts(&s);
    info.stat0[i] = s.statistic;
    if(verbose)  vmessage("%20s: %10g %10g", parfiles[i], info.par[i], info.stat0[i]);
  }
  if(verbose)  message("");

  i = array_sort(info.par);
  parfiles = parfiles[i];
  struct_filter(info, i);
  info.stat = @info.stat0;

  if(doplots)
  { pointstyle(2);
    plot(info.par, info.stat);
  }

  variable di, i1, i2, improved;
  % i1 < i < i2 = i1+di   (unless extrapolation is allowed)

  switch(method)
  { case "optimize":
    %%%%%%%%%%%%%%%
    variable interpol_table = struct
    { i1 = Integer_Type[0],
      i2 = Integer_Type[0],
      i  = Integer_Type[0],
      improvement = Double_Type[0]
    };
    % find improvement due to all interpolation-combinations:
    % loop( (n^3 - 3n^2 + 2n)/6 )
    if(extrapol)
      _for i (0, n-1, 1)  % 0 <= i < n
        _for i1 (0, n-2, 1)  % i1 < i2 < n
          _for i2 (i1+1, n-1, 1)  % i1 < i2 < n
  	    append_interpol_table(interpol_table,  info, i1, i2, i, min_improvement);
    else
      _for i (1, n-2, 1)  % 0 <= i1 < i < i2 < n
        _for i1 (0, i-1, 1)  % 0 <= i1 < i
          _for i2 (i+1, n-1, 1)  % i < i2 < n
  	    append_interpol_table(interpol_table,  info, i1, i2, i, min_improvement);

    while(length(interpol_table.i)>0);
    { % find optimal improvement:
      variable opt = array_sort(interpol_table.improvement)[-1];
      variable iopt = interpol_table.i[opt];
      i1 = interpol_table.i1[opt];
      i2 = interpol_table.i2[opt];
      improved = improvement_by_interpolation(info, i1, i2, iopt, parname, parfiles;; __qualifiers());
      if(improved>0)
      { % update table:
        interpol_table.improvement[where(interpol_table.i ==iopt)] -= improved;  % has just been improved
        interpol_table.improvement[where(interpol_table.i1==iopt or interpol_table.i2==iopt)] = 0;  % previously calculated improvement may no longer be valid
	% recalculate improvement of interpolation from iopt (as i1 or i2):
	if(extrapol)
	{
  	  i2 = iopt;
          _for i (0, n-1, 1)  % 0 <= i < n
           _for i1 (0, i2-1, 1)  % 0 <= i1 < i2
             append_interpol_table(interpol_table,  info, i1, i2, i, min_improvement);
	  i1 = iopt;
          _for i (0, n-1, 1)  % 0 <= i < n
           _for i2 (i1+1, n-1, 1)  % i1 < i2 < n
             append_interpol_table(interpol_table,  info, i1, i2, i, min_improvement);
	}
	else
	{
  	  i2 = iopt;
          _for i (1, iopt-1, 1)  % 0 <= i1 < i < i2
           _for i1 (0, i-1, 1)  % 0 <= i1 < i
             append_interpol_table(interpol_table,  info, i1, i2, i, min_improvement);
	  i1 = iopt;
          _for i (iopt+1, n-2, 1)  % i1 < i < i2 < n
           _for i2 (i+1, n-1, 1)  % i < i2 < n
             append_interpol_table(interpol_table,  info, i1, i2, i, min_improvement);
	}
        struct_filter(interpol_table, where(interpol_table.improvement > min_improvement));
	if(doplots)  oplot(info.par, info.stat);
      }
      else
        struct_filter(interpol_table, [[0:opt-1],[opt+1:length(interpol_table.i)-1]]);
    }
  }
  { case "interpol_guess":
    %%%%%%%%%%%%%%%%%%%%%
    do
    { improved = 0;

      _for i (1, n-2, 1)
        _for di (2, n-1, 1)
          _for i1 (int(_max(0, i+1-di)), int(_min(i-1, n-1-di)), 1)   % i1 >= 0  &&  i1 + di > i   &&   i1 < i  &&  i1 + di < n
          { i2 = i1+di;
  	    if(   interpol(info.par[i], info.par[[i1,i2]], info.stat[[i1,i2]]) < info.stat[i]
	       && improvement_by_interpolation(info, i1, i2, i, parname, parfiles;; __qualifiers()) > 0 )
	    { improved = 1;
    	      if(doplots)  oplot(info.par, info.stat);
	    }
	  }
    } while(improved);
  }
  { case "eval_all":
    %%%%%%%%%%%%%%%
    do
    { improved = 0;
      _for i (1, n-2, 1)   % i1 < i < i2
        _for di (2, n-1, 1)  % di = i2 - i1
          _for i1 (int(_max(0, i+1-di)), int(_min(i-1, n-1-di)), 1)   % i1 >= 0  &&  i1 + di > i   &&   i1 < i  &&  i1 + di < n
	    if( improvement_by_interpolation(info, i1, i2, i, parname, parfiles;; __qualifiers()) > 0 )
	    { improved = 1;
    	      if(doplots)  oplot(info.par, info.stat);
	    }
    } while(improved);
  }

  Fit_Verbose = FitVerbose;
  return info;
}
