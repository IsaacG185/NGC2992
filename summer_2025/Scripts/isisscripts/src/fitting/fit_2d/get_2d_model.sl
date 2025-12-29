%%%%%%%%%%%%%%%%%%%
define get_2d_model()
%%%%%%%%%%%%%%%%%%%
{
  variable id;
  switch(_NARGS)
  { case 0: id = 1; }
  { case 1: id = (); }
  { help(_function_name()); return; }

  variable model = get_model_counts(id);
  variable nx, ny; (nx, ny) = get_2d_data_grid(; dim);
  reshape(model.value, [ny, nx]);
  return model.value;
}
