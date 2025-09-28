%%%%%%%%%%%%%%%%%%%%%%
define KS_test(x1,x2)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{KS_test}
%\synopsis{computes the test statistics of a two sample Kolmogorov-Smirnov test}
%\usage{test_statistics = KS_test(Double_Type x1, Double_Type x2);}
%\description
% The null hypothesis of the KS test is that two samples are
% distributed according to the same distribution. It is rejected if
% the test statistic D=max(F_1(x),F_2(x)) is greater than a certain
% value
%!%-
{
   % sort distributions
   variable y1=x1[array_sort(x1)];
   variable y2=x2[array_sort(x2)];
   variable n1=length(x1);
   variable n2=length(x2);   
   % get empirical distribution function (step function)
   variable F1=1.0*[1:n1:1]/n1;
   variable F2=1.0*[1:n2:1]/n2;
   % sort the two distributions with respect to each other
   variable s=array_sort([y1,y2]);
   variable Fe1=Double_Type[n1+n2+1];
   variable Fe2=Double_Type[n1+n2+1];
   Fe1[*]=-1;
   Fe2[*]=-1;
   Fe1[0]=0;
   Fe2[0]=0;
   variable int=[1:n1+n2:1];
   Fe1[int[where(s<n1)]]=F1;
   Fe2[int[where(s>n1-1)]]=F2;
   % there is a -1  everywhere where the other function changes, there
   % the value should be the last not -1 value (because this function
   % stays constant):
   variable m=where(Fe1==-1);
   while (length(m)>0)
     {
	Fe1[m]=Fe1[m-1];
	m=where(Fe1==-1);
     }
   m=where(Fe2==-1);
   while (length(m)>0)
     {
         Fe2[m]=Fe2[m-1];
	 m=where(Fe2==-1);
     }
   % return the maximum of the difference
   return max(abs(Fe1-Fe2));
}
%%%%%%%%%%%%%%%%%%%%
