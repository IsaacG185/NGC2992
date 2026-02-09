%%%%%%%%%%%%%%%%%%%%%%%
define ratio_error_prop()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ratio_error_prop}
%\synopsis{calculates a ratio and error propagation}
%\usage{(rat, err) = ratio_error_prop(a, a_err, b, b_err);
%\altusage{(rat, err) = ratio_error_prop(a, b; Poisson);}
%}
%\description
%    \code{rat = a/b}\n
%    \code{err = sqrt[ (1/b * a_err)^2 + (a/b^2 * b_err)^2 ]}
%\qualifiers{
%\qualifier{Poisson}{\code{a_err = sqrt(a);  b_err = sqrt(b);}}
%}
%\seealso{hardnessratio_error_prop}
%!%-
{
  variable a, a_err, b, b_err;
  switch(_NARGS)
  { case 2: if(qualifier_exists("Poisson"))
            { (a, b) = (); a_err = sqrt(a); b_err = sqrt(b); }
            else
            { help(_function_name()); return; }
  }
  { case 4: (a, a_err, b, b_err) = (); }
  { help(_function_name()); return; }

  return 1.*a/b,  sqrt( (a_err/b)^2 + (a/b^2*b_err)^2 );
}
