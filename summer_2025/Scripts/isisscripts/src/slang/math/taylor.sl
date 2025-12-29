define taylor()
%!%+
%\function{taylor}
%\synopsis{Returns the taylor series for given coefficients}
%\usage{Double_Type taylor(Double_Type[] x, coefficients)}
%\description
%    Returns the taylor series around x with the given
%    'coefficients', which lengths determines the order.
%    The sum is evaluated using the Horner (1819) schema
%    for numerical accuracy and computation speed:
%
%    c0 + c1*x + 1/2!*c2*x^2 + 1/3!*c3*x^3 + ...
%    = (((... + c3)*x/3 + c2)*x/2 + c1)*x + c0
%\example
%    x = [0, 1];
%    c = [1, 4e-3, 0, 3e-6]; % up to third order
%
%    taylor(x, c); % returns [1.0, 1.0040005]
%!%-
{
  variable x,c;
  switch (_NARGS)
    { case 2: (x,c) = (); }
    { help(_function_name); return; }

  c = [c];
  variable n = length(c);

  % we use the Horner schema here to
  % achieve a higher numerical precission
  % and faster computation (Horner, 1819)

  variable y = typeof(x) == Array_Type ? Double_Type[length(x)] : 0;
  variable i;
  _for i (n-1, 1, -1) {
    y = (y + c[i])*x/i;
  }
  y += c[0];

  return y;
}


%%%%%%%%%%%%%%%%%%%%%%%%
define taylorcoeff_from_struct()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{taylorcoeff_from_struct}
%\synopsis{extracts taylor coefficients from the field names of a structure}
%\usage{Double_Type[] taylorcoeff_from_struct(Struct_Type struct[,
%                    String_Type 0th_pattern, String_Type Nth_pattern]);}
%\description
%    If a structure has fields which names reflect the
%    different orders of a taylor series, this function
%    extracts these coefficients by matching the field
%    names against two patterns.
%
%    '0th_pattern' is the field name of the zero order
%    and 'Nth_pattern' this of all higher order terms.
%    Both patterns have to be regular expressions. In
%    particular, the expression of the Nth order must
%    contain a number extraction two determine the order
%    N of that field.
%
%
%    By default, '0th_pattern' is set to "[a-zA-Z]0" and
%    'Nth_pattern' to "[a-zA-Z]\\([0-9]*\\)dot"R. If the
%    latter _pattern matches, but the extracted number
%    is an empty string N=1 is assumed.
%
%    The returned array contains the taylor coefficients
%    in ascending order as used by the 'taylor'-function.
%\seealso{taylor, string_matches}
%!%-
{
  variable s, pat0 = "[a-zA-Z]0", patN = "[a-zA-Z]\([0-9]*\)dot"R;
  switch(_NARGS)
    { case 1: (s) = (); }
    { case 3: (s,pat0,patN) = (); }
    { help(_function_name()); return; }

  % extract and loop over struct's fields
  variable fields = get_struct_field_names(s);
  variable coeff = Double_Type[0];
  variable i;
  _for i (0, length(fields)-1, 1) {
    % check if field matches 0th order
    if (string_matches(fields[i], pat0) != NULL) {
      if (length(coeff) == 0) { coeff = Double_Type[1]; }
      coeff[0] = get_struct_field(s, fields[i]);
    }
    % check if field matches Nth order
    else {
      variable match = string_matches(fields[i], patN, 1);
      if (match != NULL) {
        % get the N and eventually increase coeff-array
        variable n = match[1] == "" ? 1 : atoi(match[1]);
        if (length(coeff) <= n) { coeff = [coeff, Double_Type[n-length(coeff)+1]]; }
        coeff[n] = get_struct_field(s, fields[i]);
      }
    }
  }

  return coeff;
}
