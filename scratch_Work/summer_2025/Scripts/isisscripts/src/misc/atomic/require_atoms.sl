define require_atoms()
%!%+
%\function{require_atoms}
%\usage{require_atoms();}
%\description
%    This function loads the atomic data from the
%    Astrophysical Plasma Emission Database via\n
%       \code{atoms(aped);}\n
%    unless \code{_isis->Dbase} is already initialized.
%\seealso{atoms}
%!%-
{
  if(_isis->Dbase.dir == NULL)  atoms(aped);
}
