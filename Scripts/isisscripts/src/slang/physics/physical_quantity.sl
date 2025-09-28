#ifnexists PhysicalQuantity_Type

%%%%%%%
typedef struct {
%%%%%%%
  numerical_value,
  leng_unit, leng_dim,
  time_unit, time_dim,
  mass_unit, mass_dim,
  curr_unit, curr_dim,
  temp_unit, temp_dim,
} PhysicalQuantity_Type;

#endif

private variable physical_quantity_baseunits = struct {
       length_in_m  = Assoc_Type[Double_Type],
         time_in_s  = Assoc_Type[Double_Type],
         mass_in_kg = Assoc_Type[Double_Type],
      current_in_A  = Assoc_Type[Double_Type],
  temperature_in_K  = Assoc_Type[Double_Type],
         unit       = Assoc_Type[PhysicalQuantity_Type],
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%
private define parse_unit_power(str)
        %%%%%%%%%%%%%%%%%%%%%%%
{
  variable m = string_matches(str, `\(.*\)^\(.*\)`, 1);
  if(m!=NULL)
    (m[1], atoi(str_delete_chars(m[2], "{[()]}")));  % (unit, power);  % left on stack
  else
    if(str=="")
      ("", 0);   % (unit, power);  % left on stack
    else
      (str, 1);  % (unit, power);  % left on stack
}


private define handle_physical_quantity_units(q, units);

%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity}
%\synopsis{initializes a physical quantity with number and units}
%\usage{PhysicalQuantity_Type physical_quantity(Double_Type number)}
%\qualifiers{
%\qualifier{leng}{length unit and dimension}
%\qualifier{time}{time unit and dimension}
%\qualifier{mass}{mass unit and dimension}
%\qualifier{curr}{electrical current unit and dimension}
%\qualifier{temp}{temperature unit and dimension}
%\qualifier{unit}{array of compound units (see \code{physical_quantity_unit})}
%}
%\description
%    The units are specified as strings with their dimensionality
%    indicated by "^" as powers, i.e., "[unit]^[dim]".
%    [dim] can be a negative number as well.
%    For dim==1, "^1" can be omitted.
%\example
%    variable c = physical_quantity(299792.458; length="km", time="s^-1");
%\seealso{physical_quantity_unit}
%!%-
{
  variable number;
  switch(_NARGS)
  { case 1: number = (); }
  { help(_function_name()); return; }

  variable quant = @PhysicalQuantity_Type;
  quant.numerical_value = number;
  (quant.leng_unit, quant.leng_dim) = parse_unit_power(qualifier("leng", ""));
  (quant.time_unit, quant.time_dim) = parse_unit_power(qualifier("time", ""));
  (quant.mass_unit, quant.mass_dim) = parse_unit_power(qualifier("mass", ""));
  (quant.curr_unit, quant.curr_dim) = parse_unit_power(qualifier("curr", ""));
  (quant.temp_unit, quant.temp_dim) = parse_unit_power(qualifier("temp", ""));

  if(qualifier_exists("unit"))
    quant = handle_physical_quantity_units(quant, [qualifier("unit")]);

  return quant;
}


%%%%%%%%%%%%%%%
define SIprefix(prefix)
%%%%%%%%%%%%%%%
%!%+
%\function{SIprefix}
%\usage{Double_Type SIprefix(String_Type prefix)}
%!%-
{
  switch(prefix)
  { case "Y": return 1e24; }
  { case "Z": return 1e21; }
  { case "E": return 1e18; }
  { case "P": return 1e15; }
  { case "T": return 1e12; }
  { case "G": return 1e9; }
  { case "M": return 1e6; }
  { case "k": return 1e3; }
  { case "h": return 1e2; }
% { case "da": return 1e1; }
  { case "" : return 1; }
  { case "d": return 1e-1; }
  { case "c": return 1e-2; }
  { case "m": return 1e-3; }
  { case "µ": return 1e-6; }
  { case "n": return 1e-9; }
  { case "p": return 1e-12; }
  { case "f": return 1e-15; }
  { case "a": return 1e-18; }
  { case "z": return 1e-21; }
  { case "y": return 1e-24; }
  if(qualifier_exists("verbose"))  vmessage("error (%s): unknown prefix '%s'", _function_name(), prefix);
  return 0;
}

        %%%%%%%%%%%%%%%%%%%%%%%
