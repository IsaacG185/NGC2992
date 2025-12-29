define factorset(n)
  %%%%%%%%%%%%%%%%%%%
  %!%+
  %\function{factorset}
  %\synopsis{factorizes an integer number into all possible integer factors}
  %\usage{Integer_Type factors[] = factorset(Integer_Type x);}
  %\description
  %    The array of factors will be ordered:
  %    \code{factor[i] <= factor[j]  %} for \code{i<j}.
  %!%-
{
  if( _typeof(n) != Integer_Type )
    return n;

  variable I = [1:n];
  
  return I[where( n mod I == 0 )];
}
