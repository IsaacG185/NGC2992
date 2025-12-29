private variable _ansi_escape_codes = Assoc_Type[String_Type];
_ansi_escape_codes["reset"] = "0m";
% normal colors
_ansi_escape_codes["black"] = "30m";
_ansi_escape_codes["red"] = "31m";
_ansi_escape_codes["green"] = "32m";
_ansi_escape_codes["yellow"] = "33m";
_ansi_escape_codes["blue"] = "34m";
_ansi_escape_codes["magenta"] = "35m";
_ansi_escape_codes["cyan"] = "36m";
_ansi_escape_codes["white"] = "37m";
% bright colors
_ansi_escape_codes["bblack"] = "90m";
_ansi_escape_codes["bred"] = "91m";
_ansi_escape_codes["bgreen"] = "92m";
_ansi_escape_codes["byellow"] = "93m";
_ansi_escape_codes["bblue"] = "94m";
_ansi_escape_codes["bmagenta"] = "95m";
_ansi_escape_codes["bcyan"] = "96m";
_ansi_escape_codes["bwhite"] = "97m";
% text formats
_ansi_escape_codes["bold"] = "1m";
_ansi_escape_codes["italic"] = "3m";
_ansi_escape_codes["underline"] = "4m";
_ansi_escape_codes["blink"] = "5m";
% cursor movement
_ansi_escape_codes["up"] = "A";
_ansi_escape_codes["down"] = "B";
_ansi_escape_codes["forward"] = "C";
_ansi_escape_codes["back"] = "D";

%%%%%%%%%%%%%%%
define ansi_escape_code()
%%%%%%%%%%%%%%%
%!%+
%\function{ansi_escape_code}
%\synopsis{transforms a text format, e.g., a color into its corresponding ANSI code}
%\usage{String_Type ansi_escape_code(String_Type format[, String_Type text]);}
%\qualifiers{
%  \qualifier{list}{print a list of available keywords}
%}
%\description
%  Transforms the given (human readable) format string into
%  a sequence of ANSI escape codes. The format string consists
%  of keywords, e.g., colors separated by semicolons. A list
%  of supported keywords is printed setting the 'list'
%  qualifiers.
%
%  The cursor movement keywords 'up', 'down', 'forwards', and
%  'back' allow an optional preceding number, which specifies
%  the amount of the movement.
%
%  In order to reset a previous format you may use the 'reset'
%  keyword. In case an optional text is provided, this text
%  and the reset ANSI code is appended to the returned string
%  automatically.
%\example
%  ansi_escape_code("red;blink", "ALERT");
%  ansi_escape_code("3up"); % move three lines up
%  ansi_escape_code("blue"); % blue color *from now on*
%  ansi_escape_code("reset"); % turn off the format again
%!%-
{
  % list of keywords
  if (qualifier_exists("list")) {
    variable list = assoc_get_keys(_ansi_escape_codes);
    list = list[array_sort(list, &strcmp)];
    array_map(Void_Type, &message, list);
    return;
  }

  variable format, text = NULL;
  switch (_NARGS)
    { case 1: format = (); }
    { case 2: (format,text) = (); }
    { help(_function_name); return; }

  variable key, out = "", num, pos;

  % split the input format
  foreach key (strchop(format, ';', 0)) {
    % amount of cursor movement
    pos = array_map(Integer_Type, &is_substr, key, ["up", "down", "forward", "back"]);
    pos = pos[where(pos > 0)];
    if (length(pos) == 1) {
      num = atoi(substr(key, 1, pos[0]-1));
      key = substr(key, pos[0], -1);
    } else {
      num = 0;
    }
    % replace keyword
    if (assoc_key_exists(_ansi_escape_codes, key)) {
      out += sprintf("\033[%s%s", num > 0 ? sprintf("%d", num) : "", _ansi_escape_codes[key]);
    } else {
      vmessage("error (%s): unknown keyword '%s'", _function_name, key);
      return;
    }
  }

  % return
  if (text == NULL) { return out; }
  else { return sprintf("%s%s\033[0m", out, text); }
}
