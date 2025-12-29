
private variable _element_sym = ["Bare","H","He","Li","Be","B","C","N","O","F","Ne",
				  "Na","Mg","Al","Si","P","S","Cl","Ar","K","Ca","Sc",
				  "Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge",
				  "As","Se","Br","Kr", "Rb","Sr","Y","Zr","Nb","Mo","Tc",
				  "Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I","Xe",
				  "Cs","Ba","La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb",
				  "Dy","Ho","Er","Tm","Yb","Lu","Hf","Ta","W","Re","Os",
				  "Ir","Pt","Au","Hg","Tl","Pb","Bi","Po","At","Rn",
				  "Rr","Ra","Ac","Th","Pa","U","Np","Pu","Am","Cm","Bk",
				  "Cf","Es","Fm","Md","No","Lr","Rf","Db","Sg","Bh","Hs",
				  "Mt","Ds","Rg","Cn","Nh","Fl","Mc","Lv","Ts","Og"];

private variable _element_name = ["Bare","Hydrogen","Helium","Lithium","Beryllium","Boron",
				  "Carbon","Nitrogen","Oxygen","Fluorine","Neon",
				  "Sodium","Magnesium","Aluminum","Silicon","Phosphorus",
				  "Sulfur","Chlorine","Argon","Potassium","Calcium","Scandium",
				  "Titanium","Vanadium","Chromium","Manganese","Iron","Cobalt",
				  "Nickel","Copper","Zinc","Gallium","Germanium",
				  "Arsenic","Selenium","Bromine","Krypton","Rubidium","Strontium",
				  "Yttrium","Zirconium","Niobium","Molybdenum","Technetium",
				  "Ruthenium","Rhodium","Palladium","Silver","Cadmium","Indium",
				  "Tin","Antimony","Tellurium","Iodine","Xenon",
				  "Cesium","Barium","Lanthanum","Cerium","Praseodymium",
				  "Neodymium","Promethium","Samarium","Europium","Gadolinium",
				  "Terbium",
				  "Dysprosium","Holmium","Erbium","Thulium","Ytterbium",
				  "Lutetium","Hafnium","Tantalum","Tungsten","Rhenium",
				  "Osmium",
				  "Oridium","Platinum","Gold","Mercury","Thallium","Lead",
				  "Bismuth","Polonium","Astatine","Radon",
				  "Francium","Radium","Actinum","Thorium","Protactinium",
				  "Uranium","Neptunium","Plutonium","Americium","Curium",
				  "Berkelium",
				  "Californium","Einsteinium","Fermium","Mendelevium","Nobelium",
				  "Lawrencium","Rutherfordium","Dubnium","Seaborgium",
				  "Bohrium","Hassium",
				  "Meitnerium","Darmstadtium","Roentgenium","Copernicium",
				  "Nihonium","Flerovium","Moscovium","Livermorium",
				  "Tennessine","Oganesson"];

private variable _element2Z=Assoc_Type[Int_Type];

define element_name() {
%!%+
%\function{element_name}
%\synopsis{returns the name of the element with proton number Z}
%\usage{String_Type element_name(Integer_Type Z)}
%\qualifiers{
%\qualifier{lc}{return symbol or name in lower case (default: Capitalized)}
%}
%\description
% This function returns the name of the element with
% nuclear charge Z for all named elements.
%
% This function is array safe.
%\seealso{element_symbol,element2Z}
%!%-
  variable Z;
  switch(_NARGS)
  { case 1: Z = (); }
  { help(_function_name()); return; }

  if (min(Z)<0 or max(Z)>=length(_element_name)) {
      throw UsageError,sprintf("%s: Element Z outside of 0<Z<%i",_function_name(),length(_element_name));
  }

  if (qualifier_exists("lc")) {
      return strlow(_element_name[Z]);
  } 
  return _element_name[Z];
}

define element_symbol() {
%!%+
%\function{element_symbol}
%\synopsis{returns the symbol of the element with proton number Z}
%\usage{String_Type element_symbol(Integer_Type Z)}
%\qualifiers{
%\qualifier{full}{return full element name rather than symbol}
%\qualifier{lc}{return symbol or name in lower case (default: Capitalized)}
%}
%\description
% This function returns the symbol or the name of the element with
% nuclear charge Z for all named elements. 
% Z=0 returns 'Bare'.
%
% This function is array safe.
%\seealso{element_name, element2Z}
%!%-
  variable Z;
  switch(_NARGS)
  { case 1: Z = (); }
  { help(_function_name()); return; }

  if (min(Z)<0 or max(Z)>=length(_element_sym)) {
      throw UsageError,sprintf("%s: Element Z outside of 0<Z<%i",_function_name(),length(_element_sym));
  }

  if (qualifier_exists("full")) {
      if (qualifier_exists("lc")) {
	  return strlow(_element_name[Z]);
      } 
      return _element_name[Z];
  }
  
  if (qualifier_exists("lc")) {
      return strlow(_element_sym[Z]);
  } 
  
  return _element_sym[Z];
}

define element2Z() {
%!%+
%\function{element2Z}
%\synopsis{returns Z for an element symbol or name}
%\usage{z=element2Z(String_Type name)}
%\description
% This function returns the nuclear charge for the given element symbol
% symbol or element name.
%
% This function is array safe.
%\seealso{element_name, element_symbol}
%!%-
   variable names;
   switch(_NARGS)
   { case 1: names=(); }
   { help(_function_name()); return; }

   % are we initialized?
   variable i;
   if (length(_element2Z)==0) {
       _for i(0,length(_element_sym)-1,1) {
	   _element2Z[strup(_element_sym[i])]=i;
	   _element2Z[strup(_element_name[i])]=i;
       }
   }

   if (typeof(names)==String_Type) {
       return _element2Z[strup(names)];
   }

   variable ret=Integer_Type[length(names)];
   
   _for i(0,length(names)-1,1) {
       ret[i]=_element2Z[strup(names[i])];
   }
   return ret;
}
