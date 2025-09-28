define pushString(str, new, sep)
{
  if(@str==NULL or @str=="") { @str = new; } else { @str = @str + sep + new; }
}
