<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Intro](#intro)
- [SHACL Notes](#shacl-notes)
- [RDFS2020 vs RDFSEd2Beta](#rdfs2020-vs-rdfsed2beta)
    - [Classes](#classes)
    - [Props](#props)
    - [Individuals](#individuals)

<!-- markdown-toc end -->

## Intro
samuel.dayet@ext.entsoe.eu, Intern in Standardization Team, ENTSO-E
Olivier Aine <olivier.aine@entsoe.eu>,
Erik Wolfs <erik.wolfs@sec.entsoe.eu>,
Eduardo Relano Algaba <eduardo.relanoalgaba@entsoe.eu>,
Fedder Skovgaard <FSD@energinet.dk>

Find attached some of the CGMES 3.0 SHACL shapes to validate EQ profile.
You can find test profiles here in CGMES Conformity Assessment Scheme v3.
Then you can download the Test Configurations v3.0.2 zip file.
In it, you will find several test models and in each of them there is at least one EQ profile.

(sent 3 Jul 2023) Important information about the availability of  SHACL advanced in GraphDB:
- https://rdf4j.org/release-notes/4.3.0_4.3.1/ (May 19, 2023) implements SHACL advanced:
  User defined SPARQL queries in SHACL Constraints and Targets
- https://graphdb.ontotext.com/documentation/10.2/release-notes.html:
  GraphDB 10.2.1 (released 25 April 2023) uses RDF4J 4.2.3 (released Feb 11, 2023)
  There's a lag of 1-2 months between RDF4J releases and their incorporation in GraphDB.
- GraphDB 10.2.2 was released 7 June 2023.
- GraphDB 10.3.0 was released on 17 Jul 2023 and incorporates RDF4J 4.3.3, thus SHACL Advanced.
  - doc: https://graphdb.ontotext.com/documentation/10.3/shacl-validation.html#sparql-capabilities-in-shacl-shapes
  - release notes: https://graphdb.ontotext.com/documentation/10.3/shacl-validation.html#sparql-capabilities-in-shacl-shapes
    GDB-7427 As a data architect, I want to have SPARQL capabilities in SHACL shapes

## SHACL Notes

IEC61970-600-2_CGMES_3_0_1_ApplicationProfiles\v3.0\SHACL includes 75 SHACL files, what is their status?
I looked at one of them and here are some questions.
If you can answer them, that will help me provide more relevant observations.

SHACL\Common\IdentifiedObjecStringLength.ttl notes:
- sh:declare should be attached to the Shapes Graph, see https://w3c.github.io/data-shapes/shacl/#sparql-prefixes.
  It's not obvious to me that the cim: ontology URL will also serve as the shapes graph.
- The shapes in this file use `sh:targetNode cim:IdentifiedObjectStringLength`.
  So are they triggered globally? Not attached to relevant CIM classes?
- These are simple literal length checks, so they can be implemented with sh:minLength/sh:maxLength
  (see https://w3c.github.io/data-shapes/shacl/#core-components-string).
  But they are all implemented with sh:SPARQLConstraint, which is more expensive!
- They all check a subject `?s` but return `$this`, what's the relation between these variables?

EQ_600-2.ttl notes:
- `cim: sh:declare ...`: it's better to attach the prefixes to the specific ontology `eq600:Ontology` that defines the shapes
- `eq600:TapChanger.neutralU-valueRangePairSparql`:
  - Should be implemented as `sh:equals` (and an alternate property path) rather than the more expensive SPARQL constraint
  - It binds `?rratedu` or `?pratedu` but returns and reports only  `?rratedu`
  - As written, it will succeed if `TapChanger.neutralU` exists but `PowerTransformerEnd.ratedU` doesn't exist, is this really intended?
- `eq600:SubstationCountShape`:
  - `sh:targetNode cim:SubstationCount`: this won't be triggered unless such a fake node is inserted in the data
  - Isn't it better to lay the blame on the model node, not on this fake node?
  - It tries to find violation "Substation per VoltageLevel" by the check `?substations=?voltagelevels`. But if it's legitimate to have a VoltageLevel without any Substations, that check is not correct. Instead, it should look for VoltageLevels with only 1 Substation
- `eq600:ReactiveCapabilityCurve-unitsSparql`: `?hasy2unit` will be true because the previous line fetches `cim:Curve.y2Unit` without OPTIONAL. This means the FILTER can never succeed and this rule will never return violations. Instead, if you need to check that `Curve.xUnit, Curve.y1Unit, Curve.y2Unit` are present, you need to write a different rule (`minCount=maxCount=1`)
   - Then you don't need an expensive SPARQL check, you can use `sh:hasValue`
   - Split it into 3 rules per property, and use those properties as `sh:path` instead of blaming `rdf:type`

## RDFS2020 vs RDFSEd2Beta

Comparing these two files:
- RDFS2020\IEC61970-600-2_CGMES_3_0_0_RDFS2020_DL
- RDFSEd2Beta\RDFS\IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_DL

### Classes
```ttl
@prefix dl:      <http://iec.ch/TC57/ns/CIM/DiagramLayout-EU#> .
@prefix cims:    <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> .

cim:AngleDegrees  rdf:type      rdfs:Class ;
        rdfs:comment            "Measurement of angle in degrees." ;
        rdfs:label              "AngleDegrees"@en ;
        cims:belongsToCategory  dl:Package_DiagramLayoutProfile ;
        cims:stereotype         "CIMDatatype" .

cim:AngleDegrees  rdf:type  owl:Class ;
        rdfs:label        "AngleDegrees"@en ;
        skos:definition   "\nMeasurement of angle in degrees.\n\n\t"@en ;
        dl:Package        "Package_DiagramLayoutProfile" ;
        dl:isCIMDatatype  "True" .
```
- `rdfs:Class` vs `owl:Class`
- `rdfs:Comment` vs `skos:definition`, and the formatting is worse
- `cims:belongsToCategory` (resource) vs `dl:Package` (string)
- `cims:stereotype "CIMDatatype"` vs `dl:isCIMDatatype "True"`

```
 grep  -i "isFixed.*true" *.ttl|uniq -c
      2 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_DL.ttl:        dl:isFixed   "True " .
     20 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_DY.ttl:        dy:isFixed   "True " .
     43 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_EQ.ttl:        eq:isFixed   "True " .
      2 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_EQBD.ttl:    eqbd:isFixed   "True " .
      2 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_OP.ttl:        op:isFixed   "True " .
     24 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_SC.ttl:        sc:isFixed   "True " .
     22 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_SSH.ttl:      ssh:isFixed   "True " .
     10 IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_SV.ttl:        sv:isFixed   "True " .
```

- `cims:` was used for metadata fields, now it's `dl:` vs `eq:` etc (why??)

### Props
```ttl
cim:AngleDegrees.multiplier
        rdf:type           rdf:Property ;
        rdfs:domain        cim:AngleDegrees ;
        rdfs:range         cim:UnitMultiplier ;
        cims:isFixed       "none" ;
        rdfs:label         "multiplier"@en ;
        cims:multiplicity  cims:M:0..1 ;
        cims:stereotype    <http://iec.ch/TC57/NonStandard/UML#attribute> .
cim:IdentifiedObject.mRID
        rdf:type           rdf:Property ;
        cims:multiplicity  cims:M:1..1 .

cim:AngleDegrees.multiplier
        rdf:type     owl:FunctionalProperty , owl:DatatypeProperty ;
        rdfs:domain  cim:AngleDegrees ;
        rdfs:range   cim:UnitMultiplier ;
        rdfs:label   "multiplier"@en ;
        rdf:value    "none" ;
        dl:isFixed   "True " .
cim:IdentifiedObject.mRID
        rdf:type         owl:DatatypeProperty ;
```
- generic `rdf:Property` is replaced with specific `owl:DatatypeProperty` vs `owl:ObjectProperty`
- `cims:multiplicity cims:M:0..1` vs `owl:FunctionalProperty`.
  Unfortunately, `cims:M:1..1` is not mapped to anything: hopefully SHACL takes care of that
- `cims:isFixed` is broken into two: `rdf:value, dl:isFixed`
- no `cims:stereotype`

```ttl
cim:AngleDegrees.value
        cims:dataType      cim:Float .
cim:Float  rdf:type             rdfs:Class ;
        rdfs:label              "Float"@en ;
        rdfs:comment            "A floating point number. The range is unspecified and not limited." ;
        cims:belongsToCategory  dl:Package_DiagramLayoutProfile ;
        cims:stereotype         "Primitive" .

cim:AngleDegrees.value
        rdfs:range   xsd:float .
cim:Float  rdf:type      owl:Class ;
        rdfs:label       "Float"@en ;
        skos:definition  "\nA floating point number. The range is unspecified and not limited.\n\n\t"@en ;
        dl:Package       "Package_DiagramLayoutProfile" ;
        dl:isPrimitive   "True" .
```
- `cims:dataType cim:Float` ("primitive" datatype that in reality maps to XSD) vs `rdfs:range xsd:float` (use XSD datatype)
- Nevertheless, the primitive datatypes are still defined (and still are wrongly declared as `Class`)

```ttl
cim:ACDCConverter.maxP
        rdf:type           rdf:Property ;
        cims:dataType      cim:ActivePower ;
        cims:multiplicity  cims:M:0..1 ;

cim:ACDCConverter.maxP
        rdf:type         owl:FunctionalProperty , owl:DatatypeProperty ;
        rdfs:range       cim:ActivePower ;
```

- In some cases `rdfs:range` is used with a "primitive" datatype (eg `cim:ActivePower`),
  although for all such types `isFixed` is always "True", i.e. only a number is used in instance data (no unit/multiplier)

```ttl
cim:ACDCConverter.PccTerminal
        cims:inverseRoleName  cim:Terminal.ConverterDCSides .

cim:ACDCConverter.PccTerminal
        owl:inverseOf    cim:Terminal.ConverterDCSides .
```
- `cims:inverseRoleName` vs real `owl:inverseOf`

### Individuals

```ttl
cim:UnitMultiplier.M  rdf:type  cim:UnitMultiplier ;
        rdfs:comment     "Mega 10**6." ;
        rdfs:label       "M"@en ;
        cims:stereotype  "enum" .

cim:UnitMultiplier.M  rdf:type  owl:NamedIndividual , owl:Thing ;
        rdfs:domain      cim:UnitMultiplier ;
        rdfs:label       "M "@en ;
        dl:isenum        "True" ;
        skos:definition  "Mega 10**6."@en .
```
- `rdf:type cim:UnitMultiplier` (right) vs `rdfs:domain cim:UnitMultiplier` (wrong)
- Now has `owl:NamedIndividual, owl:Thing`, which are useless
