#ifeval __get_reference("TimeoutError") == NULL
new_exception ("TimeoutError", RunTimeError, "Operation has timed out");
#endif

private define __alarm_signal_handler(sig) {
  throw TimeoutError;
}

%!%+
%\function{try_or_timeout}
%\usage{try_or_timeout(UInteger_Type seconds, Ref_Type function, ...);}
%\description
%    Runs the function referenced by \code{function} for at most
%    \code{seconds} seconds. If \code{function} finishes before
%    \code{seconds} have elapsed it returns the return values of
%    \code{function}. If \code{function} does not finish in that time
%    it throws a \code{TimoutError}.
%    Additional arguments passed on to \code{function} may simply be
%    specified as additional arguments to \code{try_or_timeout}.
%    Qualifiers can be passed on as usual.
%!%-
define try_or_timeout() {
  if ( _NARGS <= 1 ) {
    throw NumArgsError, "Invalid number of arguments";
  }
  variable args = __pop_list(_NARGS);
  variable seconds = args[0];
  list_delete(args, 0);
  variable old_handler;
  try {
    signal(SIGALRM, &__alarm_signal_handler, &old_handler);
    alarm(seconds);
    variable todo = args[0];
    list_delete(args, 0);
    (@todo)(__push_list(args);; __qualifiers);
  } finally {
    alarm(0);
    if ( typeof(old_handler) == Ref_Type || typeof(old_handler) == Integer_Type ) {
      signal(SIGALRM, old_handler);
    } else {
      signal(SIGALRM, SIG_DFL);
    }
  }
}
