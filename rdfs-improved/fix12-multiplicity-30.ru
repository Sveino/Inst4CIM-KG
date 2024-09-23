# https://github.com/Sveino/Inst4CIM-KG/issues/30

prefix cims:         <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
prefix owl:          <http://www.w3.org/2002/07/owl#>

delete {?p cims:multiplicity cims:M:1}
insert {?p cims:multiplicity cims:M:1..1}
where  {?p cims:multiplicity cims:M:1};

insert {
  ?p a owl:FunctionalProperty.
  ?q1 a owl:InverseFunctionalProperty.
  ?q2 a owl:InverseFunctionalProperty.
} where {
  values ?singleValued {cims:M:0..1 cims:M:1..1}
  ?p cims:multiplicity ?singleValued
  # This works regardless in which direction inverseOf is declared, even without reasoning
  optional {?p  owl:inverseOf ?q1}
  optional {?q2 owl:inverseOf ?p}
};

