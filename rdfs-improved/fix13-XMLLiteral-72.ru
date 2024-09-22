# https://github.com/Sveino/Inst4CIM-KG/issues/72

prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>

delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  ?x ?p ?old
  filter(datatype(?old) = rdf:XMLLiteral)
  bind(str(?old) as ?new)
};

