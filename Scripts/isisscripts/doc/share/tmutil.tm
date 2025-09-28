#% Some useful macros
#d optarg#1 $1\__btrim__
#d ifarg#2 \if{\strlen{$1}}{$2}{}
#d ifnarg#2 \if{\strlen{$1}}{}{$2}
#d begin#1 <$1>
#d end#1 </$1>
