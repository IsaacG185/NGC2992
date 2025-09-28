define split_struct()
%!%+
%\function{split_struct}
%\synopsis{splits a structure of related arrays into several structures of the same kind}
%\usage{Struct_Type structs[] = split_struct(Struct_Type s, Integer_Type group[]);}
%\description
%    All fields of the structure \code{s}, as well as \code{group}, have to be related arrays
%    of equal length. The array elements with the same corresponding \code{group} value
%    are selected to form a new structure, unless the \code{group} value is negative.
%    In the latter case (\code{group<0}), the array elements are discarded.
%    The split structures are returned in an array, indexed by the \code{group} value.
%    In other words:\n
%       \code{structs[g].field = s.field[where(group==g)]}\n
%    for \code{0 <= g <= max(group)} and any \code{field} of the structure \code{s}.
%\examples
%    \code{variable prime_struct = struct { i, p };}\n
%    \code{prime_struct.i = [ 1,  2,  3,  4,  5,  6,  7,  8,  9, 10];}\n
%    \code{prime_struct.p = [ 2,  3,  5,  7, 11, 13, 17, 19, 23, 29];}\n
%
%    \code{variable group = [-1,  1, -1,  2,  0,  1,  2,  3,  1,  3];}\n
%    \code{% which might be obtained from the following selection:}\n
%    \code{group = Integer_Type[length(prime_struct.p)];}\n
%    \code{group[*] = -1;}\n
%    \code{group[where(prime_struct.p mod 10 == 1)] = 0;}\n
%    \code{group[where(prime_struct.p mod 10 == 3)] = 1;}\n
%    \code{group[where(prime_struct.p mod 10 == 7)] = 2;}\n
%    \code{group[where(prime_struct.p mod 10 == 9)] = 3;}\n
%
%    \code{variable primes = split_struct(prime_struct, group);}\n
%    \code{writecol(stdout, primes[1].i, primes[1].p);  % primes with last digit 3}\n
%\seealso{split_lc_at_gaps}
%!%-
{
  variable s, group;
  switch(_NARGS)
  { case 2: (s, group)= (); }
  { help(_function_name()); return; }

  % lots of checks necessary...

  variable g, structs = Struct_Type[0];
  _for g (0, max(group), 1)
    structs = [ structs, struct_filter(s, where(group==g); copy) ];
  return structs;
}
