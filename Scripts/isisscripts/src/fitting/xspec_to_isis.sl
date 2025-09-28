require("xspec");

private define read_xspec (file_name)

{
	if ( not qualifier_exists("nonverbose") )
		vmessage("Running Xspec.................");
	variable file_stream = popen("echo '@"+file_name+"' | xspec", "r");
	variable all_lines = fgetslines(file_stream);
	variable i=0;
	variable start_index, end_index;
try
{
	_for i(0, length(all_lines)-1, 1)
	{
		if ( string_match(all_lines[i], "===") == 1 )
			start_index=i;
		if ( string_match(all_lines[i], "___") == 1 )
			end_index=i;
	}
	variable return_parameters=String_Type[end_index-start_index-4];
	variable counter=0;
	_for i(start_index+4, end_index-1, 1)
	{
		return_parameters[i-start_index-4] = all_lines[i];
		counter++;
	}
	variable return_header = all_lines[start_index+2];
	variable model_line=all_lines[start_index+1];
	variable return_model=substr(model_line, string_match(model_line, " ")+1, string_match(model_line, "Source")-string_match(model_line, " ")-1);
	return (return_parameters, return_header, return_model);
} catch AnyError: {
	vmessage("Evaluation of "+file_name+" in Xspec failed:");
	_for i(0, length(all_lines)-1, 1)
		vmessage(all_lines[i]);
	throw ApplicationError;
}
}

private define search (input, pattern)
{
        variable count=0;
        variable i=0;
        variable len=strlen(input);
        _for i(1, len, 1)
        {
                if (substr(input, i, 1) == pattern) {count++;};
        }
        variable positions=Integer_Type[count];
        count=0;
        _for i(1, len, 1)
        {
                if (substr(input, i, 1) == pattern) {positions[count]=i; count++;};
        }
        if ( length(positions) != 0) {return positions;} else {return NULL;};   %CAREFULL: returns position for the ">" for use with substr
}

private define model_start (input, position_start)                              %position_start refers to the position of the closing ">" behind the model
{
        variable start=position_start-3;
        while ( isalnum(substr(input, start, 1) ) == 1) {start--;}
        return start;
}

private define correct_model (model_string_raw)
{
        variable len = strlen(model_string_raw);
        variable all_characters = String_Type[len];
        variable i=0;
        _for i(1, len, 1)
                all_characters[i-1]=substr(model_string_raw, i, 1);
        variable pos = search(model_string_raw, ">");
        variable models = String_Type[length(pos)];
        variable between = String_Type[length(pos)+1];
        variable start = Integer_Type[length(pos)];
        variable end = Integer_Type[length(pos)];
        variable model_string="";
        _for i(0, length(pos)-1, 1)
        {
                start[i] = model_start(model_string_raw, pos[i])+1;
                end[i] = pos[i]-model_start(model_string_raw, pos[i]);
                if ( i == 0 )
                        between[i] = substr(model_string_raw, 1, start[i]-1);
                else    
                        between[i] = substr(model_string_raw, start[i-1]+end[i-1], start[i]-start[i-1]-end[i-1]);
                models[i] = substr(model_string_raw, start[i], end[i]);
                if ( substr(between[i], 1, 1) == "(" )
                        between[i] = "*"+between[i];
                if ( substr(between[i], strlen(between[i]), 1) == ")" )
                        between[i] = between[i]+"*";
                model_string = model_string + between[i] + models[i];
        }
        i=length(pos)-1;
        between[i+1] = substr(model_string_raw, start[i]+end[i], len-end[i]-start[i]+1);
        model_string = model_string+between[i+1];
	return model_string;
}


private define get_string_starts(input)
{
        variable len=strlen(input);
        variable test;
        variable count=0;
        variable was_before=0;
        variable i=1;
        variable char_at_start=isspace(input);                                          %if there is a normal character at the start, this value is not 0
        _for i(1, len-1, 1)
        {       
                test = isspace(substr(input, i, 1));
                if ( ( (was_before == 0) )and (test == 0) )
                {       
                        was_before = 1;
                        count++;
                }
                else if ( (was_before == 1) and (test == 1) )
                {
                        was_before = 0;
                }
        }
        variable starts=Integer_Type[count];
        variable stops=Integer_Type[count];
        variable count2=0;
        _for i(1, len-1, 1)
        {       
                test = isspace(substr(input, i, 1)); 
                if ( ( (was_before == 0) ) and (test == 0) )
                {       
                        was_before = 1;
                        starts[count2] = i;
                        count2++;
                }
                else if ( (was_before == 1) and (test == 1))
                {       
                        stops[count2-1] = i;
                        was_before = 0;
                }
        }
        variable got_substrings = String_Type[length(starts)];
        if (char_at_start != 1)
        {
                starts=shift(starts, -1);
                stops=shift(stops, -1);
                starts[0] = starts[0]+1;
        }
        _for i(0, length(starts)-1, 1)
                {
                        got_substrings[i] = substr(input, starts[i], (stops[i]-starts[i]));
                }
        return (starts, stops, got_substrings);
}


