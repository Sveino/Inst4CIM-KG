# https://github.com/Sveino/Inst4CIM-KG/issues/75

PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

# move classes from RDFS to OWL
delete {?class a rdfs:Class}
insert {?class a owl:Class}
where  {?class a rdfs:Class};

# if range is XSD then DatatypeProperty
delete {?prop a rdf:Property}
insert {?prop a owl:DatatypeProperty}
where {
  ?prop a rdf:Property; rdfs:range ?dt
  filter(strstarts(str(?dt),str(xsd:)))
};

# else ObjectProperty
delete {?prop a rdf:Property}
insert {?prop a owl:ObjectProperty}
where {?prop a rdf:Property};