private define unit_to_baseunit(unit, baseunits)
        %%%%%%%%%%%%%%%%%%%%%%%
{
  variable strlen_unit = strlen(unit);
  variable baseunit, basevalue, result=NULL, interpretation={};
  foreach baseunit, basevalue (baseunits) using ("keys", "values")
  { variable strlen_baseunit = strlen(baseunit);
    if(strlen_baseunit<=strlen_unit && unit[[-strlen_baseunit:]] == baseunit)
    {
      variable SIprefix_name = unit[[:-strlen_baseunit-1]];
      variable SIprefix_value = SIprefix(SIprefix_name);
      if(SIprefix_value!=0)
      {
	list_append(interpretation, (SIprefix_name=="" ? "" : SIprefix_name + "-") + baseunit);
        if(__is_numeric(basevalue))
          result = SIprefix_value * basevalue;
        else
        { result = @basevalue;
	  result.numerical_value *= SIprefix_value;
	}
      }
    }
  }
  if(qualifier_exists("get_interpretation"))
    return interpretation;

  if(result==NULL)
    vmessage("error (%s): unknown unit '%s'", _function_name(), unit);
  if(length(interpretation)>1)
    vmessage("warning: ambiguous unit '%s'\n         possible interpretations: %s",
	     unit, strjoin(list_to_array(interpretation), " or "));
  return result;
}


