require( "png" );

define ImageMagick_text(txt)
{
  variable tmpfile = "/tmp/ImageMagick_txt_tmp.png";
  variable size = qualifier("size", 12)*4/3;
  variable cmd = "convert";
  cmd += sprintf(" -size %dx%d", 8192, 3*size);
  cmd += " xc:white";
  cmd += sprintf(" -pointsize %d", size);
  cmd += sprintf(` -draw "text %d,%d '%s'"`, size, 2*size, txt);
  cmd += " -colors 2";
  cmd += " "+tmpfile;
  ()=system(cmd);
  variable i = png_read_flipped(tmpfile) < 0xFFFF;
  remove(tmpfile);
  return i[rectangle_where(i)];
}

