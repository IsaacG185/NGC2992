#!/usr/bin/perl

while(<>)
{ $_ =~ s|\\section|\\Section|;
  $_ =~ s|\\usepackage\{linuxdoc-sgml\}|%\\usepackage\{linuxdoc-sgml\}|; 
  $_ =~ s|\\usepackage\{qwertz\}|%\\usepackage\{qwertz\}\n\\usepackage\[a4paper,hmargin=2cm,vmargin=1cm,bottom=0.5cm,includefoot\]\{geometry\}|;
  $_ =~ s|\\tableofcontents|\\tableofcontents\n\\newpage|;
  $_ =~ s|\\begin{document}|\\newcommand{\\Section}[1]{\\section*{#1}\\addcontentsline{toc}{section}{#1}}\n\\begin{document}|;

  print; 
}
