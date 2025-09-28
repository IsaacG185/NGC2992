#ifeval getenv("ATOMDB")!=NULL
define init_Apec ()
{
   plasma(aped);
   create_aped_fun("Apec",default_plasma_state);
}
#endif