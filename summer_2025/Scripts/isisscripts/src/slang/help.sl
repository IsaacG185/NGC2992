#ifnexists help
define help(topic)
{
  variable doc = get_doc_string_from_file (topic);
  if (doc == NULL)
    vmessage ("No help found for %S\n", topic);
  else
    message (topic);
}
#endif
