define ntree();
%!%+
%\function{ntree}
%\synopsis{creates a new node of a tree with n children}
%\usage{Struct_Type ntree(DataType_Type objectType[, Struct_Type ntreeType]);
% or Struct_Type ntree(DataType_Type objectType[, Integer_Type numChilds]);}
%\description
%  An n-tree is a special kind of a tree data structure.
%  Each node has exactly n children, which are n-tree
%  nodes themselves. The number of children is specified,
%  e.g., by the 'numChilds' parameter, which is 2 by
%  default. Initially, all children are null pointers.
%  Most importantly, a node contains a list of objects,
%  which is an array of the type specified by the
%  'objectType' parameter. Using the functions provided
%  in the n-tree structure, objects can be inserted or
%  removed.
%  
%  The n-tree structure contains the following functions:
%    insert    - appends an object to the list.
%                Usage: ntree.insert(objectType object);
%    remove    - removes an object from the list and
%                returns 1 on success, 0 otherwise.
%                Usage: Integer_Typer ntree.remove(objectType object);
%    get       - returns all objects stored in the node.
%                Usage: objectType[] ntree.get();
%    getChilds - returns all objects stored in the children.
%                Usage: objectType[] ntree.getChilds();
%    getAll    - iterates over all nodes recursively to
%                return all objects stored in the tree.
%                Usage: objectType[] ntree.getAll();
%    childN    - returns the N's child of the actual node.
%                If the child does not exist, NULL will be
%                returned. The function names can be
%                overwritten by the type definition (see
%                below).
%                Usage: Struct_Type ntree.childN();
%                Qualifiers:
%                  new    - creates the child if it does
%                           not exist
%                  renew  - creates a new child no matter
%                           if it exists already
%                  delete - deletes the child
%
%  In addition, the following fields exist:
%    objects   - array of objects stored in the node
%    childs    - array of length N containing the
%                children of the node
%    type      - structure describing the type of the
%                n-tree (see below)
%
%  The type of the n-tree can be specified by the
%  optional 'ntreeType' parameter. This structure
%  defines additional behaviours of the n-tree, and
%  the number of children and their the return function
%  names eventually. The default type sets these names
%  to the ones described above (childN). Additional
%  informations about the usage of n-tree types can
%  be found in the help of the 'ntree_type' function.
%\example
%  % creates an 4-tree (called quad tree) with one
%  % initial node and an object array of Integer_Type
%  tree = ntree(Integer_Type, 4);
%
%  % insert '5' into the initial node
%  tree.insert(5);
%
%  % create and insert '10' into the third child
%  tree.child3(; new).insert(10);
%
%  % checks if child2 exists
%  if (tree.child2() == NULL)
%    message("child2 does not exist");
%
%  % insert '8' into child3, but it is not
%  % created again since it exists already
%  tree.child3(; new).insert(8);
%
%  % get all objects of the children
%  % (will return [10,8])
%  print(tree.getChilds());
%\seealso{ntree_type}
%!%-


%%%
% private functions
%%%

% inserts an object into the tree
private define ntree_insert_method(nargs) {
  variable node, new;
  variable addargs = (nargs > 2 ? __pop_args(nargs-2) : Struct_Type[0]); % additional parameters for type specific insert function
  switch (nargs - length(addargs))
    { case 2: (node, new) = (); }
    { vmessage("error (%s): object to be inserted not given", _function_name); return; }

  % call insert callback function
  if (struct_field_exists(node.type, "insert")) {
    variable insertfun = node.type.insert; % prevent type structure to be pushed onto the stack
    node = @insertfun(node, new, __push_args(addargs) ;; __qualifiers);
  }
  
  if (node != NULL) node.objects = [node.objects, typecast(new, _typeof(node.objects))];
}

% removes an object from the tree
private define ntree_remove_method(nargs) {
  variable node, del;
  variable addargs = (nargs > 2 ? __pop_args(nargs-2) : Struct_Type[0]); % additional parameters for type specific delete function
  switch (nargs - length(addargs))
    { case 2: (node, del) = (); }
    { vmessage("error (%s): object to be deleted not given", _function_name); return; }

  variable len = length(node.objects);

  % call delete callback function
  if (struct_field_exists(node.type, "remove")) {
    variable removefun = node.type.insert; % prevent type structure to be pushed onto the stack
    node = @removefun(node, del, __push_args(addargs) ;; __qualifiers);
  }
  
  if (node != NULL) node.objects = node.objects[wherenot(node.objects == del)];

  return (len != length(node.objects) && node != NULL);
}

% returns the objects within a node
private define ntree_get_method(nargs) {
  variable node;
  switch(nargs)
    { case 1: (node) = (); }

  return node.objects;
}

