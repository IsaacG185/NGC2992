#%+
  These macros are used to format tm help docs into slang's internal
  doc format.  It is an alternative to the tm2txt program.
#%-
#d __comment_begin
#d __comment_end
#d __passthru_begin
#d __passthru_end
#d __verbatim_begin
#d __verbatim_end
#d __remove_empty_lines 2
#d __remove_comment_lines 1

#s+
tm_map_character ('&', "&");
tm_map_character ('<', "<");
tm_map_character ('>', ">");
define wikilink_fun (s) {insert("");}
tm_add_macro("WIKILINK", &wikilink_fun, 1, 1);
#s-

#d wikilink#1  \WIKILINK{$1}
#d _hlp_section#1 \__newline__\__space__{1}$1

#d function#1 \__newline__{}$1\__newline__
#d variable#1 \__newline__{}$1\__newline__
#d datatype#1 \__newline__{}$1\__newline__

#d math#1 $1

#d synopsis#1 \_hlp_section{SYNOPSIS}\__newline__{}\__space__{4}$1\__newline__
#d usage#1 \_hlp_section{USAGE}\__newline__\__space__{4}$1
#d altusage#1 \__space__{4}% or\__newline__\__space__{4}$1
#d description \_hlp_section{DESCRIPTION}
#d qualifiers#1 \_hlp_section{QUALIFIERS}$1
#d qualifier#2 \__space__{4}* $1: $2
#d example \_hlp_section{EXAMPLE}
#d examples \_hlp_section{EXAMPLES}
#d notes \_hlp_section{NOTES}
#d seealso#1 \_hlp_section{SEE ALSO}\__newline__\__space__{4}$1
#d done \__newline__{}--------------------------------------------------------------

#d n
#d tt#1 $1
#d code#1 $1
