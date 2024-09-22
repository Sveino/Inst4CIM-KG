# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure
# https://github.com/Sveino/Inst4CIM-KG/issues/38
# https://github.com/Sveino/Inst4CIM-KG/issues/29

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX qudt: <http://qudt.org/schema/qudt/>

# fix QuantityKinds
delete {?qk a rdfs:Class; cims:stereotype "CIMDatatype"}
insert {?qk a qudt:QuantityKind; qudt:applicableUnit ?unitOfMeasure}
where {
  ?qk a rdfs:Class; cims:stereotype "CIMDatatype" 
  optional {
    ?unit rdfs:domain ?qk; rdfs:range cim:UnitSymbol; cims:isFixed ?unit1
    bind(iri(concat(str(cim:UnitSymbol),".",?unit1)) as ?unitOfMeasure)
  }
};

# Currency is an enumeration of currencies. They all apply to Money as "units"
insert {cim:Money qudt:applicableUnit ?unit}
where {
  cim:Money.unit rdfs:domain cim:Money; rdfs:range cim:Currency.
  ?unit a cim:Currency.
};
