# https://github.com/Sveino/Inst4CIM-KG/issues/26

prefix cims:         <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
prefix owl:          <http://www.w3.org/2002/07/owl#>

delete {?p cims:inverseRoleName ?q}
insert {?p owl:inverseOf ?q}
where {?p cims:inverseRoleName ?q};

