define first_valid_digit( x )
%!%+
%\function{first_valid_digit}
%\synopsis{gives the position of the first valid digit}
%\usage{Integer_Type fvd = first_valid_digit( Integer/Double_Type x )};
%!%-
{
  variable absx = abs(x);

  if( absx == 0 ){
    return 0;
  }
  else if( absx < 1 ){
    return int(floor(log10(absx)));
  }
  else if( absx == 1 ){
    return 1;
  }
  else{
    return int(ceil(log10(absx)*(1+DOUBLE_EPSILON)));
  }
}
