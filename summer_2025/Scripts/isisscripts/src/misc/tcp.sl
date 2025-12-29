require("socket"); 

% global variable for the server.
% only one server allowed, i.e., NULL = no server running
private variable _TCP_SERVER = NULL;
private variable _TCP_DEFAULT_PORT = 1149;
private variable _TCP_BUF_SIZE = 252; % maximum string length of SLang
private variable _TCP_CODE = struct {
  disconnect = "D", greet = "G", object = "O"
};

private define ccode(code) { return sprintf("%c%s", 2, code); }
private define dcode(code) {
  if (strlen(code) == 2 && code[0] == 2) { return char(code[1]); } else { return NULL; }
}

% print error message
private define _print_err(err) {
  vmessage("%s\n%s:%s:%d %s", err.message, err.file, err.function, err.line, err.descr);
  if (err.traceback != "") { message(err.traceback); }
}

private define _tcp_send_msg();
private define _tcp_receive_msg();

% send a message to the server or a client
private define _tcp_send_msg(sc, buf) {
  if (sc.connected || qualifier_exists("greet")) {
    variable len, err;
    if (bstrlen(buf) > _TCP_BUF_SIZE) {
      vmessage("error(%s): message exceeds buffer size of %d", _TCP_BUF_SIZE);
      return;
    }
    try (err) {
      % send the message
      len = write(sc.config.socket, buf);%fputs(buf, sc.config.fw);
%      ()=fflush(sc.config.fw);
      % wait for a receipt
      if (qualifier_exists("receipt")) {
	if (_tcp_receive_msg(sc) != "1") {
          throw (RunTimeError, "receipt failed");
	}
      }
    }
    catch AnyError: {
      _print_err(err);
      vmessage("error(%s): could not send the message!", _function_name);
      return -1;
    }
    return len;
  }
  throw (RunTimeError, "not accepted");
}

% send an object to the server or a client
private define _tcp_send_obj(sc, obj) {
  if (sc.connected) {
    sc.config.busyobj = 1;
    % convert the object into a string
    variable str = pack_obj(obj), len = 0;
    % send object code
    if (sc.config.chatty) { ()=system("echo -n 'sending object '"); }
    len += _tcp_send_msg(sc, ccode(_TCP_CODE.object); receipt);
    % send array length
    len += _tcp_send_msg(sc, pack_obj(length(str))[0]; receipt);
    % send the strings
    variable i;
    _for i (0, length(str)-1, 1) {
      len += _tcp_send_msg(sc, str[i]; receipt);
      if (sc.config.chatty && i mod 1000 == 0) {
	()=system(sprintf("echo -n '%3.0f%%\b\b\b\b'", 100.*i/length(str)));
      }
    }
    if (sc.config.chatty) { message("100%"); }
    sc.config.busyobj = 0;
    return len;
  }
  throw (RunTimeError, "not accepted");
}

% either send a message or an object
private define _tcp_send(sc, obj) {
  if (typeof(obj) == BString_Type || typeof(obj) == String_Type) {
    return _tcp_send_msg(sc, obj;; __qualifiers);
  }
  return _tcp_send_obj(sc, obj);
}

% receive a message from a client or the server
private define _tcp_receive_msg(sc) {
  if (sc.config.busy) { throw (RunTimeError, "busy"); }
  % skip if a connection is in progress
  if (sc.connected || qualifier_exists("greet")) {
    sc.config.busy = 1;
    % check the ability to read from the socket
    variable stat;
    (,stat) = select(0, sc.config.socket, NULL, NULL, 0);
    variable buf = NULL;
    % read the message
    if (length(stat.iread) > 0 || not qualifier_exists("dontwait")) {
      ()=read(sc.config.socket, &buf, _TCP_BUF_SIZE);
    }
    % send a receipt
    if (qualifier_exists("receipt")) {
      ()=_tcp_send_msg(sc, "1");
    }
    % return
    sc.config.busy = 0;
    return buf;
  }
  throw (RunTimeError, "not accepted");
}

