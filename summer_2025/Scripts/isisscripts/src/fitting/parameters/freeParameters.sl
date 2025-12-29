%%%%%%%%%%%%%%%%%%%%%%%
define freeParameters()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{freeParameters}
%\synopsis{find all free parameters of the current fit-function}
%\usage{Integer_Type[] freeParameters()}
%\description
%    Free parameters are not frozen, tied to another one,
%    or derived as functions of other parameters.
%\seealso{thawedParameters}
%!%-
{
  variable ind = {};
  variable par;
  foreach par ( get_params() )
    if(par.freeze==0 && par.tie==NULL && par.fun==NULL)
      list_append(ind, par.index);
  return list_to_array(ind, Integer_Type);
}
