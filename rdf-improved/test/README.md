# RDF Serializations
This folder has a number of serializations

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [RDF Serializations](#rdf-serializations)
    - [cimxml](#cimxml)
    - [rdf](#rdf)
    - [rdf-typed](#rdf-typed)
    - [nquads](#nquads)
    - [trig](#trig)
    - [jsonld](#jsonld)

<!-- markdown-toc end -->


## cimxml

This is the traditional CIM XML format that has the following defects:
- URLs are under-defined because no `xml:base` is set. The have the form `#_<uuid>`. The parasitic leading underscore is because `rdf:ID` cannot start with a digit
- Literals have no datatypes
- RDF XML has no named graphs. There is an implicit assumption that triples in the same file are somehow associated to the Model (header), 
  which is only true if the file is loaded in the same named graph and the model URI.

We include files from `ENTSO-E_Test_Configurations_v3.0.2`:

- 20210323T1730Z_1D_BE_SSH_1.xml
- 20210323T1730Z_1D_BE_SV_1.xml
- 20210323T1730Z_1D_BE_TP_1.xml
- FullGrid_OP.xml
- FullGrid_OP_diff.xml
- FullGrid_SC_diff.xml
- FullGrid_SSH.xml
- FullGrid_SV.xml
- FullGrid_TP.xml
- MicroGrid-Assembled-DL_diff.xml
- MicroGrid-BD-MAS-diff.xml
- MicroGrid-BE-MAS-DY_diff.xml
- MicroGrid-NL-MAS-EQ_diff.xml
- MicroGrid-NL-MAS-GL_diff.xml

## rdf

These are RDF XML files contributed by @Haigutus.
They are generated from [ENTSO-E ReliCapGrid](https://github.com/entsoe/relicapgrid/ ":"): the Svedala individual grid model (IGM: EQ, SSH, SV, TP); plus boundary and common data files using `triplets` library with CGMES 3.0 export schema.
They use `urn:uuid` fully-defined URIs, but don't include literal datatypes or named graphs:

- 20220615T2230Z_2D_Svedala_SSH_1.rdf
- 20220615T2230Z_2D_Svedala_SV_1.rdf
- 20220615T2230Z_2D_Svedala_TP_1.rdf
- 20220615T2230Z__Svedala_EQ_1.rdf
- Boundary_Border-Svedala-Belgovia.rdf
- Boundary_Border-Svedala-Espheim.rdf
- Grid_CommonData_CGM-CD.rdf

## rdf-typed
These are RDF XML files contributed by @Haigutus.
They use `urn:uuid` fully-defined URIs, include literal datatypes, but don't include named graphs:

- 20220615T2230Z_2D_Svedala_SSH_1.rdf
- 20220615T2230Z_2D_Svedala_SV_1.rdf
- 20220615T2230Z_2D_Svedala_TP_1.rdf
- 20220615T2230Z__Svedala_EQ_1.rdf
- Boundary_Border-Svedala-Belgovia.rdf
- Boundary_Border-Svedala-Espheim.rdf
- Grid_CommonData_CGM-CD.rdf

## nquads

NQuads is a line-oriented format that represents each quad on a separate line.
It's easy to parse but rather verbose.
It was contributed by @Haigutus (see prev section) 
and includes `urn:uuid` fully-defined URIs, literal datatypes, URIs, and named graphs:

- `svedala_full.nq`: 95228 quads

## trig

These are Trig (Turtle with graphs) files contributed by @VladimirAlexiev. They:
- Upgrade namespaces to the CGMES 3.0 version-independent namespace
- Force all instance URLs to `urn:uuid:` to avoid under-defined URLs, and disagreement between TSOs/MAS about border resource URIs
- Add datatypes
- Add named graphs

List of full models (consist of one named graph):

- 20210323T1730Z_1D_BE_SSH_1.trig
- 20210323T1730Z_1D_BE_SV_1.trig
- 20210323T1730Z_1D_BE_TP_1.trig
- FullGrid_OP.trig
- FullGrid_SSH.trig
- FullGrid_SV.trig
- FullGrid_TP.trig
- svedala_full.trig

List of differential models: consist of a base graph, plus graphs `backwardDifferences` (triples to delete) and `forwardDifferences` (triples to insert):

- FullGrid_OP_diff.trig
- FullGrid_SC_diff.trig
- MicroGrid-Assembled-DL_diff.trig
- MicroGrid-BD-MAS-diff.trig
- MicroGrid-BE-MAS-DY_diff.trig
- MicroGrid-NL-MAS-EQ_diff.trig
- MicroGrid-NL-MAS-GL_diff.trig

## jsonld

These are compacted JSON-LD using the context
https://raw.githack.com/Sveino/Inst4CIM-KG/develop/rdf-improved/cim-context-new.jsonld .
It declares the datatypes of all literal props (except `xsd:string` which is default) and `@type: @id` for object props.

The files are made from `trig` using standard RDF tools (`riot -formatted jsonld` then `jsonld compact`):


