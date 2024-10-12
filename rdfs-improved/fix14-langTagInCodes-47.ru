# https://github.com/Sveino/Inst4CIM-KG/issues/47
# This is now subsumed by fix16-langTagLabelVsDefinition.ru (https://github.com/Sveino/Inst4CIM-KG/issues/93)
#delete {?x rdfs:label ?old}
#insert {?x rdfs:label ?new}
#where {
#  values ?enumOfCodes {cim:Currency cim:IfdBaseKind cim:PhaseCode cim:StaticLoadModelKind cim:UnitMultiplier cim:UnitSymbol cim:WindingConnection}
#  ?x a ?enumOfCodes; rdfs:label ?old
#  filter(lang(?old) != "")
#  bind(str(?old) as ?new)
#};