% receive an object from the server or a client
private define _tcp_receive_obj(sc) {
  if (sc.connected) {
    sc.config.busyobj = 1;
    if (sc.config.chatty) { ()=system("echo -n 'receiving object '"); }
    variable str = BString_Type[unpack_obj(_tcp_receive_msg(sc; receipt))];
    % loop until the object code has been sent
    variable i;
    _for i (0, length(str)-1, 1) {
      str[i] = _tcp_receive_msg(sc; receipt);
      if (sc.config.chatty && i mod 1000 == 0) {
	()=system(sprintf("echo -n '%3.0f%%\b\b\b\b'", 100.*i/length(str)));
      }
    }
    if (sc.config.chatty) { message("100%"); }
    % convert the string into an object
    sc.config.busyobj = 0;
    return unpack_obj(str);
  }
  throw (RunTimeError, "not accepted");
}

% either receive a message or an object
private define _tcp_receive(sc) {
  variable msg = _tcp_receive_msg(sc;; __qualifiers);
  if (msg == NULL) { return NULL; }
  if (qualifier_exists("ignorecode")) { return msg; }
  % react on control codes
  switch (dcode(msg))
    { case _TCP_CODE.disconnect:
      if (sc.config.chatty) {
        vmessage("connection closed by server");
      }
      ()=close(sc.config.socket);
      sc.connected = 0;
      if (struct_field_exists(sc.hook, "closed") && sc.hook.closed != NULL) {
	(@sc.hook.closed)(sc);
      }
      return NULL;
    }
    { case _TCP_CODE.object:
      ifnot (qualifier_exists("receipt")) { ()=_tcp_send_msg(sc, "1"); }
      return _tcp_receive_obj(sc);
    }
    { return msg; }
}


% kick a client or disconnect from the server
private define _tcp_disconnect(sc) {
  % send disconnect code
  ()=_tcp_send_msg(sc, ccode(_TCP_CODE.disconnect);; __qualifiers);
  % close socket
  variable err;
  try (err) {
    ()=close(sc.config.socket);
    % mark as disconnected
    sc.connected = 0;
  }
  catch AnyError: {
    _print_err(err);
    vmessage("error(%s): could not close socket!", _function_name);
    return 0;
  }
  return 1;
}

% shutdown the server
private define _tcp_server_shutdown(s) {
  % triggered shutdown
  if (qualifier_exists("trigger")) { _TCP_SERVER.running = -1; return 1; }
  % normal shutdown
  variable err;
  try (err) {
    % close all client connections
    variable client;
    foreach client (s.client) { if (client.connected == 1) { ()=client.kick(); } }
    % close main socket
    ()=close(s.config.socket);
  }
  catch AnyError: {
    _print_err(err);
    vmessage("error(%s): could not shutdown server!", _function_name);
    return 0;
  }
  _TCP_SERVER.running = 0; % also modifies the user's variable
  if (_TCP_SERVER.config.chatty) {
    vmessage("shutdown of server on port %d", _TCP_SERVER.config.port);
  }
  ifnot (struct_field_exists(_TCP_SERVER, "active")) { alarm(0); _TCP_SERVER = NULL; }
  return 1;
}

% remove not connected clients from the list
private define _tcp_server_cleanclients(s) {
  s.client = s.client[where(array_struct_field(s.client, "connected") == 1)];
}

