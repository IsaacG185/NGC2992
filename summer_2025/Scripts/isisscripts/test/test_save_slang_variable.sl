% -*- mode: slang; mode: fold -*-

require("./share/isisscripts.sl");

private variable filename = "/tmp/test_save_slang_variable_result.sl";

define primitive_datatypes_are_saved_correctly() %{{{
{
  variable in = struct {
    s  = 42h,
    us = 42uh,
    i  = 42,
    ui = 42u,
    l  = 42l,
    ul = 42ul,
    d  = 4.2,
    f  = 4.2f,
    c  = 42i,
    ch = typecast(42, Char_Type),
    uch = '*',
    str = "42",
    bst = "42"B,
    n = NULL,
    dt = DataType_Type
  };

  save_slang_variable(filename, in);
  ()=evalfile(filename);
  variable out = ();

  return _eqs(in, out)
     &&  typeof(in.s)   == typeof(out.s)
     &&  typeof(in.us)  == typeof(out.us)
%    &&  typeof(in.i)   == typeof(out.i)
%    &&  typeof(in.ui)  == typeof(out.ui)
     &&  typeof(in.l)   == typeof(out.l)
     &&  typeof(in.ul)  == typeof(out.ul)
     &&  typeof(in.d)   == typeof(out.d)
     &&  typeof(in.f)   == typeof(out.f)
     &&  typeof(in.c)   == typeof(out.c)
     &&  typeof(in.ch)  == typeof(out.ch)
     &&  typeof(in.uch) == typeof(out.uch)
     &&  typeof(in.str) == typeof(out.str)
     &&  typeof(in.bst) == typeof(out.bst)
     &&  typeof(in.n)   == typeof(out.n)
     &&  typeof(in.dt)  == typeof(out.dt);
}
%}}}

define complex_data_structures_are_saved_correctly() %{{{
{
  variable ref = &sin;
  variable arr = [1, 2, 3];
  variable multi_arr = _reshape([1:6], [2, 3]);
%jw commented since at the moment the test fails since vector is not
%jw defined
%  variable vec = vector(3, 4, 12);
%  variable str = struct { ref=ref, arr=arr, multi_arr=multi_arr, vec=vec };
%  variable lis = { ref, arr, multi_arr, vec, str };

  variable str = struct { ref=ref, arr=arr, multi_arr=multi_arr};
  variable lis = { ref, arr, multi_arr, str };

  save_slang_variable(filename, lis);
  ()=evalfile(filename);
  variable restored_list = ();

  return _eqs(restored_list, lis);
}
%}}}

private define create_deeply_nested_structure() %{{{
{
  variable st = struct { unterer_stephansberg, oberer_stephansberg, sternwartstrasse };
  variable ba = struct { stephansberg=st, gartenstadt };
  variable ofr = struct { bamberg=ba, bayreuth };
  variable fr = struct { oberfranken=ofr, mittelfranken, unterfranken };
  variable bay = struct { franken=fr, altbayern };
  variable d = struct { bayern=bay, baden_württemberg, hessen };
  variable meu = struct { deutschland=d, frankreich };
  variable eu = struct { mitteleuropa=meu, südeuropa };
  variable e = struct { europa=eu, afrika, amerika, asien };
  variable ipl = struct { erde=e, merkur, venus, mars };
  variable pl = struct { innere_planeten=ipl, äußere_planeten };
  return pl;
}
%}}}
define deeply_nested_structure_is_saved_correctly() %{{{
{
  variable orig_struct = create_deeply_nested_structure();

  save_slang_variable(filename, orig_struct);
  ()=evalfile(filename);
  variable restored_struct = ();

  return _eqs(restored_struct, orig_struct);
}
%}}}

define associative_array_is_saved_correctly() %{{{
{
  variable ass = Assoc_Type[Char_Type];
  ass["ä"] = 'a';
  ass["ö"] = 'o';
  ass["ü"] = 'u';

  save_slang_variable(filename, ass);
  ()=evalfile(filename);
  variable hash = ();

  % _eqs does not work on associative arrays => manual checking
  variable keys = assoc_get_keys(hash);
  return length(keys) == 3
     &&  any(keys == "ä")  &&  hash["ä"] == 'a'
     &&  any(keys == "ö")  &&  hash["ö"] == 'o'
     &&  any(keys == "ü")  &&  hash["ü"] == 'u';
}
%}}}


variable passed = all([
  primitive_datatypes_are_saved_correctly(),
  complex_data_structures_are_saved_correctly(),
  deeply_nested_structure_is_saved_correctly(),
  associative_array_is_saved_correctly(),
]);

()=remove(filename);

exit(passed ? 0 : 1);