%%%%%%%%%%%%%%%%%%%%
define convert_units()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{convert_units}
%\synopsis{convers units of a physical quantity}
%\usage{convert_units(PhysicalQuantity_Type q);
%\altusage{PhysicalQuantity_Type convert_units(PhysicalQuantity_Type q; copy)}
%}
%\qualifiers{
%\qualifier{leng}{unit of length}
%\qualifier{time}{unit of time}
%\qualifier{mass}{unit of mass}
%\qualifier{curr}{unit of electrical current}
%\qualifier{temp}{unit of temperature}
%\qualifier{SI}{sets  leng="m", time="s", mass="kg", curr="A", temp="K"}
%\qualifier{copy}{does not change unit of q, but returns a copy of q}
%}
%\description
%   The allowed units are specified by the associative arrays
%         baseunits_length_in_m, baseunits_time_in_s,
%         baseunits_mass_in_kg, baseunits_current_in_A,
%     and baseunits_temperature_in_K
%   which specify the factor to the corresponding SI units.
%!%-
{
  variable q;
  switch(_NARGS)
  { case 1: q = (); }
  { help(_function_name()); return; }

  variable leng_unit = qualifier("leng", "");
  variable time_unit = qualifier("time", "");
  variable mass_unit = qualifier("mass", "");
  variable curr_unit = qualifier("curr", "");
  variable temp_unit = qualifier("temp", "");
  if(qualifier_exists("SI"))
    (leng_unit, time_unit, mass_unit, curr_unit, temp_unit)
    = ("m",     "s",       "kg",      "A",       "K");

  variable copy = qualifier_exists("copy");
  if(copy)  q = @q;

  variable factor1, factor2;
  if(leng_unit!="" && q.leng_dim!=0)
  {
    factor1 = unit_to_baseunit(q.leng_unit, physical_quantity_baseunits.length_in_m);
    factor2 = unit_to_baseunit(  leng_unit, physical_quantity_baseunits.length_in_m);
    if(factor1!=NULL && factor1!=0 && factor2!=NULL && factor2!=0)
      q.numerical_value *= (factor1/factor2)^q.leng_dim,
      q.leng_unit = leng_unit;
  }
  if(time_unit!="" && q.time_dim!=0)
  {
    factor1 = unit_to_baseunit(q.time_unit, physical_quantity_baseunits.time_in_s);
    factor2 = unit_to_baseunit(  time_unit, physical_quantity_baseunits.time_in_s);
    if(factor1!=NULL && factor1!=0 && factor2!=NULL && factor2!=0)
      q.numerical_value *= (factor1/factor2)^q.time_dim,
      q.time_unit = time_unit;
  }
  if(mass_unit!="" && q.mass_dim!=0)
  {
    factor1 = unit_to_baseunit(q.mass_unit, physical_quantity_baseunits.mass_in_kg);
    factor2 = unit_to_baseunit(  mass_unit, physical_quantity_baseunits.mass_in_kg);
    if(factor1!=NULL && factor1!=0 && factor2!=NULL && factor2!=0)
      q.numerical_value *= (factor1/factor2)^q.mass_dim,
      q.mass_unit = mass_unit;
  }
  if(curr_unit!="" && q.curr_dim!=0)
  {
    factor1 = unit_to_baseunit(q.curr_unit, physical_quantity_baseunits.current_in_A);
    factor2 = unit_to_baseunit(  curr_unit, physical_quantity_baseunits.current_in_A);
    if(factor1!=NULL && factor1!=0 && factor2!=NULL && factor2!=0)
      q.numerical_value *= (factor1/factor2)^q.curr_dim,
      q.curr_unit = curr_unit;
  }
  if(temp_unit!="" && q.temp_dim!=0)
  {
    factor1 = unit_to_baseunit(q.temp_unit, physical_quantity_baseunits.temperature_in_K);
    factor2 = unit_to_baseunit(  temp_unit, physical_quantity_baseunits.temperature_in_K);
    if(factor1!=NULL && factor1!=0 && factor2!=NULL && factor2!=0)
      q.numerical_value *= (factor1/factor2)^q.temp_dim,
      q.temp_unit = temp_unit;
  }

  if(copy)  return q;
}


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_string(quant)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable str = string(quant.numerical_value);
  variable unit;
  foreach unit ([{quant.leng_dim, quant.leng_unit},
	         {quant.time_dim, quant.time_unit},
		 {quant.mass_dim, quant.mass_unit},
		 {quant.curr_dim, quant.curr_unit},
		 {quant.temp_dim, quant.temp_unit}])
    if(unit[0]!=0)
    {
      str = sprintf("%s %s", str, unit[1]);
      if(unit[0]!=1)
        str = sprintf("%s^%d", str, unit[0]);
    }
  return str;
}
__add_string(PhysicalQuantity_Type, &physical_quantity_string);

        %%%%%%%%%%%%%%%%%%%%%%
