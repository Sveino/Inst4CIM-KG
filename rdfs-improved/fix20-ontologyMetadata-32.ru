# https://github.com/Sveino/Inst4CIM-KG/issues/32

prefix owl:  <http://www.w3.org/2002/07/owl#>
prefix dcat: <http://www.w3.org/ns/dcat#>
prefix dct:  <http://purl.org/dc/terms/>
prefix dc:   <http://purl.org/dc/elements/1.1/>

delete {?x dct:conformsTo ?old}
insert {?x dc:source ?new}
where {
  ?x a owl:Ontology; dct:conformsTo ?old
  filter(strstarts(?old,"file://"))
  bind(strafter(?old,"file://") as ?new)
};

delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  values ?p {dcat:landingPage dct:conformsTo}
  ?x a owl:Ontology; ?p ?old
  bind(iri(?old) as ?new)
};

delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  values ?p {dct:publisher dct:rightsHolder owl:versionInfo}
  ?x a owl:Ontology; ?p ?old
  bind(str(?old) as ?new)
};

