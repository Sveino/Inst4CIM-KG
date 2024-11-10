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
    - [Sample Instance Data](#sample-instance-data)
        - [Counting Triples](#counting-triples)
        - [Multipled Data](#multipled-data)
    - [JSON-LD Serialization](#json-ld-serialization)
        - [Formatting of Numbers and Booleans](#formatting-of-numbers-and-booleans)

<!-- markdown-toc end -->

## Represent Models as Named Graphs
https://github.com/Sveino/Inst4CIM-KG/issues/53

CIM Difference Models are important because they allow to record only a delta against a base model,
thus enabling "What If" analysis and other important scenarios.

A Differential Model:
- Refers to the base model using `md:Model.Supersedes`
- Checks certain statements using `dm:preconditions` (but this is not used in CIM)
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
that contains the model triples (thus they become quads).

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

It uses command-line tools to do the bulk of the work (see `sub ttl`):
- For prettier formatting, it runs `owl-cli` by `@atextor` (the Windows version of a batch file)
  as described at https://github.com/Sveino/Inst4CIM-KG/blob/develop/rdfs-improved#atextor-tools-owl-cli-and-turtle-formatter :
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

## Fix Resource URLs
The URLs of CIM power system resources are represented in CIM XML like this:
- definition: `rdf:ID="_f37786d0-b118-4b92-bafb-326eac2a3877"`
- reference: `rdf:resource="#_44e63d79-6b05-4c64-b490-d181863af7da"`

They have two problems:

These are relative URLs. 
- However, CIM XML files don't specify `xml:base` (see RDF 1.1 XML Syntax, section [2.14 Abbreviating URIs: rdf:ID and xml:base](https://www.w3.org/TR/rdf-syntax-grammar/#section-Syntax-ID-xml-base)).
- This means the URLs are resolved in a tool-dependent way (eg by using the file location on local disk).
- This is a very serious problem that undermines the stability of resource URLs.
- We've resolved it by declaring `md:Model.modelingAuthoritySet` as BASE.
- This is fixed by the `cim-trig.pl` script described above: see URL examples in the previous section.

They start with a parasitic `_`.
- The reason is that `rdf:ID` cannot start with a digit, see
  - RDF 1.1 XML Syntax, section [C.1 RELAX NG Compact Schema](https://www.w3.org/TR/rdf-syntax-grammar/#h3_section-RELAXNG-Schema), `IDsymbol`
  - XML Schema Definition Language (XSD) 1.1 Part 2: Datatypes, section [3.4.4 NMTOKEN](https://www.w3.org/TR/xmlschema11-2/#NMTOKEN)
  - Extensible Markup Language (XML) 1.1 (Second Edition) section [Nmtoken](https://www.w3.org/TR/xml11/#NT-Nmtoken)
- `rdf:about` could have been used instead of `rdf:ID` to avoid that limitation.
- This is a purely cosmetic problem and we leave it as is.


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
- Note: the NC spec is new, so its prefix is only available int he new namespaces:
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
  graph ?g {?x ?p ?old}
  filter(datatype(?old)=xsd:string)
  bind(if(strstarts(str(?p),str(cim1:)),uri(concat(str(cim:),strafter(str(?p),str(cim1:)))),?UNDEF) as ?p1)
  bind(if(strstarts(str(?p),str(eu1:)), uri(concat(str(eu:), strafter(str(?p),str(eu1:)))), ?UNDEF) as ?p2)
  filter(?p=?prop || ?p1=?prop || ?p2=?prop)
  bind(strdt(?old,?dt) as ?new)
};
```

These updates can be applied on:
- One CIM file, using an in-memory SPARQL Update tool like Jena `update`
- A whole repository of CIM data, eg using GraphDB

We include 3 versions because applying "both" on old data produces `cim1, eu1` prefixes.
This is harmless, but doesn't look nice.

## Sample Instance Data
To work out reasoning, validation and performance issues, we need sample instance data.
We can use the following datasets:

| dataset                                 | xml  | zip | files | FullModel | triples | largest | largest file                             |
|-----------------------------------------|------|-----|-------|-----------|---------|---------|------------------------------------------|
| [ENTSO-E_Test_Configurations_v3.0.2](https://www.entsoe.eu/Documents/CIM_documents/Grid_Model_CIM/ENTSO-E_Test_Configurations_v3.0.2.zip) | 151M | 19M |   357 |       350 | 1844380 |  947208 | RealGrid/RealGrid-Merged/RealGrid_EQ.xml |
| [Nordic44](https://github.com/Sveino/Nordic44/tree/develop/Instances)                           | 2.9M |     |    15 |        12 |   35481 |   17420 | CGMES_2_4/Nordic44_CGM_37a_EQ.xml        |

- "FullModel" are files that have a standard `md:FullModel` structure.
  ENTSOE also have 7 `DifferenceModel` that we'll use but not "multiply".
- See next section for counting triples
 
### Counting Triples
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

### Multipled Data
Chavdar Ivanov took 4 files from [ENTSO-E_Test_Configurations_v3.0.2](https://www.entsoe.eu/Documents/CIM_documents/Grid_Model_CIM/ENTSO-E_Test_Configurations_v3.0.2.zip)
and multiplied the data 10, 20, 50 and 100 times. 
The results are in this [Microsoft Teams Drive](https://1drv.ms/f/s!AhDObGm0xWObjJI3y0obO3j9L4TSRw?e=4CDbxL).

I got these 4 files: `RealGrid_EQ100.zip, RealGrid_SSH100.zip, RealGrid_SV100.zip, RealGrid_TP100.zip`.
They are 1.9Gb zipped, 11Gb unzipped.

## JSON-LD Serialization

```
riot.bat --formatted jsonld test/trig/FullGrid_OP.trig | jsonld compact -c https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdf-improved/cim-context-old.jsonld
```

### Formatting of Numbers and Booleans
https://github.com/Sveino/Inst4CIM-KG/issues/120

JSON has only a few native literal datatypes: number, boolean, string, etc.
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

Note: in all cases we didn't specify a context to use.
If we do, then more tools may output values in quotes.

