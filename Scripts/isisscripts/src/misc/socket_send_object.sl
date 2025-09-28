% -*- mode: slang; mode: fold -*-
require("tcp.sl");

% LAYOUT
%
% socket_get_object                  socket_send_object
% -> receive object                   -> send object
%   no  qualifier: via _sso_client     no  qualifier: via _sso_server
%  `re' qualifier: via _sso_server    `re' qualifier: via _sso_client


%%% VARIABLES %{{{

% global variable for the object: we need this globally to
% use the object during the hook functions (e.g., _sso_send)
private variable _sso_obj = NULL;
% name of the receiver (_sso_server) or the sender (_sso_client)
% and the expected username on the host 
private variable _sso_host = "";
private variable _sso_user = NULL; % if NULL -> disable greet messages
%}}}

%%% HOOKS %{{{

% greet_hook of _sso_server:
% 1) send own username
% 2) check re-greet message with expected username
private define _server_greet() {
  variable s, c, greet;
  switch (_NARGS)
    { case 2: (s,c) = (); return getenv("USER"); } % case 1)
    { case 3: (s,c,greet) = (); % case 2)
      if (greet == _sso_user) { return 1; } % accepted
      s.shutdown(; trigger); % trigger shutdown after server's main loop
      return 0; % greet not accepted
    }
}

% greet_hook of _sso_client: check greet message against
% expected username and send own username
private define _client_greet(c, greet) {
  if (greet == _sso_user) {  return getenv("USER"); } % accepted
  return 0; % not accepted
}

% established_hook of _sso_server: send/get the object
% and shut down the server afterwards
private define _server_send(s, c) {
  c.config.chatty = 1; % enable progress bar
  ()=c.send(_sso_obj);
  ()=s.shutdown();
  % we do not need to set c.config.chatty back to 0 since this does not affect
  % the chattiness of the server itself (which is set in s.config.chatty (c->s))
}
private define _server_get(s, c) {
  c.config.chatty = 1;
  () = c.send("1"); % see footnote *1
  _sso_obj = c.receive();
  ()=s.shutdown();
}

% connect hook of _sso_client:  get/send the object
private define _client_get(c) {
  c.config.chatty = 1; % enable progress bar
  _sso_obj = c.receive();
  c.config.chatty = 0; % disable further client messages
}
private define _client_send(c) {
  c.config.chatty = 1;
  if (c.receive() == "1") { % see footnote *1
    ()=c.send(_sso_obj);
  } else { throw RunTimeError, "unexpected communication"; }
  c.config.chatty = 0;
}
%}}}

%%% MAIN ROUTINES %{{{

% establish a server and either send (default)
% or get the object (`re' qualifier)
define _sso_server() {
  ()=tcp_server(;; struct_combine(struct {
    maxclients = 1, % we do not expect more connections
    chatty = 0,
    greet_hook = &_server_greet,
    established_hook = qualifier_exists("re")
		? &_server_get  % get the object or
		: &_server_send % send the object by this hook
  }, _sso_user == NULL ? struct { nogreet } : NULL));
  % return the object
  if (qualifier_exists("re")) { return _sso_obj; }
}

% connect to the server and either get (default)
% or send the object (`re' qualifier)
define _sso_client() {
  variable client;
  % try to connect to the sender until a connection is established
  do {
    client = tcp_client(_sso_host;; struct_combine(struct {
      chatty = 0,
      greet_hook = &_client_greet,
      connect_hook = qualifier_exists("re")
		? &_client_send  % get the object or
		: &_client_get % send the object by this hook
    }, _sso_user == NULL ? struct { nogreet } : NULL));
    % client == 0 -> connection failed, e.g., server is not running
    if (typeof(client) == Integer_Type && client == 0) { sleep(1); }
  } while (typeof(client) != Struct_Type);
  % disconnect from the server
  ()=client.disconnect();
  % return the object
  ifnot (qualifier_exists("re")) { return _sso_obj; }
}

% split the given "username@host" in _sso_host into
% the username and host
define _sso_split_input() {
  variable n = is_substr(_sso_host, "@");
  if (n > 0) {
    _sso_user = substr(_sso_host, 1, n-1);
    _sso_host = substr(_sso_host, n+1, -1);
  }
}

%%%%%%%%%%%%%%%%%%%%
define socket_send_object()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{socket_send_object, socket_get_object}
%\synopsis{send or get an SLang object to or from another machine via a TCP socket}
%\usage{         socket_send_object("[username@]to_host", Any_Type object);
%    Any_Type socket_get_object("[username@]from_host");}
%\description
%    Established a connection to another machine in order to send or
%    receive an SLang object. Of course, this requires user input
%    from an active ISIS environment on the host. See the help of
%    `pack_obj' for the supported object formats.
%
%    socket_send_object:
%      A TCP server is started and as soon as a client connects the
%      object is sent. The server is shut down afterwards.
%    socket_get_object:
%      A TCP client tries to connect to the host in order to receive
%      the object. The connection is closed after the object has been
%      received.
%
%    For security reasons, it is recommended to provide the username
%    expected on the host. In this case the server and the client
%    exchange and check the corresponding username before the object
%    is transferred. If the username does not match the expected one
%    the connection is not trusted and closed automatically.
%
%    It might occur that machine A which is about to send an object
%    is behind a router/firewall or does not has a public internet IP
%    address, while the retrieving machine B does. Using the qualifier
%    `re' machine B starts a server for retrieving the object and
%    machine A a client connection for sending purposes (i.e., the
%    connection is established with server/client inverted with
%    respect to the default behavior).
%\example
%    % receive an object from user "falkner" on "indus"
%    obj = socket_get_object("falkner@indus");
%    
%    % send an array of doubles to "ara" without a greet message
%    socket_send_object("ara", Double_Type[10000]);
%
%    % send a structure `s' to an outside machine, while the own
%    % machine "laptop" is behind a router
%    socket_send_object("volans.sternwarte.uni-erlangen.de", s; re);
%    % the call on "volans" then would be
%    obj = socket_get_object("laptop"; re); % starts a server
%\seealso{tcp_server, tcp_client}
%!%-
{
  switch (_NARGS)
    { case 2: (_sso_host, _sso_obj) = (); }
    { help(_function_name); }

  _sso_split_input(); % split _sso_host into username and host
  % send object
  qualifier_exists("re") ? _sso_client(; re) : _sso_server();
}

define socket_get_object() {
  switch (_NARGS)
    { case 1: (_sso_host) = (); }
    { help(_function_name); }
  
  _sso_split_input(); % split _sso_host into username and host
  % get object
  return qualifier_exists("re") ? _sso_server(; re) : _sso_client();
}
%}}}


% *1) %{{{
%     In case the client sends the object, the connect_hook _may not_
%     send any message/object in the first place! That is the server
%     waits for the re-greet message of the client every 100 ms.
%     During this time the greet message of the server get accepted
%     by the client probably, which then would send the re-greet _and_
%     a message/object. The server would first receive the latter,
%     which of course is not the expected greet message and closes
%     the connection! Thus, whenever the client should send a message
%     first, it _has to_ wait for a "go"-message by the server!
%}}}

