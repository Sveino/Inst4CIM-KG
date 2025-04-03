prefix cim:  <https://cim.ucaiug.io/ns#>
prefix cim1: <http://iec.ch/TC57/CIM100#>
prefix nc:   <https://cim4.eu/ns/nc#>
prefix eu:   <https://cim.ucaiug.io/ns/eu#>
prefix eu1:  <http://iec.ch/TC57/CIM100-European#>
prefix eumd: <https://cim4.eu/ns/Metadata-European#>
prefix md:   <http://iec.ch/TC57/61970-552/ModelDescription/1#>
prefix xsd:  <http://www.w3.org/2001/XMLSchema#>

delete {graph ?g {?x ?p ?old}}
insert {graph ?g {?x ?p ?new}}
where {
  values (?prop ?dt) {
TODO: copy from fix-datatypes-common.ru
  }
  graph ?g {?x ?p ?old}
  filter(datatype(?old)=xsd:string)
  bind(if(strstarts(str(?p),str(cim1:)),uri(concat(str(cim:),strafter(str(?p),str(cim1:)))),?UNDEF) as ?p1)
  bind(if(strstarts(str(?p),str(eu1:)), uri(concat(str(eu:), strafter(str(?p),str(eu1:)))), ?UNDEF) as ?p2)
  filter(?p=?prop || ?p1=?prop || ?p2=?prop)
  bind(strdt(?old,?dt) as ?new)
};

