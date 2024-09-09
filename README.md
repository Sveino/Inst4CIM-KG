# Instance of CIM Knowledge Graph

## Overview

The **Instance of CIM Knowledge Graph** project focuses on producing issue resolutions and example files that demonstrate how the IEC Common Information Model (CIM) can be upgraded to support the latest W3C standards. The project includes schema ontologies and instance data, utilizing profiles such as **CGMES 3.0** and **Network Code (NC) CGMES extensions**. It also validates **DX-PROF** and incorporates the **LinkML** project to model CIM data cases.

## Purpose

The project aims to:
- Create example cases that cover all relevant CIM modeling scenarios using JSON-LD, Turtle, and RDF/XML.
- Address issues and provide examples for all relevant modeling of CIM.
- Demonstrate how CIM can support W3C standards for both schema and instance data.


## Key Components

1. **CGMES 3.0 Profile**: Applying the latest CIM profiles in compliance with CGMES standards.
2. **NC CGMES Extensions**: Extending the existing Network Code CGMES to support specific use cases.
3. **LinkML**: LinkML project to produce CGMES 3.0 and Network Code (NC) extensions.
4. **Example model**: Example of all relevant CIM modelling concept.


## Schema profiling

The project will show example of the generation of [RDFS-plus](http://mlwiki.org/index.php/RDFS-Plus) based vocabulary and [Shapes Constraints Language (SHACL)](https://www.w3.org/TR/shacl/) from [LinkML](https://linkml.io/) with the profile structure according to [**W3C DX-PROF**:](https://www.w3.org/TR/dx-prof/).

### RDF Syntaxes for profiling

THe CIM profiles should be possible to be described with all RDF Syntax. However, the following RDF Syntaxes are planed to be generated and tested:

- [**JSON-LD 1.1 Specification**](https://www.w3.org/TR/json-ld11/) The most advance syntax. Support multiple graphs. Primary for machine-understandable. There could be some feature that would only be supported in JSON-LD and most like will the other syntax be generated based on an JSON-LD instance.
  
- [**Turtle 1.1 Specification**:](https://www.w3.org/TR/turtle/) Focused on human readability.

- [**RDF/XML 1.1 Specification**](https://www.w3.org/TR/rdf-syntax-grammar/): Focused to provide backwards support. For application that support todays profile syntax to have a smaller upgrading path.

## Instance Data in JSON-LD

Today CIM instance data is exchange in CIM RDF (a variance of RDF XML) specified according to IEC 61970-553 (IEC 61970-600-1:2021 do deviate from this standard on some items). We would like to look into how we can create a converter from CIM XML to JSON-LD and reversal. There should be no loss going from CIM XML to JSON-LD, but it is assumed that there might be loses going the other way.
The focus is on how to use JSON-LD for exchanging structure data, however it could also be looked at how to do schedule and streaming data. The goal would be to have one syntax that can handle all relevant exchange types. The focus is JSON-LD 1.1, but in general is should be possible to use any of the other RDF syntax as long as the general features are supported in the given RDF syntax. We expect to enhance the current syntax of JSON-LD to be able to exchange difference model. This might be a challenge to exchange in Turtle. 


## Resources

- **Primary Sources for Instance Data**: 
  - [JSON-LD 1.1](https://www.w3.org/TR/json-ld11/)
 

## Contributing

Contributions to this project are welcome. If you'd like to help with documentation, standards alignment, or the creation of examples, please follow the [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the [Apache-2.0 license](LICENSE). Please see the license file for more information.