private define unit_qualifiers(q)
        %%%%%%%%%%%%%%%%%%%%%%
{
  variable pow = qualifier("power", 1);

  if(qualifier_exists("nodim"))
    return struct {
      leng = q.leng_unit,
      time = q.time_unit,
      mass = q.mass_unit,
      curr = q.curr_unit,
      temp = q.temp_unit
    };
  else
    return struct {
      leng = q.leng_unit+"^"+string(int(round(q.leng_dim*pow))),
      time = q.time_unit+"^"+string(int(round(q.time_dim*pow))),
      mass = q.mass_unit+"^"+string(int(round(q.mass_dim*pow))),
      curr = q.curr_unit+"^"+string(int(round(q.curr_dim*pow))),
      temp = q.temp_unit+"^"+string(int(round(q.temp_dim*pow)))
    };
}

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_add(q1, q2)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  if(   q1.leng_dim != q2.leng_dim
     || q1.time_dim != q2.time_dim
     || q1.mass_dim != q2.mass_dim
     || q1.curr_dim != q2.curr_dim
     || q1.temp_dim != q2.temp_dim
    )
    throw MathError, sprintf("error (%s): cannot add %S and %S", _function_name(), q1, q2);
  % else
  if(   (q1.leng_dim!=0  &&  q1.leng_unit != q2.leng_unit)
     || (q1.time_dim!=0  &&  q1.time_unit != q2.time_unit)
     || (q1.mass_dim!=0  &&  q1.mass_unit != q2.mass_unit)
     || (q1.curr_dim!=0  &&  q1.curr_unit != q2.curr_unit)
     || (q1.temp_dim!=0  &&  q1.temp_unit != q2.temp_unit)
    )
  {
%    q1 = convert_units(q1; SI, copy);
%    q2 = convert_units(q2; SI, copy);
    q2 = convert_units(q2;; struct_combine(unit_qualifiers(q1; nodim), struct { copy }));
  }
  return physical_quantity(q1.numerical_value + q2.numerical_value;; unit_qualifiers(q1));
}
__add_binary("+", PhysicalQuantity_Type, &physical_quantity_add, PhysicalQuantity_Type, PhysicalQuantity_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_chs(q)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return physical_quantity(-q.numerical_value;; unit_qualifiers(q));
}
__add_unary("-", PhysicalQuantity_Type, &physical_quantity_chs, PhysicalQuantity_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_sub(q1, q2)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return q1 + (-q2);
}
__add_binary("-", PhysicalQuantity_Type, &physical_quantity_sub, PhysicalQuantity_Type, PhysicalQuantity_Type);


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_mul(q1, q2)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  if(q1.leng_dim!=0  &&  q2.leng_dim!=0  &&  q1.leng_unit != q2.leng_unit)
    q2 = convert_units(q2; leng=q1.leng_unit, copy);
  if(q1.leng_dim==0  &&  q2.leng_dim!=0)  q1.leng_unit = q2.leng_unit;

  if(q1.time_dim!=0  &&  q2.time_dim!=0  &&  q1.time_unit != q2.time_unit)
    q2 = convert_units(q2; time=q1.time_unit, copy);
  if(q1.time_dim==0  &&  q2.time_dim!=0)  q1.time_unit = q2.time_unit;

  if(q1.mass_dim!=0  &&  q2.mass_dim!=0  &&  q1.mass_unit != q2.mass_unit)
    q2 = convert_units(q2; mass=q1.mass_unit, copy);
  if(q1.mass_dim==0  &&  q2.mass_dim!=0)  q1.mass_unit = q2.mass_unit;

  if(q1.curr_dim!=0  &&  q2.curr_dim!=0  &&  q1.curr_unit != q2.curr_unit)
    q2 = convert_units(q2; curr=q1.curr_unit, copy);
  if(q1.curr_dim==0  &&  q2.curr_dim!=0)  q1.curr_unit = q2.curr_unit;

  if(q1.temp_dim!=0  &&  q2.temp_dim!=0  &&  q1.temp_unit != q2.temp_unit)
    q2 = convert_units(q2; temp=q1.temp_unit, copy);
  if(q1.temp_dim==0  &&  q2.temp_dim!=0)  q1.temp_unit = q2.temp_unit;

  return physical_quantity(q1.numerical_value * q2.numerical_value;
				leng=q1.leng_unit+"^"+string(q1.leng_dim+q2.leng_dim),
				time=q1.time_unit+"^"+string(q1.time_dim+q2.time_dim),
				mass=q1.mass_unit+"^"+string(q1.mass_dim+q2.mass_dim),
				curr=q1.curr_unit+"^"+string(q1.curr_dim+q2.curr_dim),
				temp=q1.temp_unit+"^"+string(q1.temp_dim+q2.temp_dim),
			       );
}
__add_binary("*", PhysicalQuantity_Type, &physical_quantity_mul, PhysicalQuantity_Type, PhysicalQuantity_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_mul_sq(s, q)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return physical_quantity(s*q.numerical_value;; unit_qualifiers(q));
}
__add_binary("*", PhysicalQuantity_Type, &physical_quantity_mul_sq, Any_Type, PhysicalQuantity_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_mul_qs(q, s)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return physical_quantity(s*q.numerical_value;; unit_qualifiers(q));
}
__add_binary("*", PhysicalQuantity_Type, &physical_quantity_mul_qs, PhysicalQuantity_Type, Any_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_power(q, p)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable dim;
  if(__is_numeric(p)!=1)  % Integer_Type
    foreach dim ([q.leng_dim, q.time_dim, q.mass_dim, q.curr_dim, q.temp_dim]*p)
      if( abs(dim - round(dim)) > 1e-6 )
        throw MathError, sprintf("error (%s): cannot compute (%S)^%S", _function_name(), q, p);
  return physical_quantity(q.numerical_value^p;; unit_qualifiers(q; power=p));
}
__add_binary("^", PhysicalQuantity_Type, &physical_quantity_power, PhysicalQuantity_Type, Any_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_div(q1, q2)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return q1 * (@q2)^-1;
}
__add_binary("/", PhysicalQuantity_Type, &physical_quantity_div, PhysicalQuantity_Type, PhysicalQuantity_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_div_qs(q, s)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return q * s^-1;
}
__add_binary("/", PhysicalQuantity_Type, &physical_quantity_div_qs, PhysicalQuantity_Type, Any_Type);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define physical_quantity_div_sq(s, q)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  return s * q^-1;
}
__add_binary("/", PhysicalQuantity_Type, &physical_quantity_div_sq, Any_Type, PhysicalQuantity_Type);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define handle_physical_quantity_units(q, units)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable unit, dim;
  foreach unit (units)
  { (unit, dim) = parse_unit_power(unit);
    q *= unit_to_baseunit(unit, physical_quantity_baseunits.unit) ^ dim;
  }
  return q;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity_length_in_m()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity_length_in_m}
