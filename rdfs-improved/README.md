# Improvements to CIM and CGMES RDFS Representation 

This document describes proposed inprovements to the representation of CIM/CGMES ontologies.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Improvements to CIM and CGMES RDFS Representation ](#improvements-to-cim-and-cgmes-rdfs-representation)
    - [Source Files](#source-files)
    - [RDF Serializations](#rdf-serializations)
        - [Turtle Serialization](#turtle-serialization)
            - [atextor tools: owl-cli and turtle-formatter](#atextor-tools-owl-cli-and-turtle-formatter)
            - [EDMC Tools for serialization, diff, hygiene checks, publication](#edmc-tools-for-serialization-diff-hygiene-checks-publication)
            - [OBO Robot](#obo-robot)
        - [JSON-LD Serialization](#json-ld-serialization)
            - [JSON-LD Context](#json-ld-context)
            - [Coverting to JSON-LD as a Debugging Tool](#coverting-to-json-ld-as-a-debugging-tool)
        - [RDF/XML Serialization](#rdfxml-serialization)
- [Fixes](#fixes)
    - [Use Only One of RDFS2020 and RDFSEd2Beta Style](#use-only-one-of-rdfs2020-and-rdfsed2beta-style)
        - [Namespace Discrepancies in RDFS2020 CGMES vs NC](#namespace-discrepancies-in-rdfs2020-cgmes-vs-nc)
    - [Merge and Fix DatasetMetadata, Header, FileHeader](#merge-and-fix-datasetmetadata-header-fileheader)
    - [Fixes to Ontology Metadata](#fixes-to-ontology-metadata)
    - [Add rdfs:isDefinedBy](#add-rdfsisdefinedby)
    - [Duplication Between Ontologies](#duplication-between-ontologies)
        - [Duplicated Definitions](#duplicated-definitions)
        - [Duplicated Terms](#duplicated-terms)
        - [Duplication Summary](#duplication-summary)
    - [Prefixes](#prefixes)
        - [Mis-defined Prefixes](#mis-defined-prefixes)
        - [Too Many Prefixes](#too-many-prefixes)
    - [Improve Ordering of Ontology Terms](#improve-ordering-of-ontology-terms)
    - [Terms Per Namespace](#terms-per-namespace)
    - [Namespace Hijacking](#namespace-hijacking)
    - [Meta-Props Duplicated Per Profile](#meta-props-duplicated-per-profile)
    - [Remove Unused Enumeration Classes](#remove-unused-enumeration-classes)
    - [Wrong Declaration of Enumerations](#wrong-declaration-of-enumerations)
    - [Fix Representation of NamedIndividuals](#fix-representation-of-namedindividuals)
    - [Mis-declared Packages](#mis-declared-packages)
    - [Whitespace in Definitions](#whitespace-in-definitions)
    - [Datatype XMLLiteral in Definitions](#datatype-xmlliteral-in-definitions)
    - [LangTag in Label vs Definition](#langtag-in-label-vs-definition)
    - [Whitespace and Lang Tags in Key Values](#whitespace-and-lang-tags-in-key-values)
    - [HTML Tags and Escaped Entities in Definitions](#html-tags-and-escaped-entities-in-definitions)
    - [Use Standard Datatypes](#use-standard-datatypes)
        - [Multilinguality in CIM?](#multilinguality-in-cim)
        - [rdf:PlainLiteral](#rdfplainliteral)
    - [Deprecated Properties](#deprecated-properties)
    - [Change Class and Property Kinds](#change-class-and-property-kinds)
    - [Use Standard `inverseOf` Property](#use-standard-inverseof-property)
    - [Express Multiplicity in OWL](#express-multiplicity-in-owl)
    - [QuantityKinds and Units of Measure](#quantitykinds-and-units-of-measure)
        - [Fixed Units Representation](#fixed-units-representation)
        - [Fixed Multipliers Representation](#fixed-multipliers-representation)
        - [Property Datatype Maps](#property-datatype-maps)
        - [Actual QuantityKinds](#actual-quantitykinds)
        - [Actual Multipliers and Units](#actual-multipliers-and-units)
        - [Mapping QuantityKinds and Units](#mapping-quantitykinds-and-units)
        - [Mapping Unit Multipliers](#mapping-unit-multipliers)
        - [All QuantityKinds, Units and Multipliers](#all-quantitykinds-units-and-multipliers)
    - [Represent Models as Named Graphs](#represent-models-as-named-graphs)
- [Fix Technical Notes](#fix-technical-notes)
    - [Fix Structure](#fix-structure)
    - [Fix Debugging](#fix-debugging)
    - [Fix Ordering and List](#fix-ordering-and-list)

<!-- markdown-toc end -->

## Source Files
We start from these RDFS renditions, which are the latest versions of CIM/CGMES and CGMES-NC respectively:
- https://www.entsoe.eu/Documents/CIM_documents/Grid_Model_CIM/IEC61970-600-2_CGMES_3_0_1_ApplicationProfiles.zip folder `v3.0/RDFS2020`.
  Available locally in [source/CGMES/v3.0/RDFS2020](../source/CGMES/v3.0/RDFSEd2Beta/RDFS)
- https://github.com/Sveino/CGMES-NC/tree/develop/r2.3/ap-voc/rdf
  Available locally in [source/CGMES-NC/r2.3/ap-voc/rdf](../source/CGMES-NC/r2.3/ap-voc/rdf)

## RDF Serializations

Originally CIM/CGMES is modeled in UML, from which the ontologies were extracted as RDF/XML.
- [x] We agreed to adopt Turtle as master format, so we need to produce "good looking" and stable Turtle (see [Turtle Serialization](#turtle-serialization)).
  In the process of conversion we also apply all ontology [Fixes](#fixes) described below.
- [x] Then we produce good JSON-LD (see [JSON-LD Serialization](#json-ld-serialization)).

TODO:
- [ ] Agree folder structure: `rdf` vs `ttl` vs `jsonld`.
  - But given the multitude of subfolders in `source/CGMES/v3.0/SHACL`, where do we make the format subfolders
  - For now I make the latter two but don't copy `rdf`
- [x] Automate the conversion: I did it with a Makefile
  - Or see [spotless](https://github.com/diffplug/spotless/), which is used to automate file manipulation in a project

### Turtle Serialization
What tool to use to format Turtle? Requirements:
- Do it in a predictable way
- The conversion should be stable, i.e. diff-friendly
- Should be able to sort by term kind

A relevant thread "Diff'ing RDF files" appeared on the <semantic-web@w3.org> and <public-rdf-star-wg@w3.org> mailing lists in [Sep 2024](https://lists.w3.org/Archives/Public/semantic-web/2024Sep/0011.html).
It mentions the atextor tools (my current choice), EDMC tools, and ROBOT.

Here is a list of tools. But I have made sub-sections for the most promising ones (see below):
- For a long time I used Jena `riot`.
  - It has Formatted and Streaming mode (better for very large files)
  - But has no options how to sort terms
  - Invocation command:
```
riot --formatted ttl IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_EQ.rdf > IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_EQ.ttl
```
- [rdflib#2880 about longturtle](https://github.com/RDFLib/rdflib/issues/2880) which is a request to add pretty-printing features to Python's `rdflib`

#### atextor tools: owl-cli and turtle-formatter
This is my current selection:

[atextor/turtle-formatter](https://github.com/atextor/turtle-formatter) is a Jena/Java tool specifically for this purpose.
- Under active development and the author is responsive
- Incorporated in the `owl-cli` tool ([owl-cli-snapshot.jar](https://github.com/atextor/owl-cli/releases/download/snapshot/owl-cli-snapshot.jar))
- See usage guide of [write-command](https://atextor.de/owl-cli/main/snapshot/usage.html#write-command)
- QUDT is also likely to use it: [qudt-public-repo#959](https://github.com/qudt/qudt-public-repo/issues/959)
- Invocation (where `owl.bat` is `java -jar owl-cli-snapshot.jar %*`)
```
owl.bat write <many-options> --input=rdfxml <source.rdf> <target.ttl>
```

Features of `turtle-formatter` (`owl-cli`) that we use:
- First sort CIM-related prefixes, then others (see `Makefile`).
  IMHO there's too many prefixes, so the profile prefixes should be removed: https://github.com/Sveino/Inst4CIM-KG/issues/4
- Sort by term kind: ontology, classes, object properties, data properties, individuals
- Don't align predicates and objects since that leaves too much whitespace (a matter of preference)

We'll watch closely its development and fixes.
I posted a large number of issues. As of 26-Sep-2024:
- https://github.com/atextor/turtle-formatter/issues/created_by/vladimiralexiev (10). The important ones are:
  - #22 section sorting:
    I want to sort all props alphabetically, but currently it is not possible (`ObjectProperty` first, `DatatypeProperty` next)
  - #27 prefixes trouble when using `--subjectOrder`:
    rdfs:Class comes before `owl:Ontology`
  - #32 `prefixAlign=left` makes invalid turtle:
    So we use  `prefixAlign=right`
  - #33 `--useCommaByDefault` not respected on source build of owl-cli:
    So multiple values of eg `dct:conformsTo` are printed on separate lines, with the property repeated
  - #38 Use `base` in Turtle (when present in the RDF/XML)
- https://github.com/atextor/owl-cli/issues/created_by/vladimiralexiev (8).  The important ones are:
  - #21 make frequent binary releases:
    Until automated, we need to build ourselves to pick up the latest features.
    For linux, see [Building from Source](https://atextor.de/owl-cli/main/snapshot/index.html#building-from-source)
  - #22 how to build on Windows (troubles with Cygwin):
    For Windows, see how I did it
  - #16 location-mapping.ttl missing:
    This prints a nasty warning, but is harmless
  - #14 log messages should go to STDERR not STDOUT bug:
    It just means that we must specify the output filename when running it

#### EDMC Tools for serialization, diff, hygiene checks, publication
https://github.com/Sveino/Inst4CIM-KG/issues/58

Elisa Kendall (one of the main FIBO ontologists):

There is an open-source tool available from the EDM Council for converting between RDF/XML, Turtle, and JSON-LD and for consistent serialization of any of these representations of RDF and OWL. The GitHub site for it is https://github.com/edmcouncil/rdf-toolkit. It is actively maintained, freely available, and addresses a number of issues mentioned on the thread, among other things. It also allows users to turn any of its features on/off as desired. It runs on the command line, or can be invoked automatically through GitHub commit hooks, for example.

For collaborative work across development teams for large ontology projects, consistent serialization for comparison purposes was one of our first and relatively important issues. It enables visual comparison in GitHub (and likely other source code management systems), so that anyone reviewing the changes can see exactly what changed, down to the single character level.

We also have a pipeline that looks for a myriad of issues in ontologies, performs regression testing using examples and reference data, and includes an html-based publication process that itself has a comparison feature, enabling comparison of any pull request or prior release with another version or with the latest version. The code for this is also open source, available from the EDM Council GitHub repository, though support is required for hosting and customization.

- https://spec.edmcouncil.org/fibo/ontology/ it's really quite an interesting system for publishing an ontology.
- Is there a document explaining how all the EDMCouncil tools are stitched together to achieve this?
- Paweł Garbacz: see [An Infrastructure for Collaborative Ontology Development](https://ebooks.iospress.nl/pdf/doi/10.3233/FAIA210375).
  Dean Allemang, Pawel Garbacz, Przemysław Grądzki, Elisa Kendall, Robert Trypuz.
  Formal Ontology in Information Systems, DOI 10.3233/FAIA210375

#### OBO Robot
https://robot.obolibrary.org/ . Download `robot.jar` from the [ROBOT releases](https://github.com/ontodev/robot/releases) page
- By the OBO Foundry
- Used by EDM Council. Elisa: I don’t know how well it works on RDF alone, mainly because I haven’t attempted to use it for that, but it works well as a companion tool to the RDF Toolkit
- Used in the [Emacs Literate Ontology Tool](https://github.com/johanwk/elot/) by Johan Wolter Kluwer (DNV) and Vladimir Alexiev (Ontotext).
  This tool is used in the development of the Industrial Data Ontology.
- Axiomatic diff
- Output Turtle
- Run SPARQL and capture results
- Convert Manchester notation
- Ontology metrics

### JSON-LD Serialization
https://github.com/Sveino/Inst4CIM-KG/issues/99

To produce good JSON-LD serialization of the ontologies, we use the experience from [GS1 EPCIS](https://github.com/gs1/EPCIS), see [Ontology#conversion-to-jsonld](https://github.com/gs1/EPCIS/tree/master/Ontology#conversion-to-jsonld).
We have considered several tools, and use the first two:
- [ttl2jsonld](https://github.com/frogcat/ttl2jsonld). 
  Install with: `npm install -g @frogcat/ttl2jsonld`
  - Pro: converts Turtle to JSON-LD, preserves order
  - Pro (if needed): emits lists in short-hand
    - eg `"@type":"owl:Class", "owl:unionOf":{"@list":[{"@id":"Class1"}, {"@id":"Class2"}]}}}`
  - Cons: generates a simple context using only the Turtle prefixes
  - Cons: can't specify a custom context
- [jsonld-cli](https://github.com/digitalbazaar/jsonld-cli). 
  It's the same code that drives the [JSON-LD Playground](https://json-ld.org/playground).  
  Install with: `npm install -g jsonld-cli`.
  See [gs1/EPCIS#jsonld-cli](https://github.com/gs1/EPCIS/blob/master/Turtle/README.md#jsonld-cli) for further advice.
  - Cons: can't convert Turtle to JSON-LD, see [digitalbazaar/jsonld-cli#19](https://github.com/digitalbazaar/jsonld-cli/issues/19)
  - Pro: can compact JSON-LD properties while preserving compact lists
  - Pro: can specify custom context
  - Cons: the context must be a file (or URL), cannot be inline
    Uses this specific syntax for the filename: `jsonld compact -c file://*.jsonld`
    - The context cannot be embedded in the output to make the JSONLD self-contained
    - Emits the same filename as remote context in the output: this relative URL is not ok
- [Jena riot](https://jena.apache.org/download/index.cgi)
  Download and install Apache Jena Commands
  - Pro: can convert Turtle to JSON-LD and back
  - Cons: doesn't preserve term order
  - Cons: emits lists as `rdf:List` long-hand using blank nodes and first/rest
  - Cons: can't specify a custom context
  - Pro: generates a richer context by examining the values of each property and defining prop characteristics
    - Eg `{"@context": {"rdfs:range" : {"@type" : "@id"}}}`
    - So that's a good "first cut" context to start from
  - Cons: puts the context last, so it doesn't support **Streaming JSON-LD**
  - Cons: JSON-LD to Turtle doesn't use the prefixes from the context
- [jq](https://stedolan.github.io/jq/download/ ) (if needed): for JSON manipulations

#### JSON-LD Context
To obtain the best possible JSON-LD form, we defined [CIM-ontology-context.jsonld](CIM-ontology-context.jsonld).
It consists of two sections:
- First we define the same prefixes as in `prefixes.ttl`:
```
{"@context":
 {"cim":          "https://cim.ucaiug.io/ns#",
  "nc":           "https://cim4.eu/ns/nc#",
  "eu":           "https://cim.ucaiug.io/ns/eu#",
  ...
```
- Then we define property characteristics, so the instance data can carry pure values, rather than having to repeat these characteristics. Notes:
  - We have shown only one example per namespace per characteristic. See the full file for all props.
  - `"@type": "@id"` declares an object property
  - `"@type": "xsd:date"` declares a data property with the specified datatype 
  - `"@language": "en"` results in a `langString` with that lang tag
```js
  "cim:unitMultiplier"          : {"@type": "@id"},
  "cims:belongsToCategory"      : {"@type": "@id"},
  "dcat:landingPage"            : {"@type": "@id"},
  "dct:creator"                 : {"@language": "en"},
  "dct:issued"                  : {"@type": "xsd:dateTime"},
  "dct:modified"                : {"@type": "xsd:date"},
  "owl:backwardCompatibleWith"  : {"@type": "@id"},
  "qudt:hasUnit"                : {"@type": "@id"},
  "qudt:prefixMultiplier"       : {"@type": "xsd:double"},
  "rdfs:comment"                : {"@language": "en"},
  "rdfs:domain"                 : {"@type": "@id"},
  "skos:narrower"               : {"@type": "@id"}
```

https://github.com/Sveino/Inst4CIM-KG/issues/110
It is important to deploy `CIM-ontology-context.jsonld` at a network location.
- The first cut was done with a local file file://CIM-ontology-context.jsonld .
  The output includes the same relative URL, which is not good.
- We cannot use github directly 
  (https://github.com/Sveino/Inst4CIM-KG/raw/refs/heads/develop/rdfs-improved/CIM-ontology-context.jsonld)
  because it doesn't serve the appropriate content type
- So we currently use rawgit2 (https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdfs-improved/CIM-ontology-context.jsonld),
  which serves the file with `content-type: application/ld+json`.
  This works, but it's not a permanent location, so we need to look for a better location.

For the ontologies, we could embed the context by using techniques described at GS1 EPCIS.
But for instance data we definitely need a network context, so we better find a solution.

#### Coverting to JSON-LD as a Debugging Tool
As part of working out the best possible JSON-LD form, we looked for irregularities
as explained in https://github.com/Sveino/Inst4CIM-KG/issues/99 :
```
grep -h '       "@' */*/*.jsonld|perl -pe 's{^ +}{}' |sort|uniq -c
grep -h '"http' */*/*.jsonld|sort|uniq -c|less
```

We found and diagnosed a number of issues:
- https://github.com/Sveino/Inst4CIM-KG/issues/69
- https://github.com/Sveino/Inst4CIM-KG/issues/104
- https://github.com/Sveino/Inst4CIM-KG/issues/108
- https://github.com/Sveino/Inst4CIM-KG/issues/109
- https://github.com/Sveino/Inst4CIM-KG/issues/110
- https://github.com/digitalbazaar/jsonld.js/issues/558

This is one of the benefits of using standard RDF serializations:
by converting between them, one can check that everything is defined properly and as expected.

### RDF/XML Serialization

TODO

# Fixes

This section describes fixes that we want to implement over the CGMES RDFS representation.
In general, we proceed in this way:
- We load all ontologies to a semantic database (I used Ontotext's GraphDB Free version 10.6 or later)
- We analyze the patterns to be fixed using command-line tools (`grep, uniq` etc) or SPARQL
- Then we write SPARQL Updates to fix the problems

## Use Only One of RDFS2020 and RDFSEd2Beta Style
https://github.com/Sveino/Inst4CIM-KG/issues/41

NC 2.3 uses the older RDFS2020 style, CGMES 3.0 is available in the older and the newer RDFSEd2Beta style.
- Using only one style will harmonize data and simplify SPARQL Updates
- Currently it's not easy to upgrade NC 2.3 to the RDFSEd2Beta style
- So we decided to use only the RDFS2020 style

The issue listed above includes a growing list of tasks, so we won't repeat them here.
- In effect, the SPARQL Updates will upgrade from the old to the new style
- While avoiding the regressions (bugs) present in the new style

### Namespace Discrepancies in RDFS2020 CGMES vs NC
https://github.com/Sveino/Inst4CIM-KG/issues/68

Even limiting to the RDFS2020 style only, there are some discrepancies between CGMES and NC:
```sparql
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
PREFIX cim: <http://iec.ch/TC57/CIM100#>
select * {
    ?prop cims:dataType ?qk1,?qk2
    filter(str(?qk1)<str(?qk2))
} order by ?prop
```
| prop                                  | qk1           | qk2                               |
|---------------------------------------|---------------|-----------------------------------|
| dm:DifferenceModel.forwardDifferences | rdf:Statement | rdf:Statements                    |
| dm:DifferenceModel.preconditions      | rdf:Statement | rdf:Statements                    |
| dm:DifferenceModel.reverseDifferences | rdf:Statement | rdf:Statements                    |
| md:Model.created                      | cim:DateTime  | https://cim.ucaiug.io/ns#DateTime |
| md:Model.description                  | cim:String    | https://cim.ucaiug.io/ns#String   |
| md:Model.modelingAuthoritySet         | eu:URI        | https://cim.ucaiug.io/ns/eu#URI   |
| md:Model.profile                      | eu:URI        | https://cim.ucaiug.io/ns/eu#URI   |
| md:Model.scenarioTime                 | cim:DateTime  | https://cim.ucaiug.io/ns#DateTime |
| md:Model.version                      | cim:Integer   | https://cim.ucaiug.io/ns#String   |

- Use different `cim, eu` namespaces
- Use `rdf:Statement` vs `rdf:Statements` (but neither is correct: https://github.com/Sveino/Inst4CIM-KG/issues/53)

Actually this problem goes much deeper:
```sparql
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
PREFIX cim: <http://iec.ch/TC57/CIM100#>
select ?qk (count(*) as ?c) {
    ?prop cims:dataType ?qk
} group by ?qk order by ?qk
```
We can see that most properties are shown twice in two different namespaces, eg:
- 100 https://cim.ucaiug.io/ns#ActivePower
- 73 http://iec.ch/TC57/CIM100#ActivePower

We can confirm this by looking at the files (I've deleted namespaces that are the same):
```
head -10 CGMES-NC/ttl/AssessedElement-AP-Voc-RDFS2020.ttl
@prefix     cim: <https://cim.ucaiug.io/ns#> .
@prefix      nc: <https://cim4.eu/ns/nc#> .
@prefix profcim: <https://cim.ucaiug.io/ns/prof-cim#> .

$ head -10 CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS2020_EQ.ttl
@prefix     cim: <http://iec.ch/TC57/CIM100#> .
@prefix    cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> .
@prefix      eu: <http://iec.ch/TC57/CIM100-European#> .
```

We find all namespaces, and all discrepant (duplicate) prefixes like this:
```
grep -h '^@prefix' */*/*|perl -pe 's{\@prefix *}{}'|sort|uniq >prefixes.txt
cut -f1 -d ' ' prefixes.txt|uniq -d

cim:
dm:
eu:
```

## Merge and Fix DatasetMetadata, Header, FileHeader
https://github.com/Sveino/Inst4CIM-KG/issues/69

There are 3 ontologies `DatasetMetadata, Header, FileHeader` with overlapping scope.
Several of the ontology terms are defined in 2 of the 3, indicating the need to merge:
```
grep -E '(dm:|eumd:)\w' */*/*
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DocDatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:eumd:DateTimeStamp a rdfs:Class ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DocDatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DocDatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DocDatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:belongsToCategory dm:Package_DocDatasetMetadataProfile ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:dm:Ontology a owl:Ontology ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:dataType eumd:DateTimeStamp ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:dataType eumd:DateTimeStamp ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:eumd:Model1 a rdf:Property ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:usedSettings ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:eumd:Model2 a rdf:Property ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:processType ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:eumd:processType a rdf:Property ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:Model2 ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:eumd:usedSettings a rdf:Property ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:Model1 ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:dm:Package_DatasetMetadataProfile a cims:ClassCategory ;
CGMES-NC/ttl/DatasetMetadata-AP-Voc-RDFS2020.ttl:dm:Package_DocDatasetMetadataProfile a cims:ClassCategory ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:dm:DifferenceModel a rdfs:Class ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:eumd:DateTimeStamp a rdfs:Class ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  cims:dataType eumd:DateTimeStamp ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  cims:dataType eumd:DateTimeStamp ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:dm:DifferenceModel.forwardDifferences a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  rdfs:domain dm:DifferenceModel .
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:dm:DifferenceModel.preconditions a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  rdfs:domain dm:DifferenceModel .
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:dm:DifferenceModel.reverseDifferences a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  rdfs:domain dm:DifferenceModel .
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:eumd:Model.applicationSoftware a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:eumd:Model1 a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:usedSettings ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:eumd:Model2 a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:processType ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:eumd:processType a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:Model2 ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:eumd:usedSettings a rdf:Property ;
CGMES-NC/ttl/Header-AP-Voc-RDFS2020.ttl:  cims:inverseRoleName eumd:Model1 ;
CGMES/ttl/FileHeader_RDFS2019.ttl:dm:DifferenceModel a rdfs:Class ;
CGMES/ttl/FileHeader_RDFS2019.ttl:dm:DifferenceModel.forwardDifferences a rdf:Property ;
CGMES/ttl/FileHeader_RDFS2019.ttl:  rdfs:domain dm:DifferenceModel .
CGMES/ttl/FileHeader_RDFS2019.ttl:dm:DifferenceModel.preconditions a rdf:Property ;
CGMES/ttl/FileHeader_RDFS2019.ttl:  rdfs:domain dm:DifferenceModel .
CGMES/ttl/FileHeader_RDFS2019.ttl:dm:DifferenceModel.reverseDifferences a rdf:Property ;
CGMES/ttl/FileHeader_RDFS2019.ttl:  rdfs:domain dm:DifferenceModel .
```
In addition:
- `eumd:DateTimeStamp` is wrong
- `eumd:Model1, eumd:Model2` are junk prop names

## Fixes to Ontology Metadata
https://github.com/Sveino/Inst4CIM-KG/issues/32

Some fixes are needed to the format of ontology metadata.
From this (only the fields to change are shown):
```ttl
eq:Ontology a owl:Ontology ;
  dcat:landingPage "https://www.entsoe.eu/digital/cim/cim-for-grid-models-exchange/" ;
  dct:license "https://www.apache.org/licenses/LICENSE-2.0"@en ;
  dcat:theme "vocabulary"@en ;
  dct:conformsTo "file://iec61970cim17v40_iec61968cim13v13a_iec62325cim03v17a.eap",
    "urn:iso:std:iec:61970-301:ed-7:amd1", "urn:iso:std:iec:61970-501:draft:ed-2", "urn:iso:std:iec:61970-600-2:ed-1" ;
  dct:publisher "ENTSO-E"@en ;
  dct:rightsHolder "ENTSO-E"@en ;
  owl:versionInfo "3.0.0"@en .
```
To this (the lines marked `##` not yet done, pending decision)
```ttl
eq:Ontology a owl:Ontology ;
  dcat:landingPage <https://www.entsoe.eu/digital/cim/cim-for-grid-models-exchange/> ;
  dct:license <https://www.apache.org/licenses/LICENSE-2.0> ;
  ## DELETE ## dcat:theme "vocabulary"@en ;
  dc:source "iec61970cim17v40_iec61968cim13v13a_iec62325cim03v17a.eap";
  dct:conformsTo
    <urn:iso:std:iec:61970-301:ed-7:amd1>, <urn:iso:std:iec:61970-501:draft:ed-2>, <urn:iso:std:iec:61970-600-2:ed-1> ;
  dct:publisher "ENTSO-E" ;
  dct:rightsHolder "ENTSO-E" ;
  owl:versionInfo "3.0.0" .
```

## Add rdfs:isDefinedBy

https://github.com/Sveino/Inst4CIM-KG/issues/103
Each ontology term should have rdfs:isDefinedBy to the ontology node.
This allows semantic web crawlers that stumble upon a CIM term, to discover the whole CIM ontology.

https://github.com/Sveino/Inst4CIM-KG/issues/5 is a soft blocker for this:
- We could add multiple values for each term
- But this is untypical usage
- It may lead to a crawler fetching the same ontology multiple times, but I think the risk is low since the crawler should keep a queue of ontologies to be fetched (or already fetched) in any case.

## Duplication Between Ontologies
https://github.com/Sveino/Inst4CIM-KG/issues/5

Common terms are duplicated many times.
Eg the `Boolean` primitive is defined in 12/18 NC ontologies, and 9/10 CGMES ontologies (total 21):
```
grep ^cim:Boolean */*/*.ttl
CGMES-NC/ttl/AssessedElement-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/AvailabilitySchedule-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/Contingency-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/EquipmentReliability-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/GridDisturbance-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/PowerSchedule-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/RemedialAction-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/RemedialActionSchedule-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/SecurityAnalysisResult-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/StateInstructionSchedule-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/SteadyStateHypothesisSchedule-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES-NC/ttl/SteadyStateInstruction-AP-Voc-RDFS2020.ttl:cim:Boolean a rdfs:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_DL.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_DY.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_EQ.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_EQBD.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_GL.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_OP.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_SC.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_SSH.ttl:cim:Boolean a owl:Class ;
CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_SV.ttl:cim:Boolean a owl:Class ;
```

What's the problem:
- There are discrepancies between multiple definitions.
  They are due to CGMES using `RDFSEd2Beta` style but NC using `RDFS2020` style
- If you put ontologies in separate named graphs,
  there will be actual duplicated definitions of classes and properties,
  causing a lot more expensive reasoning

It's not only about primitives and other meta-terms.
Electrical terms are also duplicated.
The following subsections include an analysis of duplication.

### Duplicated Definitions
First let's take the definition into account:
```
grep -h ^[a-z] */*/*.ttl|grep -Ev '=|e[.]g[.]|kp1,|kq1'|sort|uniq -c|grep -v ' 1 '> duplicated-definitions.txt
      4 cim:ACDCConverter a owl:Class ;
      2 cim:ACDCConverter a rdfs:Class ;
      3 cim:ACDCConverterDCTerminal a owl:Class ;
      3 cim:ApparentPower.value a owl:DatatypeProperty, owl:FunctionalProperty ; ### RDFSEd2Beta
      2 cim:ApparentPower.value a rdf:Property ; ### RDFS2020
```
This means that:
- `ACDCConverter` is defined in 4 files one way, and in 2 files another way (inconsistently).
- `ACDCConverterDCTerminal` is defined in 3 files, but always the same way
- `cim:ApparentPower.value` is defined 3+2 times, and I've marked with `###` from which style it comes.

### Duplicated Terms
Now let's keep only the term.
```
grep -h ^[a-z] */*/*.ttl|grep -Ev '=|e[.]g[.]|kp1,|kq1'|perl -pe 's{ .*}{}'|sort|uniq -c|grep -v ' 1 '> duplicated-terms.txt
      6 cim:ACDCConverter
      3 cim:ACDCConverterDCTerminal
      5 cim:ApparentPower.value
     21 cim:Boolean
```
The counts may be a bit higher than the sum in the previous file:
if a term is defined once in `RDFSEd2Beta` and once in `RDFS2020` style it won't appear in the previous file,
but will appear in this file.

### Duplication Summary
Let's also extract the unique terms:
```
grep -h ^[a-z] */*/*.ttl|grep -Ev '=|e[.]g[.]|kp1,|kq1'|perl -pe 's{ .*}{}'|sort|uniq>terms-uniq.txt
```

And count of the analysis files we've produced:
```
wc -l *.txt
   882 duplicated-definitions.txt
   875 duplicated-terms.txt
  7268 terms-uniq.txt
```
The problem is pervasive: 12% of terms are duplicated (875 out of 7268).
The most "popular" terms are duplicated 28 times:
```
sort -rn duplicated-terms.txt |head -10
     28 cim:String
     28 cim:Date
     24 cim:IdentifiedObject.mRID
     24 cim:IdentifiedObject
     23 cim:Float
     22 cim:IdentifiedObject.name
     21 cim:UnitSymbol
     21 cim:UnitMultiplier
     21 cim:DateTime
     21 cim:Boolean
```

## Prefixes
Here are all prefixes used across CGMES and NC: collected in [prefixes.ttl](prefixes.ttl).
```ttl
@prefix cim      : <http://iec.ch/TC57/CIM100#> .
@prefix cim      : <https://cim.ucaiug.io/ns#> .
@prefix cims     : <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> .
@prefix dcat-cim : <https://cim4.eu/ns/dcat-cim#> .
@prefix eu       : <http://iec.ch/TC57/CIM100-European#> .
@prefix eu       : <https://cim.ucaiug.io/ns/eu#> .
@prefix eumd     : <https://cim4.eu/ns/Metadata-European#> .
@prefix md       : <http://iec.ch/TC57/61970-552/ModelDescription/1#> .
@prefix nc       : <https://cim4.eu/ns/nc#> .
@prefix profcim  : <https://cim.ucaiug.io/ns/prof-cim#> .

@prefix dl       : <http://iec.ch/TC57/ns/CIM/DiagramLayout-EU#> .
@prefix dm       : <http://iec.ch/TC57/61970-552/DifferenceModel/1#> .
@prefix dy       : <http://iec.ch/TC57/ns/CIM/Dynamics-EU#> .
@prefix eq       : <http://iec.ch/TC57/ns/CIM/CoreEquipment-EU#> .
@prefix eqbd     : <http://iec.ch/TC57/ns/CIM/EquipmentBoundary-EU#> .
@prefix gl       : <http://iec.ch/TC57/ns/CIM/GeographicalLocation-EU#> .
@prefix op       : <http://iec.ch/TC57/ns/CIM/Operation-EU#> .
@prefix sc       : <http://iec.ch/TC57/ns/CIM/ShortCircuit-EU#> .
@prefix ssh      : <http://iec.ch/TC57/ns/CIM/SteadyStateHypothesis-EU#> .
@prefix sv       : <http://iec.ch/TC57/ns/CIM/StateVariables-EU#> .
@prefix tp       : <http://iec.ch/TC57/ns/CIM/Topology-EU#> .

@prefix ae       : <https://ap.cim4.eu/AssessedElement#> .
@prefix as       : <https://ap.cim4.eu/AvailabilitySchedule#> .
@prefix co       : <https://ap.cim4.eu/Contingency#> .
@prefix dh       : <https://ap.cim4.eu/DocumentHeader#> .
@prefix er       : <https://ap.cim4.eu/EquipmentReliability#> .
@prefix gd       : <https://ap.cim4.eu/GridDisturbance#> .
@prefix iam      : <https://ap.cim4.eu/ImpactAssessmentMatrix#> .
@prefix ma       : <https://ap.cim4.eu/MonitoringArea#> .
@prefix or       : <https://ap.cim4.eu/ObjectRegistry#> .
@prefix ps       : <https://ap.cim4.eu/PowerSchedule#> .
@prefix psp      : <https://ap.cim4.eu/PowerSystemProject#> .
@prefix ra       : <https://ap.cim4.eu/RemedialAction#> .
@prefix ras      : <https://ap.cim4.eu/RemedialActionSchedule#> .
@prefix sar      : <https://ap.cim4.eu/SecurityAnalysisResult#> .
@prefix shs      : <https://ap.cim4.eu/SteadyStateHypothesisSchedule#> .
@prefix sis      : <https://ap.cim4.eu/StateInstructionSchedule#> .
@prefix sm       : <https://ap.cim4.eu/SensitivityMatrix#> .
@prefix ssi      : <https://ap.cim4.eu/SteadyStateInstruction#> .

@prefix adms     : <http://www.w3.org/ns/adms#> .
@prefix dcat     : <http://www.w3.org/ns/dcat#> .
@prefix dct      : <http://purl.org/dc/terms/> .
@prefix dcterms  : <http://purl.org/dc/terms/#> .
@prefix euvoc    : <http://publications.europa.eu/ontology/euvoc#> .
@prefix owl      : <http://www.w3.org/2002/07/owl#> .
@prefix prov     : <http://www.w3.org/ns/prov#> .
@prefix rdf      : <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs     : <http://www.w3.org/2000/01/rdf-schema#> .
@prefix skos     : <http://www.w3.org/2004/02/skos/core#> .
@prefix xsd      : <http://www.w3.org/2001/XMLSchema#> .
```

They are listed in the following order:
- CIM/CGMES/NC/model/header/meta
- CGMES profiles
- NC profiles
- other (standard prefixes).

The same order is used in [Makefile](Makefile) as `--prefixOrder` option
so as to present the prefixes in the same order in converted Turtle files.

### Mis-defined Prefixes
https://github.com/Sveino/Inst4CIM-KG/issues/13

There are a couple of problems with prefixes:
- `dcterms` is wrong (has exraneous hash), as you can see at https://prefix.cc/dcterms:
```ttl
@prefix dct      : <http://purl.org/dc/terms/> .
@prefix dcterms  : <http://purl.org/dc/terms/#> .
```
- For consistency, only `dct` should be used (which is the more popular spelling), not `dcat`

This below is an expected issue, and will cause confusion if all ontologies are used together:
- The CIM and CGMES "business" prefixes are defined twice.
  This comes from the `RDFSEd2Beta` style (used for CGMES) vs `RDFS2020` style (used for CGMES NC)
```ttl
@prefix cim      : <http://iec.ch/TC57/CIM100#> .
@prefix cim      : <https://cim.ucaiug.io/ns#> .
@prefix eu       : <http://iec.ch/TC57/CIM100-European#> .
@prefix eu       : <https://cim.ucaiug.io/ns/eu#> .
```

### Too Many Prefixes
https://github.com/Sveino/Inst4CIM-KG/issues/4

As you see, CGMES/NC uses about 4x more prefixes than the standard ones.
Also, it hogs short 2-3 letter prefixes.
There's no conflict with the standard ones eg (`dct, sh`) maybe by pure luck.

Happily, the profile prefixes (group 2 and 3) are not used on terms (classes, props, individuals).
(That would drive ontology users crazy.)
Perhaps not even standards creators can say what is `psp` or `sis` without consulting some files.

Most profile prefixes are used only for a couple of things, eg:
```ttl
grep -E '(ae|psp):' terms-uniq.txt
ae:Ontology
ae:Package_AssessedElementProfile
ae:Package_DocAssessedElementProfile
psp:Ontology
psp:Package_PowerSystemProjectProfile
```
But there's no need to consume a prefix just for that.
So it is recommended to remove profile prefixes.

Only the `xx:Ontology` terms are ok (but don't need a namespace).
The other terms in profile-specific namespaces are not ok, as analyzed in subsequent sections.

## Improve Ordering of Ontology Terms
https://github.com/Sveino/Inst4CIM-KG/issues/40

- rdfs:Class should come after owl:Ontology:  https://github.com/atextor/turtle-formatter/issues/22
- This query finds all types of things in the ontologies that don't have a type from the standard namespaces:
```sparql
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select ?type (count(*) as ?c) {
  ?x a ?type
  filter not exists {
    ?x a ?standard
    bind(concat(str(owl:),"|",str(rdf:),"|",str(rdfs:)) as ?regex)
    filter(regex(str(?standard),?regex))
  }
} group by ?type order by desc(?c)
```
- `cims:Category` (35) is the only extra we need to add
  - `xx:Package` (28+1+1...) should be added as `cims:Package` after fixing https://github.com/Sveino/Inst4CIM-KG/issues/10
  - The others are enumeration values (`Currency, PhaseCode` etc) that will go last, where `NamedIndividuals` belong anyway
- Use the `--subjectOrder` option of `owl-cli` to sort them in the best possible way
  - Blocked by https://github.com/atextor/turtle-formatter/issues/27 , so we use the standard order

## Terms Per Namespace
Let's analyze all terms per namespace:
```
cut -d: -f1 terms-uniq.txt |uniq -c|sort -rn>namespace-count.txt
```

They break down into the following groups:
- Electrical, model, header: business, productive. OK
```
   4828 cim
   2099 nc
     30 eu
     16 md
      7 eumd
      4 profcim
      4 dm
      4 dcat-cim
```
- NC Profiles: not needed, as described in the previous section (https://github.com/Sveino/Inst4CIM-KG/issues/4)
```
      3 ssi
      3 sm
      3 sis
      3 shs
      3 sar
      3 ras
      3 ra
      3 ps
      3 or
      3 ma
      3 iam
      3 gd
      3 er
      3 dh
      3 co
      3 as
      3 ae
      2 psp
```

## Namespace Hijacking
There's no need to redefine standard terms, that is considered namespace hijacking.
There are other problems as well (junk term names).
This is limited to two CGMES-NC files:
- Header-AP-Voc-RDFS2020.ttl: https://github.com/Sveino/Inst4CIM-KG/issues/8
- PowerSystemProject-AP-Voc-RDFS2020.ttl: https://github.com/Sveino/Inst4CIM-KG/issues/9

```
     42 dcterms
     19 dcat
      9 prov
      1 rdf
      1 euvoc
      1 adms
```

## Meta-Props Duplicated Per Profile
https://github.com/Sveino/Inst4CIM-KG/issues/10

CGMES (but not CGMES NC) Profile namespaces redefine the same meta properties several times.
Here is the count of terms per namespace:
```
     39 dy
     13 tp
     13 eqbd
     13 eq
     12 sv
     12 ssh
     12 sc
     11 op
     11 gl
     11 dl
```

Let's get the terms of 4 namespaces and put them side by side:
```
grep -E '(dl|eq|tp|gl):' terms-uniq.txt
```
| term1            | term2            | term3            | term4          |
|------------------|------------------|------------------|----------------|
| dl:isAbstract    | eq:isAbstract    | tp:isAbstract    | gl:isAbstract  |
| dl:isCIMDatatype | eq:isCIMDatatype |                  |                |
|                  |                  |                  | gl:isCompound  |
| dl:isConst       | eq:isConst       | tp:isConst       | gl:isConst     |
|                  |                  | tp:isDescription |                |
|                  | eq:isEuropean    | tp:isEuropean    |                |
| dl:isFixed       | eq:isFixed       | tp:isFixed       | gl:isFixed     |
| dl:isPrimitive   | eq:isPrimitive   | tp:isPrimitive   | gl:isPrimitive |
| dl:isUnique      | eq:isUnique      | tp:isUnique      | gl:isUnique    |
|                  | eq:isdeprecated  | tp:isdeprecated  |                |
| dl:isenum        | eq:isenum        | tp:isenum        | gl:isenum      |

All these are CIM meta-properties that should stay in the `cims:` namespace.

Consider the definition of `cim:StreetAddress` in GL:
```ttl
cim:StreetAddress a owl:Class ;
  rdfs:label "StreetAddress"@en ;
  gl:Package "Package_GeographicalLocationProfile" ;
  gl:isCompound "True" ;
  skos:definition "General purpose street and postal address information."@en .
```
`isCompound` should be `cims:isCompound` since it's part of the CIM metamodel, not part of GL.

This also relates https://github.com/Sveino/Inst4CIM-KG/issues/5 and is an aspect of inconsistency:
the same meta-prop should always be used with the same prefix.

## Remove Unused Enumeration Classes
https://github.com/Sveino/Inst4CIM-KG/issues/11

CGMES profiles define per-profile `Enumeration` classes that are not used since only `cim:Enumeration` is used:
```
grep -h Enumeration */*/* |sort|uniq -c
     66   rdfs:subClassOf cim:Enumeration ;
      1 dl:Enumeration a owl:Class ;
      1 dy:Enumeration a owl:Class ;
      1 eq:Enumeration a owl:Class ;
      1 eqbd:Enumeration a owl:Class ;
      1 gl:Enumeration a owl:Class ;
      1 op:Enumeration a owl:Class ;
      1 sc:Enumeration a owl:Class ;
      1 ssh:Enumeration a owl:Class ;
      1 sv:Enumeration a owl:Class ;
      1 tp:Enumeration a owl:Class ;
```
Remove these parasitic `Enumeration` classes.

## Wrong Declaration of Enumerations
https://github.com/Sveino/Inst4CIM-KG/issues/7

All enumerations are declared like this:
```ttl
cim:ControlAreaTypeKind a owl:Class ;
  rdfs:label "ControlAreaTypeKind"@en ;
  eq:Package "Package_CoreEquipmentProfile" ;
  owl:oneOf ( cim:ControlAreaTypeKind.AGC cim:ControlAreaTypeKind.Forecast
    cim:ControlAreaTypeKind.Interchange ) ;
  rdfs:subClassOf cim:Enumeration ;
```
This means that the `owl:NamedIndividual` values across all enumerations will also obtain type `cim:Enumeration`.
I think that's not needed because you wouldn't query by it.

Instead, it's better to say:
```ttl
cim:ControlAreaTypeKind a owl:Class, cim:Enumeration  ;
```
This way you mark the nature of the class without adding every instance under `cim:Enumeration`.
Instances already have `cims:isenum "True"`.

## Fix Representation of NamedIndividuals
https://github.com/Sveino/Inst4CIM-KG/issues/45

This query finds 554 individuals (all CIM individuals have these 3 characteristics)
```ttl
select * {
  ?s a owl:Thing, owl:NamedIndividual; rdfs:domain ?class
} order by ?s
```

They are represented like this:
```ttl
cim:AsynchronousMachineKind.generator a owl:NamedIndividual, owl:Thing ;
  rdfs:label "generator "@en ;
  rdfs:domain cim:AsynchronousMachineKind ;
  skos:definition "The Asynchronous Machine is a generator."@en ;
  ssh:isenum "True" .
```
Problems:
- `owl:NamedIndividual, owl:Thing` are useless since they are too generic, you'd never query by these classes
- `rdfs:domain cim:AsynchronousMachineKind` is wrong, should be `rdf:type`

So we want to change this to:
```ttl
cim:AsynchronousMachineKind.generator a cim:AsynchronousMachineKind ;
  rdfs:label "generator "@en ;
  skos:definition "The Asynchronous Machine is a generator."@en ;
  ssh:isenum "True" .
```

## Mis-declared Packages
https://github.com/Sveino/Inst4CIM-KG/issues/12

Let's see how packages are used on the example of DY that has the biggest number:
```
grep -i "[^ ]package" CGMES/ttl/IEC61970-600-2_CGMES_3_0_0_RDFS_501Ed2CD_DY.ttl|sort|uniq -c
      3   dy:Package "Package_AsynchronousMachineDynamics" ;
      6   dy:Package "Package_Core" ;
      3   dy:Package "Package_DC" ;
      4   dy:Package "Package_DiscontinuousExcitationControlDynamics" ;
     36   dy:Package "Package_Domain" ;
     57   dy:Package "Package_ExcitationSystemDynamics" ;
      3   dy:Package "Package_HVDCDynamics" ;
      6   dy:Package "Package_LoadDynamics" ;
      2   dy:Package "Package_MechanicalLoadDynamics" ;
      5   dy:Package "Package_OverexcitationLimiterDynamics" ;
      3   dy:Package "Package_PFVArControllerType1Dynamics" ;
      4   dy:Package "Package_PFVArControllerType2Dynamics" ;
     19   dy:Package "Package_PowerSystemStabilizerDynamics" ;
      1   dy:Package "Package_StandardInterconnections" ;
      2   dy:Package "Package_StandardModels" ;
      1   dy:Package "Package_StaticVarCompensatorDynamics" ;
      5   dy:Package "Package_SynchronousMachineDynamics" ;
     35   dy:Package "Package_TurbineGovernorDynamics" ;
      2   dy:Package "Package_TurbineLoadControllerDynamics" ;
      6   dy:Package "Package_UnderexcitationLimiterDynamics" ;
     22   dy:Package "Package_UserDefinedModels" ;
      2   dy:Package "Package_VoltageAdjusterDynamics" ;
      4   dy:Package "Package_VoltageCompensatorDynamics" ;
     36   dy:Package "Package_WindDynamics" ;
      8   dy:Package "Package_Wires" ;
      1 dy:Package_AsynchronousMachineDynamics a dy:Package ;
      1 dy:Package_Base a dy:Package ;
      1 dy:Package_Core a dy:Package ;
      1 dy:Package_DC a dy:Package ;
      1 dy:Package_DiscontinuousExcitationControlDynamics a dy:Package ;
      1 dy:Package_Domain a dy:Package ;
      1 dy:Package_Dynamics a dy:Package ;
      1 dy:Package_DynamicsProfile a dy:Package ;
      1 dy:Package_ExcitationSystemDynamics a dy:Package ;
      1 dy:Package_HVDCDynamics a dy:Package ;
      1 dy:Package_LoadDynamics a dy:Package ;
      1 dy:Package_MechanicalLoadDynamics a dy:Package ;
      1 dy:Package_OverexcitationLimiterDynamics a dy:Package ;
      1 dy:Package_PFVArControllerType1Dynamics a dy:Package ;
      1 dy:Package_PFVArControllerType2Dynamics a dy:Package ;
      1 dy:Package_PowerSystemStabilizerDynamics a dy:Package ;
      1 dy:Package_StandardInterconnections a dy:Package ;
      1 dy:Package_StandardModels a dy:Package ;
      1 dy:Package_StaticVarCompensatorDynamics a dy:Package ;
      1 dy:Package_SynchronousMachineDynamics a dy:Package ;
      1 dy:Package_TurbineGovernorDynamics a dy:Package ;
      1 dy:Package_TurbineLoadControllerDynamics a dy:Package ;
      1 dy:Package_UnderexcitationLimiterDynamics a dy:Package ;
      1 dy:Package_UserDefinedModels a dy:Package ;
      1 dy:Package_VoltageAdjusterDynamics a dy:Package ;
      1 dy:Package_VoltageCompensatorDynamics a dy:Package ;
      1 dy:Package_WindDynamics a dy:Package ;
      1 dy:Package_Wires a dy:Package ;
```
There are several mistakes above:
- Package nodes are defined (with `comment`) but as type `dy:Package`: instead should be `cims:Package`
- Package nodes are defined in the profile namespace `dy:`: instead should be in `cims:` namespace.
  Eg `Package_Core` is one and the same thing no matter in which profile it appears.
- Packages are attached to terms as strings: eg `dy:Package "Package_WindDynamics"` is used for 36 terms
  - Instead, it should use the already defined "things" (nodes): eg `cims:Package_WindDynamics`
- The property should be in lowercase, else it's confused with the class `dy:Package`

There are more mistakes in the definition of the property:
```ttl
dy:Package a owl:AnnotationProperty ;
  rdfs:label "MOF Package"@en ;
  rdfs:comment "Declaration that this is a MOF Package."@en ;
  rdfs:domain rdfs:Class ;
  rdfs:range xsd:string .
```

This should be changed to:
```ttl
cims:Package a rdfs:Class;
  rdfs:label "MOF Package"@en ;
  rdfs:comment "A group of terms (classes and properties)"@en.

cims:package owl:AnnotationProperty ;
  rdfs:label "MOF Package"@en ;
  rdfs:comment "Package this term belongs to."@en ;
  schema:domainIncludes rdfs:Class, rdf:Property, owl:ObjectProperty, owl:DatatypeProperty ;
  rdfs:range cims:Package .
```
The prop applies to many kinds of terms, so I've used `schema:domainIncludes`.
Another way is to use `owl:unionOf`.

## Whitespace in Definitions
https://github.com/Sveino/Inst4CIM-KG/issues/6

Many definitions include leading/trailing whitespace (newlines, tabs etc), eg:
```ttl
cim:Boolean a owl:Class ;
  rdfs:label "Boolean"@en ;
  dl:Package "Package_DiagramLayoutProfile" ;
  dl:isPrimitive "True" ;
  skos:definition """
A type with the value space "true" and "false".

\t"""@en .
```

This query finds 1556 instances of leading/trailing whitespace in strings.
(I guess some are duplicated between 2.3 and 3.0 CIM namespaces):
```
select * {
    ?x ?p ?label
    filter(regex(?label,"^\\s|\\s$"))
}
```
Saved as [literals-whitespace.tsv](literals-whitespace.tsv).

This query counts by property:
```sparql
select ?p (count(*) as ?c) {
    ?x ?p ?label
    filter(regex(?label,"^\\s|\\s$"))
} group by ?p order by desc(?c)
```
New style:
| p               | c     | comment                                                                                                                              |
|-----------------|-------|--------------------------------------------------------------------------------------------------------------------------------------|
| skos:definition | "660" |                                                                                                                                      |
| rdfs:label      | "614" | Most of these are key values (see next section) but some are prop names. Eg `ssh:isDescription` has multiple trailing spaces or tabs |
| rdfs:comment    | "150" | This and all below are key values (see next section)                                                                                 |
| eq:isFixed      | "43"  |                                                                                                                                      |
| sc:isFixed      | "24"  |                                                                                                                                      |
| ssh:isFixed     | "22"  |                                                                                                                                      |
| dy:isFixed      | "20"  |                                                                                                                                      |
| sv:isFixed      | "10"  |                                                                                                                                      |
| dcterms:creator | "7"   |                                                                                                                                      |
| dl:isFixed      | "2"   |                                                                                                                                      |
| eqbd:isFixed    | "2"   |                                                                                                                                      |
| op:isFixed      | "2"   |                                                                                                                                      |

Old style is much better:
| p               | c     |
|-----------------|-------|
| rdfs:comment    | "299" |
| dcterms:creator | "7"   |

This can be fixed easily with SPARQL Update.
- Just need to be careful to restore a lang tag if such was present
- So we need a conditional like this:
```sparql
select * {
    values ?label {"plain" "langString"@en}
    bind(if(lang(?label)!="",strlang(str(?label),lang(?label)),?label) as ?label1)
    bind(datatype(?label1) as ?dt)
}
```
| label            | label1           | dt              |
|------------------|------------------|-----------------|
| "plain"          | "plain"          | xsd: string     |
| "langString" @en | "langString" @en | rdf: langString |

## Datatype XMLLiteral in Definitions
https://github.com/Sveino/Inst4CIM-KG/issues/72

We checked literals for unusual datatypes:
```sparql
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select * where {
  ?x ?p ?o
  filter(isLiteral(?o))
  bind(datatype(?o) as ?dt)
  filter(?dt not in (xsd:string, rdf:langString, xsd:date, xsd:dateTime))
}
```
It turns out that 25 definitions are marked as `rdf:XMLLiteral`.
But they don't include any XML markup, so we should use the simpler datatype `xsd:string`.

## LangTag in Label vs Definition
https://github.com/Sveino/Inst4CIM-KG/issues/93

CIM terms are defined like this:
```ttl
cim:AsynchronousMachineUserDefined a owl:Class ;
  rdfs:label "AsynchronousMachineUserDefined"@en ;
  rdfs:comment "Asynchronous machine whose dynamic behaviour is described by a user-defined model." ;
```
The label has langTag, the comment doesn't. But it should be the other way around:
- `label` equals the local name of the term's URL, and that won't be translated.
  - Note: if it was written as a phrase "Asynchronous Machine User Defined", then it should have a lang tag.
- `comment` is an English sentence, so it should have a langTag

## Whitespace and Lang Tags in Key Values

Key values must be spelled with ultimate care because... well, they are key.
This is similar to the previous section but worse.

Extraneous spaces in key values are NOK because:
- People will use these values in queries
- In some cases SPARQL updates will upgrade strings to things, i.e. use them in URLs

Bad examples:
```ttl
cim:UnitSymbol.VA a owl:NamedIndividual, owl:Thing ;
  rdfs:label "VA "@en ;
  eq:isenum "True" ;

cim:UnitMultiplier.M a owl:NamedIndividual, owl:Thing ;
  rdfs:label "M "@en ;

cim:Temperature.multiplier
  sc:isFixed "True ";
  dy:isFixed "True".
```

The last one is worst: some profiles map `isFixed` to a value with space, others without a space.

In addition, the "en" lang tag is not appropriate for code values.
Eg "VA" and "M" are SI unit and multiplier respectively.
SI is the international system of units, so these codes cannot have lang tags.

This query finds 842 enumerations whose label is marked `@en`:
```sparql
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
select * {
  ?x ?p ?y; cims:stereotype "enum"
  filter(lang(?y)="en")
} order by ?x
```
- Examination shows that the following consist entirely of codes:
  `cim:Currency cim:IfdBaseKind cim:PhaseCode cim:StaticLoadModelKind cim:UnitMultiplier cim:UnitSymbol cim:WindingConnection`
- Eg `eu:LimitKind` includes mostly codes (`tatl, tc, tct` etc).
  It also includes an English phrase: `"warningVoltage"@en`, but it's not likely that code will be translated, so we strip the langTag.

Also: `rdfs:comment` does not include lang tag but should, eg it should be:
```ttl
eu:LimitKind.operationalVoltageLimit a eu:LimitKind ;
  rdfs:label "operationalVoltageLimit" ;
  rdfs:comment "Operational voltage limit."@en.
```

## HTML Tags and Escaped Entities in Definitions
https://github.com/Sveino/Inst4CIM-KG/issues/21

This query finds 2776 instances of HTML tags and entities:
```sparql
select * {
    ?x ?p ?label
    filter(regex(?label,"[&<][^ =]|\\\\"))
}
```
Saved as [literals-html.tsv](literals-html.tsv).

It includes:
- False hits like `e.g. <tool_name>-<major_version>.<minor_version>.<patch>`
  (these are not HTML tags, but "meta-variables")
- Unicode entities like `&#178;` (GraphDB workbench displays it as the unicode char ² but maybe that's a misfeature)
- HTML entities like `&lt;md:Model.created&gt;2014-05-15T17:48:31.474Z&lt;/md:Model.created&gt;`
- HTML block markup like `\n<ul>\n\t<li> ...`. This is nok: markdown is ok (`\n- ...`)
- HTML inline markup like `field voltage (<i>Efd</i>)`. This is nok: markdown is ok (`*Efd*`)
- Useless HTML markup like `<font color="#636671">...</font>`

Some lists use a mix of HTML and markdown, eg `cim:AsynchronousMachineTimeConstantReactance`:
```
Parameter details:
<ol>
    <li>If <i>X'' </i>=<i> X'</i>, a single cage (one equivalent rotor winding per axis) is modelled.</li>
    <li>The “<i>p</i>” in the attribute names is a substitution for a “prime” in the usual parameter notation, e.g. <i>tpo</i> refers to <i>T'o</i>.</li>
</ol>
The parameters used for models expressed in time constant reactance form include:
- RotatingMachine.ratedS (<i>MVAbase</i>);
- RotatingMachineDynamics.damping (<i>D</i>);
- RotatingMachineDynamics.inertia (<i>H</i>);
```
Note: the code block may show "block" chars. These are actually smart quotes:
> The “p” in the attribute names

The problem is that HTML is not interpreted in RDF strings.
- We could use the `^^rdf:HTML` datatype, but that's more complex,
  and no guarantee that tools will interpret it in fields like `rdfs:comment`
- It was decided not to use this datatype

This is a large data cleaning task because all occurrences need to be analyzed, then fixing patterns should be defined:
- Replace Unicode escapes with the real Unicode char (RDF/XML and Turtle allow UTF8 chars)
- Remove &lt;...&gt; or replace with real ASCII chars `<...>`:
  - RDF tags in examples like `<md:Model.created>...</md:Model.created>` should be removed
    because they are syntax specific to RDF/XML, and we don't need to repeat the prop name in the comment
  - "Meta-variables" like `&lt;tool_name&gt;` should be retained
- Replace HTML constructs with Markdown. It is ok because people can read it easily
  (assuming newlines are rendered as newlines not `\n`: `owl-cli` does that using `"""` for string quotes)
  - Lists: `<ul><li>` to `- `
  - Emphasis: `<i>` and `<em>` to `*`, `<b>` and `<strong>` to `**`

## Use Standard Datatypes
https://github.com/Sveino/Inst4CIM-KG/issues/74
https://github.com/Sveino/Inst4CIM-KG/issues/28
https://github.com/Sveino/Inst4CIM-KG/issues/61

CIM defines its own datatypes:
```ttl
cim:Boolean a rdfs:Class ;
  rdfs:label "Boolean"@en ;
  rdfs:comment "A type with the value space \"true\" and \"false\"." ;
  cims:belongsToCategory dl:Package_DiagramLayoutProfile ;
  cims:stereotype "Primitive" .
```

This query finds all their uses:
```sparql
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
select ?dt (count(*) as ?c) {
  ?prop cims:dataType ?dt.
  ?dt cims:stereotype "Primitive"
} group by ?dt order by ?dt
```
(Note: the next section deals with `cims:stereotype "CIMDatatype"`).

We want to map them to corresponding XSD datatypes:
| dt                          |   c | xsd               |                                       |
|-----------------------------|-----|-------------------|---------------------------------------|
| cim:Boolean                 | 230 | xsd:boolean       |                                       |
| cim:Date                    |   1 | xsd:date          |                                       |
| cim:DateTime                |  64 | xsd:dateTime      |                                       |
| cim:Decimal                 |  16 | xsd:decimal       |                                       |
| cim:Duration                |  26 | xsd:duration      |                                       |
| cim:Float                   | 369 | xsd:float         |                                       |
| cim:Integer                 |  59 | xsd:integer       |                                       |
| cim:MonthDay                |   2 | xsd:gMonthDay     |                                       |
| cim:String                  | 121 | xsd:string        |                                       |
| cim:Time                    |   2 | xsd:time          |                                       |
| eu:URI                      |   2 | xsd:anyURI        |                                       |
| profcim:URL                 |   0 | xsd:anyURI        | Not used, but mapped for completeness |
| profcim:IRI                 |   3 | xsd:anyURI        |                                       |
| profcim:StringFixedLanguage |   1 | xsd:string        |                                       |
| profcim:StringIRI           |   3 | xsd:string        |                                       |
| eumd:DateTimeStamp          |   2 | xsd:dateTimeStamp |                                       |

This means to **delete** all their statements, and replace with standard datatypes.

Notes:
- `profcim:StringIRI` is used for `identifier, conformsTo`,
  i.e. values that can be "string or IRI" (though its description mentions only IRI).
  But when we are unsure, we must go with the "lowest common denominator" which is `string`
- Potentially mapping `cim:String` to `rdf:PlainLiteral` is considered in the next two sections

### Multilinguality in CIM?

This section was provoked by pondering the difference between `cim:String` and `profcim:StringFixedLanguage`.

AFAIK, CIM does not allow (and has not considered?) multilinguality
- https://github.com/Sveino/Inst4CIM-KG/issues/8 : Header-AP-Voc-RDFS2020.ttl misdefines `rdf:LangString` but that doesn't count

Eg `cim:IdentifiedObject.name` doesn't allow multiple values:
```ttl
ido:IdentifiedObject.name-cardinality
        rdf:type        sh:PropertyShape;
        sh:description  "This constraint validates the cardinality of the property (attribute).";
        sh:group        ido:CardinalityIO;
        sh:message      "Missing required property (attribute).";
        sh:maxCount     1;
        sh:minCount     1;
        sh:name         "IdentifiedObject.name-cardinality";
        sh:order        0.1;
        sh:path         cim:IdentifiedObject.name;
        sh:severity     sh:Violation .
```
I think it would be better to allow multiple values
but impose a `sh:uniqueLang` constraint (`skos:prefLabel` has the same restriction).
In that way CIM data could accommodate multilinguality.
Eg looking at some random properties:
- `cim:IdentifiedObject.mRID`: always `string`
- `cim:IdentifiedObject.description`: `string` or `langString`
- `cim:IdentifiedObject.name`: `string` or `langString`
- `nc:AssessedElementWithContingency.mRID`: always `string`
- `nc:AssessedElement.normalTargetRemainingAvailableMarginJustification`: `string` or `langString`

Unfortunately, `cim:String` is used even for props that should not allow `langString`,
i.e. no distinction is made between these two cases:
- Names/descriptions could be `string` or `langString`
- But identifiers should only be `string`

So for the time being I think CIM implicitly **forbids** the use of `langString`:
if you cannot have multiple `uniqueLang` values, there's not much use for lang tags.
Also, allowing lang tags may cause some disturbance in some receiving system.

So I'll map `cim:String` to `xsd:string`.

### rdf:PlainLiteral

The EU eProcurement Ontology allows multilingual data, and used `rdfs:Literal`.
But that datatype is way too broad, so I raised an issue:
https://github.com/OP-TED/ted-rdf-mapping/issues/407

The datatype hierarchy is like this: `rdfs:Literal > rdf:PlainLiteral > (xsd:string, rdf:langString)`.
What a text field needs to be mapped to depends on its nature:
- `xsd:string` is appropriate for codes that are never translated to multiple langs
- `rdf:langString` is appropriate for texts that are always translated to multiple langs (if not now, then in the future): so a lang tag is required
- `rdf:PlainLiteral` is appropriate for texts that may but don't have to be translated, i.e. lang tag is not required. It is defined at https://w3.org/TR/rdf-plain-literal , and means `string` or `langString`.

If you want `cim:String` to allow langStrings, then we should map it to `rdf:PlainLiteral`.

## Deprecated Properties
https://github.com/Sveino/Inst4CIM-KG/issues/24

This query shows 7 props that are marked as deprecated, using `cims:stereotype`:
```sparql
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
select * {
  ?p cims:stereotype "deprecated"
}
```
| p                                         |
|-------------------------------------------|
| eu: IdentifiedObject.energyIdentCodeEic   |
| eu: IdentifiedObject.shortName            |
| cim: SVCControlMode                       |
| cim: PhaseTapChangerLinear.xMin           |
| cim: PhaseTapChangerNonLinear.xMin        |
| cim: StaticVarCompensator.sVCControlMode  |
| cim: StaticVarCompensator.voltageSetPoint |

We convert this to `owl:deprecated true` and delete `cims:stereotype "deprecated"`, so it has fewer free-text values.

## Change Class and Property Kinds
https://github.com/Sveino/Inst4CIM-KG/issues/75

The new style changes class and property kinds as follows:
- `rdfs:Class` -> `owl:Class`
- `rdf:Property` -> `owl:DatatypeProperty` (if range is `xsd:*`), `owl:ObjectProperty` otherwise

It doesn't mean that we need full OWL reasoning much beyond RDFS.
We are just being more specific about the nature of properties.

## Use Standard `inverseOf` Property
https://github.com/Sveino/Inst4CIM-KG/issues/26

Inverses are very important in CIM: each object property has its inverse.
- So we need to enable Inverse reasoning.
- For this to work, we need to replace `cims:inverseRoleName` with the standard prop `owl:inverseOf`

## Express Multiplicity in OWL
https://github.com/Sveino/Inst4CIM-KG/issues/30

CIM properties have rich multiplicity (cardinality) information:
```sparql
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#>
select ?mult (count(*) as ?c) {
  ?x cims:multiplicity ?mult
} group by ?mult order by ?mult
```

| mult        |    c |
|-------------|------|
| cims:M:0..1 | 1123 |
| cims:M:0..2 |    2 |
| cims:M:0..n |  462 |
| cims:M:1    |  304 |
| cims:M:1..1 | 3240 |
| cims:M:1..2 |    1 |
| cims:M:1..n |  100 |
| cims:M:2..2 |    2 |
| cims:M:2..n |    3 |

- Fix `M:1` to `M:1..1` for uniformity
- Declare single-valued props (`0..1, 1..1`) as `owl:FunctionalProperty`
- Declare their **inverse** (if any) as `owl:InverseFunctionalProperty`

We keep the `cims:multiplicity` annotation because it has more info than these OWL declarations.
Such cardinalities are reflected in SHACL, but `cims:multiplicity`  gives easier access to this important info.

## QuantityKinds and Units of Measure
https://github.com/Sveino/Inst4CIM-KG/issues/38
- https://github.com/Sveino/Inst4CIM-KG/issues/29 is a subset of this
- TODO: check if https://github.com/3lbits/CIM4NoUtility/issues/338 has anything more

CGMES datatype properties are defined like this (`# new` shows the new style`):

```ttl
cim:ACDCConverter.baseS a rdf:Property;       # new: owl:FunctionalProperty , owl:DatatypeProperty ;
  rdfs:domain cim:ACDCConverter ;
  cims:dataType cim:ApparentPower.            # new: rdfs:range

cim:ApparentPower a owl:Class ;
  rdfs:label "ApparentPower"@en ;
  eq:Package "Package_CoreEquipmentProfile" ;
  cims:stereotype "CIMDatatype";              # new: xx:isCIMDatatype "True" ;
  rdfs:comment                                # new: skos:definition, lang @en, leading/trailing whitespace
    "Product of the RMS value of the voltage and the RMS value of the current.".

cim:ApparentPower.multiplier a rdf:Property;  # new: owl:FunctionalProperty , owl:DatatypeProperty ;
  cims:isFixed "M" ;                          # new: rdf:value "M"; xx:isFixed "True "
  rdfs:domain cim:ApparentPower ;
  rdfs:label "multiplier"@en ;
  rdfs:range cim:UnitMultiplier.

cim:ApparentPower.unit a rdf:Property;        # new: owl:FunctionalProperty , owl:DatatypeProperty ;
  cims:isFixed "VA";                          # new: rdf:value "VA"; xx:isFixed "True "
  rdfs:domain cim:ApparentPower ;
  rdfs:label "unit"@en ;
  rdfs:range cim:UnitSymbol .

cim:ApparentPower.value a rdf:Property;       # new: owl:FunctionalProperty , owl:DatatypeProperty ;
 cims:multiplicity cims:M:0..1;               # new: missing
 rdfs:domain cim:ApparentPower ;
 rdfs:label "value"@en ;
 cims:dataType cim:Float.                     # new: rdfs:range xsd:float
```

There are numerous problems:
- `cim:ApparentPower` is a class, and datatype properties cannot point to a class
- `cim:ApparentPower` is not used in any CGMES instance data
- In CGMES instance data, `ACDCConverter.baseS` is a string, but should be marked as `^^xsd:float`
- The meta-properties `eq:isCIMDatatype, eq:isFixed` use profile dataspaces rather than `cims`
- The key value "True " is spelled with a space for `multiplier, unit`

CIM defines a large set of units of measure, eg:
```ttl
cim:UnitSymbol a owl:Class ;
  rdfs:label "UnitSymbol"@en ;
  cims:stereotype <http://iec.ch/TC57/NonStandard/UML#enumeration>.  # new: missing
                                                                     # new: owl:oneOf (... cim:UnitSymbol.VA ...).

cim:UnitSymbol.VA a cim:UnitSymbol;                                  # new: owl:NamedIndividual, owl:Thing; rdfs:domain cim:UnitSymbol ;
  rdfs:label "VA"@en ;                                               # new: trailing whitespace
  cims:stereotype "enum";                                            # new: xx:isenum "True" ;
  skos:definition "Apparent power in volt amperes..".                # new: lang @en .

cim:UnitMultiplier a owl:Class ;
  rdfs:label "UnitMultiplier"@en ;
  cims:stereotype <http://iec.ch/TC57/NonStandard/UML#enumeration>.  # new: missing
                                                                     # new: owl:oneOf (... cim:UnitMultiplier.M ...).

cim:UnitMultiplier.M a a cim:UnitMultiplier;                         # new: owl:NamedIndividual, owl:Thing; rdfs:domain cim:UnitMultiplier ;
  rdfs:label "M"@en ;                                                # new: trailing whitespace
  cims:stereotype "enum";                                            # new: xx:isenum "True" ;
  rdfs:comment "Mega 10**6."@en .                                    # new: skos:definition
```
- But they are not used: eg `cim:ApparentPower.unit` says it has `rdfs:range cim:UnitSymbol`, but uses a string value "VA". Same for `cim:ApparentPower.multiplier`
- `cim:UnitSymbol.VA` uses a different label `rdfs:label "VA "@en`, which has two mistakes:
  - Trailing space
  - lang tag `@en` (in fact it's a SI symbol that has no language)
- `cim:UnitSymbol.VA` wrongly says `a owl:Thing; rdfs:domain cim:UnitSymbol`.
  - Instead it should say `a cim:UnitSymbol`.
- Similar problems apply to `cim:UnitMultiplier.M`, and:
  - It doesn't express the multiplier as a number `1e6` but only as a string `"Mega 10**6"`

### Fixed Units Representation
We want to fix the representation as follows, and also connect to QUDT (see https://github.com/qudt/qudt-public-repo/issues/969) .
To be clear, this below is just a blueprint, which parts of it will be implemented and where is still for discussion.

First we correct the property: give a numeric range,
but also specify `hasQuantityKind` and `hasUnit` using `qudt` props.
We link to a global QUDT unit, but also give the multiplier and unitSymbol separately, using `cims` props:
```ttl
@prefix qudt: <http://qudt.org/schema/qudt/> .
@prefix unit: <http://qudt.org/vocab/unit/> .

cim:ACDCConverter.baseS a owl:FunctionalProperty , owl:DatatypeProperty ;
  rdfs:domain          cim:ACDCConverter ;
  rdfs:range           xsd:float ;
  qudt:hasQuantityKind cim:ApparentPower;
  qudt:hasUnit         unit:MegaV-A;
  cim:unitMultiplier   cim:UnitMultiplier.M;
  cim:unitSymbol       cim:UnitSymbol.VA.
```

Then we correct the QuantityKind and relate it to QUDT
(see https://github.com/Sveino/Inst4CIM-KG/issues/43 for this particular case):
```ttl
@prefix qudt: <http://qudt.org/schema/qudt/> .
@prefix quantitykind: <http://qudt.org/vocab/quantitykind/> .

cim:ApparentPower a qudt:QuantityKind ;
  rdfs:label          "ApparentPower"@en ;
  cims:package        "Package_CoreEquipmentProfile" ;
  qudt:applicableUnit cim:UnitSymbol.VA;
  skos:exactMatch     quantitykind:ApparentPower;
  rdfs:comment        "Product of the RMS value of the voltage and the RMS value of the current." .
```

We delete `cim:ApparentPower.multiplier, cim:ApparentPower.unit`
because they are replaced by universal props `cim:multiplier, cim:unitSymbol` respectively.

We delete `cim:ApparentPower.value` because the actual DatatypeProperty `cim:ACDCConverter.baseS`
now carries a number (`xsd:float`).
Please note that some classes have actual DatatypeProperties named `.value`.
We keep those, although in some cases the domain class doesn't have any more data so we could skip it, eg:
```ttl
cim:ActivePowerLimit.value a owl:DatatypeProperty, owl:FunctionalProperty ;
  rdfs:label "value"@en ;
  rdfs:comment "Value of active power limit. The attribute shall be a positive value or zero." ;
  cim:unitMultiplier cim:UnitMultiplier.M ;
  cim:unitSymbol cim:UnitSymbol.W ;
  cims:multiplicity cims:M:1..1 ;
  qudt:hasQuantityKind cim:ActivePower ;
  qudt:hasUnit unit:MegaW ;
  rdfs:domain cim:ActivePowerLimit ;
  rdfs:range xsd:float .
```

We correct CIM unit symbols and relate them to QUDT:
```ttl
cim:UnitSymbol a owl:Class ;
  rdfs:label "UnitSymbol"@en ;
  skos:exactMatch qudt:Unit.

cim:UnitSymbol.VA a cim:UnitSymbol ;
  rdfs:label "VA" ;
  cims:stereotype "enum" ; # TODO: should we delete it?
  skos:definition "Apparent power in volt amperes...";
  qudt:hasQuantityKind cim:ApparentPower;
  skos:exactMatch unit:V-A.
```

### Fixed Multipliers Representation
https://github.com/Sveino/Inst4CIM-KG/issues/62

We correct CIM multipliers, add a numeric `prefixMultiplier` and relate them to QUDT (where they are called "prefixes"):
```ttl
@prefix prefix: <http://qudt.org/vocab/prefix/> .

cim:UnitMultiplier a owl:Class ;
  rdfs:label "UnitMultiplier"@en ;
  skos:exactMatch qudt:DecimalPrefix.

cim:UnitMultiplier.M a cim:UnitMultiplier;
  rdfs:label "M" ;
  cims:stereotype "enum" ;
  skos:definition "Mega 10**6."@en ;
  qudt:prefixMultiplier 1.0E6;
  skos:exactMatch prefix:Mega.
```


CIM has a "none" multipler:
```ttl
cim:UnitMultiplier.none a cim:UnitMultiplier ;
  rdfs:label "none"@en ;
  rdfs:comment "No multiplier or equivalently multiply by 1." ;
  cims:stereotype "enum" .
```
- Some quantity kinds refer to it (as string, not thing):
  `cim:<QuantityKind>.multiplier/cims:isFixed="none"`
- QUDT better follows the semantic web principle that when some data is missing or doesn't apply, you don't need to state it:
  it doesn't have something like `prefix:One`.
- But we'll follow CIM and use the `cim:UnitMultiplier.none` as given


### Property Datatype Maps
The previous section defines how we want to correct units, but where can we find the datatypes to use?
There are several approaches/resources that may help us:
- CGMES has [CompleteDatatypeMap.properties](../source/CGMES/v3.0/SHACL/DatatypeMapping/CompleteDatatypeMap.properties) that maps data props to datatypes and is used by some Java process.
  We extracted a table from it and used prefixes: [CompleteDatatypeMap.tsv](datatypes/CompleteDatatypeMap.tsv).
  But it has some shortcomings:
  - Last updated Nov 09 2020, but perhaps there are new props added since then?
  - Doesn't cover NC
- The "ModShape" project has [DatatypeMapping/RDFdatatypes.rdf](https://github.com/griddigit-ci/ModShape/blob/master/CGMES_v3_0_constraints/DatatypeMapping/RDFdatatypes.rdf).
  We converted it to turtle, fixed https://github.com/griddigit-ci/ModShape/issues/3
  and saved as [RDFdatatypes.tsv](datatypes/RDFdatatypes.tsv).
  - It maps 3101 properties and is identical to the above one.
- After mapping CIM datatypes (https://github.com/Sveino/Inst4CIM-KG/issues/74 )
  and fixing the representation of data props with units (https://github.com/Sveino/Inst4CIM-KG/issues/38 )
  we extract [datatypes-actual.tsv](datatypes/datatypes-actual.tsv) with this query. 
  It includes NC and maps 3704 props (was 3712 in an older version):
```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select * where {
  ?p a owl:DatatypeProperty; rdfs:range ?datatype
} order by ?p
```

Now let's analyze the differences:
```
comm -23 RDFdatatypes.tsv datatypes-actual.tsv|wc -l
0

comm -13 RDFdatatypes.tsv datatypes-actual.tsv|wc -l
611
```
The new file has all the old props, and 611 more.
Breakdown per namespace:
```
comm -13 RDFdatatypes.tsv datatypes-actual.tsv > datatypes-new.tsv
cut -d: -f1 datatypes-new.tsv | uniq -c | sort -rn
    548 nc
     21 dct
     16 cim
     10 dcat
      3 rdf
      1 prov
      1 md
      1 euvoc
      1 eumd
      1 adms
```
These fall into the following categories:
- NC props
- New CIM props (eg `cim:IdentifiedObject.aliasName`) and even whole classes with their props (`cim:Name`
- Hijacked namespaces `dcat, rdf, prov, euvoc, adms`: https://github.com/Sveino/Inst4CIM-KG/issues/8

- New datatype for `md:Model.version`: `xsd:string` (the older is `xsd:integer`).
  We can confirm that only one prop is defined with two datatypes (inconsistent):
```
cut -f1 datatypes-actual.tsv |uniq -d
md:Model.version
```

Mis-defined terms from `Header-AP-Voc-RDFS2020` (https://github.com/Sveino/Inst4CIM-KG/issues/22 ):
- `rdf:Statements.object rdf:Statements.predicate rdf:Statements.subject`
  (the correct terms are `rdf:Statement` and `rdf:object rdf:predicate rdf:subject`
- In a hijacked namespace
- With wrong type `xsd:string` (should be `rdf:Resource`)

### Actual QuantityKinds
Let's find all CIM datatypes (called QuantityKinds in QUDT).

In CGMES 3.0 they are represented as `isCIMDatatype "True"`
- We need to use a bunch of namespaces because of https://github.com/Sveino/Inst4CIM-KG/issues/10
```sparql
select distinct ?qk {
  values ?isDatatype {dy:isCIMDatatype tp:isCIMDatatype eqbd:isCIMDatatype eq:isCIMDatatype sv:isCIMDatatype ssh:isCIMDatatype sc:isCIMDatatype op:isCIMDatatype gl:isCIMDatatype dl:isCIMDatatype cims:isCIMDatatype}
  {?qk ?isDatatype "True"
} order by ?qk
```
Saved as [qk-CGMES.txt](qk-CGMES.txt).

In CGMES NC 2.3 they are marked as `cims:stereotype "CIMDatatype"`:
```ttl
select * {
  ?qk cims:stereotype "CIMDatatype"
} order by ?qk
```
Saved as [qk-CGMES_NC.txt](qk-CGMES_NC.txt)

Removed the namespaces (they differ between 2.3 and 3.0) and merged as the full list [qk-all.txt](qk-all.txt).
There are 30 QuantityKinds in use:
- ActivePower
- ActivePowerChangeRate
- ActivePowerPerCurrentFlow
- ActivePowerPerFrequency
- AngleDegrees
- AngleRadians
- ApparentPower
- Area
- Capacitance
- Conductance
- CurrentFlow
- Frequency
- Impedance
- Inductance
- Length
- Money
- PU
- PerCent
- Pressure
- Reactance
- ReactivePower
- RealEnergy
- Resistance
- RotationSpeed
- Seconds
- Susceptance
- Temperature
- Voltage
- VoltagePerReactivePower
- VolumeFlowRate

### Actual Multipliers and Units

This query finds QuantityKinds, Multipliers and Units for the new style:
```sparql
select distinct ?qk ?mult ?uom ?range ?multFixed ?uomFixed {
  values ?isDatatype {dy:isCIMDatatype tp:isCIMDatatype eqbd:isCIMDatatype eq:isCIMDatatype sv:isCIMDatatype ssh:isCIMDatatype sc:isCIMDatatype op:isCIMDatatype gl:isCIMDatatype dl:isCIMDatatype cims:isCIMDatatype}
  ?qk ?isDatatype "True"
  optional {
    values ?isFixed1 {dy:isFixed tp:isFixed eqbd:isFixed eq:isFixed sv:isFixed ssh:isFixed sc:isFixed op:isFixed gl:isFixed dl:isFixed cims:isFixed}
    ?multiplier rdfs:domain ?qk; rdfs:label "multiplier"@en; rdf:value ?mult; ?isFixed1 ?multFixed}
  optional {
    values ?isFixed2 {dy:isFixed tp:isFixed eqbd:isFixed eq:isFixed sv:isFixed ssh:isFixed sc:isFixed op:isFixed gl:isFixed dl:isFixed cims:isFixed}
    ?unit rdfs:domain ?qk; rdfs:label "unit"@en; rdf:value ?uom; ?isFixed2 ?uomFixed}
  optional {
        ?value rdfs:domain ?qk; rdfs:label "value"@en; rdfs:range ?range}
} order by ?qk
```

This query finds QuantityKinds, Multipliers and Units for the old style:
```sparql
select ?qk ?mult ?uom ?range {
  ?qk cims:stereotype "CIMDatatype"
  optional {?multiplier rdfs:domain ?qk; rdfs:label "multiplier"@en; cims:isFixed ?mult}
  optional {?unit rdfs:domain ?qk; rdfs:label "unit"@en; cims:isFixed ?uom}
  optional {?value rdfs:domain ?qk; rdfs:label "value"@en; cims:dataType ?range}
} order by ?qk
```

(`multFixed, uomFixed` are always `"True"` so we skip them from the tables below)

### Mapping QuantityKinds and Units
We see that the data agrees between old and new style
- But one uses `cim` and the other uses `xsd` for the numeric datatypes
- Currently "range" is filled for NC and "new range" is filled for CGMES: in actuality more of them should be filled because CGMES is also available in the old style

We add corresponding QUDT resources (last 3 columns):

| qk                            | mult   | uom       | range       | new range   | QuantityKind                           | Unit                        | unit match      |
|-------------------------------|--------|-----------|-------------|-------------|----------------------------------------|-----------------------------|-----------------|
| cim:ActivePower               | "M"    | "W"       | cim:Float   | xsd:float   | quantitykind:ActivePower               | unit:MegaW                  | skos:exactMatch |
| cim:ActivePowerChangeRate     | "M"    | "WPers"   | cim:Float   |             | quantitykind:ActivePowerChangeRate     | unit:MegaW-PER-SEC          | skos:exactMatch |
| cim:ActivePowerPerCurrentFlow | "M"    | "WPerA"   |             | xsd:float   | quantitykind:ActivePowerPerCurrentFlow | unit:MegaW-PER-A            | skos:exactMatch |
| cim:ActivePowerPerFrequency   | "M"    | "WPerHz"  |             | xsd:float   | quantitykind:ActivePowerPerFrequency   | unit:MegaW-PER-HZ           | skos:exactMatch |
| cim:AngleDegrees              | "none" | "deg"     | cim:Float   | xsd:float   | quantitykind:Angle                     | unit:DEG                    | skos:exactMatch |
| cim:AngleRadians              | "none" | "rad"     |             | xsd:float   | quantitykind:Angle                     | unit:RAD                    | skos:exactMatch |
| cim:ApparentPower             | "M"    | "VA"      | cim:Float   | xsd:float   | quantitykind:ApparentPower             | unit:MegaV-A                | skos:exactMatch |
| cim:Area                      | "none" | "m2"      |             | xsd:float   | quantitykind:Area                      | unit:M2                     | skos:exactMatch |
| cim:Capacitance               | "none" | "F"       |             | xsd:float   | quantitykind:Capacitance               | unit:FARAD                  | skos:exactMatch |
| cim:Conductance               | "none" | "S"       |             | xsd:float   | quantitykind:Conductance               | unit:S                      | skos:exactMatch |
| cim:CurrentFlow               | "none" | "A"       | cim:Float   | xsd:float   | quantitykind:ElectricCurrent           | unit:A                      | skos:exactMatch |
| cim:Frequency                 | "none" | "Hz"      | cim:Float   | xsd:float   | quantitykind:Frequency                 | unit:HZ                     | skos:exactMatch |
| cim:Impedance                 | "none" | "ohm"     | cim:Float   | xsd:float   | quantitykind:Inductance                | unit:OHM                    | skos:exactMatch |
| cim:Length                    | "k"    | "m"       |             | xsd:float   | quantitykind:Length                    | unit:KiloM                  | skos:exactMatch |
| cim:Money                     | "none" |           | cim:Decimal | xsd:decimal | quantitykind:Currency                  |                             | skos:exactMatch |
| cim:PU                        | "none" | "none"    | cim:Float   | xsd:float   | quantitykind:DimensionlessRatio        |                             |                 |
| cim:PerCent                   | "none" | "none"    | cim:Float   | xsd:float   | quantitykind:DimensionlessRatio        | unit:PERCENT                | skos:exactMatch |
| cim:Pressure                  | "k"    | "Pa"      | cim:Float   |             | quantitykind:Pressure                  | unit:KiloPA                 | skos:exactMatch |
| cim:Reactance                 | "none" | "ohm"     | cim:Float   | xsd:float   | quantitykind:Reactance                 | unit:OHM                    | skos:exactMatch |
| cim:ReactivePower             | "M"    | "VAr"     | cim:Float   | xsd:float   | quantitykind:ReactivePower             | unit:MegaV-A_Reactive       | skos:exactMatch |
| cim:RealEnergy                | "M"    | "Wh"      | cim:Float   | xsd:float   | quantitykind:Energy                    | unit:MegaW-HR               | skos:exactMatch |
| cim:Resistance                | "none" | "ohm"     | cim:Float   | xsd:float   | quantitykind:Resistance                | unit:OHM                    | skos:exactMatch |
| cim:RotationSpeed             | "none" | "Hz"      | xsd:float   |             | quantitykind:AngularVelocity           | unit:REV-PER-SEC            | skos:narrower   |
| cim:Seconds                   | "none" | "s"       | cim:Float   | xsd:float   | quantitykind:Time                      | unit:SEC                    | skos:exactMatch |
| cim:Susceptance               | "none" | "S"       |             | xsd:float   | quantitykind:Susceptance               | unit:S                      | skos:exactMatch |
| cim:Temperature               | "none" | "degC"    | cim:Float   | xsd:float   | quantitykind:Temperature               | unit:DEG_C                  | skos:exactMatch |
| cim:Voltage                   | "k"    | "V"       | cim:Float   | xsd:float   | quantitykind:Voltage                   | unit:KiloV                  | skos:exactMatch |
| cim:VoltagePerReactivePower   | "k"    | "VPerVAr" | cim:Float   | xsd:float   | quantitykind:VoltagePerReactivePower   | unit:KiloV-PER-V-A_Reactive | skos:exactMatch |
| cim:VolumeFlowRate            | "none" | "m3Pers"  |             | xsd:float   | quantitykind:VolumeFlowRate            | unit:M3-PER-SEC             | skos:exactMatch |

- `cim:VoltagePerReactivePower` uses two multipliers, which is inconsistent: https://github.com/Sveino/Inst4CIM-KG/issues/77

We need to submit a MR to QUDT for these new QuantityKinds and Units (https://github.com/qudt/qudt-public-repo/issues/970 ) :
- Note: `WPers` is used for two different kinds: `ActivePowerPerFrequency` and `ActivePowerChangeRate`.
  The former is wrong: corrected to `WperHz`, and defined `cim:UnitSymbol.WperHz`.

| QuantityKind              | Unit1              | Unit2                  |
|---------------------------|--------------------|------------------------|
| ActivePowerChangeRate     | W-PER-SEC          | MegaW-PER-SEC          |
| ActivePowerPerCurrentFlow | W-PER-A            | MegaW-PER-A            |
| ActivePowerPerFrequency   | W-PER-HZ           | MegaW-PER-HZ           |
| VoltagePerReactivePower   | V-PER-V-A_Reactive | KiloV-PER-V-A_Reactive |

After we add the above kinds, all `QuantityKinds` will be mapped as `skos:exactMatch`.
- `skos:broader`: no such cases, I thought `ApparentPower` is a sub-concept of `ComplexPower` but QUDT has `ApparentPower`: https://github.com/Sveino/Inst4CIM-KG/issues/43

Almost all `Units` are mapped as `skos:exactMatch` except one:
- `skos:narrower`: "Hz" is a super-concept of `REV-PER-SEC`: https://github.com/Sveino/Inst4CIM-KG/issues/42

This is also reflected eg in this property:
```ttl
cim:AsynchronousMachine.nominalSpeed a owl:DatatypeProperty, owl:FunctionalProperty ;
  rdfs:label "nominalSpeed"@en ;
  rdfs:comment "Nameplate data.  Depends on the slip and number of pole pairs." ;
  cim:unitMultiplier cim:UnitMultiplier.none ;
  cim:unitSymbol cim:UnitSymbol.Hz ;
  cims:multiplicity cims:M:0..1 ;
  cims:stereotype <http://iec.ch/TC57/NonStandard/UML#attribute> ;
  qudt:hasQuantityKind cim:RotationSpeed ;
  qudt:hasUnit unit:REV-PER-SEC ;
  rdfs:domain cim:AsynchronousMachine ;
  rdfs:range xsd:float .
```
- `cim:unitSymbol` is `Hz` (1/s),
  which is a bit imprecise for `cim:RotationSpeed`
- `qudt:hasUnit` is unit:REV-PER-SEC, which is more specific (rotations/s)

CIM includes this more specific unit, but unfortunately it's not used for any property:
```ttl
cim:UnitSymbol.rotPers a cim:UnitSymbol ;
  rdfs:label "rotPers" ;
  rdfs:comment "Rotations per second (1/s). See also Hz (1/s)." ;
```

### Mapping Unit Multipliers

Only 3 multipliers are used. We map them as follows:

| cim:UnitMultiplier  | qudt:prefixMultiplier | skos:exactMatch |
|---------------------|-----------------------|-----------------|
| UnitMultiplier.none |                   1.0 |                 |
| UnitMultiplier.k    |                 1.0E3 | prefix:Kilo     |
| UnitMultiplier.M    |                 1.0E6 | prefix:Mega     |

### All QuantityKinds, Units and Multipliers

This query finds all enumeration members:
```sparql
select ?class (count(*) as ?c) {
    ?s a  owl:NamedIndividual; rdfs:domain ?class
} group by ?class order by desc(?c)
```
3 of the top 4 are related to units, multipliers and currencies.
But a very small number of them are in actual use in CGMES ontologies (see last column):
|   | class              | c     | in use |
|---|--------------------|-------|--------|
| 1 | cim:Currency       | "161" |      0 |
| 2 | cim:UnitSymbol     | "141" |     30 |
| 3 | cim:PhaseCode      | "26"  |        |
| 4 | cim:UnitMultiplier | "21"  |      3 |

We should fix all units and multipliers as shown in [Fixed Units Representation](#fixed-units-representation),
but will map to QUDT only the ones that are in use: this is shown in the previous two sections.

## Represent Models as Named Graphs
- https://github.com/Sveino/Inst4CIM-KG/issues/53
- https://github.com/3lbits/CIM4NoUtility/discussions/321 is a relevant discussion
  - See my examples there
  - TODO: blank nodes will cause huge problems
- [CGMES-TC/FullGrid_SC_diff.xml](https://github.com/Sveino/CGMES-TC/blob/develop/v3.0/FullGrid/FullGrid_SC_diff/FullGrid_SC_diff.xml) is an example difference model
- [NC/PowerSystemProject.rdf](https://github.com/Sveino/Inst4CIM-KG/blob/develop/source/CGMES-NC/r2.3/ap-voc/rdf/PowerSystemProject-AP-Voc-RDFS2020.rdf) is a profile that addresses the difference model with some meta-data.

# Fix Technical Notes
The actual fixing can be done in two ways:
- Using a semantic database:
  - Load the ontology to a defined graph (usually same as the ontology URL)
  - Run the updates over that graph only
  - Export the graph to a file
  - Format the file as Turtle (see above)
- Using a tool that does updates in-memory (eg Jena `update`)
  - Run `update` with the original file and concatenated update queries
  - Pass the result through the Turtle formatter
  - Save it to a file

The latter is slightly simpler, so we use that.

## Fix Structure
We write one Update per issue, using a strict structure to allow comprehension and evolution:
- Naming: `fixNN-Topic-M.ru`, eg [fix01-whitespace-6.ru](fix01-whitespace-6.ru), where
  - `NN` is the sequence number of the update. Some must be run in a specified order, and we concat all updates to `fix-all.ru` in order.
  - `Topic` is a short phrase about what it does
  - `M` is the issue number
- Content:
  - Two links: to the section in this doc, and to the issue, eg
```
# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#whitespace-in-definitions
# https://github.com/Sveino/Inst4CIM-KG/issues/6
```
  - SPARQL that typically looks like this. The `where` part reuses analysis queries from this doc, and adds more binds and tricks
```sparql
prefix ...
delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  ...
}
```
  - Trailing semicolon and newline, so the concat works ok

SPARQL Update allows multiple update blocks separated with semicolon, and intervening prefixes.
This approach allows us to run fixes one by one, or all at once.

## Fix Debugging

It will be a very bad thing if a fix loses some data because of some mistake in the query.
- As we develop fixes, we apply them one by one
- Then we make a PR and review it on git to ensure that the intended changes to ontologies are properly done
- But this development cycle is longer: requires commits, then someone else takes a look...

So here we explain a way to debug fixes faster, using SPARQL.
Say that you run `fix01-whitespace-6.ru`, which fixes whitespace:
```sparql
delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  ?x ?p ?old
  bind(str(?old) as ?oldStr)
  filter(regex(?oldStr,"^\\s|\\s$"))
  bind(replace(replace(?oldStr,"^\\s+",""),"\\s+$","") as ?newStr)
  bind(if(lang(?old)!="",strlang(?newStr,lang(?old)),?newStr) as ?new)
};

```
GraphDB reports "3 statements deleted" (it doesn't say how many were changes, but the net difference).

WHAT? This update shouldn't lose triples, so let's debug it.

First we change it to a `select` and look for unbound `?new`:
maybe we made a mistake when calculating it?
(SPARQL is very tolerant: if there's some problem in evaluating an expression, it just returns unbound):
```sparql
select ?x ?p ?old ?new
where {
  ?x ?p ?old
  bind(str(?old) as ?oldStr)
  filter(regex(?oldStr,"^\\s|\\s$"))
  bind(replace(replace(?oldStr,"^\\s+",""),"\\s+$","") as ?newStr)
  bind(if(lang(?old)!="",strlang(?newStr,lang(?old)),?newStr) as ?new)
  filter(!bound(?new))
}
```
Nothing returned.

Then let's count `?old` and `?new` (should be the same because `count` discards nulls, but to make sure):
```sparql
select (count(distinct ?old) as ?oldCpount) (count(distinct ?new) as ?newCount)
where {
  ?x ?p ?old
  bind(str(?old) as ?oldStr)
  filter(regex(?oldStr,"^\\s|\\s$"))
  bind(replace(replace(?oldStr,"^\\s+",""),"\\s+$","") as ?newStr)
  bind(if(lang(?old)!="",strlang(?newStr,lang(?old)),?newStr) as ?new)
}
```

Same, so now let's count `distinct`.
The same triple cannot be recorded twice, so if two `?old` are mapped to the same `?new` for the same subject and property `?x ?p`, that will decrease number of triples:
```sparql
select (count(distinct ?old) as ?oldCpount) (count(distinct ?new) as ?newCount)
where {
  ?x ?p ?old
  bind(str(?old) as ?oldStr)
  filter(regex(?oldStr,"^\\s|\\s$"))
  bind(replace(replace(?oldStr,"^\\s+",""),"\\s+$","") as ?newStr)
  bind(if(lang(?old)!="",strlang(?newStr,lang(?old)),?newStr) as ?new)
}
```
Here it is: the count is reduced by 3.

But how to catch these duplicate instances?
It takes some doing.
- It turns out the duplication is due to trailing whitespace added in some ontologies but not others.
- If you grok this below, then your SPARQL force is strong indeed, Luke!
```sparql
select ?x ?p ?old1 ?old2 ?new1
where {
  ?x ?p ?old1, ?old2
  filter(isLiteral(?old1))
  filter(isLiteral(?old2))
  bind(str(?old1) as ?oldStr1)
  bind(str(?old2) as ?oldStr2)
  filter(?old1 != ?old2)
  filter(regex(?oldStr2,"^\\s|\\s$"))

  bind(replace(replace(?oldStr1,"^\\s+",""),"\\s+$","") as ?newStr1)
  bind(if(lang(?old1)!="",strlang(?newStr1,lang(?old1)),?newStr1) as ?new1)
  bind(replace(replace(?oldStr2,"^\\s+",""),"\\s+$","") as ?newStr2)
  bind(if(lang(?old2)!="",strlang(?newStr2,lang(?old2)),?newStr2) as ?new2)

  filter(?new1 = ?new2)
}
```

This exercise, and looking at intermediate results, gave me the idea to add a safety feature to the fix:
```sparql
  filter(isLiteral(?old))
```

## Fix Ordering and List

Here's a proposed ordering (and numbering) of the fixes, with reasons why.
We also track status with the tag "DONE" and by adding a link to the fix.

- [Namespace Discrepancies in RDFS2020 CGMES vs NC](#namespace-discrepancies-in-rdfs2020-cgmes-vs-nc) #68, [Mis-defined Prefixes](#mis-defined-prefixes) #13
  - Else other fixes become harder because they need to deal with pairs of namespaces
  - This is best done with a script not SPARQL update
  - DONE [fix-namespaces.pl](fix-namespaces.pl)
- 01 [Whitespace in Definitions](#whitespace-in-definitions) #6
  - Because it's independent of the others
  - DONE [fix01-whitespace-6.ru](fix01-whitespace-6.ru)
- 02 [Use Standard Datatypes](#use-standard-datatypes) (also deletes CIM Primitive datatypes) #28, #61, #74
  - DONE [fix02-datatypes-74.ru](fix02-datatypes-74.ru)
- 05 Correct a couple of units #76, #77
  - DONE [fix05-units-76,77.ru](fix05-units-76,77.ru)
- 06 [Fixed Units Representation](#fixed-units-representation), [Fixed Multipliers Representation](#fixed-multipliers-representation) #38
  - DONE [fix06-quantityKind-38.ru](fix06-quantityKind-38.ru)
- 07 Attach datatype, unit, multiplier to data props #38
  - DONE [fix07-dataProps-38.ru](fix07-dataProps-38.ru)
- 08 Remove intermediate props `.unit, .multiplier, .value` #38
  - DONE [fix08-remove-qkProps-38.ru](fix08-remove-qkProps-38.ru)
- 09 [Mapping QuantityKinds and Units](#mapping-quantitykinds-and-units), [Mapping Unit Multipliers](#mapping-unit-multipliers) #38
  - DONE [fix09-map-qkUnitsMultipliers-38.ru](fix09-map-qkUnitsMultipliers-38.ru)
  - TODO: It inserts "standalone" `exactMatch`, even if that CIM quantityKind isn't used in a particular file.
    I am not sure why this happens, but it's harmless (another file has the full definition of that quantityKind),
    so I'll leave it in.
```
cim:ActivePowerChangeRate skos:exactMatch quantitykind:ActivePowerChangeRate .
```
- 10 Change Class and Property Kinds from RDFS to OWL #75
  - DONE [fix10-classPropKind-75.ru](fix10-classPropKind-75.ru)
- 11 `cims:inverseRoleName -> owl:inverseOf` #26
  - DONE [fix11-inverseOf-26.ru](fix11-inverseOf-26.ru)
- 12 [Express Multiplicity in OWL](#express-multiplicity-in-owl) #30
  - DONE [fix12-multiplicity-30.ru](fix12-multiplicity-30.ru)
- 13 [Datatype XMLLiteral in Definitions](#datatype-xmlliteral-in-definitions) #72
  - DONE [fix13-XMLLiteral-72.ru](fix13-XMLLiteral-72.ru)
  - TODO TODO All these appear in Header, but RDFS2020 doesn't include such ontologies.
    Which is a problem because `CGMES/v3.0/SHACL/ttl, CGMES-NC/r2.3/ap-con/ttl` include shapes about them!
- 14 [Whitespace and Lang Tags in Key Values](#whitespace-and-lang-tags-in-key-values) #47
  - DONE [fix14-langTagInCodes-47.ru](fix14-langTagInCodes-47.ru)
- 15 [Deprecated Properties](#deprecated-properties) #24
  - DONE [fix15-deprecated-24.ru](fix15-deprecated-24.ru)
- 16 [LangTag in Label vs Definition](#langtag-in-label-vs-definition) #93
  - DONE [fix16-langTagLabelVsDefinition-93.ru](fix16-langTagLabelVsDefinition-93.ru)
- 20 [Fixes to Ontology Metadata](#fixes-to-ontology-metadata) #32
  - DONE [fix20-ontologyMetadata-32.ru](fix20-ontologyMetadata-32.ru)