private define get_index (input_array, input_value)
{
	variable i;
	_for i(0, length(input_array)-1, 1)
	{
		if ( (i<length(input_array)) and (input_array[i] == input_value ) ) {return i;};
	}
	return -1;
}

%%%%%%%%%%%%%%%%%%%%%%%%%
define xspec_to_isis (name)
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{xspec_to_isis}
%\synopsis{Parse xspec parameter file to isis parameter file}
%\usage{Integer_Type t = xspec_to_isis(String_Type xspec_par)}
%\qualifiers{
%\qualifier{set}{set loadad parameters}
%\qualifier{save}{ [=String_Type filename] save parameters as isis parameter file
%	if filename is not specified it is saved as the .xcm file but with .par suffix}
%\qualifier{nonverbose}{suppress any output not produced by errors}
%}
%\description
%	Parse an xspec parameter file \code{.xcm} to an isis parameter file.
%	If desired parameters can be set after parsing.
%	*** Warning:
%	Xspec tying expressions are only supported in the form of
%	\code{= p1}
%	*** Warning:
%	Convolution models are not supported!
%	If tied parameters is out of range of the respective parameter
%	the limits are set to fit and a warning is given.
%\example
%	isis> t=xspec_to_isis ("test.xcm"; save);
%	Running Xspec.................
%	parameters saved to test.par as:
%	diskbb(1) + nthComp(2)
%	 idx  param            tie-to  freeze         value         min         max
%	  1  diskbb(1).norm        0     0          21.7378           0       1e+10  
%	  2  diskbb(1).Tin         0     0         0.230239       0.001          10  keV
%	  3  nthComp(2).norm       0     0       0.00019705           0       1e+10  
%	  4  nthComp(2).Gamma      0     0           1.9752       1.001           5  
%	  5  nthComp(2).kT_e       0     0          1.68497     1.68497        1000  keV
%	  6  nthComp(2).kT_bb      2     0         0.230239       0.001          10  keV
%	  7  nthComp(2).inp_type   0     1                1           0           1  0/1
%	  8  nthComp(2).Redshift   0     1                0      -0.999          10  
%\seealso{set_par, load_par}
%!%-
{
%Assuming a .xcm file, then getting the name without .xcm
	if (string_match(name, ".xcm") == 0) {vmessage(name+" is not an xcm-file"); return -1;};
	variable name_file=strreplace(name, ".xcm", "");
	variable old_fun = get_fit_fun;
	variable old_pars = get_params;
	try
	{
	%Splitting the .xcm file
		require("xspec");
		require("isisscripts");
	        variable cut_lines, header_string, model_string_raw;
		try
		{
			(cut_lines, header_string, model_string_raw) = read_xspec(name ;; __qualifiers);
		} catch AnyError: {
			return -1;
		}
		variable model_string = correct_model(model_string_raw);
		model_string = strreplace(strreplace(model_string, "<", "("), ">", ")" );
	        variable i=0;
	        _for i (0, length(cut_lines)-1, 1)
	        {
	                cut_lines[i] = substr(cut_lines[i], 1, strlen(cut_lines[i])-1);                 %removing the \n
	        };
		variable all_lines=Array_Type[length(cut_lines)];
		variable all_lines_starts=Array_Type[length(cut_lines)];
		variable all_lines_stops=Array_Type[length(cut_lines)];
		_for i(0, length(all_lines)-1, 1)
		{
			(all_lines_starts[i], all_lines_stops[i], all_lines[i]) = get_string_starts(cut_lines[i]);
		}
		variable value_starts = string_match(header_string, "Value");
		variable parameter_indices = String_Type[length(all_lines)];
		variable parameter_model_indices = String_Type[length(all_lines)];
		variable parameter_models = String_Type[length(all_lines)];
		variable parameter_parameters = String_Type[length(all_lines)];
		variable parameter_values = Double_Type[length(all_lines)];
		variable parameter_frozen = Integer_Type[length(all_lines)];
		_for i (0, length(parameter_indices)-1, 1)
		{
			parameter_indices[i] = all_lines[i][0];
			parameter_model_indices[i] = all_lines[i][1];
			parameter_models[i] = all_lines[i][2];
			parameter_parameters[i] = all_lines[i][3];
		};
		_for i(0, length(all_lines)-1, 1) 
		{
			parameter_values[i] = atof(all_lines[i][get_index(all_lines_starts[i], value_starts)]);
			if ( all_lines[i][get_index(all_lines_starts[i], value_starts)+1] == "frozen" ) { parameter_frozen[i] = 1;}
		};
		variable parameter_strings = String_Type[length(all_lines)];
		_for i(0, length(all_lines)-1, 1)
		{
			parameter_strings[i] = parameter_models[i]+"("+parameter_model_indices[i]+")."+parameter_parameters[i];
		}
		fit_fun(model_string);
		variable temp_pars=get_params;
		_for i(0, length(all_lines)-1, 1)
		{
			try
			{
				if ( (get_par_info(parameter_strings[i]).min ) > parameter_values[i] )
				{
					set_par(parameter_strings[i], parameter_values[i], parameter_frozen[i], parameter_values[i], get_par_info(parameter_strings[i]).max);
				}
				else if ( (get_par_info(parameter_strings[i]).max ) < parameter_values[i] )
				{
					set_par(parameter_strings[i], parameter_values[i], parameter_frozen[i],get_par_info(parameter_strings[i]).min, parameter_values[i]);
				}
				else
				{
					set_par(parameter_strings[i], parameter_values[i], parameter_frozen[i]);
				}
			} catch AnyError: {
				vmessage("Error setting Parameter %i: %s = %f", i, parameter_strings[i], parameter_values[i]);
			}
		}
	%Getting which parameters are tied to another
	        variable tied_count=0;
	        variable which_tied = Integer_Type[length(all_lines)];
	        _for i(0, length(all_lines)-1, 1)
	        {
	                if ( all_lines[i][get_index(all_lines_starts[i], value_starts)+1] == "=" )
	                {
	                        if ( string_match(all_lines[i][get_index(all_lines_starts[i], value_starts)+2], "p") != 0 )
	                        {
	                                tied_count++;
	                        }
	                }
	        }
	        variable tied_from=Integer_Type[tied_count];
	        variable tied_to=Integer_Type[tied_count];
	        tied_count=0;
	        _for i(0, length(all_lines)-1, 1)
	        {
	                if ( all_lines[i][get_index(all_lines_starts[i], value_starts)+1] == "=" )
	                {
	                        if ( string_match(all_lines[i][get_index(all_lines_starts[i], value_starts)+2], "p") != 0 )
	                        {
	                                tied_from[tied_count] = i;
	                                tied_to[tied_count] = typecast(atof(strreplace(all_lines[i][get_index(all_lines_starts[i], value_starts)+2], "p", ""))-1, Integer_Type);
	                                tied_count++;
	                        }
	                }
	        }
	        _for i(0, length(tied_to)-1, 1)
	        {
			try
			{
		                tie(parameter_strings[tied_to[i]], parameter_strings[tied_from[i]]);
				
				if (get_par_info(parameter_strings[tied_to[i]]).min < get_par_info(parameter_strings[tied_from[i]]).hard_min)
				{
					if (not qualifier_exists("nonverbose"))
					{
						vmessage("***Warning: Minimum of '%s': %f violates hard limit of '%s': %f, setting new Minimum", parameter_strings[tied_to[i]],									%<<--- new line
						get_par_info(parameter_strings[tied_to[i]]).min, parameter_strings[tied_from[i]], get_par_info(parameter_strings[tied_from[i]]).hard_min);
					}
					set_par(parameter_strings[tied_to[i]], get_par(parameter_strings[tied_to[i]]), parameter_frozen[tied_to[i]], get_par_info(parameter_strings[tied_from[i]]).hard_min, get_par_info(parameter_strings[tied_to[i]]).max);
				}
				if (get_par_info(parameter_strings[tied_to[i]]).max > get_par_info(parameter_strings[tied_from[i]]).hard_max)
	                        {
					if (not qualifier_exists("nonverbose"))
					{
	                                	vmessage("***Warning: Maximum of '%s': %f violates hard limit of '%s': %f, setting new Maximum", parameter_strings[tied_to[i]], 
		                                get_par_info(parameter_strings[tied_to[i]]).max, parameter_strings[tied_from[i]], get_par_info(parameter_strings[tied_from[i]]).hard_max);
					}
	        	                set_par(parameter_strings[tied_to[i]], get_par(parameter_strings[tied_to[i]]), parameter_frozen[tied_to[i]], get_par_info(parameter_strings[tied_to[i]]).min, get_par_info(parameter_strings[tied_from[i]]).hard_max);
	                        }
	
			} catch AnyError: {
				vmessage("Error tieing parameters. Expression in Xspec: %s", all_lines[i][get_index(all_lines_starts[i], value_starts)+2]);
			}
	        }
		if (qualifier_exists("save") )
		{
			if ( qualifier("save")==NULL )
				{
		        	save_par(name_file+".par");
				if ( not qualifier_exists("nonverbose") )
				        vmessage("parameters saved to "+name_file+".par as:");
				}
			else
			{
				save_par(qualifier("save"));
				if ( not qualifier_exists("nonverbose") )
	                               vmessage("parameters saved to "+qualifier("save")+".par as:");
			}
		}
		if ( not qualifier_exists("nonverbose") )
		        list_par;
	} catch AnyError: {
		vmessage("Fatal Error");
		return -1;
	}
	if ( not qualifier_exists("set") )
	{
		set_params(temp_pars);
		fit_fun(old_fun);
		set_params(old_pars);
	}
	return 0;
}
