#!perl -wp

# https://github.com/3lbits/CIM4NoUtility/issues/343

# To allow this script to work on RDF or Turtle, we cannot emit this turtle line:
# BEGIN {print "\@prefix uml: <http://iec.ch/TC57/NonStandard/UML#>.\n"}

s{http://langdale.com.au/2005/UML#}          {http://iec.ch/TC57/NonStandard/UML#};
s{http://iec.ch/TC57/CIM100-European#}       {https://cim.ucaiug.io/ns/eu#};
s{http://iec.ch/TC57/CIM100#}                {https://cim.ucaiug.io/ns#};
s{http://iec.ch/TC57/CIM100}                 {https://cim.ucaiug.io/ns};  # bug https://github.com/statnett/Talk2PowerSystem_PM/issues/225
s{http://iec.ch/TC57/CIM/CIM100#}            {https://cim.ucaiug.io/ns#}; # bug in Nordic44 AS/AC instance data
s{http://iec.ch/TC57/ns/CIM#}                {https://cim.ucaiug.io/ns#}; # bug https://github.com/statnett/CIM4Enterprise/issues/16
s{http://iec.ch/TC57/2016/CIM-schema-cim17#} {https://cim.ucaiug.io/ns#};
s{http://entsoe.eu/ns/nc#}                   {https://cim4.eu/ns/nc#};
s{http://purl.org/dc/terms/#}                {http://purl.org/dc/terms/};
s{dct:}                                      {dcterms:}g;
