# Improvements to CIM and CGMES RDFS Representation
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Improvements to CIM and CGMES RDFS Representation](#improvements-to-cim-and-cgmes-rdfs-representation)
    - [Source Files](#source-files)
    - [RDF Serializations](#rdf-serializations)
        - [Turtle Serialization Tools](#turtle-serialization-tools)
            - [atextor tools: owl-cli and turtle-formatter](#atextor-tools-owl-cli-and-turtle-formatter)
            - [EDMC Tools](#edmc-tools)
            - [OBO Robot](#obo-robot)
- [Fixes](#fixes)
    - [Use Only One of RDFS2020 and RDFSEd2Beta Style](#use-only-one-of-rdfs2020-and-rdfsed2beta-style)
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
    - [Whitespace and Lang Tags in Key Values](#whitespace-and-lang-tags-in-key-values)
    - [HTML Tags and Escaped Entities in Definitions](#html-tags-and-escaped-entities-in-definitions)
    - [Datatypes and Units of Measure](#datatypes-and-units-of-measure)
        - [Fixed Units Representation](#fixed-units-representation)
        - [Fixed Multipliers Representation](#fixed-multipliers-representation)
        - [CompleteDatatypeMap](#completedatatypemap)
        - [Actual QuantityKinds](#actual-quantitykinds)
        - [Actual Multipliers and Units](#actual-multipliers-and-units)
        - [Mapping QuantityKinds and Units](#mapping-quantitykinds-and-units)
        - [Mapping Unit Multipliers](#mapping-unit-multipliers)
        - [All QuantityKinds, Units and Multipliers](#all-quantitykinds-units-and-multipliers)
    - [Add Datatypes To Instance Data](#add-datatypes-to-instance-data)
- [Fix Technical Notes](#fix-technical-notes)
    - [Fix Structure](#fix-structure)
    - [Fix Debugging](#fix-debugging)

<!-- markdown-toc end -->

## Source Files
We start from these RDFS renditions, which are the latest versions of CIM/CGMES and CGMES-NC respectively:
- https://www.entsoe.eu/Documents/CIM_documents/Grid_Model_CIM/IEC61970-600-2_CGMES_3_0_1_ApplicationProfiles.zip folder `v3.0/RDFS2020`.
  Available locally in [source/CGMES/v3.0/RDFS2020](../source/CGMES/v3.0/RDFSEd2Beta/RDFS)
- https://github.com/Sveino/CGMES-NC/tree/develop/r2.3/ap-voc/rdf
  Available locally in [source/CGMES-NC/r2.3/ap-voc/rdf](../source/CGMES-NC/r2.3/ap-voc/rdf)

## RDF Serializations
TODO:
- [ ] Agree folder structure: `rdf` vs `ttl` vs `jsonld`.
  - But given the multitude of subfolders in `source/CGMES/v3.0/SHACL`, where do we make the format subfolders
  - For now I make the latter two but don't copy `rdf`
- [x] Automate the conversion: I did it with a Makefile
  - Or see [spotless](https://github.com/diffplug/spotless/), which is used to automate file manipulation in a project
- [ ] Produce good JSON-LD (see GS1 EPCIS tooling)

### Turtle Serialization Tools
It was agreed to adopt `ttl` as master format.

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
I posted a large number of issues. As of 17-Sep-2024:
- https://github.com/atextor/turtle-formatter/issues/created_by/vladimiralexiev (9). The important ones are:
  - #22 section sorting: 
    I want to sort all props alphabetically, but currently it is not possible (`ObjectProperty` first, `DatatypeProperty` next)
  - #27 prefixes trouble when using `--subjectOrder`: 
    rdfs:Class comes before `owl:Ontology`
  - #32 `prefixAlign=left` makes invalid turtle:
    So we use  `prefixAlign=right`
  - #33 `--useCommaByDefault` not respected on source build of owl-cli:
    So multiple values of eg `dct:conformsTo` are printed on separate lines, with the property repeated
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

#### EDMC Tools
Elisa Kendall (one of the main FIBO ontologists):

There is an open-source tool available from the EDM Council for converting between RDF/XML, Turtle, and JSON-LD and for consistent serialization of any of these representations of RDF and OWL. The GitHub site for it is https://github.com/edmcouncil/rdf-toolkit. It is actively maintained, freely available, and addresses a number of issues mentioned on the thread, among other things. It also allows users to turn any of its features on/off as desired. It runs on the command line, or can be invoked automatically through GitHub commit hooks, for example.

For collaborative work across development teams for large ontology projects, consistent serialization for comparison purposes was one of our first and relatively important issues. It enables visual comparison in GitHub (and likely other source code management systems), so that anyone reviewing the changes can see exactly what changed, down to the single character level. 

We also have a pipeline that looks for a myriad of issues in ontologies, performs regression testing using examples and reference data, and includes an html-based publication process that itself has a comparison feature, enabling comparison of any pull request or prior release with another version or with the latest version. The code for this is also open source, available from the EDM Council GitHub repository, though support is required for hosting and customization.

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
- "VA" and "M" are SI unit and multiplier respectively. SI is international, so these codes cannot have lang tags
- The last one is worst: some profiles map `isFixed` to a value with space, others without a space

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

## Datatypes and Units of Measure
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


### CompleteDatatypeMap
The previous section defines how we want to correct units, but how can we do it?
There is a resource that may help us:

CGMES has [CompleteDatatypeMap.properties](../source/CGMES/v3.0/SHACL/DatatypeMapping/CompleteDatatypeMap.properties) that maps data props to datatypes and is used by some Java process.
We extracted a table from it and used prefixes: [CompleteDatatypeMap.tsv](CompleteDatatypeMap.tsv).
But it has some shortcomings:
- Last updated Nov 09 2020, but perhaps there are new props added since then?
- Doesn't cover NC
- Mis-defines terms
  - `rdf:Statements.object rdf:Statements.predicate rdf:Statements.subject`
    (the correct terms are `rdf:Statement` and `rdf:object rdf:predicate rdf:subject`
  - In a hijacked namespace
  - With wrong type `xsd:string` (should be `rdf:Resource`)

Although this is not an ontology file, a similar problem is present in `Header-AP-Voc-RDFS2020`:
https://github.com/Sveino/Inst4CIM-KG/issues/22

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

| qk                            | mult   | uom       | range       | new range   | QuantityKind                    | Unit                  | unit match      |
|-------------------------------|--------|-----------|-------------|-------------|---------------------------------|-----------------------|-----------------|
| cim:ActivePower               | "M"    | "W"       | cim:Float   | xsd:float   | quantitykind:ActivePower        | unit:MegaW            | skos:exactMatch |
| cim:ActivePowerChangeRate     | "M"    | "WPers"   | cim:Float   |             |                                 |                       |                 |
| cim:ActivePowerPerCurrentFlow | "M"    | "WPerA"   |             | xsd:float   |                                 |                       |                 |
| cim:ActivePowerPerFrequency   | "M"    | "WPers"   |             | xsd:float   |                                 |                       |                 |
| cim:AngleDegrees              | "none" | "deg"     | cim:Float   | xsd:float   | quantitykind:Angle              | unit:DEG              | skos:exactMatch |
| cim:AngleRadians              | "none" | "rad"     |             | xsd:float   | quantitykind:Angle              | unit:RAD              | skos:exactMatch |
| cim:ApparentPower             | "M"    | "VA"      | cim:Float   | xsd:float   | quantitykind:ApparentPower      | unit:MegaV-A          | skos:exactMatch |
| cim:Area                      | "none" | "m2"      |             | xsd:float   | quantitykind:Area               | unit:M2               | skos:exactMatch |
| cim:Capacitance               | "none" | "F"       |             | xsd:float   | quantitykind:Capacitance        | unit:FARAD            | skos:exactMatch |
| cim:Conductance               | "none" | "S"       |             | xsd:float   | quantitykind:Conductance        | unit:S                | skos:exactMatch |
| cim:CurrentFlow               | "none" | "A"       | cim:Float   | xsd:float   | quantitykind:ElectricCurrent    | unit:A                | skos:exactMatch |
| cim:Frequency                 | "none" | "Hz"      | cim:Float   | xsd:float   | quantitykind:Frequency          | unit:HZ               | skos:exactMatch |
| cim:Impedance                 | "none" | "ohm"     | cim:Float   | xsd:float   | quantitykind:Inductance         | unit:H                | skos:exactMatch |
| cim:Length                    | "k"    | "m"       |             | xsd:float   | quantitykind:Length             | unit:KiloM            | skos:exactMatch |
| cim:Money                     | "none" |           | cim:Decimal | xsd:decimal | quantitykind:Currency           |                       | skos:exactMatch |
| cim:PU                        | "none" | "none"    | cim:Float   | xsd:float   | quantitykind:DimensionlessRatio |                       |                 |
| cim:PerCent                   | "none" | "none"    | cim:Float   | xsd:float   | quantitykind:DimensionlessRatio | unit:PERCENT          | skos:exactMatch |
| cim:Pressure                  | "k"    | "Pa"      | cim:Float   |             | quantitykind:Pressure           | unit:KiloPA           | skos:exactMatch |
| cim:Reactance                 | "none" | "ohm"     | cim:Float   | xsd:float   | quantitykind:Reactance          | unit:OHM              | skos:exactMatch |
| cim:ReactivePower             | "M"    | "VAr"     | cim:Float   | xsd:float   | quantitykind:ReactivePower      | unit:MegaV-A_Reactive | skos:exactMatch |
| cim:RealEnergy                | "M"    | "Wh"      | cim:Float   | xsd:float   | quantitykind:Energy             | unit:MegaW-HR         | skos:exactMatch |
| cim:Resistance                | "none" | "ohm"     | cim:Float   | xsd:float   | quantitykind:Resistance         | unit:OHM              | skos:exactMatch |
| cim:RotationSpeed             | "none" | "Hz"      | xsd:float   |             | quantitykind:AngularVelocity    | unit:REV-PER-SEC      | skos:narrower   |
| cim:Seconds                   | "none" | "s"       | cim:Float   | xsd:float   | quantitykind:Time               | unit:SEC              | skos:exactMatch |
| cim:Susceptance               | "none" | "S"       |             | xsd:float   | quantitykind:Susceptance        | unit:S                | skos:exactMatch |
| cim:Temperature               | "none" | "degC"    | cim:Float   | xsd:float   | quantitykind:Temperature        | unit:DEG_C            | skos:exactMatch |
| cim:Voltage                   | "k"    | "V"       | cim:Float   | xsd:float   | quantitykind:Voltage            | unit:KiloV            | skos:exactMatch |
| cim:VoltagePerReactivePower   | "k"    | "VPerVAr" | cim:Float   | xsd:float   |                                 |                       |                 |
| cim:VolumeFlowRate            | "none" | "m3Pers"  |             | xsd:float   | quantitykind:VolumeFlowRate     | unit:M3-PER-SEC       | skos:exactMatch |

We need to submit a MR to QUDT for these new QuantityKinds and Units (https://github.com/qudt/qudt-public-repo/issues/970 ) :
| QuantityKind              | Unit1              | Unit2                  |
|---------------------------|--------------------|------------------------|
| ActivePowerChangeRate     | W-PER-SEC          | MegaW-PER-SEC          |
| ActivePowerPerCurrentFlow | W-PER-A            | MegaW-PER-A            |
| ActivePowerPerFrequency   | W-PER-SEC          | MegaW-PER-SEC          |
| VoltagePerReactivePower   | V-PER-V-A_Reactive | KiloV-PER-V-A_Reactive |
- Note: `WPers` is used for two different kinds: `ActivePowerPerFrequency` and `ActivePowerChangeRate`.

After we add the above kinds, all `QuantityKinds` will be mapped as `skos:exactMatch`.
- `skos:broader`: no such cases, I thought `ApparentPower` is a sub-concept of `ComplexPower` but QUDT has `ApparentPower`: https://github.com/Sveino/Inst4CIM-KG/issues/43 

Almost all `Units` are `skos:exactMatch` except one:
- `skos:narrower`: "Hz" is a super-concept of `REV-PER-SEC`: https://github.com/Sveino/Inst4CIM-KG/issues/42 


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

## Add Datatypes To Instance Data
https://github.com/Sveino/Inst4CIM-KG/issues/49

In CGMES instance data, all literals are string, but should be marked with the appropriate datatype.
- E.g. `cim:ACDCConverter.baseS` should be marked `^^xsd:float`
- Otherwise sort won't work and range queries will be slower.
- This pertains to `boolean, dateTme, float, gMonthDay, integer` as `string` is the default datatype

This query counts props by XSD datatype:
```sparql
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

select ?range (count(*) as ?c) {
   ?x rdfs:range ?range
    filter(strstarts(str(?range), str(xsd:)))
} group by ?range order by ?range
```

Here are the current results, but it should be rerun after fixes to ontology: see col "comment"
| range         |   c | comment                                                                             |
|---------------|-----|-------------------------------------------------------------------------------------|
| xsd:boolean   | 218 | Inflated because meta-data props are duplicated, and many are boolean               |
| xsd:dateTime  |   5 |                                                                                     |
| xsd:decimal   |   1 |                                                                                     |
| xsd:float     | 310 | Deflated because eg `cim:ActivePower.value` may be used by hundreds of "real" props |
| xsd:gMonthDay |   2 |                                                                                     |
| xsd:integer   |  36 |                                                                                     |
| xsd:string    |  51 |                                                                                     |

I have a tentative SPARQL Update, but need to revise it.

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