% returns the objects within all children
private define ntree_getChilds_method(nargs) {
  variable node;
  switch(nargs)
    { case 1: (node) = (); }

  variable obj = _typeof(node.objects)[0];
  variable i;
  _for i (0, length(node.childs)-1, 1)
    if (node.childs[i] != NULL) obj = [obj, node.childs[i].objects];
  return obj;
}

% returns all objects within the n-tree
private define ntree_getAll_method();
private define ntree_getAll_method(nargs) {
  variable node, visited;
  switch(nargs)
    { case 1: (node) = (); visited = Struct_Type[0]; }
    { case 2: (node, visited) = (); }

  variable obj = _typeof(node.objects)[0];
  % proceed if node has not been visited yet
  if (wherefirst(visited == node) == NULL || length(visited) == 0) {
    visited = [visited, node]; % set this node as visited
    obj = node.objects;
    % recurse children
    variable child;
    foreach child (node.childs) if (child != NULL) obj = [obj, ntree_getAll_method(child, visited, 2)];
  };

  return obj;
}

% returns the n^th child node structure
private variable ntree_child_method_definition = `private define ntree_child_method(n, nargs) {
  variable node;
  switch(nargs)
    { case 1: (node) = (); }

  % eventually create new child
  % qualifiers important since they are passed to the type dependent creation function
  if ((qualifier_exists("new") && node.childs[n-1] == NULL) || qualifier_exists("renew")) node.childs[n-1] = ntree(_typeof(node.objects); parent = node, index = n-1);
  % delete a child (note: children will NOT be deleted recursively)
  if (qualifier_exists("delete")) node.childs[n-1] = NULL;

  return node.childs[n-1];
}`;

%%%
% handler functions
%%%

private define ntree_insert() {
  variable args = __pop_args(_NARGS);
  return ntree_insert_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define ntree_remove() {
  variable args = __pop_args(_NARGS);
  return ntree_remove_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define ntree_get() {
  variable args = __pop_args(_NARGS);
  return ntree_get_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define ntree_getChilds() {
  variable args = __pop_args(_NARGS);
  return ntree_getChilds_method(__push_args(args), _NARGS ;; __qualifiers);
}
private define ntree_getAll() {
  variable args = __pop_args(_NARGS);
  return ntree_getAll_method(__push_args(args), _NARGS ;; __qualifiers);
}
private variable ntree_child_definition = `private define ntree_child%d() {
  variable args = __pop_args(_NARGS);
  return ntree_child_method(__push_args(args), %d, _NARGS ;; __qualifiers);
}`;


%%%
% main functions
%%%

% returns a new n-tree node
define ntree() {
  variable objtype, type;
  variable addargs = (_NARGS > 2 ? __pop_args(_NARGS-2) : Struct_Type[0]); % additional parameters for type specific creation function
  switch (_NARGS - length(addargs))
    { case 1: (objtype) = (); }
    { case 2: (objtype, type) = (); }
    { help(_function_name); return; }

  variable parent = qualifier("parent", NULL);
  variable index  = qualifier("index", NULL);
  % default structure defining a binary tree
  ifnot (__is_initialized(&type))
    type = (parent == NULL ? struct { numChilds = 2 } : parent.type);
  % number of children given
  else if (typeof(type) == Integer_Type)
    type = struct { numChilds = type };
  % type checks
  else if (typeof(type) != Struct_Type)
    { vmessage("error (%s): either a type structure or the number of children has to be given", _function_name); return; }
  ifnot (struct_field_exists(type, "numChilds")) { vmessage("error (%s): the number of children has to be given", _function_name); return; }
  ifnot (struct_field_exists(type, "childNames"))
    type = struct_combine(type, struct { childNames = array_map(String_Type, &sprintf, "child%d", [1:type.numChilds]) });
  if (length(type.childNames) != type.numChilds) { vmessage("error (%s): the number of child names has to be %d", _function_name, type.numChilds); return; }

  % build child function structure
  variable childfun = struct_combine(type.childNames);
  % loop to define the private child functions
  % is this a cheat for function nesting?
  variable n;
  eval(ntree_child_method_definition, "isis");
  _for n (1, type.numChilds, 1) {
    eval(sprintf(ntree_child_definition, n, n), "isis");
    set_struct_field(childfun, type.childNames[n-1], eval(sprintf("&ntree_child%d", n), "isis"));
  }
  
  % build node structure
  variable node = struct_combine(
    struct {
      insert    = &ntree_insert,
      remove    = &ntree_remove,
      get       = &ntree_get,
      getChilds = &ntree_getChilds,
      getAll    = &ntree_getAll
    },
    childfun,
    struct {
      objects = objtype[0],
      childs  = Struct_Type[type.numChilds],
      type    = type
    }
  );

  % call creation callback function
  if (struct_field_exists(type, "new")) {
     variable newfun = type.new; % prevent type structure to be pushed onto the stack
     node = @newfun(node, index, parent, __push_args(addargs) ;; __qualifiers);
  }
  
  return node;
}
