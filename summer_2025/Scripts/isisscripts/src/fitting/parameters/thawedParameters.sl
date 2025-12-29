define thawedParameters()
%!%+
%\function{thawedParameters}
%\synopsis{find all parameters of the current fit-function that are not frozen}
%\usage{Integer_Type[] thawedParameters()}
%\description
%    Note that \code{thawedParameters} may include ones that are
%    tied to another one, or derived as functions of other parameters.
%\seealso{freeParameters}
%!%-
{
  variable params = get_params();
  if(params!=NULL)
    return where( array_struct_field(params, "freeze")==0 )
           + 1;  % parameter numbers start with 1
  else
    return Integer_Type[0];
}
