package frontend


import ll "core:container/intrusive/list"
import "core:odin/ast"



/*
  What We need to do

  we need a array of types 
  and a hash map of identifier based types to 

  Resolve implicit variable type declarations

  Check types

  after ast generation we gotta make a types ast tree
  ambiguous declarations are put in a registry to 
  check how to resolve that declaration


  function() -> not true
*/


Type_Node :: struct {
  using link: ll.Node,
  type: Type,
}


Sema :: struct {
  resolved: ll.List,
  unresolved: ll.List,
}