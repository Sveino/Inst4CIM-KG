# Improvements to CIM and CGMES RDF Representation

This document describes proposed inprovements to the representation of CIM/CGMES instance data.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Improvements to CIM and CGMES RDF Representation](#improvements-to-cim-and-cgmes-rdf-representation)
    - [Represent Models as Named Graphs](#represent-models-as-named-graphs)
        - [Naive Graph Representation Attempt](#naive-graph-representation-attempt)
        - [Nearly Correct Graph Representation](#nearly-correct-graph-representation)
        - [Custom CIM XML Parser](#custom-cim-xml-parser)
    - [Fix Resource URLs](#fix-resource-urls)
    - [Add Datatypes To Instance Data](#add-datatypes-to-instance-data)

<!-- markdown-toc end -->

## Represent Models as Named Graphs

CIM Differential Models are important because they allow to record only a delta against a base model,
thus enabling What If analysis and other important scenarios.

A Differential Model:
- Refers to the base model using `md:Model.Supersedes`
- Checks certain statements using `dm:preconditions` (but this is not used in  CIM)
- Specifies statements to delete using `dm:reverseDifferences`
- Specifies statements to insert using `dm:forwardDifferences`

These sets of statements are modeled in the ontology using the RDF Reification ontology:
`rdf:Statement` (sometimes misspelled `rdf:Statements`),
with props `rdf:subject, rdf:predicate, rdf:object`
(sometimes misspelled `rdf:Statement.subject, rdf:Statement.predicate, rdf:Statement.object`).

But Reification is a very inefficient way to capture triples.
So in instance data, CIM doesn't actually use that construct.
CIM uses its own dialect of RDF/XML with `rdf:parseType="Statements"`,
which is a set of statements.
This non-standard addition is only supported in CIM-specific tools
and is a major impediment to the use of standard semantic web processing tools.
For example, https://github.com/Sveino/Inst4CIM-KG/issues/85
describes problems converting CIM XML files to Turtle
(in that case the `parseType="Statements"` payload is captured as a string, not as triples).

Even for `md:FullModel`, there is the more basic problem
that the statements are not associated with the model URI in any way.
(Just because some triples appear in a file, does not link the triples to the model URI in that file).
When a CIM `FullModel` is loaded in a semantic repository,
the triples are intermingled with triples from other models
(and the file name is not saved in any way).

Therefore it was agreed that each model will be represented as a Named Graph
that contains the model triples (thus they become quads):
https://github.com/Sveino/Inst4CIM-KG/issues/53 .

### Naive Graph Representation Attempt

RDF/XML cannot carry named graphs, but JSON-LD and Trig (Turtle with graphs) can.
https://github.com/3lbits/CIM4NoUtility/discussions/321
makes a coupple of naive attempts to represent a `DifferenceModel` using the nesting structure of JSON-LD.

See the [trials](trials) folder for some attempts.
For example, `option2.jsonld` looks like this:

```json
{
  "@context": {
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "cim": "http://iec.ch/TC57/CIM100#",
    "md": "http://iec.ch/TC57/61970-552/ModelDescription/1#",
    "eu": "http://iec.ch/TC57/CIM100-European#",
    "dm": "http://iec.ch/TC57/61970-552/DifferenceModel/1#"
  },
  "@graph": [
    {
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d",
      "@type": "dm:DifferenceModel",
      "dm:reverseDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {
            "cim:Length.value": 50.0
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "@type": "cim:Switch",
          "cim:IdentifiedObject.Name": "Switch1"
        }
      ]
    },
    {
      "@id": "urn:uuid:f1aa3e3a-8391-4bf9-b435-6bd0702f9e0d",
      "@type": "dm:DifferenceModel",
      "dm:forwardDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {
            "cim:Length.value": 55.0
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "@type": "cim:Switch",
          "cim:IdentifiedObject.Name": "Switch2"
        }
      ]
    },
    {
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6t",
      "@type": "dm:DifferenceModel",
      "dm:reverseDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {
            "cim:Length.value": 60.0
          }
        }
      ]
    },
    {
      "@id": "urn:uuid:f1aa3e3a-8391-4bf9-b435-6bd0702f9e0ru",
      "@type": "dm:DifferenceModel",
      "dm:forwardDifferences": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "@type": "cim:ACLineSegment",
          "cim:Conductor.length": {
            "cim:Length.value": 65.0
          }
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
we see that the statements `Conductor.length` are all mixed up:
```ttl
<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d>
  rdf:type               dm:DifferenceModel ;
  dm:reverseDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> , <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5>
  rdf:type                   cim:Switch ;
  cim:IdentifiedObject.Name  "Switch2" , "Switch1" .

<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6t>
  rdf:type               dm:DifferenceModel ;
  dm:reverseDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:f1aa3e3a-8391-4bf9-b435-6bd0702f9e0ru>
  rdf:type               dm:DifferenceModel ;
  dm:forwardDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .

<urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9>
  rdf:type              cim:ACLineSegment ;
  cim:Conductor.length  [ cim:Length.value  65 ] ;
  cim:Conductor.length  [ cim:Length.value  60 ] ;
  cim:Conductor.length  [ cim:Length.value  55 ] ;
  cim:Conductor.length  [ cim:Length.value  50 ] .

<urn:uuid:f1aa3e3a-8391-4bf9-b435-6bd0702f9e0d>
  rdf:type               dm:DifferenceModel ;
  dm:forwardDifferences  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> , <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> .
```

### Nearly Correct Graph Representation

We can correct the representation by adding graph names (URNs).
Let's start with Trig (`option3.trig`):
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

<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d> a dm:DifferenceModel ;
  md:Model.Supersedes <urn:uuid:base-model>;
  dm:forwardDifferences <urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-forward>;
  dm:reverseDifferences <urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-reverse>.

<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-reverse> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  50 ] .
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> cim:IdentifiedObject.Name "Switch1" .
}

<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-forward> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  55 ] .
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5> cim:IdentifiedObject.Name "Switch2" .
}


<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a> a dm:DifferenceModel ;
  md:Model.Supersedes <urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d>;
  dm:reverseDifferences <urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-reverse>;
  dm:forwardDifferences <urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-forward>.

<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-reverse> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  60 ]
}

<urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-forward> {
  <urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9> cim:Conductor.length  [ cim:Length.value  65 ]
}
```

Let's convert this to JSON-LD. The crucial difference is that the `@graph` elements now have names (`@id`):
```
{
  "@graph": [
    {
      "@id": "urn:uuid:base-model",
      "@type": "dm:Model",
      "@graph": [
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d9",
          "cim:Conductor.length": {
            "@id": "_:b4"
          },
          "@type": "cim:ACLineSegment"
        },
        {
          "@id": "_:b4",
          "cim:Length.value": {
            "@value": "50",
            "@type": "http://www.w3.org/2001/XMLSchema#integer"
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
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a",
      "dm:forwardDifferences": {
        "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-forward"
      },
      "dm:reverseDifferences": {
        "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-reverse"
      },
      "md:Model.Supersedes": {
        "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d"
      },
      "@type": "dm:DifferenceModel"
    },
    {
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-forward",
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
            "@type": "http://www.w3.org/2001/XMLSchema#integer"
          }
        }
      ]
    },
    {
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6a-reverse",
      "@graph": [
        {
          "@id": "_:b1",
          "cim:Length.value": {
            "@value": "60",
            "@type": "http://www.w3.org/2001/XMLSchema#integer"
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
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d",
      "dm:reverseDifferences": {
        "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-reverse"
      },
      "dm:forwardDifferences": {
        "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-forward"
      },
      "md:Model.Supersedes": {
        "@id": "urn:uuid:base-model"
      },
      "@type": "dm:DifferenceModel"
    },
    {
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-reverse",
      "@graph": [
        {
          "@id": "_:b0",
          "cim:Length.value": {
            "@value": "50",
            "@type": "http://www.w3.org/2001/XMLSchema#integer"
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
      "@id": "urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-forward",
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
            "@type": "http://www.w3.org/2001/XMLSchema#integer"
          }
        },
        {
          "@id": "urn:uuid:9d58e5bb-834c-4faa-928c-7da0bb1497d5",
          "cim:IdentifiedObject.Name": "Switch2"
        }
      ]
    }
  ],
  "@context": {
    "eu": "http://iec.ch/TC57/CIM100-European#",
    "dm": "http://iec.ch/TC57/61970-552/DifferenceModel/1#",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "cim": "http://iec.ch/TC57/CIM100#",
    "md": "http://iec.ch/TC57/61970-552/ModelDescription/1#"
  }
}
```

Note: We'll see later how by using a richer `@context` we'll reduce this expanded representation:
```json
"cim:Length.value": {
 "@value": "50",
 "@type": "http://www.w3.org/2001/XMLSchema#integer"
}
```

To the much more compact and natural:
```json
"cim:Length.value": "50"
```

But there are still some problems:
- We've used URNs like `urn:uuid:f52f12c3-db10-4d41-a9f2-b1fe29ab4d6d-forward` (notice the last part)
  for clarity of the example.
  But this is not a valid URN under the `urn:uuid:` scheme:
  so we must generate new UUIDs for the `reverse` and `forward` graphs.
- There are blank nodes represented in Trig as `cim:Conductor.length [cim:Length.value 60]`
  and in JSON-LD as  `_:b4` etc.
  This is a problem, since we cannot delete a blank node by specifying another blank node in the `reverse` graph.
  Every two blank nodes are different, unless they came from the same file and have the same blank node name.
  So it is good that actual CIM instance data has the simpler representation `cim:Conductor.length "60"`,
  and we fixed the CIM ontologies to use the simpler representation (https://github.com/Sveino/Inst4CIM-KG/issues/38)

### Custom CIM XML Parser

https://github.com/Sveino/Inst4CIM-KG/issues/94

We need to  implement a custom CIM XML parser that handles `parseType="Statements"` and emits named graphs.

[cim-trig.pl](cim-trig.pl) is a Perl script that converts CIM XML file to Trig (Turtle with graphs).
It uses simple string manipulation rather than a XML parser, so it relies on a repeatable CIM XML layout as lines:
- A file has exactly one model: `md:FullModel` or `dm:DifferenceModel`
- `dm:DifferenceModel` has exactly two sections `dm:reverseDifferences` and `dm:forwardDifferences`, in this order

It uses the `owl-cli` tool by `@atextor`, as described at
  https://github.com/Sveino/Inst4CIM-KG/blob/develop/rdfs-improved#atextor-tools-owl-cli-and-turtle-formatter .
- It runs a command like this, using the Windows version of the `owl` command:
```
owl.bat write --keepUnusedPrefixes -i rdfxml ...rdf ...ttl
```
- `owl` produces better formatting, but for very large files it's better to use streaming.
  In that case we should use Jena RIOT by changing one line in `sub ttl`:
```
riot.bat --syntax=rdfxml --out=ttl ...rdf > ...ttl
```

For a `dm:DifferenceModel` it invokes the command-line tool 3 times:
- To convert the model statements
- To convert the `dm:reverseDifferences` statements
- To convert the `dm:forwardDifferences` statements

It generates new `urn:uuid` URIs for the reverse and forward models (using UUID v4),
and adds named graphs to all model parts.
In particular, model metadata is stored in the model graph,
so it can be updated or deleted easily (eg by using the SPARQL Graph Protocol).

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
<http://fullgrid.eu/CGMES/3.0#87478acb-cd1f-40a6-b4a7-59ec99f8b063>
  cim:IdentifiedObject.description "SET_PNT_1" .
<http://fullgrid.eu/CGMES/3.0#fc908c16-468f-4a64-ba74-6f57175e0005>
  cim:AnalogLimit.value "99" .
}

<urn:uri:63528ef9-48ff-469b-a58e-ba274f2a10bb> { # forwardDifferences
<http://fullgrid.eu/CGMES/3.0#87478acb-cd1f-40a6-b4a7-59ec99f8b063>
  cim:IdentifiedObject.description "SET_PNT_1 test" .
<http://fullgrid.eu/CGMES/3.0#fc908c16-468f-4a64-ba74-6f57175e0005>
  cim:AnalogLimit.value "100" .
}
```

## Fix Resource URLs
The URLs of CIM power system resources are represented in CIM XML like this:
- definition: `rdf:ID="_f37786d0-b118-4b92-bafb-326eac2a3877"`
- reference: `rdf:resource="#_44e63d79-6b05-4c64-b490-d181863af7da"`

They have two problems:
- These are relative URLs. 
  However, CIM XML files don't specify `xml:base` (see RDF 1.1 XML Syntax, section [2.14 Abbreviating URIs: rdf:ID and xml:base](https://www.w3.org/TR/rdf-syntax-grammar/#section-Syntax-ID-xml-base)).
  This means the URLs are resolved in a tool-dependent way (eg by using the file location on local disk).
  This is a very serious problem that undermines the stability of resource URLs.
  We've resolved it by declaring `md:Model.modelingAuthoritySet` as BASE.
- They start with a parasitic `_`.
  - The reason is that `rdf:ID` cannot start with a digit, see
    - RDF 1.1 XML Syntax, section [C.1 RELAX NG Compact Schema](https://www.w3.org/TR/rdf-syntax-grammar/#h3_section-RELAXNG-Schema), `IDsymbol`
    - XML Schema Definition Language (XSD) 1.1 Part 2: Datatypes, section [3.4.4 NMTOKEN](https://www.w3.org/TR/xmlschema11-2/#NMTOKEN)
    - Extensible Markup Language (XML) 1.1 (Second Edition) section [Nmtoken](https://www.w3.org/TR/xml11/#NT-Nmtoken)
  - `rdf:about` could have been used instead of `rdf:ID` to avoid that limitation.
  - This is a purely cosmetic problem and we may leave it as is.

The problems are fixed by the `cim-trig.pl` script described above: see URL examples in the previous section.

## Add Datatypes To Instance Data
https://github.com/Sveino/Inst4CIM-KG/issues/49

In CGMES instance data, all literals are strings, but should be marked with the appropriate datatype.
- E.g. `cim:ACDCConverter.baseS` should be marked `^^xsd:float`
- Otherwise sort won't work properly and range queries will be slower.
- This pertains to `boolean, dateTme, float, gMonthDay, integer` 
  - `string` is the default datatype
  - TODO for `boolean` in JSON-LD, check https://github.com/digitalbazaar/jsonld.js/issues/558

[Property Datatype Maps](../rdfs-improved#property-datatype-maps) in the sibling folder `rdfs-improvement/datatypes` makes a comprehensive analysis.
We extract a datatypes map, omitting hijacked namespaces and `xsd:string`:
```
grep -E '^(cim|nc|eu|md|eumd)' datatypes-older.tsv | grep -v xsd:string > fix-datatypes.ru
```
Then we format it as `values` for use in SPARQL.

[fix-datatypes.ru](fix-datatypes.ru) looks like this:
- We define dual prefixes `cim, cim1` and `eu, eu1` to accommodate the newest and older CIM versions:
```sparql
prefix cim:  <https://cim.ucaiug.io/ns#>
prefix cim1: <http://iec.ch/TC57/CIM100#>
prefix nc:   <https://cim4.eu/ns/nc#>
prefix eu:   <https://cim.ucaiug.io/ns/eu#>
prefix eu1:  <http://iec.ch/TC57/CIM100-European#>
prefix eumd: <https://cim4.eu/ns/Metadata-European#>
prefix md:   <http://iec.ch/TC57/61970-552/ModelDescription/1#>
prefix xsd:  <http://www.w3.org/2001/XMLSchema#>
```
- After  [Represent Models as Named Graphs](#represent-models-as-named-graphs), all CIM triples live in named graphs, so:
```
delete {graph ?g {?x ?p ?old}}
insert {graph ?g {?x ?p ?new}}
```
- The `where` clause
  - Includes a pretty huge mapping table from props to datatypes
  - Finds quads where the `?old` value is `string`
  - Maps it to the appropriate datatype, considering different namespace versions
```
where {
  values (?prop ?dt) {
    (cim:ACDCConverter.baseS xsd:float)
    # 3000 more rows
  }
  bind(uri(concat(str(cim1:),strafter(str(?prop),str(cim:)))) as ?prop1)
  bind(uri(concat(str( eu1:),strafter(str(?prop),str( eu:)))) as ?prop2)
  graph ?g {?x ?p ?old}
  filter(datatype(?old)=xsd:string)
  filter(?p=?prop || ?p=?prop1 || ?p=?prop2)
  bind(strdt(?old,?dt) as ?new)
};
```
This update query can be applied on:
- One CIM file, using an in-memory SPARQL Update tool like Jena `update`
- A whole repository of CIM data, eg using GraphDB

