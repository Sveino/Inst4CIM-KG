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

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 
PREFIX eu: <https://cim.ucaiug.io/ns/eu#>
PREFIX eumd: <https://cim4.eu/ns/Metadata-European#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX profcim: <https://cim.ucaiug.io/ns/prof-cim#> 
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

delete {?prop a rdf:Property;         cims:dataType ?old}
insert {?prop a owl:DatatypeProperty; rdfs:range    ?new}
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
  ?prop a rdf:Property; cims:dataType ?old
};

delete {?old ?p ?y}
where {
  ?old cims:stereotype "Primitive"; ?p ?y
};

