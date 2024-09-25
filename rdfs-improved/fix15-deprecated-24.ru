# https://github.com/Sveino/Inst4CIM-KG/issues/24

prefix cims:         <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
prefix owl:          <http://www.w3.org/2002/07/owl#>

delete {?p cims:stereotype "deprecated"}
insert {?p owl:deprecated true}
where  {?p cims:stereotype "deprecated"};