% server handler: accept connections and receive messages
% from the clients. is called as a result from the alarm signal
% in case no handler is provided
private define _tcp_server_handle(dummy) {
  % check on running sever
  if (_TCP_SERVER == NULL) {
    vmessage("error (%s): server is not running, cancelling handler!", _function_name);
    ifnot (struct_field_exists(_TCP_SERVER, "active")) { alarm(0); }
    return;
  }

  variable client;
  
  % check on pending connections
  variable stat; % check the ability to read from the main socket
  (,stat) = select(0, _TCP_SERVER.config.socket, NULL, NULL, 0);
  if (length(stat.iread) > 0) {
    % prepare client structure
    client = struct {
      send = &_tcp_send,
      receive = &_tcp_receive,
      kick = &_tcp_disconnect,
      connected = 0,
      number = length(_TCP_SERVER.client) == 0 ? 0
             : max(array_struct_field(_TCP_SERVER.client, "number")) + 1,
      config = struct {
        socket, ip, port, chatty = _TCP_SERVER.config.chatty,
        busy = 0, busyobj = 0
      },
      unhmsg = BString_Type[0],
      unhobj = list_new()
    };
    % hook 
    if (_TCP_SERVER.hook.connect != NULL
      && (@_TCP_SERVER.hook.connect)(_TCP_SERVER, client) == 0) {
        ()=close(accept(_TCP_SERVER.config.socket));
        if (_TCP_SERVER.config.chatty) {
          vmessage("client #%d from %s on port %d refused by hook", client.number,
		   client.config.ip, client.config.port);
        }
    }
    % restrict number of clients
    else if (client.number >= _TCP_SERVER.config.maxclients) {
      ()=close(accept(_TCP_SERVER.config.socket));
      if (_TCP_SERVER.config.chatty) {
        vmessage("client #%d from %s on port %d exceeded maximum number of connections",
          client.number, client.config.ip, client.config.port);
      }
    }
    % accept
    else {
      client.config.socket = accept(
        _TCP_SERVER.config.socket, &(client.config.ip), &(client.config.port)
      );
      if (_TCP_SERVER.config.chatty) {
        vmessage("client #%d connected from %s on port %d", client.number,
	         client.config.ip, client.config.port);
      }
      % send greet
      if (_TCP_SERVER.config.nogreet == 0) {
	()=_tcp_send_msg(client, _TCP_SERVER.hook.greet != NULL
          ? (@_TCP_SERVER.hook.greet)(_TCP_SERVER, client) : ccode(_TCP_CODE.greet)
        ; greet);
      } else { % skip greet
        client.connected = 1;
	% call "main" function after a client's connection is established
	if (_TCP_SERVER.hook.established != NULL) {
	  (@_TCP_SERVER.hook.established)(_TCP_SERVER, client);
	}
      }
      % add to list of clients
      _TCP_SERVER.client = [_TCP_SERVER.client, client];
    }
  }

  % check for pending messages
  foreach client (_TCP_SERVER.client) {
    variable msg;
    % client is not trustworthy
    if (client.connected == -1) { continue; }
    % greet
    if (client.connected == 0) {
      msg = _tcp_receive_msg(client; dontwait, greet);
      if (typeof(msg) == BString_Type) {
  	% greet accepted
  	if (dcode(msg) == "G" || (_TCP_SERVER.hook.greet != NULL
	      && (@_TCP_SERVER.hook.greet)(_TCP_SERVER, client, msg))) {
          client.connected = 1;
          if (_TCP_SERVER.config.chatty) {
            vmessage("client #%d's greet accepted", client.number);
          }
	  % call "main" function after a client's connection is established
	  if (_TCP_SERVER.hook.established != NULL) {
	    (@_TCP_SERVER.hook.established)(_TCP_SERVER, client);
	  }
        }
        % client's greet not as expected -> not trustworthy!
  	else {
          ()=client.kick(; greet);
          client.connected = -1;
          if (_TCP_SERVER.config.chatty) {
            vmessage("client #%d's greet refused", client.number);
	  }
	}
      }
      continue;
    }
    % proceed normally
    if (client.config.busy || client.config.busyobj) { continue; }
    msg = _tcp_receive_msg(client; dontwait, ignorecode);
    if (typeof(msg) == BString_Type) {
      switch (dcode(msg))
  	% client disconnected
        { case _TCP_CODE.disconnect:
          client.connected = 0;
          ()=close(client.config.socket);
  	  % hook
	  if (_TCP_SERVER.config.chatty) {
            vmessage("client #%d disconnected", client.number);
	  }
	  if (_TCP_SERVER.hook.disconnect != NULL) {
	    (@_TCP_SERVER.hook.disconnect)(_TCP_SERVER, client);
	  }
  	}
        % object received
        { case _TCP_CODE.object:
	  ()=_tcp_send_msg(client, "1");
	  variable obj = _tcp_receive_obj(client);
          % call client handler
          if (_TCP_SERVER.hook.obj_handler != NULL) {
            (@_TCP_SERVER.hook.obj_handler)(_TCP_SERVER, client, obj);
          }
          % append to received objects
	  else {
	    list_append(client.unhobj, obj);
	  }
	}
        % call client handler or
  	% append to unhandled messages
        {
	  if (_TCP_SERVER.hook.msg_handler != NULL) {
            (@_TCP_SERVER.hook.msg_handler)(_TCP_SERVER, client, msg);
	  } else {
            client.unhmsg = [client.unhmsg, msg];
	  }
        }
    }
    if (_TCP_SERVER.running == 0) { return; }
  }
  
  % re-schedule alarm
  ifnot (struct_field_exists(_TCP_SERVER, "active")) { alarm(1); }
}

