# https://github.com/Sveino/Inst4CIM-KG/issues/93

prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>

delete {?x rdfs:label ?oldLabel; rdfs:comment ?oldComment}
insert {?x rdfs:label ?newLabel; rdfs:comment ?newComment}
where {
  ?x rdfs:label ?oldLabel; rdfs:comment ?oldComment
  bind(lang(?oldLabel) as ?lang)
  filter(?lang="" || ?lang="en")  # safeguard in case multiple langs are added: that would get mixed up
  bind(str(?oldLabel) as ?newLabel)
  bind(strlang(?oldComment,"en") as ?newComment)
};

