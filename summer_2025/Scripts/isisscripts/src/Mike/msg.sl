public define msg(str_array)
{
   () = printf("\n");
   foreach(str_array)
   {
      variable str = ();
      () = printf(" %s\n", str);
   }
   () = printf("\n");
   return;
}