%%%%%%%%%%%%%%%%%%%%
define tcp_server()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{tcp_server}
%\synopsis{implements a basic TCP server}
%\usage{Integer_Type tcp_server();
% or  Struct_Type tcp_server(; background);}
%\qualifiers{
%    \qualifier{port}{bind port (default: 1149)}
%    \qualifier{maxclients}{maximum allowed number of clients connected
%      simultaneously (default: 10)}
%    \qualifier{nogreet}{disable greet messages (see below)}
%    \qualifier{background}{run server in the background (see below)}
%    \qualifier{ip}{bind address (default: "0.0.0.0", i.e., accept
%      connections from outside; only change if you know what
%      you are doing)}
%    \qualifier{chatty}{chattiness (default: 1)}
%    \qualifier{COMMENT:}{Further qualifiers are listed at HOOKS below.}
%}
%\description
%    Uses the `socket' module to implement a basic TCP server. It
%    listens for clients trying to connect and accepts a connection
%    after a greet message has been exchanged successfully. The
%    greet message can be disabled using the `nogreet' qualifier,
%    which in this case needs to be set for a `tcp_client' as well.
%    Furthermore, any message or object received from a client is
%    read automatically. After any of these actions taken by the
%    server, a user-defined function may be called in order to handle
%    these events further (see the HOOK section below).
%
%    The `background' qualifier allows the server to be started in
%    background mode, such that commands can still be entered into
%    the ISIS prompt. This background mode is realized by calling
%    the main server function, which handles client events, each
%    second scheduling an `alarm` signal (SIGALRM).
%    NOTE: the alarm signals are triggered in the main program loop
%          of ISIS, i.e., while it's "working". That means the
%          main server function is not executed while ISIS awaits
%          input from the prompt (ISIS "sleeps" here). Thus, you
%          might want to do at least something, e.g, press enter.
%    WARNING: further alarms should not be scheduled using `alarm'
%             or `signal'. Otherwise, the server might crash.
%
%    If not in background mode, `tcp_server' returns either 1 after 
%    the server has been shut down successfully or 0 otherwise. Else
%    the structure of the following form is returned. Note that this
%    structure is also passed to each hook (see below):
%    
%      Struct_Type[] client - list of clients
%      Integer_Type &shutdown()
%        Function to shut down the server. After all clients are
%        requested to disconnect, all sockets are closed. Returns
%        whether the shut down was successful (1) or not (0).
%        Qualifiers:
%          trigger - shut down the server at the end of the main
%            loop, which does not interrupt ongoing communication
%      Void_Type &cleanclients()
%        Function to remove clients no longer connected from the list.
%      Integer_Type running - boolean value indicating the server's
%        state (1: running; 0: shut down)
%      Struct_Type config - internal configuration
%      Struct_Type hook - defined hooks
%
%    Each `client' structure has the following fields:
%    
%      Integer_Type &send(String_Type msg or Any_Type obj)
%        Function for sending a string message or an SLang object
%        to a client (see `pack_obj' for list of supported types).
%        Returns the number of bytes sent.
%        Warning: Currently, sending objects is slow (~40 kB/s,
%                 i.e., ~20 s for 100,000 doubles).
%        Qualifiers:
%          receipt - wait for a confirmation by the client for the
%            receipt (the client's `receive' function needs the
%            same qualifier to be set).
%      BString_Type or Any_Type &receive()
%        Wait for and receive a message from the client. Returns
%        either the message itself (BString_Type) or in case of a
%        received object the object itself.
%        Qualifiers:
%          dontwait - do not wait for a message and return NULL in
%            case no message or object is pending.
%          receipt  - send a receipt to the client after having
%            received a message or an object
%      Integer_Type &kick()
%        Kick the client, i.e., close the communication socket.
%        Returns 1 in success or 0 otherwise.
%      Integer_Type connected - boolean value indicating whether
%        the client is still connected (1) or not (0)
%      Integer_Type number - the client's number, which is a serial
%        increasing identifier starting with zero
%      Struct_Type config - internal configuration
%      BString_Type[] unhmsg - in case the `msg_handler'-hook is not
%        set, messages of the client, which have been received
%        without a call to `receive` during the server's main loop
%        are appended here
%      List_Type unhobj - in case the `obj_handler'-hook is not set,
%        objects without a call to `receive' are appended here
%
% HOOKS
%    The following functions are called via qualifiers of the same
%    name, which need to be set to references (Ref_Type) to user-
%    defined functions (see below for an example). The passed
%    `server' and `client' are the server's and corresponding
%    client's structures as defined above.
%    
%    Integer_Type &connect_hook(server, client)
%      Called after a client tries to connect to the server. Should
%      return 1 or 0 for accepting or rejecting the connection,
%      respectively.
%    String_Type  &greet_hook(server, client)
% or Integer_Type &greet_hook(server, client, greetmsg)
%      Called after accepting a client's connection, which should
%      return the greet message to be sent to the client. Is called
%      again after the re-greet message has been received from the
%      client, which should return 1 or 0 for accepting or rejecting
%      the greet, i.e, the connection, respectively. The hook is not
%      called if the server was set up with the `nogreet' qualifier.
%    Void_Type &established_hook(server, client)
%      After a connection has been accepted including the greet, this
%      function allows to start the communication between the client
%      and the server by, e.g., sending messages to the client in
%      combination with the `msg_handler' hook.
%    Void_Type &disconnect_hook(server, client)
%      Called after a client disconnected from the server by itself,
%      i.e., the client has not been kicked.
%    Void_Type &msg_handler(server, client, msg)
%      Called after a message (BString_Type) has been received from
%      the client. If this hook is not set, then the message is
%      appended to the `unhmsg` field of the client's structure.
%    Void_Type &obj_handler(server, client, obj)
%      Called after an object has been received from the client. If
%      this hook is not set, then the object is appended to the
%      `unhobj` field of the client's structure.
%\example
%    % after a client's connection has been accepted,
%    % send a data structure and disconnect client
%    define do_client(s,c) {
%      vmessage("sending data to client #%d", c.number);
%      ()=c.send("welcome client! sending data...");
%      ()=c.send(struct { data = [1:5]*10, err = [1:5] });
%      ()=c.kick();
%      % remove kicked client from the list
%      s.cleanclients();
%    }
%    % start the server
%    variable stat = tcp_server(; established_hook = &do_client);
%    % check its exit status
%    if (stat == 0) { message("server exited unexpectedly"); }
%
%    % a more sophisticated example can be found on the Remeis wiki
%    % www.sternwarte.uni-erlangen.de/wiki/doku.php?id=isis:socket
%\seealso{tcp_client, socket, alarm, pack_obj}
%!%-
{
  % check on already running server
  if (_TCP_SERVER != NULL) {
    vmessage("error: server already running on port %d!", _TCP_SERVER.config.port);
    return 0;
  }

  % prepare server structure
  variable server = struct {
    client = Struct_Type[0],
    shutdown = &_tcp_server_shutdown,
    cleanclients = &_tcp_server_cleanclients,
    running = 0,
    config = struct {
      socket, ip = qualifier("ip", "0.0.0.0"),
      port = qualifier("port", _TCP_DEFAULT_PORT),
      maxclients = qualifier("maxclients", 10),
      nogreet = qualifier_exists("nogreet"),
      chatty = qualifier("chatty", 1)
    },
    hook = struct {
      connect = qualifier("connect_hook", NULL),
      greet = qualifier("greet_hook", NULL),
      established = qualifier("established_hook", NULL),
      disconnect = qualifier("disconnect_hook", NULL),
      msg_handler = qualifier("msg_handler", NULL),
      obj_handler = qualifier("obj_handler", NULL)
    }
  };
  % create and bind a socket
  variable err;
  try (err) {
    server.config.socket = socket(PF_INET, SOCK_STREAM, 0);
    bind(server.config.socket, server.config.ip, server.config.port);
  }
  catch AnyError: {
    _print_err(err);
    vmessage("error: could not launch server!");
    return 0;
  }

  % start listening
  listen(server.config.socket, server.config.maxclients);
  server.running = 1;
  if (server.config.chatty) {
    vmessage("server starts listening on port %d", server.config.port);
  }
    
  % put handler into the background
  _TCP_SERVER = server;
  if (qualifier_exists("background")) {
    signal(SIGALRM, &_tcp_server_handle);
    alarm(1);
    return server;
  }

  % main loop: call handler
  _TCP_SERVER = struct_combine(server, struct { active });
  variable stime = qualifier("sleep", .1);
  try (err) {
    while (_TCP_SERVER.running == 1) {
      _tcp_server_handle(NULL);
      sleep(stime); % avoid 100% CPU
    }
    % shutdown has been triggered
    if (_TCP_SERVER.running == -1) { ()=_TCP_SERVER.shutdown(); }
  }
  catch UserBreakError: {
    return _TCP_SERVER.shutdown();
  }
  catch AnyError: {
    _print_err(err);
    return 0;
  }
  _TCP_SERVER = NULL;
  return 1; % exit successfully
}

