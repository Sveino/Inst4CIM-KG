#!perl -wp

BEGIN {print "\@prefix uml: <http://iec.ch/TC57/NonStandard/UML#>.\n"}

s{http://iec.ch/TC57/CIM100#}         {https://cim.ucaiug.io/ns#};
s{http://iec.ch/TC57/CIM100-European#}{https://cim.ucaiug.io/ns/eu#};
s{http://purl.org/dc/terms/#}         {http://purl.org/dc/terms/};
s{dcterms:}                           {dct:}g;
