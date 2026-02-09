%%%%%%%%%%%%%%%%%%%%%%%%
define get_warmabs_model()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_warmabs_model}
%\synopsis{computes the contribution of separate elements in a warmabs-model}
%\usage{Struct_Type data = get_warmabs_model();}
%!%-
{
  variable fitFun = get_fit_fun;
  fit_fun("warmabs(1)");

  variable atoms = ["c", "n", "o", "ne", "mg", "si", "s", "ar", "ca", "fe"];
  variable data = @Struct_Type(["bin_lo", "bin_hi", "warmabs", "warmabs_" + atoms]);
  data.bin_lo = [1:20:0.002];
  data.bin_hi = make_hi_grid(data.bin_lo);
  data.warmabs = eval_fun(data.bin_lo, data.bin_hi);

  variable abund = @Struct_Type(atoms);
  variable atom;
  foreach atom (atoms)
  { set_struct_field(abund, atom, get_par("warmabs*." + atom + "abund")[0]);
  }

  foreach atom (atoms)
  { set_par("warmabs*.*abund", 0);
    set_par("warmabs*."+atom+"abund", get_struct_field(abund, atom));
    set_struct_field(data, "warmabs_"+atom, eval_fun(data.bin_lo, data.bin_hi));
  }

  foreach atom (atoms)
  { set_par("warmabs*."+atom+"abund", get_struct_field(abund, atom));
  }

  fit_fun(fitFun);
  return data;
}
