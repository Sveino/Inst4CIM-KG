# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#whitespace-in-definitions
# https://github.com/Sveino/Inst4CIM-KG/issues/6

delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  ?x ?p ?old
  filter(isLiteral(?old))
  bind(str(?old) as ?oldStr)
  filter(regex(?oldStr,"^\\s|\\s$"))
  bind(replace(replace(?oldStr,"^\\s+",""),"\\s+$","") as ?newStr)
  bind(if(lang(?old)!="",strlang(?newStr,lang(?old)),?newStr) as ?new)
};

# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#use-standard-datatypes
# https://github.com/Sveino/Inst4CIM-KG/issues/74
# https://github.com/Sveino/Inst4CIM-KG/issues/28
# https://github.com/Sveino/Inst4CIM-KG/issues/64

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 
PREFIX eu: <https://cim.ucaiug.io/ns/eu#>
PREFIX eumd: <https://cim4.eu/ns/Metadata-European#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX profcim: <https://cim.ucaiug.io/ns/prof-cim#> 
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

delete {?prop cims:dataType ?old}
insert {?prop rdfs:range    ?new}
where {
  values (?old ?new) {
    (cim:Boolean                 xsd:boolean      )
    (cim:Date                    xsd:date         )
    (cim:DateTime                xsd:dateTime     )
    (cim:Decimal                 xsd:decimal      )
    (cim:Duration                xsd:duration     )
    (cim:Float                   xsd:float        )
    (cim:Integer                 xsd:integer      )
    (cim:MonthDay                xsd:gMonthDay    )
    (cim:String                  xsd:string       )
    (cim:Time                    xsd:time         )
    (eu:URI                      xsd:anyURI       )
    (eumd:DateTimeStamp          xsd:dateTimeStamp)
    (profcim:URL                 xsd:anyURI       )
    (profcim:IRI                 xsd:anyURI       )
    (profcim:StringFixedLanguage xsd:string       )
    (profcim:StringIRI           xsd:string       )
  }
  ?prop cims:dataType ?old
};

delete {?old ?p ?y}
where {
  ?old cims:stereotype "Primitive"; ?p ?y
};

# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 

# https://github.com/Sveino/Inst4CIM-KG/issues/76
delete {cim:ActivePowerPerFrequency.unit cims:isFixed "WPers"}
insert {
  cim:ActivePowerPerFrequency.unit cims:isFixed "WPerHz".
  cim:UnitSymbol.WPerHz a cim:UnitSymbol ;
    rdfs:label "WPerHz" ;
    rdfs:comment "Active power variation with frequency in watts per hertz." ;
    cims:stereotype "enum"
} where  {cim:ActivePowerPerFrequency.unit cims:isFixed "WPers"};

# https://github.com/Sveino/Inst4CIM-KG/issues/77
delete {cim:VoltagePerReactivePower.multiplier cims:isFixed "none"}
insert {cim:VoltagePerReactivePower.multiplier cims:isFixed "k"}
where  {cim:VoltagePerReactivePower.multiplier cims:isFixed "none"};

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

# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure
# https://github.com/Sveino/Inst4CIM-KG/issues/38
# https://github.com/Sveino/Inst4CIM-KG/issues/29

prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix prefix: <http://qudt.org/vocab/prefix/>
prefix qudt: <http://qudt.org/schema/qudt/>
prefix quantitykind: <http://qudt.org/vocab/quantitykind/> 
prefix unit: <http://qudt.org/vocab/unit/>

# map QuantityKinds
insert {?qk skos:exactMatch ?quantitykind}
where {
  values (?qk                           ?quantitykind) {
         (cim:ActivePower               quantitykind:ActivePower              )
         (cim:ActivePowerChangeRate     quantitykind:ActivePowerChangeRate    )
         (cim:ActivePowerPerCurrentFlow quantitykind:ActivePowerPerCurrentFlow)
         (cim:ActivePowerPerFrequency   quantitykind:ActivePowerPerFrequency  )
         (cim:AngleDegrees              quantitykind:Angle                    )
         (cim:AngleRadians              quantitykind:Angle                    )
         (cim:ApparentPower             quantitykind:ApparentPower            )
         (cim:Area                      quantitykind:Area                     )
         (cim:Capacitance               quantitykind:Capacitance              )
         (cim:Conductance               quantitykind:Conductance              )
         (cim:CurrentFlow               quantitykind:ElectricCurrent          )
         (cim:Frequency                 quantitykind:Frequency                )
         (cim:Impedance                 quantitykind:Inductance               )
         (cim:Length                    quantitykind:Length                   )
         (cim:Money                     quantitykind:Currency                 )
         (cim:PU                        quantitykind:DimensionlessRatio       )
         (cim:PerCent                   quantitykind:DimensionlessRatio       )
         (cim:Pressure                  quantitykind:Pressure                 )
         (cim:Reactance                 quantitykind:Reactance                )
         (cim:ReactivePower             quantitykind:ReactivePower            )
         (cim:RealEnergy                quantitykind:Energy                   )
         (cim:Resistance                quantitykind:Resistance               )
         (cim:RotationSpeed             quantitykind:AngularVelocity          )
         (cim:Seconds                   quantitykind:Time                     )
         (cim:Susceptance               quantitykind:Susceptance              )
         (cim:Temperature               quantitykind:Temperature              )
         (cim:Voltage                   quantitykind:Voltage                  )
         (cim:VoltagePerReactivePower   quantitykind:VoltagePerReactivePower  )
         (cim:VolumeFlowRate            quantitykind:VolumeFlowRate           )
  }
  ?qa a qudt:QuantityKind
};