%\synopsis{defines a new length unit or gets the conversion for an existing one}
%\usage{physical_quantity_length_in_m(String_Type name, Double_Type value);
%\altusage{Double_Type value = physical_quantity_length_in_m(String_Type name);}
%}
%\description
%    The unit  \code{name} = \code{value} m  can be used in
%       \code{physical_quantity(x; leng=name);  % = x * value} m
%\seealso{physical_quantity}
%!%-
{
  variable name, value;
  switch(_NARGS)
  { case 1: name = ();
      return physical_quantity_baseunits.length_in_m[name];
  }
  { case 2: (name, value) = ();
      physical_quantity_baseunits.length_in_m[name] = value;
  }
  { help(_function_name);
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity_time_in_s()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity_time_in_s}
%\synopsis{defines a new time unit or gets the conversion for an existing one}
%\usage{physical_quantity_time_in_s(String_Type name, Double_Type value);
%\altusage{Double_Type value = physical_quantity_time_in_s(String_Type name);}
%}
%\description
%    The unit  \code{name} = \code{value} s  can be used in
%       \code{physical_quantity(x; time=name);  % = x * value} s
%\seealso{physical_quantity}
%!%-
{
  variable name, value;
  switch(_NARGS)
  { case 1: name = ();
      return assoc_key_exists(physical_quantity_baseunits.time_in_s, name)
             ? physical_quantity_baseunits.time_in_s[name]
             : NULL;
  }
  { case 2: (name, value) = ();
      physical_quantity_baseunits.time_in_s[name] = value;
  }
  { help(_function_name);
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity_mass_in_kg()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity_mass_in_kg}
%\synopsis{defines a new mass unit or gets the conversion for an existing one}
%\usage{physical_quantity_mass_in_kg(String_Type name, Double_Type value);
%\altusage{Double_Type value = physical_quantity_mass_in_kg(String_Type name);}
%}
%\description
%    The unit  \code{name} = \code{value} kg  can be used in
%       \code{physical_quantity(x; mass=name);  % = x * value} kg
%\seealso{physical_quantity}
%!%-
{
  variable name, value;
  switch(_NARGS)
  { case 1: name = ();
      return assoc_key_exists(physical_quantity_baseunits.mass_in_kg, name)
             ? physical_quantity_baseunits.mass_in_kg[name]
             : NULL;
  }
  { case 2: (name, value) = ();
      physical_quantity_baseunits.mass_in_kg[name] = value;
  }
  { help(_function_name);
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity_current_in_A()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity_current_in_A}
%\synopsis{defines a new current unit or gets the conversion for an existing one}
%\usage{physical_quantity_current_in_A(String_Type name, Double_Type value);
%\altusage{Double_Type value = physical_quantity_current_in_A(String_Type name);}
%}
%\description
%    The unit  \code{name} = \code{value} A  can be used in
%       \code{physical_quantity(x; curr=name);  % = x * value} A
%\seealso{physical_quantity}
%!%-
{
  variable name, value;
  switch(_NARGS)
  { case 1: name = ();
      return assoc_key_exists(physical_quantity_baseunits.current_in_A, name)
             ? physical_quantity_baseunits.current_in_A[name]
             : NULL;
  }
  { case 2: (name, value) = ();
      physical_quantity_baseunits.current_in_A[name] = value;
  }
  { help(_function_name);
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity_temperature_in_K()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity_temperature_in_K}
%\synopsis{defines a new temperature unit or gets the conversion for an existing one}
%\usage{physical_quantity_temperature_in_K(String_Type name, Double_Type value);
%\altusage{Double_Type value = physical_quantity_temperature_in_K(String_Type name);}
%}
%\description
%    The unit  \code{name} = \code{value} K  can be used in
%       \code{physical_quantity(x; curr=name);  % = x * value} K
%\seealso{physical_quantity}
%!%-
{
  variable name, value;
  switch(_NARGS)
  { case 1: name = ();
      return assoc_key_exists(physical_quantity_baseunits.temperature_in_K, name)
             ? physical_quantity_baseunits.temperature_in_K[name]
             : NULL;
  }
  { case 2: (name, value) = ();
      physical_quantity_baseunits.temperature_in_K[name] = value;
  }
  { help(_function_name);
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define physical_quantity_unit()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{physical_quantity_unit}
%\synopsis{defines a new compound unit or gets the value of an existing one}
%\usage{physical_quantity_unit(String_Type name, Double_Type value;; qualifiers);
%\altusage{physical_quantity_unit(String_Type name, PhysicalQuantity_Type value);}
%\altusage{PhysicalQuantity_Type value = physical_quantity_unit(String_Type name);}
%}
%\description
%    If the second argument of the \code{physical_quantity_unit} function
%    is a double value, the value of the unit is
%    constructed with the \code{physical_quantity} function,
%    i.e., all its qualifiers can be applied.
%
%    The unit  \code{name} = \code{value}  can be used in
%       \code{physical_quantity(x; unit=name);  % = x * value}
%\seealso{physical_quantity}
%!%-
{
  variable name, value;
  variable baseunits = physical_quantity_baseunits.unit;
  switch(_NARGS)
  { case 1: name = ();
      return assoc_key_exists(baseunits, name)
             ? baseunits[name]
             : NULL;
  }
  { case 2: (name, value) = ();
      variable interpretation = unit_to_baseunit(name, baseunits; get_interpretation);
      ifnot(assoc_key_exists(baseunits, name) || length(interpretation)==0)
        vmessage("warning (%s): '%s' could be confused with %s",
		 _function_name. name, strjoin(list_to_array(interpretation), " or "));

      baseunits[name]
       = __is_numeric(value)
         ? physical_quantity(value;; __qualifiers)
         : value;
  }
  { help(_function_name);
  }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

variable physical_quantity_const = struct {
  BOLTZMANN = physical_quantity(1.3806503e-23; leng="m^2", time="s^-2", mass="kg", temp="K^-1"),
         kB = physical_quantity(1.3806503e-23; leng="m^2", time="s^-2", mass="kg", temp="K^-1"),
  ELECTRON_CHARGE = physical_quantity(1.602176462e-19; time="s", curr="A"),
                e = physical_quantity(1.602176462e-19; time="s", curr="A"),
  GRAVITATIONAL_CONSTANT = physical_quantity(6.673e-11; leng="m^3", time="s^-2", mass="kg^-1"),
                       G = physical_quantity(6.673e-11; leng="m^3", time="s^-2", mass="kg^-1"),
  MASS_ELECTRON = physical_quantity(9.10938188e-31; mass="kg"),
            mEl = physical_quantity(9.10938188e-31; mass="kg"),
  MASS_NEUTRON = physical_quantity(1.67492716e-27; mass="kg"),
            mN = physical_quantity(1.67492716e-27; mass="kg"),
  MASS_PROTON = physical_quantity(1.67262158e-27; mass="kg"),
           mP = physical_quantity(1.67262158e-27; mass="kg"),
  PLANCKS_CONSTANT_H = physical_quantity(6.62606876e-34; leng="m^2", time="s^-1", mass="kg"),
                   h = physical_quantity(6.62606876e-34; leng="m^2", time="s^-1", mass="kg"),
  PLANCKS_CONSTANT_HBAR = physical_quantity(1.05457159642e-34; leng="m^2", time="s^-1", mass="kg"),
                   hbar = physical_quantity(1.05457159642e-34; leng="m^2", time="s^-1", mass="kg"),
  SPEED_OF_LIGHT = physical_quantity(299792458; leng="m", time="s^-1"),
               c = physical_quantity(299792458; leng="m", time="s^-1"),
  VACUUM_PERMITTIVITY = physical_quantity(8.854187817e-12; leng="m^-3", time="s^4", mass="kg^-1", curr="A^2"),
             epsilon0 = physical_quantity(8.854187817e-12; leng="m^-3", time="s^4", mass="kg^-1", curr="A^2"),
};

physical_quantity_baseunits.length_in_m["m"] = 1.;
physical_quantity_baseunits.length_in_m["A"] = 1e-10;
physical_quantity_baseunits.length_in_m["in"] = 0.0254;
physical_quantity_baseunits.length_in_m["ft"] = 0.30480; % = 12 in
physical_quantity_baseunits.length_in_m["yd"] = 0.91440; % =  3 ft
physical_quantity_baseunits.length_in_m["ly"] = 9.4607304725808e15;
physical_quantity_baseunits.length_in_m["pc"] = 3.0857e16;
physical_quantity_baseunits.length_in_m["R[sun]"] = 6.955e8;
physical_quantity_baseunits.length_in_m["AU"] = 1.49597870691e11;

physical_quantity_baseunits.time_in_s["s"] = 1.;
physical_quantity_baseunits.time_in_s["min"] = 60.;
physical_quantity_baseunits.time_in_s["h"] = 3600.;
physical_quantity_baseunits.time_in_s["d"] = 86400.;
physical_quantity_baseunits.time_in_s["yr"] = 3.15576e7;  % 3.1556952e7 = 365.2425 d

physical_quantity_baseunits.mass_in_kg["g"] = 1e-3;
physical_quantity_baseunits.mass_in_kg["u"] = 1.66053873e-27;
physical_quantity_baseunits.mass_in_kg["M[sun]"] = 1.98892e30;
%physical_quantity_baseunits.mass_in_kg["eV"] = 1.78266173e-36;

physical_quantity_baseunits.current_in_A["A"] = 1;

physical_quantity_baseunits.temperature_in_K["K"] = 1;

physical_quantity_unit("N", 1; mass="kg", leng="m", time="s^-2");
physical_quantity_unit("J", 1; unit="N", leng="m");
physical_quantity_unit("W", 1; unit="J", time="s^-1");
physical_quantity_unit("V", 1; unit="W", curr="A^-1");

physical_quantity_unit("erg", 1e-7; unit="J");
physical_quantity_unit("eV", physical_quantity_const.e * physical_quantity(1; unit="V"));
physical_quantity_unit("Jy", 1e-26; unit="J", leng="m^-2");
physical_quantity_unit("Hz", 1; time="s^-1");
