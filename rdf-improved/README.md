# Improvements to CIM and CGMES RDF Representation

This document describes proposed inprovements to the representation of CIM/CGMES instance data.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Improvements to CIM and CGMES RDF Representation](#improvements-to-cim-and-cgmes-rdf-representation)
    - [Folders](#folders)
    - [Files](#files)
    - [Makefile](#makefile)
        - [Makefile Variables](#makefile-variables)
        - [First Target](#first-target)
        - [Making Dirs](#making-dirs)
        - [Making Zips](#making-zips)
- [Represent Models as Named Graphs](#represent-models-as-named-graphs)
    - [Representing Difference Models](#representing-difference-models)
    - [Naive JSON-LD Graph Representation Attempt](#naive-json-ld-graph-representation-attempt)
    - [Nearly Correct JSON-LD Graph Representation](#nearly-correct-json-ld-graph-representation)
    - [Custom CIM XML Parser](#custom-cim-xml-parser)
- [CIM URIs and Resolvability](#cim-uris-and-resolvability)
    - [Fix Under-defined Resource URLs](#fix-under-defined-resource-urls)
    - [Resolvable Resource URLs or More Stable `urn:uuid`?](#resolvable-resource-urls-or-more-stable-urnuuid)
    - [Resolvable Model (Graph) URLs?](#resolvable-model-graph-urls)
    - [Global Semantic Resolution](#global-semantic-resolution)
        - [Energy Identification Code](#energy-identification-code)
        - [Energy Reference Data](#energy-reference-data)
        - [UUIDs](#uuids)
- [Add Datatypes To Instance Data](#add-datatypes-to-instance-data)
- [Sample Instance Data](#sample-instance-data)
    - [Counting Triples](#counting-triples)
    - [Multipled Data](#multipled-data)
    - [Final Instance Data](#final-instance-data)
- [JSON-LD Serialization](#json-ld-serialization)
    - [JSON-LD Context](#json-ld-context)
    - [Formatting of Numbers and Booleans](#formatting-of-numbers-and-booleans)

<!-- markdown-toc end -->

## Folders
- instances:  [Sample Instance Data](#sample-instance-data) as Trig, 
  from Nordic44, ENTSO-E and "multiplied" (large), see [Multipled Data](#multipled-data)
- test: xml, trig and jsonld test instance files (8 of each kind)
- trials: various trial files

## Files
- cim-context-new.txt: prefix file for JSON-LD context using new namespaces
- cim-context-old.txt: prefix file for JSON-LD context using old namespaces
- cim-context-common.txt: common  file for JSON-LD context
- cim-context-new.jsonld: JSON-LD context using new namespaces
- cim-context-old.jsonld: JSON-LD context using old namespaces
- cim-context-strings.txt: properties with `"@type": "xsd:string"`. Not added to context since that is the default datatype
- cim-trig.pl: converts CIM XML (Full or Difference models) to Trig: see  [Custom CIM XML Parser](#custom-cim-xml-parser)
- count.pl: script to clean up files produced by `riot --count`
- count-ENTSOE.txt: count of triples in ENTSO-E instance files as produced by `riot --count`
- count-ENTSOE1.txt: pure count of triples in ENTSO-E instance files
- count-Nordic.txt: count of triples in Nordic44 instance files as produced by `riot --count`
- count-Nordic1.txt: pure count of triples in Nordic44 instance files
- fix-datatypes-new.ru: SPARQL Update to add datatypes to instance files using new namespaces
- fix-datatypes-old.ru: SPARQL Update to add datatypes to instance files using old namespaces
- fix-datatypes-both.ru: SPARQL Update to add datatypes to instance files using either new or old namespaces
- props-same-name-different-characteristics.csv: properties with same name (last part of URL) but different characteristics
- props-same-name-different-range.csv: properties with same name (last part of URL) but different range (the most important characteristic)
- README.md: this file

## Makefile
This folder uses [make](https://www.gnu.org/software/make/manual/) to automate various tasks 
and ensure that dependencies are tracked and files are remade when needed.
The Makefile defines the following targets (printed when `make` is invoked without target)
- context: JSON-LD context for new and old namespaces
- dirs: all subdirs in `instances`
- test: test instance files in trig
- jsonld: test instance files in jsonld
- nordic: Nordic44 instance files in trig
- entsoe: ENTSO-E instance files in trig
- multiplied: "multiplied" instance files in trig
- rm-test: remove "test/trig" instance files
- rm-jsonld: remove "test/jsonld" instance files
- rm-nordic: remove Nordic44 trig instance files
- rm-entsoe: remove ENTSO-E trig instance files
- rm-multiplied: remove "multiplied" trig instance files
- clean: remove files of size zero

The `make` manual is very comprehensive, but dense and hard to understand.
So if you are not familiar with make, it can be quite a challenge to understand and maintain the Makefile.
In following subsections we explain a few of the trickier aspects.

### Makefile Variables
Let's first look at variable assignments. Consider the most complicated group:

```make
nordic_source      = ../../../Nordic44/Instances
```
States where is the source of the Nordic44 instance files relative to the current folder.

```make
nordic_dirs       != /usr/bin/find $(nordic_source) -type d
```
Finds all directories (subfolders). 
Unlike normal assignment, `!=` invokes the shell with an external command.
I've given the full name `/usr/bin/find` to avoid confusion with the DOS `find` program (an abomination).

```make
nordic_target      = instances/Nordic44
```
States where the target instance files will go (upon conversion from xml to trig).

```make
nordic_target_dirs = $(subst $(nordic_source),$(nordic_target),$(nordic_dirs)) 
```
Computes the target subfolders. 
`$(nordic_dirs)` is interpreted as a space-separated array,
and for each subfolder, the source prefix is substituted with the target prefix.

```make
nordic_ignore      = CDPSM_2_0/Nordic44_CPSM_01_MF.xml CDPSM_2_0/Nordic44_03_inc.xml CGMES_2_4/Nordic44_CGM_36f_MF.xml CGMES_2_4/Nordic44_CGM_38_CO.xml
```
Declares that some Nordic files will be ignored (not converted) for various reasons.

```make
nordic_ignore2     = $(patsubst %, $(nordic_source)/%, $(nordic_ignore))
```
Expands the ignored files to include the source folder prepended.

```make
nordic_rdf         = $(filter-out $(nordic_ignore2), $(wildcard $(nordic_source)/*_2_*/*.xml))
```
Finds all relevant source (rdf xml) files by using `$(wildcard)` (glob pattern).
The pattern `*_2_*` uses only folders `CDPSM_2_0, CGMES_2_4` 
but ignores the folder `CGMES_3_0` (since that has only some draft files in `ttl, nt, geojson`).
`$(filter-out)` further excludes the `$(nordic_ignore2)` files.

```make
nordic_trig        = $(subst .xml,.trig, $(subst $(nordic_source),$(nordic_target), $(nordic_rdf)))
```
Computes the target (trig) filenames.
`$(nordic_rdf)` is treated as a space-delimited array of filenames, and for each one
we replace source with target folder, 
and source extension `.xml` with the target extension `.trig`

### First Target
The first target in the file (conventionally called `all`) is executed if you run `make` without arguments:
```make
all:
	@echo targets: context, dirs, test, jsonld, nordic, entsoe, multiplied, rm-test, rm-jsonld, rm-nordic, rm-entsoe, rm-multiplied, clean
```
- It just prints the targets defined in the Makefile.
- The prefix `@` prevents make from printing the command line itself

This is also the place to print out any variable you're unsure about, for debugging purposes.
Eg to print `$(nordic_trig)`, add this:
```make
	@echo $(nordic_trig)
```

### Making Dirs

The `instances` folder has 49 folders going to 4 levels deep.
If make tries to create a file in non-existing folder, it will fail.
So we want to automate the creation of all these folders.
We've already computed the nested subfolders `$(nordic_target_dirs) $(entsoe_target_dirs)`,
so we just call `mkdir` on the 4 root folders, plus the nested subfolders:

```make
dirs:
	-mkdir instances $(nordic_target) $(entsoe_target) $(multiplied_target) $(nordic_target_dirs) $(entsoe_target_dirs)
```
The `-` sign  tells it to proceed even if some of these folders already exist
(`mkdir` returns an error in such case, but make ignores the error).

There is one more thing to do.
Git ignores empty folders on commit, so we need to make an empty file in each folder.
Such files are conventionally called `.gitkeep` (see [What is. gitkeep](https://www.freecodecamp.org/news/what-is-gitkeep/)):

```make
	touch $(patsubst %, %/.gitkeep, $(multiplied_target) $(nordic_target_dirs) $(entsoe_target_dirs))
```
`touch` is a convenient command to use here:
it updates the timestamp of files to the current time, and makes empty files if needed.

### Making Zips
Why would we even need these empty folders? Because we don't want to:
- Commit such a large number of large files (see [Final Instance Data](#final-instance-data)) to git.
- Transfer a large number of files to a semantic database for loading. It's better to transfer just 3 zips.

So we use `zip` to zip the the instance files and move them out of the way:
```make
zips:
	zip -r -m $(patsubst instances/%, $(zip)/%.zip, $(nordic_target))     $(nordic_target)     -x "*/.gitkeep"
	zip -r -m $(patsubst instances/%, $(zip)/%.zip, $(entsoe_target))     $(entsoe_target)	   -x "*/.gitkeep"
	zip -r -m $(patsubst instances/%, $(zip)/%.zip, $(multiplied_target)) $(multiplied_target) -x "*/.gitkeep"
```
- Option `-m` moves the files to the zip
- Option `-x` excludes the `.gitkeep` files
- The above is a bit dumb since it always considers all files and copy-pastes the same command three times, but it's ok for a starter

# Represent Models as Named Graphs
- https://github.com/3lbits/CIM4NoUtility/discussions/321 Converting CIMXML DifferenceModel to CIMJSON-LD
- https://github.com/Sveino/Inst4CIM-KG/issues/22 md:Statement is problematically defined
- https://github.com/Sveino/Inst4CIM-KG/issues/86 no connection of instance triples to Model

If you convert a CIM XML model (eg `Nordic44_CGM_36d_SSH.xml`) to Turtle, you get something like this:
```ttl
<urn:uuid:1d8b61bc-c7f3-4e9e-a3bd-f4ec24beb586>
  rdf:type                       md:FullModel ;
  md:Model.DependentOn           <urn:uuid:2dd9014f-bdfb-11e5-94fa-c8f73332c8f4> ;
  md:Model.created               "2017-11-24T09:03:09.9446768Z" ;
  md:Model.description           "CGM Test model developed by Statnett SF. Nordic 44 bus system for the Nordic region" ;
  md:Model.modelingAuthoritySet  "http://www.Statnett.no/IGM/Nordic44_CGM" ;
  md:Model.profile               "http://entsoe.eu/CIM/SteadyStateHypothesis/1/1" , "http://entsoe.eu/CIM/SteadyStateHypothesis/1/2" ;
  md:Model.scenarioTime          "2015-03-06T01:30:00.0000000Z" ;
  md:Model.version               "36" ;
  pti:Model.createdBy            "Statnett SF" .

<file:///d:/Onto/proj/electrical/Nordic44/Instances/CGMES_2_4/Nordic44_CGM_36d_SSH.xml#_e2f56599-a78e-494f-8db3-c0b0bdab1d70>
  rdf:type                    cim:Terminal ;
  cim:ACDCTerminal.connected  "true" .
```
The problem is that there's no relation between the model and CIM triples whatsoever.
The fact that they appear in the same file doesn't matter at all when it comes to the RDF representation.
(Just because some triples appear in a file, does not link the triples to the model URI in that file).
If you load this file to a semantic repository, these triples will be mixed with millions of other triples, losing all connection to the model.

Statement sets are modeled in the ontology by using the RDF Reification ontology:
`rdf:Statement` (sometimes misspelled `rdf:Statements`),
with props `rdf:subject, rdf:predicate, rdf:object`
(sometimes misspelled `rdf:Statement.subject, rdf:Statement.predicate, rdf:Statement.object`).
But Reification is a very inefficient way to capture statements.
So in instance data, CIM doesn't actually use that construct.

It was agreed that each model will be represented as a Named Graph
that contains the model metadata and triples (thus they become quads).
The model URN is also used as graph URN (name).
We can express this in TriG (Turtle with Graphs) as follows, where we also:
- Use the `rdfg:Graph` class to emphasize that the model is a named graph
- Fix the relative instance URL to an absolute URL

```ttl
PREFIX rdfg: <http://www.w3.org/2004/03/trix/rdfg-1/>

<urn:uuid:1d8b61bc-c7f3-4e9e-a3bd-f4ec24beb586> {
  <urn:uuid:1d8b61bc-c7f3-4e9e-a3bd-f4ec24beb586>
    rdf:type                       md:FullModel, rdfg:Graph ;
    md:Model.DependentOn           <urn:uuid:2dd9014f-bdfb-11e5-94fa-c8f73332c8f4> ;
    md:Model.created               "2017-11-24T09:03:09.9446768Z" ;
    md:Model.description           "CGM Test model developed by Statnett SF. Nordic 44 bus system for the Nordic region" ;
    md:Model.modelingAuthoritySet  "http://www.Statnett.no/IGM/Nordic44_CGM" ;
    md:Model.profile               "http://entsoe.eu/CIM/SteadyStateHypothesis/1/1" , "http://entsoe.eu/CIM/SteadyStateHypothesis/1/2" ;
    md:Model.scenarioTime          "2015-03-06T01:30:00.0000000Z" ;
    md:Model.version               "36".

  <http://www.Statnett.no/IGM/Nordic44_CGM/_e2f56599-a78e-494f-8db3-c0b0bdab1d70>
    rdf:type                    cim:Terminal ;
    cim:ACDCTerminal.connected  "true" .
}
```

## Representing Difference Models
- https://github.com/Sveino/Inst4CIM-KG/issues/53 representing difference models
- https://github.com/Sveino/Inst4CIM-KG/issues/85 problems converting CIM XML files to Turtle

The problem is especially acute for difference models.
[CGMES-TC/FullGrid_SC_diff.xml](https://github.com/Sveino/CGMES-TC/blob/develop/v3.0/FullGrid/FullGrid_SC_diff/FullGrid_SC_diff.xml) is an example of such a model.
CIM XML uses its own dialect of RDF/XML with `rdf:parseType="Statements"`.
This non-standard addition is only supported in CIM-specific tools
and is a major impediment to the use of standard semantic web processing tools.
(Eg if you use Jena, the `parseType="Statements"` payload is captured as a string, not as triples).

CIM Difference Models are important because they allow to record a delta against a base model,
thus enabling "What If" analysis and other important scenarios.

In particular, a Difference Model is associated with 4 named graphs:
- Model metadata in the model graph
- Refers to the base model using `md:Model.Supersedes`
- Checks for the presence of certain statements using `dm:preconditions` (but this is not used in CIM)
- Specifies statements to delete using `dm:reverseDifferences`
- Specifies statements to insert using `dm:forwardDifferences`


## Naive JSON-LD Graph Representation Attempt
Note: in this and the next subsection we use illustrative graph names (eg `base-model, reverse, forward`) but these are not valid `urn:uuid` URNs.

RDF/XML cannot carry named graphs, but JSON-LD and Trig (Turtle with graphs) can.
- https://github.com/3lbits/CIM4NoUtility/discussions/321 Converting CIMXML DifferenceModel to CIMJSON-LD
  makes a couple of naive attempts to represent a `DifferenceModel` using the nesting structure of JSON-LD.

See the [trials](trials) folder for some attempts.
For example, `option2.jsonld` looks like this:

```json
{
  "@graph": [
    {
      "@id": "urn:uuid:difference-model1",
      "@type": "dm:DifferenceModel",
      "dm:reverseDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {"cim:Length.value": 50.0}
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "@type": "cim:Switch",
          "cim:IdentifiedObject.Name": "Switch1"
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model2",
      "@type": "dm:DifferenceModel",
      "dm:forwardDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {"cim:Length.value": 55.0}
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "@type": "cim:Switch",
          "cim:IdentifiedObject.Name": "Switch2"
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model3",
      "@type": "dm:DifferenceModel",
      "dm:reverseDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {"cim:Length.value": 60.0}
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model4",
      "@type": "dm:DifferenceModel",
      "dm:forwardDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {"cim:Length.value": 65.0}
        }
      ]
    }
  ]
}
```

But if we convert this to Trig using Jena RIOT:
```
riot --formatted=trig option2.jsonld > option2.trig
```
We see a mixup:
- Two of the reverse differences are mixed together at `model1`
- Two of the forward differences are mixed together at `model2`
- The statements `Conductor.length` are mixed together
```ttl
<urn:uuid:difference-model1>
  rdf:type               dm:DifferenceModel ;
  dm:reverseDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> , <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:difference-model2>
  rdf:type               dm:DifferenceModel ;
  dm:forwardDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> , <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:difference-model3>
  rdf:type               dm:DifferenceModel ;
  dm:reverseDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:difference-model4>
  rdf:type               dm:DifferenceModel ;
  dm:forwardDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5>
  rdf:type                   cim:Switch ;
  cim:IdentifiedObject.Name  "Switch2" , "Switch1" .

<urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9>
  rdf:type              cim:ACLineSegment ;
  cim:Conductor.length  [ cim:Length.value  65 ] ;
  cim:Conductor.length  [ cim:Length.value  60 ] ;
  cim:Conductor.length  [ cim:Length.value  55 ] ;
  cim:Conductor.length  [ cim:Length.value  50 ] .
```

## Nearly Correct JSON-LD Graph Representation

We can correct the representation by adding graph names (URNs).
Let's start with Trig (`option3.trig`).
```ttl
<urn:uuid:base-model> a dm:Model.

<urn:uuid:base-model> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5>
    rdf:type                   cim:Switch ;
    cim:IdentifiedObject.Name  "Switch1".

  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9>
    rdf:type              cim:ACLineSegment ;
    cim:Conductor.length  [ cim:Length.value  50 ] .
}

<urn:uuid:difference-model1> a dm:DifferenceModel ;
  md:Model.Supersedes <urn:uuid:base-model>;
  dm:forwardDifferences <urn:uuid:difference-model1-forward>;
  dm:reverseDifferences <urn:uuid:difference-model1-reverse>.

<urn:uuid:difference-model1-reverse> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  50 ] .
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> cim:IdentifiedObject.Name "Switch1" .
}

<urn:uuid:difference-model1-forward> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  55 ] .
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> cim:IdentifiedObject.Name "Switch2" .
}


<urn:uuid:difference-model2> a dm:DifferenceModel ;
  md:Model.Supersedes <urn:uuid:difference-model1>;
  dm:reverseDifferences <urn:uuid:difference-model2-reverse>;
  dm:forwardDifferences <urn:uuid:difference-model2-forward>.

<urn:uuid:difference-model2-reverse> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  60 ]
}

<urn:uuid:difference-model2-forward> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  65 ]
}
```

Let's convert this to JSON-LD.
- The crucial difference is that the `@graph` elements now have `@id`
- There are also two levels of `@graph`: an outer envelope that carries all quads, and inner named graphs
```
{
  "@graph": [
    {
      "@id": "urn:uuid:base-model",
      "@type": "dm:Model",
      "@graph": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "cim:Conductor.length": {"@id": "_:b4"},
          "@type": "cim:ACLineSegment"
        },
        {
          "@id": "_:b4",
          "cim:Length.value": {
            "@value": "50",
            "@type": "xsd:integer"
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "cim:IdentifiedObject.Name": "Switch1",
          "@type": "cim:Switch"
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model1",
      "dm:reverseDifferences": {"@id": "urn:uuid:difference-model1-reverse"},
      "dm:forwardDifferences": {"@id": "urn:uuid:difference-model1-forward"},
      "md:Model.Supersedes": {"@id": "urn:uuid:base-model"},
      "@type": "dm:DifferenceModel"
    },
    {
      "@id": "urn:uuid:difference-model1-reverse",
      "@graph": [
        {
          "@id": "_:b0",
          "cim:Length.value": {
            "@value": "50",
            "@type": "xsd:integer"
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "cim:Conductor.length": {
            "@id": "_:b0"
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "cim:IdentifiedObject.Name": "Switch1"
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model1-forward",
      "@graph": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "cim:Conductor.length": {
            "@id": "_:b3"
          }
        },
        {
          "@id": "_:b3",
          "cim:Length.value": {
            "@value": "55",
            "@type": "xsd:integer"
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "cim:IdentifiedObject.Name": "Switch2"
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model2",
      "dm:forwardDifferences": {"@id": "urn:uuid:difference-model2-forward"},
      "dm:reverseDifferences": {"@id": "urn:uuid:difference-model2-reverse"},
      "md:Model.Supersedes": {"@id": "urn:uuid:difference-model1"},
      "@type": "dm:DifferenceModel"
    },
    {
      "@id": "urn:uuid:difference-model2-reverse",
      "@graph": [
        {
          "@id": "_:b1",
          "cim:Length.value": {
            "@value": "60",
            "@type": "xsd:integer"
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "cim:Conductor.length": {
            "@id": "_:b1"
          }
        }
      ]
    },
    {
      "@id": "urn:uuid:difference-model2-forward",
      "@graph": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "cim:Conductor.length": {
            "@id": "_:b2"
          }
        },
        {
          "@id": "_:b2",
          "cim:Length.value": {
            "@value": "65",
            "@type": "xsd:integer"
          }
        }
      ]
    }
  ]
}
```

Note: We'll see later how by using a richer `@context` we'll reduce the expanded representation:
```json
"cim:Length.value": {
 "@value": "50",
 "@type": "xsd:integer"
}
```

To the compact and natural representation:
```json
"cim:Length.value": "50"
```

But there are still some problems:
- URNs like `urn:uuid:difference-model1-forward` are not valid URNs under the `urn:uuid:` scheme,
  so we must generate new UUIDs for the `reverse` and `forward` graphs.
- There are blank nodes represented in Trig as `cim:Conductor.length [cim:Length.value 60]`
  and in JSON-LD as  `_:b4` etc.
  This is a problem, since we cannot delete a blank node by specifying another blank node in the `reverse` graph.
  Every two blank nodes are different, unless they came from the same file and have the same blank node name.
  So it is good that actual CIM instance data has the simpler representation `cim:Conductor.length "60"`,
  and we fixed the CIM ontologies to use the simpler representation (https://github.com/Sveino/Inst4CIM-KG/issues/38)

## Custom CIM XML Parser
https://github.com/Sveino/Inst4CIM-KG/issues/94 make custom CIM XML parser

We need to implement a custom CIM XML parser that handles `parseType="Statements"` and emits named graphs.

[cim-trig.pl](cim-trig.pl) is a Perl script that converts CIM XML file to Trig (Turtle with graphs).
It uses simple string manipulation rather than a XML parser, so it relies on a repeatable CIM XML layout as lines:
- A file has exactly one model: `md:FullModel` or `dm:DifferenceModel`
- `dm:DifferenceModel` has exactly two sections `dm:reverseDifferences` and `dm:forwardDifferences`, in this order, even if one of them is empty

It uses command-line tools to do the bulk of the work (see `sub ttl`):
- For prettier formatting, it runs `owl-cli` by `@atextor` (the Windows version of a batch file)
  as described at [atextor Tools: owl-cli and turtle-formatter](https://github.com/Sveino/Inst4CIM-KG/blob/develop/rdfs-improved#atextor-tools-owl-cli-and-turtle-formatter) :
```
owl.bat write --keepUnusedPrefixes -i rdfxml ...rdf ...ttl
```
- For very large files, give option `-r` to use Jena Riot in streaming mode:
```
riot.bat --syntax=rdfxml --stream=ttl ...rdf > ...ttl
```

For a `dm:DifferenceModel` it invokes the command-line tool 3 times:
- To convert the model statements
- To convert the `dm:reverseDifferences` statements
- To convert the `dm:forwardDifferences` statements

It generates new `urn:uuid` URIs for the reverse and forward models (using UUID v4),
and adds named graphs to all model parts.
In particular, model metadata is stored in the model graph,
so it can be updated or deleted easily (eg by using the SPARQL Graph Protocol).

It also sets a base to convert relative URLs to absolute URLs correctly (see next section).

See test results in [test/trig](test/trig). Let's look at a couple of examples.

[test/trig/FullGrid_OP.trig](test/trig/FullGrid_OP.trig):
```ttl
<urn:uuid:52a409c9-72d8-4b5f-bf72-9a22ec9353f7> { # model graph

# model metadata
<urn:uuid:52a409c9-72d8-4b5f-bf72-9a22ec9353f7> a md:FullModel ;
  md:Model.DependentOn <urn:uuid:0cd6ada4-b6dc-4a36-a98c-877a39168cd3> ;
  md:Model.created "2020-12-10T00:21:43Z" ;

# statements
<http://fullgrid.eu/CGMES/3.0#_13dacabf-aa4c-4a78-806e-c7c4c6949718> a cim:Discrete ;
  cim:Discrete.ValueAliasSet <http://fullgrid.eu/CGMES/3.0#1a457323-2094-440f-8d30-dc93adf0cdb3> ;
...
}
```

[test/trig/FullGrid_OP_diff.trig](test/trig/FullGrid_OP_diff.trig):
```ttl
<urn:uuid:05edbf91-231f-4386-97c0-d4cb498d0afc> { # model graph

# model metadata
<urn:uuid:05edbf91-231f-4386-97c0-d4cb498d0afc> a dm:DifferenceModel ;
  dm:forwardDifferences <urn:uri:63528ef9-48ff-469b-a58e-ba274f2a10bb> ;
  dm:reverseDifferences <urn:uri:27c8a164-c656-4712-994a-0ab7cec4fd34> ;
  md:Model.DependentOn <urn:uuid:0cd6ada4-b6dc-4a36-a98c-877a39168cd3> ;
  md:Model.Supersedes <urn:uuid:52a409c9-72d8-4b5f-bf72-9a22ec9353f7> ; # base model
  md:Model.created "2021-11-19T23:16:27Z" ;
}


<urn:uri:27c8a164-c656-4712-994a-0ab7cec4fd34> { # reverseDifferences
  <http://fullgrid.eu/CGMES/3.0#87478acb-cd1f-40a6-b4a7-59ec99f8b063> cim:IdentifiedObject.description "SET_PNT_1" .
  <http://fullgrid.eu/CGMES/3.0#fc908c16-468f-4a64-ba74-6f57175e0005> cim:AnalogLimit.value "99" .
}

<urn:uri:63528ef9-48ff-469b-a58e-ba274f2a10bb> { # forwardDifferences
  <http://fullgrid.eu/CGMES/3.0#87478acb-cd1f-40a6-b4a7-59ec99f8b063> cim:IdentifiedObject.description "SET_PNT_1 test" .
  <http://fullgrid.eu/CGMES/3.0#fc908c16-468f-4a64-ba74-6f57175e0005> cim:AnalogLimit.value "100" .
}
```

# CIM URIs and Resolvability

## Fix Under-defined Resource URLs
- https://github.com/Sveino/Inst4CIM-KG/issues/87 bad relative URLs (need BASE or `urn:uuid:`)
- https://github.com/Sveino/Inst4CIM-KG/issues/98 URL policy about MAS and BASE
- https://github.com/Sveino/Inst4CIM-KG/issues/143 use slash not hash in instance URLs (and remove parasitic underscore)

The URLs of CIM power system resources are represented in CIM XML like this:
- Definition:
  - `rdf:ID="_f37786d0-b118-4b92-bafb-326eac2a3877"`
  - or `rdf:about="#_f37786d0-b118-4b92-bafb-326eac2a3877"`
- Reference: `rdf:resource="#_44e63d79-6b05-4c64-b490-d181863af7da"`

They have several problems:
- These are relative URLs.
  - However, CIM XML files don't specify `xml:base` (see RDF 1.1 XML Syntax, section [2.14 Abbreviating URIs: rdf:ID and xml:base](https://www.w3.org/TR/rdf-syntax-grammar/#section-Syntax-ID-xml-base)).
  - This means the URLs are resolved in a tool-dependent way (e.g. by using the file location on local disk).
  - This is a serious problem that undermines the interoperability and stability of resource URLs.
  - We've resolved it by declaring `md:Model.modelingAuthoritySet` as BASE.
  - This is fixed by the [cim-trig.pl](cim-trig.pl) script described in the previous section: see URL examples there.
- They use trailing `#` (hash), which is added by `rdf:ID` by definition.
  - Using hash is not a good idea for a large collection of resources if they would ever be **resolvable**
    (which is the main reason for using URLs instead of URNs).
  - A client doesn't send the part after the hash, so the server would have to return the complete collection of instances.
- There is a parasitic `_` (underscore).
  - The reason is that `rdf:ID` cannot start with a digit (but UUIDs can), see
    - RDF 1.1 XML Syntax, section [C.1 RELAX NG Compact Schema](https://www.w3.org/TR/rdf-syntax-grammar/#h3_section-RELAXNG-Schema), `IDsymbol`
    - XML Schema Definition Language (XSD) 1.1 Part 2: Datatypes, section [3.4.4 NMTOKEN](https://www.w3.org/TR/xmlschema11-2/#NMTOKEN)
    - Extensible Markup Language (XML) 1.1 (Second Edition) section [Nmtoken](https://www.w3.org/TR/xml11/#NT-Nmtoken)
  - `rdf:about` could have been used instead of `rdf:ID` to avoid that limitation.
  - This is a purely cosmetic problem but still annoying.

The last two problems cannot be fixed in CIM XML because of `rdf:ID`.
- They could be fixed in `cim-trig.pl` by rewriting URLs in the resulting Trig.
- That will lead to an inconsistency with regards to CIM XML URLs.
- But those URLs are under-defined (because of lacking `xml:base`), so I think we should do these fixes as well.

## Resolvable Resource URLs or More Stable `urn:uuid`?
Although important resources have Energy Identification Codes (EIC), all resource URIs are based on UUIDs.
In CIM XML these URIs are under-defined URLs, and the previous section describes how to fix this by setting `xml:base`.

- https://github.com/Sveino/Inst4CIM-KG/issues/98 URL policy about MAS and BASE.

This issue also discusses a desire for CIM data to be resolvable, following Linked Data principles.
The benefits of such resolution are that one can fetch:
- Up to date information on-demand
- Data at a granularity chosen by the client not the server

For example, the complete Norwegian grid model is 800Mb 
and it is transferred multiple times per day between electricity authorities.
If semantic resolution was available, this could be done in smaller portions, 
and at different frequencies for different resources.

**Resources** are real-world things (eg transmission lines, power stations) 
and some of them are managed jointly by more than one authority.
CIM records actual or hypothetical information about resources in **Models**,
and the same resource may appear in multiple models.
The same resource should have the same URL, regardless in how many models or profiles it appears.

So resource URLs can be made resolvable only after careful consideration:
- Each Modeling Authority should be careful about the selection and stability of its URLs
- Resource URLs should not include profile names or model versions

The above issue records some sound critique:
- CIM XML models include a single `ModelAuthoritySet` (MAS).
  That MAS is currently used by `cim-trig.pl` as the namespace (base) for **all resource** URLs involved in the model.
  But as outlined above, resource URLs should be model-independent.
  Therefore a TSO should adopt a **single MAS** for all its models, which may be infeasible.
- Relying solely on MAS as a stable base seems too restrictive 
  and may lead to long-term stability, maintenance and consistency problems as domains and schemes inevitably evolve.
- Using resource URLs instead of URNs may endanger the stability of CIM URIs due to:
  - TSO changes over time
  - Different URL policies/approaches by different TSOs, or different departments of the same TSO
  - Boundary and merged profiles tend to require different MAS
  - Current CGMES recommended practice is for SV and DL profiles not to have any MAS

In addition, making CIM resources resolvable is perhaps not a valid goal.
- Statements about the same resource may be located in multiple models (named graphs).
- While it is possible to return resource data as quads and include all statements about the resource, 
  that is unusual and may be too granular and not a useful CIM response.
- The reason is that the unit of exchange in CIM is the model, which leads to the next section

In conclusion, it seems better to reformat instance URIs to use `urn:uuid:` instead of URLs.

## Resolvable Model (Graph) URLs?
The unit of data exchange in CIM is the **model**.
A model includes all statements relevant to a power system analytics task.
- It may also refer to other required models using `Model.DependentOn`
- In the case of a DifferenceModel, it also refers to `Model.Supersedes` (base model),
  `reverseDifferences` and `forwardDifferences` (statements to be deleted/inserted).

Currently CIM XML uses `urn:uuid` for models, but `urn:uuid` does not facilitate resolution
(barring a central authority that would track all model URIs minted by any authority, which is unfeasible).

As explained above, we represent models as named graphs.
One can use the [SPARQL 1.1 Graph Store HTTP Protocol](https://www.w3.org/TR/sparql11-http-rdf-update/) to resolve graph URLs and return data:
see [Direct Graph Identification](https://www.w3.org/TR/sparql11-http-rdf-update/#direct-graph-identification). 

## Global Semantic Resolution

- https://github.com/Sveino/Inst4CIM-KG/issues/144 Global semantic resolver for electrical data

To enable semantic resolution of electricity-related URLs, there are two options:
- Each authority (TSO or other issuer of CIM data) designs and maintains its own namespace.
  Resolution is based solely on the internet's Domain Name System.
- A global resolver (operated e.g. by ENTSO-E) maintains a single harmonized namespace that redirects (delegates) to specific authorities.
  The benefit is that the central resolver can enforce a stable naming policy 
  that will keep URLs stable in the face of TSO changes.

Global resolution strategies are already used by multiple communities:
- **Publishing: DOIs**: eg https://dx.doi.org/10.13140/RG.2.2.33957.10729 .
  The delegation is done based on DOI prefix, see [P1662](https://www.wikidata.org/wiki/Property:P1662) on Wikidata.
  Eg `10.13140` above designates `DataCite` (which serves as registrant on behalf of `ResearchGate`). 
  The DOI Foundation also keeps registrant pages, eg https://dx.doi.org/10.13140 .
- **Internet: IP addresses**:
  IANA and national agencies (like ARIN for USA and Canada) allocate IP addresses in blocks,
  which are further subdivided by the IP registrant.
  IPs are a fixed number of bits and don't include a separator, 
  so bigger registrants get shorter prefixes and are allocated bigger network blocks.
- **Web ID**: https://w3id.org/ by the W3C Permanent Identifiers Community Group
  is a permalink resolver implemented as a simple Apache web server with `.htaccess` files.
  These files are managed in a decentralized manner using the [perma-id/w3id.org](https://github.com/perma-id/w3id.org/) Github repo and pull requests.
  Identifiers are allocated on a first-come-first-served basis.
  - See [examples](https://github.com/perma-id/w3id.org/tree/master/examples) for a detailed description
  - See [example](https://github.com/perma-id/w3id.org/tree/master/example) for publishing an ontology
  - See [lbd/aec3po](https://github.com/perma-id/w3id.org/tree/master/lbd/aec3po) for publishing the Architecture, Engineering and Construction Compliance Checking and Permitting ontology (AEC3PO) at a permanent URL under the Linked Building Data group.
    https://w3id.org/lbd/aec3po currently resolves to https://ci.mines-stetienne.fr/aec3po/ ,
    but if that university is unable to provide the resource at some future point,
    another partner can pick up the hosting, requiring only a simple change in Github.
- **Logistics: GS1 Digital Links** based on identifiers like GTIN, GLN, GIAI etc: 
  eg https://id.gs1.org/gtin/9506000134352?linkType=all . 
  The delegation is based on GS1 Company Prefix, see [P3193](https://www.wikidata.org/wiki/Property:P3193) on Wikidata.
  GTIN etc are fixed-width, so similarly to IP addresses, bigger registrants get shorter prefixes.
  Eg `95060001343` above is one of the prefixes for "GS1 Global Office" (search at [gs1-company-database-gepir](https://www.gs1us.org/tools/gs1-company-database-gepir)),
  and `52` is an example product type within this prefix.
- **Legal Entity Identifiers**: e.g. [5967007LIEEXZXHAI017](https://search.gleif.org/#/record/5967007LIEEXZXHAI017) is Statnett
  and the LEI is issued by [5299000J2N45DDNE4Y28](https://search.gleif.org/#/record/5299000J2N45DDNE4Y28) WM Datenservice 
  based on Statnett's national registration with the Brønnøysund Register Centre
  GLEIF delegates LEI issuance to licensed Local Operating Units (LOUs).
  But rather than delegating the resolution, it keeps a central LEI database that is synchronized often with LOU data.
- **EU Semantic Resources**, e.g. European Agency for Railways [ERA Ontology](https://linkedvocabs.org/data/era-ontology/3.1.0/doc/index-en.html)
  has the semantic URL http://data.europa.eu/949/ , e.g. http://data.europa.eu/949/AggregatedObject .
  (Note: the semantic URL currently does not resolve nicely, but ERA has plans to make the resolution better).
  URL allocation is based on a numeric prefix (eg `949`) and delegation is managed by the EU Publications Office.
 
For more examples, see the Wikipedia articles on
[Persistent identifier](https://en.wikipedia.org/wiki/Persistent_identifier), [Permalink](https://en.wikipedia.org/wiki/Permalink), [PURL](https://en.wikipedia.org/wiki/Persistent_Uniform_Resource_Locator "Persistent Uniform Resource Locator"), [Handle](https://en.wikipedia.org/wiki/Handle_System "Handle System"), and [DOI](https://en.wikipedia.org/wiki/Digital_Object_Identifier "Digital Object Identifier").
 
### Energy Identification Code
What is the situation regarding permanent URLs in electricity:

ENTSO-E has defined the Energy Identification Code (EIC), 
eg see [P8645](https://www.wikidata.org/wiki/Property:P8645) on Wikidata and [Energy Identification Code](https://en.wikipedia.org/wiki/Energy_Identification_Code) on Wikipedia.
- ENTSO-E delegates EIC issuance to Local Issuing Offices (LIOs). As of 2024-12-17, there are [62 LIOs](https://www.entsoe.eu/data/energy-identification-codes-eic/#eic-lio-websites).
- ENTSO-E keeps a central database:
  - https://www.entsoe.eu/data/energy-identification-codes-eic/eic-approved-codes/ lists 59.5k (select "EIC type: All codes" and "Show: 100")
  - https://transparency.ontotext.com/graphdb/sparql (ask for login) lists 58.6k with this SPARQL query
```sparql
PREFIX tr: <https://transparency.ontotext.com/resource/tr/>
select (count(*) as ?c) {?x tr:eic ?y} 
```
- However, the central database doesn't offer individually resolvable pages per EIC. Furthermore, it is incomplete. 
 - The Wikidata page lists over 20 "source website for the property", and eg for https://iodb.elia.be/en/publiceiclist/indexpartialview the first two EIC `22T20160907---1Y, 22T20160907----1` are missing. These are "Internal Lines" but other Internal Lines are present in the central database
  - ENTSO-G https://www.entsog.eu/approved-codes refers to the ENTSO-E list, but my impression is that Gas-related codes are more sparsely represented in the central database
- The first two EIC chars are the LIO code so potentially could be used for redirecting. 
However, LIOs don't have an obligation to publish resolvable pages; the [EIC Reference Manual](https://eepublicdownloads.entsoe.eu/clean-documents/EDI/Library/EIC_Reference_Manual_Release_5_5.pdf#page=8.74) only mandates:
  - to provide a local registry on a web-page accessible by third parties. The LIO publishes the energy sector (gas or electricity or both) and the EIC code types that it covers;
  - to publish the list of all EIC codes allocated by the LIO in a processable form according to the EIC implementation guide that can be downloaded by third party

### Energy Reference Data

https://energy.referencedata.eu/ currently has a number of important lists, but no per-resource resolution.
- It serves whole semantic files, eg https://energy.referencedata.eu/StandardReasonCodeTypeList.ttl
- Needless to say, the EIC register https://energy.referencedata.eu/EIC.ttl is pretty huge.

### UUIDs

CIM/CGMES requires that node URNs are based on UUIDs. 
- EICs of major resources are recorded as additional identifiers
- But the main (canonical) mRID is based on UUID
- UUIDs don't have a prefix that would allow partitioning/delegation, which makes global resolution problematic
  (barring a central authority that would track all resource or model URIs minted by any authority, which is unfeasible)

So we would need to rely on some URL prefix before the UUID to enable resolution.
ENTSO-E could operate a central resolver and redirect per prefix:
- For example
  - `https://energy.referencedata.eu/model/statnett/<uuid>` vs 
  - `https://energy.referencedata.eu/model/elia/<uuid>`
- This is bit better than relying on TSO-specific namespaces, eg
  - `http://data.statnett.no/<uuid>` vs
  - `https://iodb.elia.be/<uuid>`
- Of course, it's still up to authorities to serve meaningful data for these URLs

# Add Datatypes To Instance Data
https://github.com/Sveino/Inst4CIM-KG/issues/49 Add Datatypes To Instance Data

In CGMES instance data, all literals are strings, but should be marked with the appropriate datatype.
- E.g. `cim:ACDCConverter.baseS` should be marked `^^xsd:float`
- Otherwise sort won't work properly and range queries will be slower.
- This pertains to `boolean, dateTme, float, gMonthDay, integer`
- `string` is the default datatype

[Property Datatype Maps](../rdfs-improved#property-datatype-maps) and the sibling folder [datatypes](../rdfs-improvement/datatypes) make a comprehensive analysis.
We extract a datatypes map, omitting hijacked namespaces and `xsd:string`:
```
grep -E '^(cim|nc|eu|md|eumd)' datatypes-older.tsv | grep -v xsd:string > fix-datatypes.ru
```
Then we format it as `values` for use in SPARQL.

We make 3 scripts to account for namespace differences:
- [fix-datatypes-old.ru](fix-datatypes-old.ru) works with the old namespaces:
```sparql
prefix cim: <http://iec.ch/TC57/CIM100#>
prefix eu:  <http://iec.ch/TC57/CIM100-European#>
```
- [fix-datatypes-new.ru](fix-datatypes-new.ru) works with the new namespaces:
```sparql
prefix cim:  <https://cim.ucaiug.io/ns#>
prefix eu:   <https://cim.ucaiug.io/ns/eu#>
```
- [fix-datatypes-both.ru](fix-datatypes-both.ru) works with either namespaces.
- Note: the NC spec is new, so its prefix is only available in the new namespaces:
```sparql
prefix nc:   <https://cim4.eu/ns/nc#>
```

The more complex "both" script works like this:
- Defines dual prefixes `cim, cim1` and `eu, eu1`:
```sparql
prefix cim:  <https://cim.ucaiug.io/ns#>
prefix cim1: <http://iec.ch/TC57/CIM100#>
prefix eu:   <https://cim.ucaiug.io/ns/eu#>
prefix eu1:  <http://iec.ch/TC57/CIM100-European#>
prefix nc:   <https://cim4.eu/ns/nc#>
prefix eumd: <https://cim4.eu/ns/Metadata-European#>
prefix md:   <http://iec.ch/TC57/61970-552/ModelDescription/1#>
prefix xsd:  <http://www.w3.org/2001/XMLSchema#>
```
- After  [Represent Models as Named Graphs](#represent-models-as-named-graphs), all CIM triples live in named graphs, so:
```
delete {graph ?g {?x ?p ?old}}
insert {graph ?g {?x ?p ?new}}
```
- The `where` clause includes a pretty huge mapping table from props to datatypes
  - It finds quads where the `?old` value is `xsd:string`
  - Maps it to the appropriate datatype, considering different namespace versions
```
where {
  values (?prop ?dt) {
    (cim:ACDCConverter.baseS xsd:float)
    # 3000 more rows
  }
  graph ?g {?x ?p ?old}
  filter(datatype(?old)=xsd:string)
  bind(if(strstarts(str(?p),str(cim1:)),uri(concat(str(cim:),strafter(str(?p),str(cim1:)))),?UNDEF) as ?p1)
  bind(if(strstarts(str(?p),str(eu1:)), uri(concat(str(eu:), strafter(str(?p),str(eu1:)))), ?UNDEF) as ?p2)
  filter(?p=?prop || ?p1=?prop || ?p2=?prop)
  bind(strdt(?old,?dt) as ?new)
};
```

These updates can be applied on:
- One CIM file, using an in-memory SPARQL Update tool like Jena `update.bat` (but it needs inordinate amounts of RAM for large files)
- A whole repository of CIM data, eg using GraphDB

We include 3 versions because applying "both" on old data produces `cim1, eu1` prefixes.
This is harmless, but doesn't look nice.

# Sample Instance Data
To work out reasoning, validation and performance issues, we need sample instance data.
We can use the following datasets (one of them has minor defects):
- https://github.com/Sveino/Inst4CIM-KG/issues/134 `ENTSO-E_Test_Configurations_v3.0.2` defects

| dataset                                 | xml   | zip  | files | FullModel | triples |  largest | largest file                             |
|-----------------------------------------|-------|------|-------|-----------|---------|----------|------------------------------------------|
| [Nordic44](https://github.com/Sveino/Nordic44/tree/develop/Instances)                           | 2.9M  |      |    15 |        12 |   35481 |    17420 | CGMES_2_4/Nordic44_CGM_37a_EQ.xml        |
| [ENTSO-E_Test_Configurations_v3.0.2](https://www.entsoe.eu/Documents/CIM_documents/Grid_Model_CIM/ENTSO-E_Test_Configurations_v3.0.2.zip) | 151M  | 19M  |   357 |       350 | 1844380 |   947208 | RealGrid/RealGrid-Merged/RealGrid_EQ.xml |
| [Multiplied](https://1drv.ms/f/s!AhDObGm0xWObjJI3y0obO3j9L4TSRw?e=4CDbxL)                         | 11G   | 1.9G |     4 |         4 |         | 94720800 | RealGrid_EQ100.zip                       |
| Statnett                                | 800MB | 30MB |       |           |         |          |                                          |

- "FullModel" are files that have a standard `md:FullModel` structure. ENTSOE also has 7 `dm:DifferenceModel`
- See next section for counting triples
- See [Multipled Data](#multipled-data) for "multiplied"
- "Statnett" describes the actual Statnett grid, which is not public data. It's included only for comparison

## Counting Triples
ENTSO-E files are nested 2-3 levels deep in the folder hierarchy:
```
cd ENTSO-E_Test_Configurations_v3.0.2/v3.0
find . -name *.xml |perl -pe 's{[\w-]+}{*}g' | sort | uniq -c
     47 ./*/*/*.*
    310 ./*/*/*/*.*
```

I want to use `riot.bat --count` to see how many triples in total.
But we will exclude `DifferenceModel` files (`*_diff.xml`) because `riot` cannot handle them (they are not standard RDF XML format):
```
find . -name *.xml ! -name *diff* | wc
    350     350   23847
```

The total length of all filenames is quite large (24k) so it overflows the command line:
```
riot.bat --count `find . -name *.xml ! -name *diff*`
The command line is too long.
```

In such case one uses `xargs`.
Since the environment and the command line together are subject to a size limit,
I tried to remove some wordy env vars (`ORIGINAL_PATH= PSModulePath= INFOPATH=`),
but still it's greater than the limit on my shell (Cygwin Bash):
```
find . -name *.xml ! -name *diff* | env ORIGINAL_PATH= PSModulePath= INFOPATH= xargs --show-limit riot.bat --count
Your environment variables take up 3940 bytes
POSIX upper limit on argument length (this system): 26012
POSIX smallest allowable upper limit on argument length (all systems): 4096
Maximum length of command we could actually use: 22072
Size of command buffer we are actually using: 26012
Maximum parallelism (--max-procs must be no greater): 2147483647
The command line is too long.
```
So I have to split the work in several parts: `-n 100` passes 100 files at a time, and `2>` saves STDERR to a file:
```
find . -name *.xml ! -name *diff* | xargs -n 100 riot.bat --count 2> count-ENTSOE.txt
```
I wrote a small script to massage this file:
```
perl count.pl count-ENTSOE.txt > count-ENTSOE1.txt
```

The total is 1844380 (1.8M triples) and the largest file is
```
947208  ./RealGrid/RealGrid-Merged/RealGrid_EQ.xml
```

Nordic44 files are a lot smaller:
```
cd Nordic44/Instances
find . -name *.xml | xargs riot.bat --count 2> count-Nordic.txt
perl count.pl count-Nordic.txt > count-Nordic1.txt
```
The total is 35481 (35k triples) and the largest file is
```
17420	./CGMES_2_4/Nordic44_CGM_37a_EQ.xml
```

## Multipled Data
- https://github.com/Sveino/Inst4CIM-KG/issues/117 multiply instance data

ENTSO-E plus Nordic44 make only 1.8M triples.
This is not very much as semantic databases go, so we decided to multiply it 100 times to obtain bigger examples.

Chavdar Ivanov took 4 files from [ENTSO-E_Test_Configurations_v3.0.2](https://www.entsoe.eu/Documents/CIM_documents/Grid_Model_CIM/ENTSO-E_Test_Configurations_v3.0.2.zip)
and multiplied the data in 4 variants (10, 20, 50 and 100 times).
The results are in this [Microsoft Teams Drive](https://1drv.ms/f/s!AhDObGm0xWObjJI3y0obO3j9L4TSRw?e=4CDbxL).

I got only the largest files: `RealGrid_EQ100.zip, RealGrid_SSH100.zip, RealGrid_SV100.zip, RealGrid_TP100.zip`.
They are 1.9Gb zipped, 11Gb unzipped.

The files use DOS line endings and maybe have byte-order mark (BOM).
BOM doesn't play well with `riot`, so we remove the BOM and convert to Unix line endings:
```
d2u *
```
(This takes about 15 minutes because the files are large)

The files also include
```
xml:base="http://iec.ch/TC57/CIM100"
```
which doesn't match other instance files, contradicts the decision to use `modelAuthoritySet` as base, and is inappropriate for base of instance URLs.
So cim-trig removes it.

The largest file is 8Gb and takes 8 min to convert from CIM XML to Trig (with about 20Gb RAM for Java and similar for Perl).
However, the query `fix-datatypes-old.ru` cannot be executed in-memory with the Jena `update` command on my laptop (64Gb RAM).
With default JVM parameters, it throws:
```
Exception: java.lang.OutOfMemoryError thrown from the UncaughtExceptionHandler in thread "main"
```

We allow Java to take 60Gb, but that causes swapping and slows down the process:
```
# cmd:
set JVM_ARGS=-Xmx60000M -Dfile.encoding=UTF-8
update.bat --update=fix-datatypes-old.ru --data=temp1.trig --dump > instances/multiplied/RealGrid_EQ100.trig

# bash:
export JVM_ARGS="-Xmx60000M -Dfile.encoding=UTF-8"
time update.bat --update=fix-datatypes-old.ru --data=temp1.trig --dump > instances/multiplied/RealGrid_EQ100.trig
```
The process was really busy, taking 60-80% of CPU and lots of RAM. I canceled it after 140 min.
So we need to run this update against a database (GraphDB), not against the Jena in-memory store.

`update` runs successfully only for `RealGrid_TP100.trig` (9.6M triples)

## Final Instance Data
The final instance data for testing consists of the following trig files:

| Instances                          | folders | files | trig  | zip   |
|------------------------------------|---------|-------|-------|-------|
| Nordic44                           |       3 |    12 | 5M    | 340k  |
| ENTSO-E_Test_Configurations_v3.0.2 |      43 |   357 | 179M  | 23.8M |
| multiplied                         |       1 |     4 | 9.67G | 2.2G  |
| TOTAL                              |      47 |   373 | 9.85G | 2.2G  |

- Only ENTSOE has 7 `dm:DifferenceModel`, all others are `md:FullModel`.
- `DifferenceModels` cannot be validated on their own (see `shacl-improved` for a scenario)

The 3 zipped files are available publicly in the Google Folder [instance-zipped](https://drive.google.com/drive/folders/16JDUjSeKY-3rgGsIfAoLn9jr_3YD4Ho_?usp=sharing).

# JSON-LD Serialization

After converting CIM XML to a representation using named graphs (Trig), we can convert it to JSON-LD.
E.g. to convert an instance file using the old namespaces, we use this command:
```
riot.bat --formatted jsonld test/trig/FullGrid_OP.trig | jsonld compact -c https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdf-improved/cim-context-old.jsonld
```
The tools used are described  in the sibling folder at [JSON-LD Serialization](https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#json-ld-serialization).


## JSON-LD Context
A good JSON-LD serialization depends on an appropriate context that defines namespaces 
and property characteristics i.e. `@type` (`@id` for object props, XSD datatype for datatype props).

We want to cater to old and new namespaces, so we use some text (not proper JSON-LD) files to assemble contexts:
- cim-context-common.txt: a common file that defines the common namespaces, and characteristics for about 5100 props
- (cim-context-strings.txt: a "spill-over" file that defines 120 `xsd:string` properties: not added to context since that is the default datatype)
- cim-context-new.txt: prefix file for JSON-LD context using new namespaces
```
 {"cim":          "https://cim.ucaiug.io/ns#",
  "eu":           "https://cim.ucaiug.io/ns/eu#",
```
- cim-context-old.txt: prefix file for JSON-LD context using old namespaces
```
 {"cim":          "http://iec.ch/TC57/CIM100#",
  "eu":           "http://iec.ch/TC57/CIM100-European#",
```

The assembled context files are:
- cim-context-new.jsonld: JSON-LD context using new namespaces
- cim-context-old.jsonld: JSON-LD context using old namespaces

https://github.com/Sveino/Inst4CIM-KG/issues/110 deploy JSON-LD contexts on a permanent network location:
- Currently JSON-LD files use network contexts on "rawgit2.com", which serves them with appropriate `content-type: application/ld+json`:
  - https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdfs-improved/CIM-ontology-context.jsonld for ontologies
  - https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdf-improved/cim-context-old.jsonld for instance files using old namespaces
  - https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdf-improved/cim-context-new.jsonld for instance files using new namespaces
- But we need for a more permanent CIMug or ENTSOE location.

## Formatting of Numbers and Booleans
https://github.com/Sveino/Inst4CIM-KG/issues/120 number representation in JSONLD

JSON has only a few native literal datatypes: `number, boolean, string, null`.
JSON numbers are imprecise:
- There is no distinction between integer and floating point
- JSON doesn't define whether a number should be represented as `float` or `double`
- Exact numbers (`xsd:decimal`) are not available natively

This is raised as issue [json-ld-syntax#387](https://github.com/w3c/json-ld-syntax/issues/387), and is accepted in the [JSON-LD errata](https://w3c.github.io/json-ld-syntax/errata/).

It is therefore better to always use **strings** rather than native **numbers**.
The JSON-LD context (see previois section) attaches appropriate datatypes.

To test the output of CIM numbers and booleans, we made `test/test.rq` that constructs a few triples:
```sparql
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX cim: <https://cim.ucaiug.io/ns#>
construct {
  [] cim:reactance "0.123"^^xsd:float; cim:normallyInService true
} where {}
```
The respective Turtle is `test.ttl`.

Then we tried with a few tools and saved the results:
- `test-GraphDB.jsonld`: GraphDB 10.7.3, save query result as JSON-LD, no context
- `test-Jena-riot.jsonld`:
  - Install from [Apache Jena Commands](https://jena.apache.org/download/index.cgi#apache-jena-binary-distributions)
  - Then run: `riot --formatted jsonld test.ttl > test-ttl2jsonld.jsonld`
- `test-ttl2jsonld.jsonld`, no context:
  - Install with `npm install -g @frogcat/ttl2jsonld`
  - Then run `ttl2jsonld test.ttl > test-ttl2jsonld.jsonld`
- `test-Virtuoso-context.jsonld`: [DBpedia SPARQL endpoint](https://dbpedia.org/sparql), save query result as [JSON-LD with context](https://dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fdbpedia.org&query=PREFIX+xsd%3A+%3Chttp%3A%2F%2Fwww.w3.org%2F2001%2FXMLSchema%23%3E%0D%0APREFIX+cim%3A+%3Chttps%3A%2F%2Fcim.ucaiug.io%2Fns%23%3E%0D%0Aconstruct+%7B%0D%0A++%5B%5D+cim%3Areactance+%220.123%22%5E%5Exsd%3Afloat%3B+cim%3AnormallyInService+true%0D%0A%7D+where+%7B%7D%0D%0A&format=application%2Fld%2Bjson&timeout=30000&signal_void=on&signal_unconnected=on)
- `test-Virtuoso-plain.jsonld`: [DBpedia SPARQL endpoint](https://dbpedia.org/sparql), save query result as [JSON-LD plain](https://dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fdbpedia.org&query=PREFIX+xsd%3A+%3Chttp%3A%2F%2Fwww.w3.org%2F2001%2FXMLSchema%23%3E%0D%0APREFIX+cim%3A+%3Chttps%3A%2F%2Fcim.ucaiug.io%2Fns%23%3E%0D%0Aconstruct+%7B%0D%0A++%5B%5D+cim%3Areactance+%220.123%22%5E%5Exsd%3Afloat%3B+cim%3AnormallyInService+true%0D%0A%7D+where+%7B%7D%0D%0A&format=application%2Fx-ld%2Bjson&timeout=30000&signal_void=on&signal_unconnected=on)

| tool             | reactance          | normallyInService  |
|------------------|--------------------|--------------------|
| GraphDB          | "0.123" xsd:float  | "true" xsd:boolean |
| Jena riot        | "0.123" xsd:float  | "true" xsd:boolean |
| ttl2jsonld       | "0.123" xsd:float  | true               |
| Virtuoso context | 0.1230000033974648 | true               |
| Virtuoso plain   | 0.1230000033974648 | true               |

- GraphDB and Jena output `@value` in quotes and always attach a datatype
- Virtuoso outputs only `@value` without quotes (and adds some fake decimal digits due to internal conversions)
- ttl2json outputs the number as `@value` in quotes with datatype, but the boolean without quotes

Note1: above we didn't specify a context to use. If we do, then more tools may output values in quotes.

Note2: see https://github.com/digitalbazaar/jsonld.js/issues/558 for a similar problem related to native `boolean` in JSON-LD.
