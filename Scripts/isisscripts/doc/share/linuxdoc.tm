#% Linuxdoc SGML Text-Macros
#d linuxdoc <!doctype linuxdoc system>
#% ---------------------------------------------------------------------------
#% Control Variables
#% ---------------------------------------------------------------------------
#d __verbatim_begin <tscreen><verb>
#d __verbatim_end </verb></tscreen>
#d __passthru_begin 
#d __passthru_end
#d __remove_empty_lines 0
#% ---------------------------------------------------------------------------
#% Macros
#% ---------------------------------------------------------------------------
#i tmutil.tm
#d abstract#1 <abstract>$1</abstract>
#d title <title>
#d author <author>
#d date <date>
#d toc <toc>
#d preface <preface>
#d chapter#1 <chapt>$1<p>
#d sect#1 <sect>$1<p>
#d sect1#1 <sect1>$1<p>
#d sect2#1 <sect2>$1<p>
#d sect3#1 <sect3>$1<p>
#d sect4#1 <sect4>$1<p>
#d sect5#1 <sect5>$1<p>
#d appendix <appendix>
#%
#d p <p>
#d enum#1 <enum>$1</enum>
#d itemize#1 <itemize>$1</itemize>
#d descript#1 <descript>$1</descript>
#d item <item>
#%
#d tt#1 <tt>$1</tt>
#d bf#1 <bf>$1</bf>
#d em#1 <em>$1</em>
#%
#d label#1 <label id="$1">
#d ref#1:2 <ref id="$1" name="\if{\strlen{$2}}{$2}{$1}">

#% #d tag#1 <tag>$1</tag>
#d tag#1 <tag/$1/
#d url#1:2 <url url="$1" \if{\strlen{$2}}{name="$2"}{}>

#% ---------------------------------------------------------------------------
#% Misc Macros
#% ---------------------------------------------------------------------------

#s+
static define linuxdoc_list_to_ref_function (list)
{
   variable items = strtok (list, ", \t\n");
   items = array_map (String_Type, &sprintf, "\\ref{%s}{%s}", items, items);
   insert (strjoin (items, ", "));
}
tm_add_macro ("linuxdoc_list_to_ref", &linuxdoc_list_to_ref_function, 1, 1);
#s-
