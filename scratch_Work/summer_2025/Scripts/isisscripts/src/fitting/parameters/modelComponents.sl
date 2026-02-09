%%%%%%%%%%%%%%%%%%%%%%
define modelComponents()
%%%%%%%%%%%%%%%%%%%%%%
{
  variable i, n = get_num_pars();
  variable components = String_Type[0];
  _for i (1, n, 1)
  { variable component = string_matches(get_par_info(i).name, `^\([^\.]*\)\.`, 1)[1];
    if(all(components!=component))  components = [components, component];
  }
  return components;
}
