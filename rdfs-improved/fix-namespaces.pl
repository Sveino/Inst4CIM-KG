#!perl -wp

# https://github.com/3lbits/CIM4NoUtility/issues/343

BEGIN {print "\@prefix uml: <http://iec.ch/TC57/NonStandard/UML#>.\n"}

s{http://langdale.com.au/2005/UML#}          {http://iec.ch/TC57/NonStandard/UML#};
s{http://iec.ch/TC57/CIM100#}                {https://cim.ucaiug.io/ns#};
s{http://iec.ch/TC57/CIM/CIM100#}            {https://cim.ucaiug.io/ns#}; # bug in Nordic44 AS/AC instance data
s{http://iec.ch/TC57/2016/CIM-schema-cim17#} {https://cim.ucaiug.io/ns#};
s{http://iec.ch/TC57/CIM100-European#}       {https://cim.ucaiug.io/ns/eu#};
s{http://entsoe.eu/ns/nc#}                   {https://cim4.eu/ns/nc#};
s{http://purl.org/dc/terms/#}                {http://purl.org/dc/terms/};
s{dct:}                                      {dcterms:}g;
