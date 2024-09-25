
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
