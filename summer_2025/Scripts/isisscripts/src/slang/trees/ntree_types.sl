% -*- mode: slang; mode: fold -*-

% map quadtree %{{{
%!%+
%\function{ntree_type_mapQuad}
%\synopsis{returns the n-tree definition of a map quadtree}
%\usage{Struct_Type ntree(DataType_Type objectType, ntree_type("mapQuad"), Double_Type size[, Double_Type x0, y0]); }
%\description
%  A map quadtree is a 4-tree, which divides a 2d-space
%  into squares with an edge length of 'size'. Therefore,
%  each node of the tree is identified by a certain
%  coordinate x,y. The coordinate of the tree's root can
%  be specified by the x0 and y0 parameters and are (0|0)
%  by default. The children are named "top", "right",
%  "bottom" and "left". Due to that structure the tree
%  will be an undirected graph, meaning that, e.g., the
%  left node is connected to the right node and vise versa:
%
%   -------            ----            -------
%  |x0-size| -right-> | x0 | -right-> |x0+size|
%  |  y0   | <--left- | y0 | <--left- |  y0   |
%   -------            ----            -------
%                       ^|
%                   top || bottom
%                       |v
%                    -------
%                   |   x0  |
%                   |y0-size|
%                    -------
%
%  The map quadtree extends the n-tree structure by the
%  following functions:
%    lookup(x,y) - returns the node fitting the given
%      x and y coordinates
%    insert(object[,x,y]) - overwrites the usual insert
%      function such, that the object is inserted into
%      the node fitting the optional x and y coordinates
%
%  Note: deleting a child by the 'delete' qualifier,
%    e.g. tree.left(; delete) does NOT cascade! That is,
%    the left node still points to the right one (here
%    called tree). It might still be accessable via
%    tree.top().left().bottom()
%\example
%\seealso{ntree, ntree_type}
%!%-
private define ntree_type_mapQuad_lookup_method(nargs) {
  variable node, x, y;
  switch(nargs)
    { case 3: (node, x, y) = (); }
    { vmessage("error (%s): x and y coordinates have to be given", _function_name); return; }

  % return yourself if no coordinates are given
  if (x == NULL && y == NULL) return node;
  % return yourself if coordinates are within
  if (abs(node.x - x) <= .5*node.size && abs(node.y - y) <= .5*node.size) return node;
  % pass request to child
  else { 
    if (x < node.x - .5*node.size) return node.left(; new).lookup(x, y);
    else if (x > node.x + .5*node.size) return node.right(; new).lookup(x, y);
    else if (y < node.y + .5*node.size) return node.bottom(; new).lookup(x, y);
    else return node.top(; new).lookup(x, y);
  }
}

private define ntree_type_mapQuad_lookup() {
  variable args = __pop_args(_NARGS);
  return ntree_type_mapQuad_lookup_method(__push_args(args), _NARGS ;; __qualifiers);
}

private define ntree_type_mapQuad_new() {
  variable node, c, parent, size, x, y;
  switch (_NARGS)
    { case 3: (node, c, parent) = (); x = 0; y = 0; }
    { case 4: (node, c, parent, size) = (); x = 0; y = 0; }
    { case 6: (node, c, parent, size, x, y) = (); }
    { vmessage("error (%s): uncorrect number of arguments", _function_name); return; }

  if (parent == NULL && (not __is_initialized(&size))) { vmessage("error (%s): size is not specified", _function_name); return; }

  % extend node structure
  node = struct_combine(struct {
    x      = (parent == NULL ? x : parent.x + (c == 1 ? 1 : c == 3 ? -1 : 0)*parent.size),
    y      = (parent == NULL ? y : parent.y + (c == 0 ? 1 : c == 2 ? -1 : 0)*parent.size),
    size   = (parent == NULL ? size : parent.size),
    lookup = &ntree_type_mapQuad_lookup
  }, node);
  % set coordinates
  % set one child as parent accordingly
  if (parent != NULL) node.childs[[2,3,0,1][c]] = parent;

  return node;
}

private define ntree_type_mapQuad_insert() {
  variable node, new, x, y;
  switch (_NARGS)
    { case 2: (node, new) = (); return node; }
    { case 4: (node, new, x, y) = (); return node.lookup(x, y); }
    { vmessage("error (%s): uncorrect number of arguments", _function_name); }
}%}}}


% available n-tree types
private variable ntree_types = struct {
  mapQuad = struct {
    numChilds  = 4,
    childNames = ["top", "right", "bottom", "left"],
    new        = &ntree_type_mapQuad_new,
    insert     = &ntree_type_mapQuad_insert
  }
};

%%%%%%%%%%%%%%%
define ntree_type()
%%%%%%%%%%%%%%%
%!%+
%\function{ntree_type}
%\synopsis{returns a specific stucture defining an n-tree type}
%\usage{Struct_Type ntree_type(String_Type typeName); }
%\description
%  This functions returns the structure defining
%  the specific n-tree type named 'typeName'. A
%  list of all available types is shown if no
%  name is passed. The 'help' qualifier shows
%  additional information about the given type.
%
%  The type of an n-tree is specified and can be
%  extended by a structure with the following
%  fields:
%  
%  numChilds
%    Defines the number of children of each node.
%    node. It has the same effect as the
%    'numChilds' parameter of the 'ntree' function.
%
%  childNames (optional)
%    Array of strings defining the return function
%    names for each children. The default names are
%    "child1" to "childN".
%
%  new (optional)
%    Reference to a callback function, which gets
%    called right before a new node created by
%    'ntree()' is returned. Parameters passed are
%    (1) the new node as a structur, (2) as which
%    child number it is created (starting at 1,
%    NULL if it is the root) and (3) the parent
%    node it belongs to (NULL if there is none).
%    The function has to return the new node.
%    
%  insert (optional)
%    Reference to a callback function, which gets
%    called before an object is inserted into a
%    node by 'node.insert()'. Parameters passed are
%    (1) the node as a structure and (2) the object,
%    which should be inserted. The function has to
%    return the node. If NULL is returned, the
%    object will not be inserted into the node.
%
%  remove (optional)
%    Reference to a callback function, which gets
%    called before an object is removed from a node
%    by 'node.remove()'. Parameters passed are (1)
%    the node as a structure and (2) the object,
%    which should be removed. The function has to
%    return the node. If NULL is returned, the
%    object will not be removed from the node.
%\example
%  % first define a callback function, which
%  % prevents inserting negative numbers
%  define ntree_myType_insert(node, object) {
%    if (object < 0) return NULL;
%    else return node;
%  }
%
%  % structure defining a 4-tree (called quadtree)
%  % and the children return functions are renamed
%  % to match directions. The insert callback
%  % function defined above is assigned also.
%  variable myType = struct {
%    numChilds = 4,
%    childNames = ["left","right","top","bottom"],
%    insert = &ntree_myType_insert
%  };
%
%  % create a new n-tree of myType
%  variable tree = ntree(Double_Type, myType);
%\seealso{ntree}
%!%-
{
  variable type, t;
  switch(_NARGS)
    { case 1: (type) = (); }
    { help(_function_name); message(" AVAILABLE TYPES"); foreach t (get_struct_field_names(ntree_types)) vmessage("    %s", t); return; }

  ifnot (struct_field_exists(ntree_types, type)) {
    vmessage("type '%s' not known\navailable types:", type);
    foreach t (get_struct_field_names(ntree_types)) vmessage("  %s", t);
    return;
  }

  if (qualifier_exists("help")) help(sprintf("ntree_type_%s", type));
  else return get_struct_field(ntree_types, type);
}
