%%%%%%%%%%%%%%%%%%%%%%
define interpol_params()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_params_interpol}
%\synopsis{interpolates between two parameter sets}
%\usage{Struct_Type params[] = interpol_params(Struct_Type p1[], Struct_Type p2[]);
%\altusage{Struct_Type params[] = interpol_params(Struct_Type p1[], Struct_Type p2[], Double_Type frac);}
%\altusage{Struct_Type params[] = interpol_params(Struct_Type p1[], Struct_Type p2[], par, Double_Type value);}
%}
%\description
%   \code{p1} and \code{p2} are parameter lists for the same fit-function
%   as obtained with \code{get_params}. Changing \code{frac} from 0 to 1,
%   the parameter set is interpolated from \code{p1} to \code{p2}.
%   If \code{frac} is not specified, \code{frac=0.5} is assumed.
%   \code{frac} can also be obtained by interpolating
%   the parameter \code{par} to the value \code{value}.
%!%-
{
  variable p1, p2, frac=0.5, par, value;
  variable i;
  switch(_NARGS)
  { case 2: (p1, p2) = (); }
  { case 3: (p1, p2, frac) = (); }
  { case 4: (p1, p2, par, value) = ();
      if(length(p1) != length(p2))
      { vmessage("error (%s): parameter sets from different fit-functions", _function_name());
	return;
      }
      variable v = NULL;
      if(typeof(par)==Integer_Type)
      { if(0 < par<=length(p1))
  	  v = [ p1[par-1].value, p2[par-1].value ];
      }
      else
        _for i (0, length(p1)-1, 1)
  	  if(p1[i].name == par)
	    v = [ p1[i].value, p2[i].value ];
      if(v!=NULL)
      { if(v[1]-v[0] != 0)
  	  frac = (value-v[0])/(v[1]-v[0]);
	else
	{ vmessage("error (%s): cannot interpolate parameter %S, which is %g in both sets.", _function_name(), par, v[0]);
	  return;
	}
      }
      else
      { vmessage("error (%s): parameter %S not found.", _function_name(), par);
	return;
      }
  }
  { help(_function_name()); return; }

  if(   length(p1) != length(p2)
     || any(array_struct_field(p1, "name") != array_struct_field(p2, "name")) )
  { vmessage("error (%s): cannot interpolate between parameter sets of different fit-functions.", _function_name());
    return;
  }

  if(frac<0 || frac>1)
    vmessage("warning (%s): frac=%f -- extrapolation", _function_name(), frac);

  variable p = Struct_Type[0];
  _for i (0, length(p1)-1, 1)
  {
    variable par_info = @(p1[i]);
    par_info.value = (1-frac) * p1[i].value + frac * p2[i].value;
    p = [p, par_info];
  }
  return p;
}
