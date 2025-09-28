%%%%%%%%%%%%
define Roman(n) {
%!%+
%\function{Roman}
%\synopsis{translates n to upper-case string with roman numeral}
%\usage{String_Type res = Roman(Integer_Type n)}
%\qualifiers{
%\qualifier{latex}{typeset minus sign ("$-$"R)}
%\qualifier{toobig}{[=""] string that is returned of n is larger
%                    than the largest known Roman numeral (3999) }
%}
%\description
% Converts an integer into a uppercase roman numeral.
% Even though not known in Roman times, negative numbers are allowed.
%
% Algorithm based on
% https://www.geeksforgeeks.org/converting-decimal-number-lying-between-1-to-3999-to-roman-numerals/
%
%\seealso{roman}
%!%-
   variable minus = "-";
   if(qualifier_exists("latex")) {minus = "$-$"R;}
   variable oob = qualifier("toobig", "");
   variable nums,w1,w2;
   variable array = 1;
   
   if (typeof(n)==Array_Type) {
       return array_map(String_Type, &Roman, n);
   }

   if (typeof(n)!=Integer_Type) {
       throw UsageError,sprintf("%s: argument must be of Integer type",_function_name());
   }

   if (n==0) {
       return "0";
   }
   
   variable num= [1,4,5,9,10,40,50,90,100,400,500,900,1000]; 
   variable sym = ["I","IV","V","IX","X","XL","L","XC","C","CD","D","CM","M"];

   variable i=12;
   variable res="";
   if (n<0) {
       res=minus;
       n=-n;
   } 
   
   while(n>0) { 
       variable div = n/num[i]; 
       n = n mod num[i];
       while(div>0) {
	   div--;
	   res+=sym[i];
       } 
       i--; 
   }

   return(res);
}

%%%%%%%%%%%%
define roman(n)
%%%%%%%%%%%%
%!%+
%\function{roman}
%\synopsis{replaces an integer with lowercase Roman numeral strings}
%\usage{String_Type rom = roman(Integer_Type);}
%\synopsis{translates n to lower-case string with roman numeral}
%\usage{String_Type roman = romann(Integer_Type n)}
%\qualifiers{
%\qualifier{latex}{typeset minus sign ("$-$"R)}
%\qualifier{toobig [=""]}{string that is returned of n is larger
%                    than the largest known Roman numeral}
%}
%\seealso{Roman}
%!%-
{
  return strlow(Roman(n;; __qualifiers));
}

define roman2int()
%!%+
%\function{roman2int}
%\usage{Integer_Type=roman2int(String_Type)}
%\synopsis{translates a roman numeral into an integer}
%\description
% This function converts roman numerals into integers.
% The function is case insensitive and array safe.
%\seealso{roman,Roman}
%!%-
{
    variable r=();

    if (typeof(r)==Array_Type) {
	return array_map(Integer_Type,&roman2int,r);
    }
    
    r=strup(r);

    % deal with negative numbers
    variable sn=+1;
    if (substr(r,1,1)=="-") {
	sn=-1;
	r=substr(r,2,strlen(r));
    }
    
    variable vals=Assoc_Type[Integer_Type];
    vals["0"]=0;
    vals["I"]=1;
    vals["V"]=5;
    vals["X"]=10;
    vals["L"]=50;
    vals["C"]=100;
    vals["D"]=500;
    vals["M"]=1000;

    variable res=0;
    variable i;
    for (i=1; i<=strlen(r); i++) {
	variable s1=vals[substr(r,i,1)];
	if (i<strlen(r)) {
	    variable s2=vals[substr(r,i+1,1)];
	    if (s1>=s2) {
		res+=s1;
	    } else {
		res+=s2-s1;
		i++;
	    }
	} else {
	    res+=s1;
	}
    }

    res=sn*res;

    % sanity check (otherwise we silently return erroneous results for
    % illegal roman numerals)
    if (r!=Roman(res)) {
	throw UsageError,sprintf("%s: %s is not a valid roman numeral",_function_name(),r);
    }

    
    return sn*res;
}
