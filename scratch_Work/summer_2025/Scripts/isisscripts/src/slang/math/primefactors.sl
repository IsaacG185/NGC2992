define primefactors(x)
%!%+
%\function{primefactors}
%\synopsis{factorizes an integer number into primes}
%\usage{Integer_Type factors[] = primefactors(Integer_Type x);}
%\description
%    The array of prime factors will be ordered:
%    \code{factor[i] <= factor[j]  %} for \code{i<j}.
%!%-
{
  variable factors = Integer_Type[0];
  variable p;
  foreach p ([2,3,5,7])
    while(x mod p==0)
    { factors = [factors, p];
      x /= p;
    }
  p = 11;
  while(x>1)
  { while(x mod p==0)
    { factors = [factors, p];
      x /= p;
    }
    do  p+=2;  while((p mod 3)*(p mod 5)*(p mod 7)==0);
    if(p*p>x)  p = x;
  }
  return factors;
}
