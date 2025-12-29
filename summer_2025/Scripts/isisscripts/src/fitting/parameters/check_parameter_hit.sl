%%%%%%%%%%%%%%%%%%%%%%%%%%
define check_parameter_hit()
%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable thres = qualifier("thres", 1e-3);

  variable info;
  foreach info (get_params())
    if(   (info.value-info.min)/(info.max-info.min) < thres
       || (info.max-info.value)/(info.max-info.min) < thres )
      vmessage("%-25s: value = %-10g, min = %-10g, max = %-10g", info.name, info.value, info.min, info.max);
}
