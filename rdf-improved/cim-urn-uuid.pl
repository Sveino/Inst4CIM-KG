#!perl -p
s{rdf:ID="_}{rdf:about="urn:uuid:}g;
s{rdf:about="#?_}{rdf:about="urn:uuid:}g;
s{rdf:resource="#?_}{rdf:resource="urn:uuid:}g;
