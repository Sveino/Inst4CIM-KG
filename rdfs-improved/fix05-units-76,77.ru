# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure

PREFIX cim: <https://cim.ucaiug.io/ns#>
PREFIX cims: <http://iec.ch/TC57/1999/rdf-schema-extensions-19990926#> 

# https://github.com/Sveino/Inst4CIM-KG/issues/76
delete {cim:ActivePowerPerFrequency.unit cims:isFixed "WPers"}
insert {cim:ActivePowerPerFrequency.unit cims:isFixed "WPerHz"}
where  {cim:ActivePowerPerFrequency.unit cims:isFixed "WPers"};

# https://github.com/Sveino/Inst4CIM-KG/issues/77
delete {cim:VoltagePerReactivePower.multiplier cims:isFixed "none"}
insert {cim:VoltagePerReactivePower.multiplier cims:isFixed "k"}
where  {cim:VoltagePerReactivePower.multiplier cims:isFixed "none"};
