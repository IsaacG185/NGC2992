define SRT_show_chunks()
%!%+
%\function{SRT_show_chunks}
%\synopsis{prints information for each chunk in an array of SRT data structures}
%\usage{SRT_show_chunks(Struct_Type data[]);}
%\seealso{SRT_read}
%!%-
{
  variable chunks = ();
  variable i;
  _for i (0, length(chunks)-1, 1)
    vmessage("chunk %2d: %4d lines after '%s'", i, length(chunks[i].Y), chunks[i].description);
}
