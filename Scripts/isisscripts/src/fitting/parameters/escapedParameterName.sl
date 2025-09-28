define escapedParameterName(par)
{
  return strreplace(
          strreplace(
           strreplace(
            strreplace(
             strreplace(
              par, "(", ""
             ), ")", ""
            ), ".", "_"
           ), "/", "_"
	  ), ">", "_"
         );
}
