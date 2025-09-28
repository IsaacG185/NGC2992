define ext_line_type()
{
  variable nr, format=0;
  switch(_NARGS)
  { case 1:  nr = (); }
  { case 2:  (nr, format) = (); }
  { print("usage: ext_line_type(nr[, format]); format = 0->string, 1->PGPLOT, 2->TeX"); return; }

  variable ret = [NULL, NULL, NULL];
  switch(nr)
  { case  1:  ret = ["Kalpha", `K\ga`, "K$\alpha$"]; }

  { case 11:  ret = "RRC" + ["", "", ""]; }

  { case 19:  ret = "f" + ["", "", ""]; }

  { case 20:  ret = "i" + ["", "", ""]; }
  { case 30:  ret = "i" + ["", "", ""]; }
  { case 40:  ret = "i" + ["", "", ""]; }

  { case 21:  ret = ["alpha", `\ga`, `$\alpha$`]; }
  { case 31:  ret = ["alpha", `\ga`, `$\alpha$`]; }
  { case 41:  ret = ["alpha", `\ga`, `$\alpha$`]; }

  { case 22:  ret = ["beta", `\gb`, `$\beta$`]; }
  { case 32:  ret = ["beta", `\gb`, `$\beta$`]; }
  { case 42:  ret = ["beta", `\gb`, `$\beta$`]; }

  { case 23:  ret = ["gamma", `\gg`, `$\gamma$`]; }
  { case 33:  ret = ["gamma", `\gg`, `$\gamma$`]; }
  { case 43:  ret = ["gamma", `\gg`, `$\gamma$`]; }

  { case 24:  ret = ["delta", `\gd`, `$\delta$`]; }
  { case 34:  ret = ["delta", `\gd`, `$\delta$`]; }
  { case 44:  ret = ["delta", `\gd`, `$\delta$`]; }

  { case 25:  ret = ["epsilon", `\ge`, `$\epsilon$`]; }
  { case 35:  ret = ["epsilon", `\ge`, `$\epsilon$`]; }
  { case 45:  ret = ["epsilon", `\ge`, `$\epsilon$`]; }

  { case 26:  ret = ["zeta", `\gz`, `$\zeta$`]; }
  { case 36:  ret = ["zeta", `\gz`, `$\zeta$`]; }
  { case 46:  ret = ["zeta", `\gz`, `$\zeta$`]; }

  return ret[format];
}
