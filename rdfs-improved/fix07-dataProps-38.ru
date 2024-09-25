# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure
# https://github.com/Sveino/Inst4CIM-KG/issues/38
# https://github.com/Sveino/Inst4CIM-KG/issues/29

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX qudt: <http://qudt.org/schema/qudt/>

# fix props pointing to QuantityKinds
delete {?prop cims:dataType ?qk}
insert {
  ?prop qudt:hasQuantityKind ?qk; cim:unitMultiplier ?multiplier; cim:unitSymbol ?unitOfMeasure;
    rdfs:range ?dataType
} where {
  ?prop a rdf:Property; cims:dataType ?qk.
  ?qk a qudt:QuantityKind.
  ?mult rdfs:domain ?qk; rdfs:range cim:UnitMultiplier; cims:isFixed ?mult1.
  bind(iri(concat(str(cim:UnitMultiplier),".",?mult1)) as ?multiplier)
  optional {
    ?unit rdfs:domain ?qk; rdfs:range cim:UnitSymbol; cims:isFixed ?unit1
    bind(iri(concat(str(cim:UnitSymbol),".",?unit1)) as ?unitOfMeasure)
  }
  ?value rdfs:domain ?qk; rdfs:label "value"@en; rdfs:range ?dataType
};

# fix props pointing to Compound
# But maybe Compounds should be removed https://github.com/Sveino/Inst4CIM-KG/issues/78
delete {?prop cims:dataType ?compound}
insert {?prop rdfs:range ?compound}
where {
  ?prop a rdf:Property; cims:dataType ?compound. 
  ?compound cims:stereotype "Compound"
};
