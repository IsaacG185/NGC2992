%
% Implementation of binary search and AVL trees
%

% Basic type definitions
private variable TREE_LEFT=0;
private variable TREE_RIGHT=1;

%
% basic key compare function
% (can be overridden if the tree contains more complex data structures)
%
private define tree_key_compare(k1,k2) {
    return (k1 < k2) ? -1 : ( (k1==k2) ? 0 : +1);
}

%
% Binary tree specific functions and structures
%
private define new_BinarySearchTreeNode() {
    variable T;
    variable data=NULL;
    if (_NARGS==1) {
        T=();
    }
    if (_NARGS==2) {
        (T,data)=();
    }
    
    return struct {     % node of a binary search tree
        child={NULL,NULL}, % value is NULL if child is empty
        data=data
    };
}

private define BinarySearchTreeInsert_helper(T,key) {
    % insert a node containing key into the binary tree T
    % this could also be programmed recursively, but iteratively is
    % faster. This returns the newly inserted key.
    
    % use new_node function such that this will also work on
    % binary search trees derived from the BinarySearchTree
    variable N=T.new_node(key);

    % empty tree: insert at root and be done with it
    if (typeof(T.root)!=Struct_Type) {
        T.root=N;
        return N;
    }

    % existing tree - iterative traversal to correct position
    variable no=T.root;
    while (1) {
        variable cmp=T.key_compare(key,no.data);
        % key < no.data ?
        if (cmp<0) {
            % empty child? - if yes, then insert
            if (no.child[TREE_LEFT]==NULL) {
                no.child[TREE_LEFT]=N;
                return N;
            }
            no=no.child[TREE_LEFT];
        } else {
            % key > no.data ?
            if (cmp>0) {
                % empty child? - if yes, then insert
                if (no.child[TREE_RIGHT]==NULL) {
                    no.child[TREE_RIGHT]=N;
                    return N;
                }
                no=no.child[TREE_RIGHT];
            } else {
                % key already exists, throw an error
                % FIXME: add graceful exit option
                throw UsageError,sprintf("insert: Key %S already exists!\n",key);
            }
        }
    }

    % should never reach this point
    throw UsageError,sprintf("This should never happen\n");
}

private define BinarySearchTreeInsert(T,key) {
    % insert a node containing key into the binary tree T
    ()=BinarySearchTreeInsert_helper(T,key);
}

private define BinarySearchTreeMinimum(N) {
    % return node with the smallest key in a binary search tree
    % if qualifier "node" is set returns the node, otherwise the key
    %
    % N can be a node or a tree

    % case of tree
    if (struct_field_exists(N,"root")) {
        N=N.root;
    }

    while (N.child[TREE_LEFT]!=NULL) {
        N=N.child[TREE_LEFT];
    }
    if (qualifier_exists("node")) {
        return N;
    }
    return N.data;
}

private define BinarySearchTreeMaximum(N) {
    % return the largest key in a binary search tree
    % if qualifier "node" is set returns the node, otherwise the key

    % case of tree
    if (struct_field_exists(N,"root")) {
        N=N.root;
    }

    while (N.child[TREE_RIGHT]!=NULL) {
        N=N.child[TREE_RIGHT];
    }
    if (qualifier_exists("node")) {
        return N;
    }
    return N.data;
}

