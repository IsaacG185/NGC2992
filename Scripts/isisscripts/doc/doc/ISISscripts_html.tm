#d __remove_empty_lines 2
#% d __remove_comment_lines 1

#d function#1    \FUNCTION{$1}
#d datatype#1    \FUNCTION{$1}
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
#d done          \lt/p\gt\lt/div\gt\n
#d n             \__newline__
#d code#1        \lt{}code\gt{}\lt{}pre\gt{}$1\lt{}/pre\gt{}\lt{}/code\gt{}
#d wikilink#1    \WIKILINK{$1}

#s+
tm_map_character ('_', "_");
tm_map_character ('%', "%");
tm_map_character ('#', "#");
tm_map_character ('<', "&lt");
tm_map_character ('>', "&gt");
tm_map_character ('&', "&");
tm_map_character ('^', "^");
tm_map_character ('|', "|");
tm_map_character ('*', "\\*"R);

define headingv_fun () {
    variable s1,s2;
    switch (_NARGS)
    { case 1: s1 = (); s2 = "";}
    { case 2: (s1, s2) = (); }
    insert(sprintf("<h5>%s</h5>\n%s", s1, s2));
}

define function_fun (s) {insert(sprintf("<div class=\"isisscripts-function\" id=\"%s\" style=\"white-space: pre-wrap;\"><p>\n<h4>%s</h4>", s, s));}

define synopsis_fun (s) {headingv_fun("Synopsis", sprintf("<div class=\"isisscripts-synopsis\"> %s\n</div>\n", s));}

define usage_fun (s) {headingv_fun("Usage", sprintf("<div class=\"isisscripts-usage\"><code>\n %s\n</code>\n</div>\n", s));}

define altusage_fun (s) {insert(sprintf("<div class=\"isisscripts-usage\"><code>\nor\n %s</code></div>\n", s));}

define seealso_fun (s) {
    variable spl = strtrim(strchop(s, ',', 0));
    insert("\n<div class=\"isisscripts-seealso\"><h6>See also:</h6>\n");
    variable l;
    foreach l (spl[[:-2]])
        insert(sprintf("<a href=\"#%s\">%s</a>,", l, l));
    insert(sprintf("<a href=\"#%s\">%s</a></div>", spl[-1], spl[-1]));
}

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

% there is a better way, I guess..?
define lt_fun () { insert("<");}
define gt_fun () { insert(">");}

tm_add_macro("HEADINGV", &headingv_fun, 1, 2);
tm_add_macro("FUNCTION", &function_fun, 1, 1);
tm_add_macro("SYNOPSIS", &synopsis_fun, 1, 1);
tm_add_macro("USAGE", &usage_fun, 1, 1);
tm_add_macro("ALTUSAGE", &altusage_fun, 1, 1);
tm_add_macro("SEEALSO", &seealso_fun, 1, 1);
tm_add_macro("WIKILINK", &wikilink_fun, 1, 1);
tm_add_macro("lt", &lt_fun, 0, 0);
tm_add_macro("gt", &gt_fun, 0, 0);
%#% tm_map_character ('{', "\\{"R);
%#% tm_map_character ('}', "\\}"R);
#s-
\lt{}!DOCTYPE html\gt{}
\lt{}!-- auto-generated from isisscripts source code --\gt{}

\lt{}h2\gt{}ISISscripts function reference\lt{}/h2\gt{}


\lt{}h3\gt{}ISISscript functions\lt{}/h3\gt{}


\lt{}h3\gt{}Function description\lt{}/h3\gt{}

#i isisscripts.tm

#s+
define tm_parse_buffer_before_hook () {
    bob();
    do {
        bol(); trim();
    } while (down_1);
}
#s-
