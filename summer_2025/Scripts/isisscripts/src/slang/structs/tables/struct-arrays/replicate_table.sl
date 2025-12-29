define replicate_table()
%!%+
%\function{replicate_table}
%\synopsis{repeats columns of a table, possibly with a periodic shift}
%\usage{Struct_Type replicate_table(Struct_Type t);}
%\qualifiers{
%\qualifier{P}{[= 1] period}
%\qualifier{back}{[= 0] repeat periods backwards}
%\qualifier{ahead}{[= 1] repeat periods forwards}
%\qualifier{periodic}{[\code{= ["bin_lo", "bin_hi"]}] periodic structure fields}
%}
%\description
%    The return value is a structure with the same fields as \code{t}.
%    All array fields are repeated (back+1+ahead) times; periodic ones as\n
%      \code{[ val-back*P, ..., val-P, val, val+P, ..., val+P*ahead ]} ,\n
%    while other ones are just replicated:\n
%      \code{[ val       , ..., val  , val, val  , ..., val         ]} .\n
%!%-
{
  variable t;
  switch(_NARGS)
  { case 1: t = (); }
  { help(_function_name()); return; }
  
  variable P = qualifier("P", 1);
  variable back = qualifier("back", 0);
  variable ahead = qualifier("ahead", 1);
  variable periodic = qualifier("periodic", ["bin_lo", "bin_hi"]);
  
  variable T = @t;
  variable i, n=back+1+ahead;
  variable field;
  foreach field ( get_struct_field_names(t) )
  {
    variable val = get_struct_field(t, field);
    if(typeof(val)!=Array_Type)
      continue;
    variable isperiodic = any(field == periodic);
    variable len = length(val);
    variable a = @ _typeof(val)[n*len];
    _for i (-back, ahead, 1)
      a[ [(i+back)*len : (i+back+1)*len-1 ] ] = (isperiodic ? val + i*P : val);
    set_struct_field(T, field, a);
  }
  return T;
}
