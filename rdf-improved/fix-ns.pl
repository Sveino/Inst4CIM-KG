#!perl -p
s{http://iec.ch/TC57/CIM100#}                      {https://cim.ucaiug.io/ns#}g;
s{http://iec.ch/TC57/2009/CIM-schema-cim14#}       {https://cim.ucaiug.io/ns#}g;
s{http://iec.ch/TC57/CIM100-European#}             {https://cim.ucaiug.io/ns/eu#}g;
s{http://iec.ch/TC57/CIM100-EuropeanExtension/1/0#}{https://cim.ucaiug.io/ns/eu#}g; # asked Svein whether they mean the same
s{http://entsoe.eu/ns/nc#}                         {https://cim4.eu/ns/nc#}g;
s{http://www.pti-us.com/PTI_CIM-schema-cim14#}     {http://www.pti-us.com/PTI_CIM-schema-cim16#}g;
