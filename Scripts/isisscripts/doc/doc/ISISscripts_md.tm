#d __remove_empty_lines 2
#% d __remove_comment_lines 1

#d function#1    ----\__newline__\__newline__\headingiv{$1}
#d datatype#1    ----\__newline__\__newline__\headingiv{$1}
#d synopsis#1    \SYNOPSIS{$1}
#d usage#1       \USAGE{$1}
#d altusage#1    \ALTUSAGE{$1}
#d description   \HEADINGV{Description}
#d example       \HEADINGV{Example}
#d examples      \HEADINGV{Examples}
#d notes         \HEADINGV{Notes}
#d seealso#1     \SEEALSO{$1}
#d qualifiers#1  \HEADINGV{Qualifiers}{$1}
#d qualifier#2   * $1: $2
#d done          \n
#d n             \__newline__ \__newline__
#d code#1        <code>$1</code>
#d wikilink#1    \WIKILINK{$1}

#d variable#1 \__newline__{}$1\__newline__
#d datatype#1 \__newline__{}$1\__newline__

#d headingiv#1   #### $1

#s+
tm_map_character ('_', "_");
tm_map_character ('%', "%");
tm_map_character ('#', "#");
tm_map_character ('<', "<");
tm_map_character ('>', ">");
tm_map_character ('&', "&");
tm_map_character ('^', "^");
tm_map_character ('|', "|");
tm_map_character ('*', "\\*"R);

define headingv_fun () {
    variable s1,s2;
    switch (_NARGS)
    { case 1: s1 = (); s2 = "";}
    { case 2: (s1, s2) = (); }
    insert(sprintf("##### %s\n%s", s1, s2));
}

define math_fun (s) {
    vinsert("$%s", s);
}

define synopsis_fun (s) {headingv_fun("Synopsis", sprintf(" %s\n", s));}

define usage_fun (s) {headingv_fun("Usage", sprintf("```c\n %s\n```\n\n", s));}

define altusage_fun (s) {insert(sprintf("```\nor\n\n```c\n %s", s));}

define seealso_fun (s) {insert(sprintf("\n\n__See also__: %s", s));}

define wikilink_fun (s) {
    variable cs = strchop(s, ',', 0);
    variable names=list_new,i;
    foreach i (cs) {
        variable tmp;
        if (string_match(i, "#"))
            tmp = strchop(i, '#', 0);
        else
            tmp = strchop(i, '/', 0);
        list_append(names, tmp[-1]);
    }
    names = array_map(String_Type, &strreplace, list_to_array(names), "-", " ");
    insert( strjoin( "["+names+"]"+"("+cs+")", "," ));
}

tm_add_macro("HEADINGV", &headingv_fun, 1, 2);
tm_add_macro("SYNOPSIS", &synopsis_fun, 1, 1);
tm_add_macro("USAGE", &usage_fun, 1, 1);
tm_add_macro("ALTUSAGE", &altusage_fun, 1, 1);
tm_add_macro("SEEALSO", &seealso_fun, 1, 1);
tm_add_macro("WIKILINK", &wikilink_fun, 1, 1);
tm_add_macro("math", &math_fun, 1, 1);
%#% tm_map_character ('{', "\\{"R);
%#% tm_map_character ('}', "\\}"R);
#s-

## ISISscripts function reference

----

### ISISscript functions

----

### Function description

#i isisscripts.tm

#s+
define tm_parse_buffer_before_hook () {
    bob();
    do {
        bol(); trim();
    } while (down_1);
}
#s-
