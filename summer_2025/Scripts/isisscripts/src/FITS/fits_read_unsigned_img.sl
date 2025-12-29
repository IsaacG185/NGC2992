define fits_read_unsigned_img()
%!%+
%\function{fits_read_unsigned_img}
%\synopsis{reads an image of unsigned integers}
%\usage{Integer_Type img[] = fits_read_unsigned_img(String_Type filename);}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable short_image = fits_read_img(filename);
  variable image = Integer_Type[length(short_image[*,0]),length(short_image[0,*])];
  variable pos, neg = where(short_image<0, &pos);
  image[pos] = short_image[pos];
  image[neg] = short_image[neg] + 65536;
  return image;
}