# map UnitMultipliers
insert {?multiplier qudt:prefixMultiplier ?prefixMultiplier; skos:exactMatch ?exactMatch}
where {
  values (?multiplier             ?prefixMultiplier ?exactMatch ) {
         (cim:UnitMultiplier.none 1.0               UNDEF       )
         (cim:UnitMultiplier.k    1.0E3             prefix:Kilo )
         (cim:UnitMultiplier.M    1.0E6             prefix:Mega )
  }
  ?multiplier a cim:UnitMultiplier
};

# map UnitSymbols
insert {?unit ?rel ?unitQudt}
where {
  values (?unit                   ?rel            ?unitQudt              ) {
         (cim:UnitSymbol.A        skos:exactMatch unit:A                 )
         (cim:UnitSymbol.F        skos:exactMatch unit:FARAD             )
         (cim:UnitSymbol.Hz       skos:exactMatch unit:HZ                )
         (cim:UnitSymbol.Hz       skos:narrower   unit:REV-PER-SEC       )
         (cim:UnitSymbol.Pa       skos:exactMatch unit:PA                )
         (cim:UnitSymbol.S        skos:exactMatch unit:S                 )
         (cim:UnitSymbol.V        skos:exactMatch unit:V                 )
         (cim:UnitSymbol.VA       skos:exactMatch unit:V-A               )
         (cim:UnitSymbol.VAr      skos:exactMatch unit:V-A_Reactive      )
         (cim:UnitSymbol.VPerVAr  skos:exactMatch unit:V-PER-V-A_Reactive)
         (cim:UnitSymbol.W        skos:exactMatch unit:W                 )
         (cim:UnitSymbol.WPerA    skos:exactMatch unit:W-PER-A           )
         (cim:UnitSymbol.WPerHz   skos:exactMatch unit:W-PER-HZ          )
         (cim:UnitSymbol.WPers    skos:exactMatch unit:W-PER-SEC         )
         (cim:UnitSymbol.Wh       skos:exactMatch unit:W-HR              )
         (cim:UnitSymbol.deg      skos:exactMatch unit:DEG               )
         (cim:UnitSymbol.degC     skos:exactMatch unit:DEG_C             )
         (cim:UnitSymbol.m        skos:exactMatch unit:M                 )
         (cim:UnitSymbol.m2       skos:exactMatch unit:M2                )
         (cim:UnitSymbol.m3Pers   skos:exactMatch unit:M3-PER-SEC        )
         (cim:UnitSymbol.ohm      skos:exactMatch unit:OHM               )
         (cim:UnitSymbol.rad      skos:exactMatch unit:RAD               )
         (cim:UnitSymbol.s        skos:exactMatch unit:SEC               )
  }
  ?unit a cim:UnitSymbol
};

