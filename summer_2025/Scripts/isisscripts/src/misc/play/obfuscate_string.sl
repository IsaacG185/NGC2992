%%%%%%%%%%%%%%%%%%%%%%%
define obfuscate_string()
%%%%%%%%%%%%%%%%%%%%%%%
{
  variable s = ();

  variable c = Char_Type[0];
  foreach $1 (s)  if(not any(c==$1))  c = [c, $1];
  seed_random(_time());
  c = c[array_permute(c)];

  $1 = 2*length(c)/3;
  c = [c[[0:$1-1]], [32,101,114,114,111,144,32], c[[$1:]]];

  variable result = `("`;
  foreach $1 (c)  result += sprintf("%c", $1);
  result += `")[[`;
  variable i = String_Type[strlen(s)];
  _for $1 (0, strlen(s)-1, 1)
  { $2 = where(c==s[$1])[0];
    if($2<10)
      i[$1] = sprintf("%d", $2);
    else
      i[$1] = sprintf("0x%X", $2);
  }
  result += strjoin(i, ",") + "]]";

  message(result);
  return result;
}