%%%%%%%%%%%%%%%%%%%%
define tcp_client()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{tcp_client}
%\synopsis{connects to a TCP server}
%\usage{Struct_Type  tcp_client(String_Type host[, Integer_Type port]);
%\altusage{Integer_Type tcp_client(String_Type host[, Integer_Type port];
%                   msg_handler = Ref_Type, obj_handler = Ref_Type);}}
%\qualifiers{
%    \qualifier{nogreet}{disable greet messages (see below)}
%    \qualifier{chatty}{chattiness (default: 1)}
%    \qualifier{COMMENT:}{Further qualifiers are listed at HOOKS below.}
%}
%\description
%    Uses the `socket' module to connect to a TCP server. After a
%    connection attempt, a greet message is exchanged with the server
%    by default unless the `nogreet' qualifier is set. In the latter
%    case the `tcp_server' has be set up with the same qualifier.
%    After the connection has been established, a structure with
%    functions for communicating with the server is returned.
%    Alternatively, if the `msg_handler` and `obj_handler` hooks are
%    set (see the HOOK section below) the client remains in a main
%    loop until the connection to the server has been closed. In this
%    case, the function returns 0 if any error occured during the
%    lifetime of the connection or 1 otherwise. The client structure,
%    which is passed to all hooks and returned if these hooks are no
%    set, has the following fields:
%    
%      Integer_Type &send(String_Type msg or Any_Type obj)
%        Function for sending a string message or an SLang object
%        to the server (see `pack_obj' for list of supported types).
%        Returns the number of bytes sent.
%        Warning: Currently, sending objects is slow (~40 kB/s,
%                 i.e., ~20 s for 100,000 doubles).
%        Qualifiers:
%          receipt - wait for a confirmation by the client for the
%            receipt (the server's `receive' function needs the
%            same qualifier to be set).
%      BString_Type or Any_Type &receive()
%        Wait for and receive a message from the server. Returns
%        either the message itself (BString_Type) or in case of a
%        received object the object itself.
%        Qualifiers:
%          dontwait - do not wait for a message and return NULL in
%            case no message or object is pending.
%          receipt  - send a receipt to the client after having
%            received a message or an object
%      Integer_Type &disconnect()
%        Disconnect from the server, i.e., close the communication
%        socket. Returns 1 in success or 0 otherwise.
%      Integer_Type connected - boolean value indicating whether
%        the connection is still established (1) or not (0)
%      Struct_Type config - internal configuration
%      Struct_Type hook - defined hooks
%
% HOOKS
%    The following functions are called via qualifiers of the same
%    name, which need to be set to references (Ref_Type) to user-
%    defined functions (see below for an example). The passed
%    `client' is the client's structure as defined above.
%    
%    String_Type or Integer_Type &greet_hook(client, greetmsg)
%      Called after having received the greet message from the server
%      (if not disabled by the `nogreet' qualifier). Should return
%      the greet message to be sent back to the server. Return 0 in
%      case the greet message from the server should be rejected,
%      which will cancel the connection.
%    Void_Type &connect_hook(client)
%      Called after a connection to the server is established. Can
%      be used to start the communication with the server in
%      combination with the `msg_handler' hook.
%    Void_Type &closed_hook(client)
%      Called after the connection has been closed from the server's
%      side.
%    Void_Type &msg_handler(client, msg)
%      Called after a message (BString_Type) has been received from
%      the server.
%    Void_Type &obj_handler(client, obj)
%      Called after an object has been received from the server.
%\example
%    % simple functions for receiving messages and objects
%    define getmsg(c, msg) { vmessage("message from server: %s", msg); };
%    define getobj(c, obj) { message("received an object:"); print(obj); };
%    % start the client
%    variable stat = tcp_client("localhost"; msg_handler = &getmsg, obj_handler = &getobj);
%    % check its exit status
%    if (stat == 0) { message("lost connection to server"); }
%
%    % a more sophisticated example can be found on the Remeis wiki
%    % www.sternwarte.uni-erlangen.de/wiki/doku.php?id=isis:socket
%\seealso{tcp_server, socket, unpack_obj}
%!%-
{
  variable host, port = _TCP_DEFAULT_PORT;
  switch (_NARGS)
    { case 1: host = (); }
    { case 2: (host, port) = (); }
    { help(_function_name); return; }

  % prepare client structure
  variable client = struct {
    send = &_tcp_send,
    receive = &_tcp_receive,
    disconnect = &_tcp_disconnect,
    connected = 0,
    config = struct{
      host = host, port = port, socket, busy = 0, busyobj = 0,
      nogreet = qualifier_exists("nogreet"),
      chatty = qualifier("chatty", 1)
    },
    hook = struct {
      greet = qualifier("greet_hook", NULL),
      connect = qualifier("connect_hook", NULL),
      closed = qualifier("closed_hook", NULL),
      msg_handler = qualifier("msg_handler", NULL),
      obj_handler = qualifier("obj_handler", NULL)
    }
  };

  % connect
  variable err;
  try (err) {
    client.config.socket = socket(PF_INET, SOCK_STREAM, 0);
    connect(client.config.socket, host, port);
  }
  catch SocketError: {
    if (client.config.chatty) {
      vmessage("error: connection to %s on port %d failed!", host, port);
    }
    return 0;
  }

  % exchange greet message
  if (client.config.nogreet == 0) {
    variable msg = _tcp_receive_msg(client; greet);
    variable tosend = client.hook.greet != NULL
      ? (@client.hook.greet)(client, msg) : ccode(_TCP_CODE.greet);
    if (client.hook.greet == NULL ? dcode(msg) != "G"
	: (typeof(tosend) == Integer_Type && tosend == 0)) {
      if (client.config.chatty) {
        vmessage("error: greet from %s refused", host);
      }
      return 0;
    }
    ()=_tcp_send_msg(client, tosend; greet);
  }

  % established
  client.connected = 1;
  if (client.config.chatty) {
    vmessage("connection to %s on port %d established", host, port);
  }
  if (client.hook.connect != NULL) { (@client.hook.connect)(client); }

  if (client.hook.msg_handler == NULL || client.hook.obj_handler == NULL) { return client; }

  % main loop: call handler
  while (client.connected) {
    try (err) {
      variable obj = client.receive();
      if (client.connected == 0) { return 0; }
      if (typeof(obj) == BString_Type) { (@client.hook.msg_handler)(client, obj); }
      else { (@client.hook.obj_handler)(client, obj); }
    }
    catch AnyError: {
      _print_err(err);
      return 0;
    }
  }
  return 1;
}

%%%%%%%%%%%%%%%%%%%%
define tcp_get_server_handle()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{tcp_get_server_handle}
%\synopsis{get a handle to a running TCP server}
%\usage{Struct_Type tcp_get_server_handle();}
%\qualifiers{
%    \qualifier{kill}{shut down / kill the server}
%}
%\description
%    In case the handle, i.e., the structure of a running
%    `tcp_server' got lost by accident, this function
%    returns this structure again. Alternatively, the
%    `kill' qualifier tries to shut down the server. If
%    this fails all communication sockets are closed,
%    which basically means to kill the server.
%\seealso{tcp_server}
%!%-
{
  % check on a running server
  if (_TCP_SERVER == NULL) {
    vmessage("warning(%s): no running TCP server found!", _function_name);
    return NULL;
  }
  % shut down the server
  if (qualifier_exists("kill")) {
    vmessage("%s: sending a shut down request to the server", _function_name);
    if (_TCP_SERVER.shutdown() == 0) {
      vmessage("%s: shut down failed, closing all sockets", _function_name);
      variable i, err;
      _for i (0, length(_TCP_SERVER.clients)-1, 1) {
        try (err) {
          ()=close(_TCP_SERVER.clients[i].config.socket);
	}
        catch AnyError: {
          _print_err(err);
        }
      }
      try (err) {
        ()=close(_TCP_SERVER.config.socket);
      }
      catch AnyError: {
        _print_err(err);
      }
      vmessage("%s: all sockets closed, i.e., server killed", _function_name);
      _TCP_SERVER = NULL;
    } else { _TCP_SERVER = NULL; }
  }
  % return the structure
  return _TCP_SERVER;
}