# map data properties
insert {?prop qudt:hasUnit ?unitQudt}
where {
  values (?qk                           ?multiplier              ?unit                   ?unitQudt                  ) {
         (cim:ActivePower               cim:UnitMultiplier.M     cim:UnitSymbol.W        unit:MegaW                 )
         (cim:ActivePowerChangeRate     cim:UnitMultiplier.M     cim:UnitSymbol.WPers    unit:MegaW-PER-SEC         )
         (cim:ActivePowerPerCurrentFlow cim:UnitMultiplier.M     cim:UnitSymbol.WPerA    unit:MegaW-PER-A           )
         (cim:ActivePowerPerFrequency   cim:UnitMultiplier.M     cim:UnitSymbol.WPerHz   unit:MegaW-PER-HZ          )
         (cim:AngleDegrees              cim:UnitMultiplier.none  cim:UnitSymbol.deg      unit:DEG                   )
         (cim:AngleRadians              cim:UnitMultiplier.none  cim:UnitSymbol.rad      unit:RAD                   )
         (cim:ApparentPower             cim:UnitMultiplier.M     cim:UnitSymbol.VA       unit:MegaV-A               )
         (cim:Area                      cim:UnitMultiplier.none  cim:UnitSymbol.m2       unit:M2                    )
         (cim:Capacitance               cim:UnitMultiplier.none  cim:UnitSymbol.F        unit:FARAD                 )
         (cim:Conductance               cim:UnitMultiplier.none  cim:UnitSymbol.S        unit:S                     )
         (cim:CurrentFlow               cim:UnitMultiplier.none  cim:UnitSymbol.A        unit:A                     )
         (cim:Frequency                 cim:UnitMultiplier.none  cim:UnitSymbol.Hz       unit:HZ                    )
         (cim:Impedance                 cim:UnitMultiplier.none  cim:UnitSymbol.ohm      unit:OHM                   )
         (cim:Length                    cim:UnitMultiplier.k     cim:UnitSymbol.m        unit:KiloM                 )
         (cim:PerCent                   cim:UnitMultiplier.none  cim:UnitSymbol.none     unit:PERCENT               )
         (cim:Pressure                  cim:UnitMultiplier.k     cim:UnitSymbol.Pa       unit:KiloPA                )
         (cim:Reactance                 cim:UnitMultiplier.none  cim:UnitSymbol.ohm      unit:OHM                   )
         (cim:ReactivePower             cim:UnitMultiplier.M     cim:UnitSymbol.VAr      unit:MegaV-A_Reactive      )
         (cim:RealEnergy                cim:UnitMultiplier.M     cim:UnitSymbol.Wh       unit:MegaW-HR              )
         (cim:Resistance                cim:UnitMultiplier.none  cim:UnitSymbol.ohm      unit:OHM                   )
         (cim:RotationSpeed             cim:UnitMultiplier.none  cim:UnitSymbol.Hz       unit:REV-PER-SEC           )
         (cim:Seconds                   cim:UnitMultiplier.none  cim:UnitSymbol.s        unit:SEC                   )
         (cim:Susceptance               cim:UnitMultiplier.none  cim:UnitSymbol.S        unit:S                     )
         (cim:Temperature               cim:UnitMultiplier.none  cim:UnitSymbol.degC     unit:DEG_C                 )
         (cim:Voltage                   cim:UnitMultiplier.k     cim:UnitSymbol.V        unit:KiloV                 )
         (cim:VoltagePerReactivePower   cim:UnitMultiplier.k     cim:UnitSymbol.VPerVAr  unit:KiloV-PER-V-A_Reactive)
         (cim:VolumeFlowRate            cim:UnitMultiplier.none  cim:UnitSymbol.m3Pers   unit:M3-PER-SEC            )
  }
  ?prop
    qudt:hasQuantityKind ?qk;
    cim:unitMultiplier   ?multiplier;
    cim:unitSymbol       ?unit
};


# https://github.com/Sveino/Inst4CIM-KG/issues/75

PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

# move classes from RDFS to OWL
delete {?class a rdfs:Class}
insert {?class a owl:Class}
where  {?class a rdfs:Class};

# if range is XSD then DatatypeProperty
delete {?prop a rdf:Property}
insert {?prop a owl:DatatypeProperty}
where {
  ?prop a rdf:Property; rdfs:range ?dt
  filter(strstarts(str(?dt),str(xsd:)))
};

# else ObjectProperty
delete {?prop a rdf:Property}
insert {?prop a owl:ObjectProperty}
where {?prop a rdf:Property};
# https://github.com/Sveino/Inst4CIM-KG/issues/26

prefix cims:         <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
prefix owl:          <http://www.w3.org/2002/07/owl#>

delete {?p cims:inverseRoleName ?q}
insert {?p owl:inverseOf ?q}
where {?p cims:inverseRoleName ?q};

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

# https://github.com/Sveino/Inst4CIM-KG/issues/72

prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>

delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  ?x ?p ?old
  filter(datatype(?old) = rdf:XMLLiteral)
  bind(str(?old) as ?new)
};

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

# https://github.com/Sveino/Inst4CIM-KG/issues/24

prefix cims:         <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
prefix owl:          <http://www.w3.org/2002/07/owl#>

delete {?p cims:stereotype "deprecated"}
insert {?p owl:deprecated true}
where  {?p cims:stereotype "deprecated"};

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