% iterative deletion of a key in a binary search tree
private define BinarySearchTreeDeleteKey_helper_iterative(T,key,N);
private define BinarySearchTreeDeleteKey_helper_iterative(T,key,N) {
    %
    % deletion of node with key K from binary tree (version 1)
    %
    if (N==NULL) {
        return NULL;
    }

    %
    % traverse tree
    %
    variable cmp=T.key_compare(key,N.data);
    variable parent;
    while (N!=NULL && cmp!=0) {
        parent=N;
        if (cmp<0) {
            N=N.child[TREE_LEFT];
        } else {
            N=N.child[TREE_RIGHT];
        }

        % not found
        if (N==NULL) {
            return N;
        }
        cmp=T.key_compare(key,N.data);        
    }

    % N is now the key to be deleted
    
    if (N.child[TREE_LEFT]==NULL) {
        if (N.child[TREE_RIGHT]==NULL) {
            N=NULL; % kill data
            return N;
        }
        N=N.child[TREE_RIGHT];
        return N;
    }

    if (N.child[TREE_RIGHT]==NULL) {
        N=N.child[TREE_LEFT];
        return N;
    }

    % node has two children: replace current node with successor data
    % and delete successor
    
    % find successor node
    variable succ=BinarySearchTreeMinimum(N.child[TREE_RIGHT];node);
    % copy successor data
    N.data=succ.data;

    % delete inorder successor
    N.child[TREE_RIGHT]=BinarySearchTreeDeleteKey_helper_iterative(T,N.data,N.child[TREE_RIGHT]);
    
    return N;
}

%
% full recursive tree deletion (needed for the AVL tree)
%
private define BinarySearchTreeDeleteKey_helper_recursive(T,key,N);

private define BinarySearchTreeDeleteKey_helper_recursive(T,key,N) {
    % no node at current position, end recursion
    if (N==NULL) {
        return NULL;
    }

    % recursive deletion
    variable cmp=T.key_compare(key,N.data);
    if (cmp<0) {
        % key < N.data
        N.child[TREE_LEFT]=BinarySearchTreeDeleteKey_helper_recursive(T,key,N.child[TREE_LEFT]);
    } else {
        if (cmp>0) {
            % key > N.data
            N.child[TREE_RIGHT]=BinarySearchTreeDeleteKey_helper_recursive(T,key,N.child[TREE_RIGHT]);
        } else {
            % all ifs below: found it!
            %
            
            if (N.child[TREE_LEFT]==NULL && N.child[TREE_RIGHT]==NULL) {
                % no child present, just delete the thing
                N=NULL;
            } else {
                if (N.child[TREE_LEFT]==NULL) {
                    N=N.child[TREE_RIGHT];
                } else {
                    if (N.child[TREE_RIGHT]==NULL) {
                        N=N.child[TREE_LEFT];
                    } else {
                        % delete node with two children

                        % find inorder successor of current node
                        variable succ=BinarySearchTreeMinimum(N.child[TREE_RIGHT];node);
                        % save the data of the successor
                        N.data=succ.data;
                        % delete successor
                        N.child[TREE_RIGHT]=BinarySearchTreeDeleteKey_helper_recursive(T,N.data,N.child[TREE_RIGHT]);
                    }
                }
            }
        }
    }
    return N;
}

private define BinarySearchTreeDeleteKey(T,key) {
    ()=BinarySearchTreeDeleteKey_helper_iterative(T,key,T.root);
}

private define BinarySearchTreeDeleteNode(T,N) {
    ()=BinarySearchTreeDeleteKey_helper_iterative(T,N.key,T.root);
}

% find node for which data==key
% returns the Node of Null, if the key does not exist
private define BinarySearchTreeSearch(T,key) {
    variable N=T.root;
    while (N!=NULL && N.data != key ) {
        if (key < N.data) {
            N=N.child[TREE_LEFT];
        } else {
            N=N.child[TREE_RIGHT];
        }
    }

    return N;
}

% return true if key is contained in T
private define BinarySearchTreeKeyExists(T,key) {
    variable N=BinarySearchTreeSearch(T,key);
    return (N!=NULL);
}

