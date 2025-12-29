#d __remove_empty_lines 2
#d __remove_comment_lines 1

#d function#1   \__newline__{}\\section*{\\texttt{$1}}\\addcontentsline{toc}{section}{$1}\\begin{description}
#d datatype#1   \__newline__{}\\section*{\\texttt{$1}}\\addcontentsline{toc}{section}{$1}\\begin{description}
#d synopsis#1   \\item[Synopsis]~\\newline $1
#d usage#1      \\item[Usage]~\\newline\\texttt{$1}
#d altusage#1   \n or\n\\texttt{$1}
#d description  \\item[Description]~\\newline
#d example      \\item[Example]~\\newline
#d examples     \\item[Examples]~\\newline
#d notes        \\item[Notes]~\\newline
#d seealso#1    \\item[See also]~\\newline\\texttt{$1}
#d qualifiers#1 \\item[Qualifiers]\\end{description}\\begin{itemize}$1\\end{itemize}\\begin{description}
#d qualifier#2  \\item \\texttt{$1}: $2
#d done         \\item[]\\end{description}\__newline__{}
#d n            \\newline
#d code#1       \\texttt{$1}

#d __verbatim_begin  \begin{verbatim}
#d __verbatim_end  \end{verbatim}

#s+
define math_function (s)
{
  vinsert("$%s$", s);
}
tm_add_macro("math", &math_function, 1, 1);
tm_map_character ('_', "_"R);
tm_map_character ('%', "\\%"R);
tm_map_character ('#', "\\#"R);
tm_map_character ('<', "$<$");
tm_map_character ('>', "$>$");
tm_map_character ('&', "\\&"R);
tm_map_character ('^', "\\^{}"R);
tm_map_character ('|', "$|$"R);
%#% tm_map_character ('{', "\\{"R);
%#% tm_map_character ('}', "\\}"R);
#s-


\\documentclass{article}

\\usepackage[a4paper,hmargin=2cm,vmargin=1cm,bottom=0.5cm,includefoot]{geometry}
\\usepackage[colorlinks=true,urlcolor=blue,linkcolor=blue]{hyperref}
\\usepackage{multicol}
\\usepackage[utf8]{inputenc}
\\usepackage{underscore}
\\begin{document}

\\setcounter{page}{1}
\\pagenumbering{roman}
\\title{\\vskip-1cm \\textsf{\\textsc{ISIS / S-Lang} scripts} \\vskip-3mm}
\\author{Contributors to the ISISscripts}
\\date{\\today}
\\maketitle
\\setlength{\\columnsep}{1cm}
\\setlength{\\columnseprule}{1pt}
\\begin{multicols}{2}
 \\tableofcontents
\\end{multicols}

\\newpage
\\setcounter{page}{1}
\\pagenumbering{arabic}

#i isisscripts.tm

\\end{document}
