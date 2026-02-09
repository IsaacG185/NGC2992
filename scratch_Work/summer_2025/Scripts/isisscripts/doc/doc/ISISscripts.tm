\linuxdoc

#s+
define wikilink_fun (s) { insert("");}
tm_add_macro("WIKILINK", &wikilink_fun, 1, 1);
#s-

#d function#1 \sect{<bf><tt>$1</tt></bf>\label{$1}}<descrip>

#% #d synopsis#1 <tag> Synopsis </tag> $1
#% #d usage#1 <tag> Usage </tag> <tt>$1</tt>
#% #d description <tag> Description </tag>
#% #d example <tag> Example </tag>
#% #d examples <tag> Examples </tag>
#% #d notes <tag> Notes </tag>
#% #d seealso#1 <tag> See Also </tag> <tt>$1</tt>

#d synopsis#1 <tag/Synopsis/$1
#d usage#1 <tag/Usage/<tt>$1</tt>
#d description <tag/Description/
#d example <tag/Example/
#d examples <tag/Examples/
#d notes <tag/Notes/
#d seealso#1 <tag/See Also/<tt>$1</tt>

#% #d qualifiers#1 <tag> Qualifiers </tag><descrip> $1 </descrip>
#% #d qualifier#2 <tag> <tt>$1</tt></tag> $2
#d qualifiers#1 <tag> Qualifiers </tag></descrip><itemize> $1 </itemize><descrip>
#d qualifier#2 <item> <tt>$1</tt>$2 </item>

#d done <tag></tag></descrip><p>

#d n <newline>
#d altusage#1 </tt>\n or\n<tt> $1
#d code#1 <tt>$1</tt>
#d wikilink#1 \WIKILINK{$1}

#d documentstyle article
\begin{\documentstyle}

\title ISIS/S-Lang scripts
\author \tt{Manfred.Hanke@sternwarte.uni-erlangen.de}
\date Remeis observatory, Bamberg, Germany

\toc

#i isisscripts.tm

\end{\documentstyle}