private define BinarySearchTreeNodeSuccessor(T,N)
% find successor node of N in tree T
% (T isn't really needed here, but this helps the tree object)
{
    if (N.child[TREE_RIGHT]!=NULL) {
        return BinarySearchTreeMinimum(N.child[TREE_RIGHT];node);
    }
    variable y=N.parent;
    while (y!=NULL && N==y.child[TREE_RIGHT]) {
        N=y;
        y=y.parent;
    }
    return y;
}

private define BinarySearchTreeNodePredecessor(T,N)
% find predecessor node of N in tree T
% (T isn't really needed here, but this helps the tree object)
{
    if (N.child[TREE_LEFT]!=NULL) {
        return BinarySearchTreeMinimum(N.child[TREE_LEFT];node);
    }
    variable y=N.parent;
    while (y!=NULL && N==y.child[TREE_LEFT]) {
        N=y;
        y=y.parent;
    }
    return y;
}

private define BinarySearchPrintNode(N) {
    ()=printf("%S\n",N.data);
}

private define BinarySearchTraversal();

private define BinarySearchTraversal() {
    variable N,func;

    if (_NARGS==1) {
        N=();
        func=&BinarySearchPrintNode;
    }
    
    if (_NARGS==2) {
        (N,func)=();
    }

    if (N==NULL) {
        return;
    }

    if (struct_field_exists(N,"root")) {
        N=N.root;
        if (N==NULL) {
            return;
        }
    }
    
    if (qualifier_exists("preorder")) {
        (@func)(N;;__qualifiers());
        BinarySearchTraversal(N.child[TREE_LEFT],func;;__qualifiers());
        BinarySearchTraversal(N.child[TREE_RIGHT],func;;__qualifiers());
        return;
    }

    if (qualifier_exists("postorder")) {
        BinarySearchTraversal(N.child[TREE_LEFT],func;;__qualifiers());
        BinarySearchTraversal(N.child[TREE_RIGHT],func;;__qualifiers());
        (@func)(N;;__qualifiers());
        return;
    }

    % default is inorder traversal
    BinarySearchTraversal(N.child[TREE_LEFT],func;;__qualifiers());
    (@func)(N;;__qualifiers());
    BinarySearchTraversal(N.child[TREE_RIGHT],func;;__qualifiers());
    return;

}

private define BinarySearchTreeNodePrint();

private define BinarySearchTreeNodePrint() {
    variable N,sp;

    (N,sp)=();

    if (N==NULL) {
        return;
    }

    BinarySearchTreeNodePrint(N.child[TREE_RIGHT],sp+"    ");
    if (struct_field_exists(N,"height")) {
        ()=printf("%s%S-%i\n",sp,N.data,N.height);
    } else {
        ()=printf("%s%S\n",sp,N.data);
    }
    BinarySearchTreeNodePrint(N.child[TREE_LEFT],sp+"    ");
}

private define BinarySearchTreePrint(T) {
    BinarySearchTreeNodePrint(T.root,"");
}

private variable BinarySearchTree_Struct=struct {
    root=NULL,
    insert=&BinarySearchTreeInsert,
    print=&BinarySearchTreePrint,
    new_node=&new_BinarySearchTreeNode,
    key_compare=&tree_key_compare,
    search=&BinarySearchTreeSearch,
    delete=&BinarySearchTreeDeleteKey,
    delete_node=&BinarySearchTreeDeleteNode,
    exists=&BinarySearchTreeKeyExists,
    min=&BinarySearchTreeMinimum,
    max=&BinarySearchTreeMaximum,
    successor=&BinarySearchTreeNodeSuccessor,
    predecessor=&BinarySearchTreeNodePredecessor,
    traversal=&BinarySearchTraversal
};

define BinarySearchTree()
%!%+
%\function{BinarySearchTree}
%\synopsis{Creates a new binary search tree}
%\usage{Struct_Type=BinarySearchTree();}
%\altusage{Struct_Type=BinarySearchTree(cmpfunction);}
%\description
%A binary search tree is an object that permits fast
%searches and ordered operations on ordinal data types (i.e.,
%data that can be sorted). 
%
%The tree consists of nodes which are structs containing
%the data (or "key") in tag "data" and references to nodes with
%keys with values less than data in child[0] and to keys with
%values larger than data in child[1]. In general, users of the
%data structure should not worry about the structure of the
%nodes and use the functions described below for all tree
%operations.
%
%Searches in a binary search tree can be fast (O(log N)) if the
%search tree is balanced, that is, if there is a similar number
%of nodes below each node (if that makes sense...). This is typically
%the case if random (unsorted) data are inserted into the tree, and
%very much not the case if ordered data are inserted. In this case
%the search degenerates to O(N). The isisscripts provide a special
%binary search tree called AVLTree that has the same accessor functions
%as BinarySearchTree but ensures that the tree is height-balanced (at some
%small additional cost for key insertions and deletions).
%
%The BinarySearchTree and the AVLTree provide the following functions:
%  insert(key) - insert a data element key into the binary search tree
%  delete(key) - remove a data element key from the binary search tree
%  exists(key) - return true if the search tree contains key
%  search(key) - return the node containing the key (or NULL if
%                they key does not exist)
%  min         - return the minimum key of the search tree (or a subtree), or
%                the node containing the minimum key if the node qualifier
%                is set.
%  max         - return the maximum key of the search tree (or a subtree), or
%                the node containing the maximum key if the node qualifier
%                is set.
%  successor   - return the successor node to a node (i.e., the node
%                containing the next largest data value in the tree).
%  predecessor - return the predecessor node to a node (i.e., the node
%                containing the next smaller data value in the tree).
%  print       - print the structure of the tree
%  traversal(&func;quals) - traverse the tree, i.e., execute func for all
%                keys of the tree. The function func is called with each
%                node N (i.e., the data are found in N.data) and all
%                qualifiers given to traversal. The order in which the
%                nodes are traversed is defined by the following qualifiers:
%                preorder: operate on the node, then on the left children,
%                          then on the right children
%                postorder: operate first on the left children, then on the
%                          right children, then on the node
%                inorder (the default): operate on the left children, then
%                          on the node, then on the right children
%                Note that it is permitted that func modifies the tree (e.g.,
%                insert new elements, delete tree elements and so on; it is
%                best practice to use a qualifier that specifies the tree to
%                let func know about it). Depending on the traversal order
%                the modified elements may or may not be operated on as part
%                of the traversal.
%
%
%The default setup of the binary search tree works on all data types
%where the operators <, ==, and > have been defined. For other data
%types, initialize the tree with a reference to a comparison function
%of the style define key_compare(k1,k2) where k1 and k2 are of the
%data type contained in the search tree and which returns a negative
%number if k1<k2, 0 if k1==k2, and a positive number if k1>k2 (this
%is the same definition as the one used by s-lang's sort function or
%by the strcmp function).
%
%\example
%   % sort some numbers
%   % (obviously a better way would be array_sort...)
%
%   define arrapp(N) {
%     % append key of N to list
%     variable list=qualifier("list");
%     list_append(list,N.data);
%   }
%    
%   variable arr=[1,4,6,3,5,7,8,2,9];
%   variable t=BinarySearchTree();
%   variable i;
%   foreach i (arr) {
%     t.insert(i);
%   }
%    
%   % print the tree
%   t.print();
%
%   % delete element with key 8
%   t.delete(8);
%
%   variable ll={};
%   t.traversal(&arrapp;list=ll);
%   foreach i (ll) {
%     print(i);
%   }
%   % print the minimum and maximum values
%   ()=printf("min: %S - max: %S\n",t.min(),t.max());
%
%\example
%   % setup a tree for strings
%   variable arr=["A","X","D","B","C"];
%   variable t=AVLTree(&strcmp);
%   variable i;
%   foreach i (arr) {
%      t.insert(i);
%   }
%   t.print();
%   
%
%\seealso{AVLTree,sort}
%!%-
{
    variable T=@BinarySearchTree_Struct;

    if (_NARGS==1) {
        variable cmpf=();
        T.key_compare=cmpf;
    }
    return T;
}


%
% AVL node specific functions and structures
%
private define new_AVLNode() {
    variable T;
    variable data=NULL;
    if (_NARGS==1) {
        T=();
    }
    if (_NARGS==2) {
        (T,data)=();
    }

    variable N=new_BinarySearchTreeNode(T,data);
    return struct_combine(N,struct{height=0});
}

private define AVLNodeHeight(N) {
    % get the node height
    if (N==NULL) {
        return -1;
    }
    return N.height;
}

private define AVLNodeUpdateHeight(N) {
    variable lh=AVLNodeHeight(N.child[TREE_LEFT]);
    variable rh=AVLNodeHeight(N.child[TREE_RIGHT]);
    if (lh>rh) {
        N.height=lh+1;
    } else {
        N.height=rh+1;
    }
}

private define AVLNodeBalanceFactor(N) {
    return AVLNodeHeight(N.child[TREE_RIGHT])-AVLNodeHeight(N.child[TREE_LEFT]);
}

private define AVLTreeRotate(N,dir) {
    % rotate tree below N by dir (where dir==TREE_LEFT or TREE_RIGHT)
    variable sav=N.child[1-dir];

    N.child[1-dir]=sav.child[dir];
    sav.child[dir]=N;

    AVLNodeUpdateHeight(N);
    AVLNodeUpdateHeight(sav);
    
    return sav;
}

private define AVLTreeRebalance(N) {
    variable bf=AVLNodeBalanceFactor(N);

    % Left heavy?
    if (bf < -1 ) {
        if (AVLNodeBalanceFactor(N.child[TREE_LEFT])<=0) {
            N=AVLTreeRotate(N,TREE_RIGHT);
        } else {
            N.child[TREE_LEFT]=AVLTreeRotate(N.child[TREE_LEFT],TREE_LEFT);
            N=AVLTreeRotate(N,TREE_RIGHT);
        }
        
        % if (AVLNodeBalanceFactor(N.child[TREE_LEFT])>0) {
        %     N.child[TREE_LEFT]=AVLTreeRotate(N.child[TREE_LEFT],TREE_LEFT);
        % }
        % N=AVLTreeRotate(N,TREE_RIGHT);
    }

    % right heavy?
    if (bf>1) {
        if (AVLNodeBalanceFactor(N.child[TREE_RIGHT])>=0) {
            N=AVLTreeRotate(N,TREE_LEFT);
        } else {
            N.child[TREE_RIGHT]=AVLTreeRotate(N.child[TREE_RIGHT],TREE_RIGHT);
            N=AVLTreeRotate(N,TREE_LEFT);
        }
        % if (AVLNodeBalanceFactor(N.child[TREE_RIGHT])<0){
        %     N.child[TREE_RIGHT]=AVLTreeRotate(N.child[TREE_RIGHT],TREE_RIGHT);
        % }
        % N=AVLTreeRotate(N,TREE_LEFT);
    }

    return N;
    
}

private define AVLTreeInsert_helper(T,key,no);

private define AVLTreeInsert_helper(T,key,no) {
    % insert node N into binary tree no in tree T
    if (no==NULL) {
        return T.new_node(key);
    }
    
    variable cmp=T.key_compare(key,no.data);
    if (cmp<0) {
        % key < no.data
        no.child[TREE_LEFT]=AVLTreeInsert_helper(T,key,no.child[TREE_LEFT]);
    } else {
        if (cmp>0) {
            no.child[TREE_RIGHT]=AVLTreeInsert_helper(T,key,no.child[TREE_RIGHT]);
        } else {
            % equal - not permitted, so throw an error
            throw UsageError,sprintf("insert: Key %S already exists!\n",key);
        }
    }
    
    AVLNodeUpdateHeight(no);

    return AVLTreeRebalance(no);
}

private define AVLTreeInsert (T,key) {
    % insert a node containing key into the binary tree T
    if (T.root==NULL) {
        T.root=T.new_node(key);
        return;
    }
    T.root=AVLTreeInsert_helper(T,key,T.root);
}


private define AVLTreeDeleteKey_helper(T,key,root) {

    variable N=BinarySearchTreeDeleteKey_helper_recursive(T,key,root);
    if (N==NULL) {
        return root;
    }
    AVLNodeUpdateHeight(N);
    AVLTreeRebalance(N);
}

private define AVLTreeDeleteKey(T,key) {
    T.root=AVLTreeDeleteKey_helper(T,key,T.root);
}

private define AVLTreeDeleteNode(T,N) {
    T.root=AVLTreeDeleteKey_helper(T,N.key,T.root);
}

private variable AVLTree_Struct=struct {
    root=NULL,
    insert=&AVLTreeInsert,
    print=&BinarySearchTreePrint,
    new_node=&new_AVLNode,
    key_compare=&tree_key_compare,
    search=&BinarySearchTreeSearch,
    delete=&AVLTreeDeleteKey,
    delete_node=&AVLTreeDeleteNode,
    exists=&BinarySearchTreeKeyExists,
    min=&BinarySearchTreeMinimum,
    max=&BinarySearchTreeMaximum,
    successor=&BinarySearchTreeNodeSuccessor,
    predecessor=&BinarySearchTreeNodePredecessor,
    traversal=&BinarySearchTraversal
};

define AVLTree()
%!%+
%\function{AVLTree}
%\synopsis{Creates a new balanced binary search tree}
%\usage{Struct_Type=AVLTree();}
%\altusage{Struct_Type=AVLTree(cmpfunction);}
%\description
%A binary search tree is an object that permits fast
%searches and ordered operations on ordinal data types (i.e.,
%data that can be sorted).
%
%An AVLTree is a balanced binary search tree, that is, a search
%tree with a structure that ensures that searches will always
%be close to O(log(N)), where N is the number of elements in the
%tree.
%
%The interface of AVLTree is identical to that of BinarySearchTree,
%see there for a description of the member functions.
%
%\seealso{BinarySearchTree}
%!%-
{
    variable T=@AVLTree_Struct;

    if (_NARGS==1) {
        variable cmpf=();
        T.key_compare=cmpf;
    }
    return T;
}


% %
% % Red Black Tree specific functions
% %

% private define RBRotateDirRoot(T,P,dir) {
%     % T  : red-black tree
%     % P  : root of subtree (may be the root of T)
%     % dir: { TREE_LEFT, TREE_RIGHT }
%     variable G=P.parent;
%     variable S=P.child[1-dir];

%     if (typeof(S)!=Struct_Type) {
%         throw UsageError,"Need a true node!";
%     }

%     variable C = S.child[dir];
%     P.child[1-dir]=C;
    
%     if (typeof(C)==Struct_Type) {
%         C.parent=P;
%     }
    
%     S.child[dir]=P;
%     P.parent=S;
%     S.parent=G;

%     if (typeof(G)==Struct_Type) {
%         G.child[ (P == G.child[TREE_RIGHT]) ? TREE_RIGHT : TREE_LEFT ] = S;
%     } else {
%         T.root=S;
%     }
%   return S; % new root of subtree
% }

% define RBinsert1(T,N,P,dir) {
%     % T: red-black tree
%     % N: node to be inserted
%     % P: parent node of N (may be NULL)
%     % dir: side ( TREE_LEFT or TREE_RIGHT ) of P where to insert N

%     variable G; % parent node of P
%     variable U; % uncle of N

%     N.color = RED;
%     N.child[TREE_LEFT]  = NULL;
%     N.child[TREE_RIGHT] = NULL;
%     N.parent = P;
    
%     if (typeof(P) != Struct_Type ) {   % There is no parent
%         T.root = N;    % N is the new root of the tree T.
%         return; % insertion complete
%     }

%     P.child[dir]=N;% insert N as dir-child of P
%     % start of the (do while)-loop:
%     do {
%         if (P.color == BLACK) {
%             % Case_I1 (P black):
%             return; % insertion complete
%         }
%         % From now on P is red.
%         G=P.parent;
%         if (typeof(G) != Struct_Type) {
%             % P red and root
%             P.color = BLACK;
%             return; % insertion complete
%         }
%         % else: P red and G!=NULL.
%         dir = childDir(P); % the side of parent G on which node P is located
%         U = G.child[1-dir]; % uncle
%         if (typeof(U) != Struct_Type || U.color == BLACK) { % considered black
%             if (N == P.child[1-dir]) {
%                 % Case_I5 (P red && U black && N inner grandchild of G):
%                 RBRotateDirRoot(T,P,dir); % P is never the root
%                 N = P; % new current node
%                 P = G.child[dir]; % new parent of N
%                 % fall through to Case_I6
%             }
%             %Case_I6 (P red && U black && N outer grandchild of G):
%             RBRotateDirRoot(T,G,1-dir); % G may be the root
%             P.color = BLACK;
%             G.color = RED;
%             return; % insertion complete
%         }
         
%         % Case_I2 (P+U red):
%         P.color = BLACK;
%         U.color = BLACK;
%         G.color = RED;
%         N = G; % new current node
%         % iterate 1 black level higher
%         %   (= 2 tree levels)
%         P=N.parent;
%     } while (typeof(P) == Struct_Type);
%     % end of the (do while)-loop
%     % Leaving the (do while)-loop (after having fallen through from Case_I2).
        
%     % Case_I3: N is the root and red.
%     return; % insertion complete

% } % end of RBinsert1

% define RBdelete(T,N) {
%     %
%     % delete node N from RB tree T
%     %

%     %
%     % simple root?
%     %
%     if (N==T.root) {
%         if (typeof(N.child[TREE_LEFT])!=Struct_Type && typeof(N.child[TREE_RIGHT])!=Struct_Type) {
%             % tree consists of one node only
%             T.root=NULL;
%             return;
%         }

%         % now at least one child exists
% %%%        if (typeof(XXX

%     }

% }

% define RBdelete2(T,N) {
%     %
%     % treatment of complex delete cases
%     %
%     % T red-black tree
%     % N node to be deleted

%     variable P = N.parent;  % -> parent node of N
%     variable S;  % sibling of N
%     variable C; %  close   nephew
%     variable D; % distant nephew

%     % P != NULL, since N is not the root.
%     variable dir = childDir(N); % side of parent P on which the node N is located
%     % Replace N at its parent P by NULL
%     P.child[dir] = NULL;

%     % start of the (do while)-loop:
%     do {
%         dir = childDir(N);   % side of parent P on which node N is located
%         S = P.child[1-dir]; % sibling of N (has black height >= 1)
%         D = S.child[1-dir]; % distant nephew
%         C = S.child[  dir]; % close   nephew
%         if (S.color == RED) {
%             % Case_D3: S red && P+C+D black:
%             RBRotateDirRoot(T,P,dir); % P may be the root
%             P.color = RED;
%             S.color = BLACK;
%             S = C; % != NIL
%             % now: P red && S black
%             D = S.child[1-dir]; % distant nephew
%             if (typeof(D) == Struct_Type && D.color == RED) {
%                 % Case_D6: % D red && S black:
%                 RBRotateDirRoot(T,P,dir); % P may be the root
%                 S.color = P.color;
%                 P.color = BLACK;
%                 D.color = BLACK;
%                 return; 
%             }
%             C = S.child[  dir]; % close   nephew
%             if (typeof(C) == Struct_Type && C.color == RED) {
%                 % Case_D5: % C red && S+D black:
%                 RBRotateDirRoot(T,S,1-dir); % S is never the root
%                 S.color = RED;
%                 C.color = BLACK;
%                 D = S;
%                 S = C;
%                 RBRotateDirRoot(T,P,dir); % P may be the root
%                 S.color = P.color;
%                 P.color = BLACK;
%                 D.color = BLACK;
%                 return; 
%             }
%             % Otherwise C+D considered black.
%             S.color = RED;
%             P.color = BLACK;
%             return; 
%         }
%         % S is black:
%         if (typeof(D) == Struct_Type && D.color == RED) { % not considered black
%             % Case_D6: % D red && S black:
%             RBRotateDirRoot(T,P,dir); % P may be the root
%             S.color = P.color;
%             P.color = BLACK;
%             D.color = BLACK;
%             return; % deletion complete
%         }
%         if (typeof(C) == Struct_Type && C.color == RED) {% not considered black
%             % C red && S+D black:
%             RBRotateDirRoot(T,S,1-dir); % S is never the root
%             S.color = RED;
%             C.color = BLACK;
%             D = S;
%             S = C;
%             RBRotateDirRoot(T,P,dir); % P may be the root
%             S.color = P.color;
%             P.color = BLACK;
%             D.color = BLACK;
%             return;
%         }
%         % Here both nephews are == NULL (first iteration) or black (later).
%         if (P.color == RED) {
%             S.color = RED;
%             P.color = BLACK;
%             return; 
%         }
%         % Case_D1 (P+C+S+D black):
%         S.color = RED;
%         N = P; % new current node (maybe the root)
%         % iterate 1 black level
%         %   (= 1 tree level) higher
%         P=N.parent;
%   } while (typeof(P) == Struct_Type);
%   % end of the (do while)-loop
%   return; 

% } % end of RBdelete

% private define RedBlackTreeInsert(T,key) {
%     % insert a node containing  key into RB tree T

%     variable N=new_RBNode(data);

%     if (typeof(T.root)!=Struct_Type) {
%         T.root=N;
%         T.root.color=BLACK;
%         return;
%     }
    
%     variable x=T.root;

%     % find the future parent of our node
%     while (typeof(x) == Struct_Type ) {
%         variable y=x; %
%         if (N.data < x.data) {
%             x=x.child[TREE_LEFT];
%         } else {
%             x=x.child[TREE_RIGHT];
%         }
%     }
%     N.parent=y;

%     % where to insert
%     variable dir=(T.key_compare(N.data,y.data)==-1) ? TREE_LEFT : TREE_RIGHT;

%     RBinsert1(T,N,N.parent,dir);
% }



% variable RedBlackTree_Struct=struct {
%     root=NULL,
%     new_node=&new_RedBlackTreeNode,
%     insert=&RedBlackTreeInsert,
%     print=&BinarySearchTreePrint,
%     key_compare=&tree_key_compare,
%     search=&BinarySearchTreeSearch,
%     delete=&RBdelete,
%     exists=&BinarySearchTreeExists,
%     min=&BinarySearchTreeMinimum,
%     max=&BinarySearchTreeMaximum,
%     successor=&BinaryNodeSuccessor,
%     predecessor=&BinaryNodePredecessor
% };



% private define new_RBTree() {
%     return @RedBlackTree_Struct;
% }



% % function joinRightRB(TL, k, TR):
% %     if (TL.color=black) and (TL.blackHeight=TR.blackHeight):
% % return Node(TL, {k,red},TR)
% % T'=Node(TL.left, {TL.key,TL.color},joinRightRB(TL.right,k,TR))
% %     if (TL.color=black) and (T'.right.color=T'.right.right.color=red):
% %         T'.right.right.color=black;
% %         return rotateLeft(T',N,T')
% %     return T' /* T''[recte T'] */

% % function joinLeftRB(TL, k, TR):
% %   /* symmetric to joinRightRB */

% % function join(TL, k, TR):
% %     if TL.blackHeight>TR.blackHeight:
% %         T'=joinRightRB(TL,k,TR)
% %         if (T'.color=red) and (T'.right.color=red):
% %             T'.color=black
% %         return T'
% %     if TR.blackHeight>TL.blackHeight:
% %         /* symmetric */
% %     if (TL.color=black) and (TR.color=black):
% % return Node(TL,{k,red},TR)
% % return Node(TL,{k,blac},TR)

% % function split(T, k):
% %     if (T = nil) return (nil, false, nil)
% %     if (k = T.key) return (T.left, true, T.right)
% %     if (k < T.key):
% %         (L',b,R') = split(T.left, k)
% %         return (L',b,join(R',T.key,T.right))
% %     (L',b,R') = split(T.right, k)
% % return (join(T.left,T.key,L'),b,T.right)

% % function union(t1, t2):
% %     if t1 = nil return t2
% %     if t2 = nil return t1
% %     (L1,b,R1)=split(t1,t2.key)
% %     proc1=start:
% %         TL=union(L1,t2.left)
% %     proc2=start:
% %         TR=union(R1,t2.right)
% %     wait all proc1,proc2
% % return join(TL, t2.key, TR)
