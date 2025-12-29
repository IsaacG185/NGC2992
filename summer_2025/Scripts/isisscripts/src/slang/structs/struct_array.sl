define struct_array(n,s) {
%!%+
%\function{struct_array}
%\synopsis{creates an array of structures}
%\usage{Struct_Type[] struct_array(Integer_Type n, Struct_Type s);}
%\description
%    An array of n structures is created,
%    where each structure is a copy of the
%    given one s. 
%\example
%    variable sarr = struct_array(4, struct { firstname, lastname });
%    sarr[2].firstname = "Karl";
%    sarr[2].lastname = "Remeis";
%
%    print(sarr);
%    % will return
%    % {firstname=NULL, lastname=NULL}
%    % {firstname=NULL, lastname=NULL}
%    % {firstname="Karl", lastname="Remeis"}
%    % {firstname=NULL, lastname=NULL}
%\seealso{table_copy}
%!%-
  variable sn = Struct_Type[n];
  _for n (0, n-1, 1) sn[n] = COPY(s);
  return sn;
}
