define get_struct_fields()
%!%+
%\function{get_struct_fields}
%\synopsis{returns several fields of a structure}
%\usage{(Any_Type val1, val2, ...) = get_struct_fields(Struct_Type s, String_Type fieldname1, fieldname2, ...);}
%\qualifiers{
%\qualifier{i}{indices used for filtering array fields}
%}
%\description
%    Each value corresponds to the according field of the structure.
%    If an \code{i} qualifier is given, array-typed field values
%    are filtered with these indices, i.e.,
%#v+
%       val = get_struct_feld(s, fieldname)[i];
%#v-
%    It also possible to create lists of structure field values,
%    by just passing lists (or, equivalently, arrays) as arguments.
%\examples
%#v+
%    variable table = struct { x=[1:5], y=[1:5]^2, err1=[1:5], err2=[1:5]*2 };
%
%    plot_with_err( get_struct_fields(table, "x", "y", "err1"; i=[1,0,4,2,3]) ; connect_points);
%    % equivalent to:
%    % plot_with_err( table.x[1,0,4,2,3], table.y[1,0,4,2,3], table.err1[1,0,4,2,3] ; connect_points);
%
%    plot_with_err( get_struct_fields(table, "x", "y", {"err1", "err2"}) );
%    % or (even less redundant):
%    plot_with_err( get_struct_fields(table, "x", "y", "err"+["1", "2"]) );
%    % equivalent to:
%    % plot_with_err( table.x, table.y, {table.err1, table.err2} );
%#v-
%\seealso{get_struct_field}
%!%-
{
  variable arg, args = __pop_list(_NARGS);
  variable s = list_pop(args);
  variable ind = qualifier("i");
  foreach arg (args)
  {
    variable field = NULL;
    switch(typeof(arg))
    { case List_Type:
	field = { get_struct_fields(s, __push_list(arg);; __qualifiers) };
    }
    { case Array_Type:
	field = { get_struct_fields(s, __push_array(arg);; __qualifiers) };
    }
    { case String_Type:
	field = get_struct_field(s, arg);
        if(ind!=NULL && typeof(field)==Array_Type)
	  field = field[ind];
    }
    { % else:
        vmessage("warning (%s): cannot process %S argument", _function_name(), typeof(arg));
    }
    field;  % left on stack
  }
}
