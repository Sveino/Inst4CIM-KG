prefix md:       <http://iec.ch/TC57/61970-552/ModelDescription/1#>
prefix dm:       <http://iec.ch/TC57/61970-552/DifferenceModel/1#>
prefix dcat-cim: <https://cim4.eu/ns/dcat-cim#>
prefix dcat:     <http://www.w3.org/ns/dcat#>
prefix dct:      <http://purl.org/dc/terms/>
prefix json-ld:  <https://www.w3.org/ns/json-ld#>
prefix rdfg:     <http://www.w3.org/2004/03/trix/rdfg-1/>
prefix xsd:      <http://www.w3.org/2001/XMLSchema#>

## Handle single-valued props only, else the blank nodes dcat:Distribution and dct:PeriodOfTime are emitted multiple times
delete {
  graph ?g {
    ?model a ?type;
      md:Model.created              ?created             ;
      md:Model.scenarioTime         ?scenarioTime        ;
      md:Model.description          ?description         ;
      md:Model.modelingAuthoritySet ?modelingAuthoritySet;
      md:Model.version              ?version             ;
      md:Model.Supersedes           ?supersedes          ;
      dm:reverseDifferences         ?reverseDifferences  ;
      dm:forwardDifferences         ?forwardDifferences  .
  }}
insert {
  graph ?g {
    ?model a ?type_new, rdfg:Graph;
      dct:identifier                                     ?model_id                ;
      dct:issued                                         ?created_date            ;
      dcat:distribution [a dcat:Distribution; dct:issued ?created_dateTime      ] ;
      dct:temporal [a dct:PeriodOfTime; dcat:startDate   ?scenario_start          ;        
                                        dcat:endDate     ?scenario_end          ] ;
      dcat:temporalResolution                            ?temporalResolution      ;
      dct:description                                    ?description             ;
      dcat:isVersionOf                                   ?modelingAuthoritySet_url;
      json-ld:base                                       ?base                    ;
      dcat:version                                       ?version_string          ;
      dcat:previousVersion                               ?supersedes              ;
      dcat-cim:reverseDifferenceSet                      ?reverseDifferences      ;
      dcat-cim:forwardDifferenceSet                      ?forwardDifferences      .
  }
  graph ?reverseDifferences {
    ?reverseDifferences a rdfg:Graph, dcat:Resource; dct:title ?reverse_title; dct:identifier ?reverse_id
  }
  graph ?forwardDifferences {
    ?forwardDifferences a rdfg:Graph, dcat:Resource; dct:title ?forward_title; dct:identifier ?forward_id
  }
}
where {
  graph ?g {
    values (?type        ?type_new) {
      (md:FullModel       dcat:Dataset          )
      (dm:DifferenceModel dcat-cim:DifferenceSet)
    }
    ?model a ?type
    bind(strafter(str(?model),"urn:uuid:") as ?model_id)
    optional {?model md:Model.created              ?created
      bind(strdt(strbefore(str(?created),"T"),xsd:date) as ?created_date)
      bind(iri(concat(str(?model),"/distribution")) as ?distribution)
      bind(strdt(str(?created),xsd:dateTime) as ?created_dateTime)}
    optional {?model md:Model.scenarioTime         ?scenarioTime.
      bind(strdt(str(?scenarioTime),xsd:dateTime) as ?scenario_start)
      bind(exists {?model md:Model.profile ?profile filter(regex(str(?profile),"SteadyStateHypothesis|StateVariables|Topology"))} as ?hasEnd)
      bind(if(?hasEnd,?scenario_start+"PT1H"^^xsd:duration,?UNDEF) as ?scenario_end)
      bind(if(?hasEnd,"PT1H"^^xsd:duration,?UNDEF) as ?temporalResolution)}
    optional {?model md:Model.description          ?description}
    optional {?model md:Model.modelingAuthoritySet ?modelingAuthoritySet
      bind(iri(str(?modelingAuthoritySet)) as ?modelingAuthoritySet_url)
      bind(concat(str(?modelingAuthoritySet),"#") as ?base)}
    optional {?model md:Model.version              ?version
      bind(str(?version) as ?version_string)}
    optional {?model md:Model.Supersedes           ?supersedes}
    optional {?model dm:reverseDifferences         ?reverseDifferences
      bind(concat("Reverse Difference Set of ",strafter(str(?model),"urn:uuid:")) as ?reverse_title)
      bind(strafter(str(?reverseDifferences),"urn:uuid:") as ?reverse_id)}
    optional {?model dm:forwardDifferences         ?forwardDifferences
      bind(concat("Forward Difference Set of ",strafter(str(?model),"urn:uuid:")) as ?forward_title)
      bind(strafter(str(?forwardDifferences),"urn:uuid:") as ?forward_id)}
  }};

# Handle multi-valued properties
delete {graph ?g {?model md:Model.profile ?profile}}
insert {graph ?g {?model dct:conformsTo   ?profile_url}}
where  {graph ?g {?model md:Model.profile ?profile
  bind(iri(str(?profile)) as ?profile_url)
}};

delete {graph ?g {?model md:Model.DependentOn ?dependentOn}}
insert {graph ?g {?model dct:requires         ?dependentOn}}
where  {graph ?g {?model md:Model.DependentOn ?dependentOn}};
