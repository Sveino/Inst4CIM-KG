# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure
# https://github.com/Sveino/Inst4CIM-KG/issues/38
# https://github.com/Sveino/Inst4CIM-KG/issues/29

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX qudt: <http://qudt.org/schema/qudt/>

# Delete now-useless props
delete {?prop ?p ?o}
where {
  ?prop rdfs:domain ?qk; ?p ?o.
  ?qk a qudt:QuantityKind
};

