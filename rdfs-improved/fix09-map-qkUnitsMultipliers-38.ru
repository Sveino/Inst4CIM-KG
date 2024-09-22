# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#quantitykinds-and-units-of-measure
# https://github.com/Sveino/Inst4CIM-KG/issues/38
# https://github.com/Sveino/Inst4CIM-KG/issues/29

prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix prefix: <http://qudt.org/vocab/prefix/>
prefix qudt: <http://qudt.org/schema/qudt/>
prefix quantitykind: <http://qudt.org/vocab/quantitykind/> 
prefix unit: <http://qudt.org/vocab/unit/>

# map QuantityKinds
insert {?qk skos:exactMatch ?quantitykind}
where {
  values (?qk                           ?quantitykind) {
         (cim:ActivePower               quantitykind:ActivePower              )
         (cim:ActivePowerChangeRate     quantitykind:ActivePowerChangeRate    )
         (cim:ActivePowerPerCurrentFlow quantitykind:ActivePowerPerCurrentFlow)
         (cim:ActivePowerPerFrequency   quantitykind:ActivePowerPerFrequency  )
         (cim:AngleDegrees              quantitykind:Angle                    )
         (cim:AngleRadians              quantitykind:Angle                    )
         (cim:ApparentPower             quantitykind:ApparentPower            )
         (cim:Area                      quantitykind:Area                     )
         (cim:Capacitance               quantitykind:Capacitance              )
         (cim:Conductance               quantitykind:Conductance              )
         (cim:CurrentFlow               quantitykind:ElectricCurrent          )
         (cim:Frequency                 quantitykind:Frequency                )
         (cim:Impedance                 quantitykind:Inductance               )
         (cim:Length                    quantitykind:Length                   )
         (cim:Money                     quantitykind:Currency                 )
         (cim:PU                        quantitykind:DimensionlessRatio       )
         (cim:PerCent                   quantitykind:DimensionlessRatio       )
         (cim:Pressure                  quantitykind:Pressure                 )
         (cim:Reactance                 quantitykind:Reactance                )
         (cim:ReactivePower             quantitykind:ReactivePower            )
         (cim:RealEnergy                quantitykind:Energy                   )
         (cim:Resistance                quantitykind:Resistance               )
         (cim:RotationSpeed             quantitykind:AngularVelocity          )
         (cim:Seconds                   quantitykind:Time                     )
         (cim:Susceptance               quantitykind:Susceptance              )
         (cim:Temperature               quantitykind:Temperature              )
         (cim:Voltage                   quantitykind:Voltage                  )
         (cim:VoltagePerReactivePower   quantitykind:VoltagePerReactivePower  )
         (cim:VolumeFlowRate            quantitykind:VolumeFlowRate           )
  }
  ?qa a qudt:QuantityKind
};

# map UnitMultipliers
insert {?multiplier qudt:prefixMultiplier ?prefixMultiplier; skos:exactMatch ?exactMatch}
where {
  values (?multiplier             ?prefixMultiplier ?exactMatch ) {
         (cim:UnitMultiplier.none 1.0               UNDEF       )
         (cim:UnitMultiplier.k    1.0E3             prefix:Kilo )
         (cim:UnitMultiplier.M    1.0E6             prefix:Mega )
  }
  ?multiplier a cim:UnitMultiplier
};

# map UnitSymbols
insert {?unit ?rel ?unitQudt}
where {
  values (?unit                   ?rel            ?unitQudt              ) {
         (cim:UnitSymbol.A        skos:exactMatch unit:A                 )
         (cim:UnitSymbol.F        skos:exactMatch unit:FARAD             )
         (cim:UnitSymbol.Hz       skos:exactMatch unit:HZ                )
         (cim:UnitSymbol.Hz       skos:narrower   unit:REV-PER-SEC       )
         (cim:UnitSymbol.Pa       skos:exactMatch unit:PA                )
         (cim:UnitSymbol.S        skos:exactMatch unit:S                 )
         (cim:UnitSymbol.V        skos:exactMatch unit:V                 )
         (cim:UnitSymbol.VA       skos:exactMatch unit:V-A               )
         (cim:UnitSymbol.VAr      skos:exactMatch unit:V-A_Reactive      )
         (cim:UnitSymbol.VPerVAr  skos:exactMatch unit:V-PER-V-A_Reactive)
         (cim:UnitSymbol.W        skos:exactMatch unit:W                 )
         (cim:UnitSymbol.WPerA    skos:exactMatch unit:W-PER-A           )
         (cim:UnitSymbol.WPerHz   skos:exactMatch unit:W-PER-HZ          )
         (cim:UnitSymbol.WPers    skos:exactMatch unit:W-PER-SEC         )
         (cim:UnitSymbol.Wh       skos:exactMatch unit:W-HR              )
         (cim:UnitSymbol.deg      skos:exactMatch unit:DEG               )
         (cim:UnitSymbol.degC     skos:exactMatch unit:DEG_C             )
         (cim:UnitSymbol.m        skos:exactMatch unit:M                 )
         (cim:UnitSymbol.m2       skos:exactMatch unit:M2                )
         (cim:UnitSymbol.m3Pers   skos:exactMatch unit:M3-PER-SEC        )
         (cim:UnitSymbol.ohm      skos:exactMatch unit:OHM               )
         (cim:UnitSymbol.rad      skos:exactMatch unit:RAD               )
         (cim:UnitSymbol.s        skos:exactMatch unit:SEC               )
  }
  ?unit a cim:UnitSymbol
};

# map data properties
insert {?prop qudt:hasUnit ?unitQudt}
where {
  values (?qk                           ?multiplier              ?unit                   ?unitQudt                  ) {
         (cim:ActivePower               cim:UnitMultiplier.M     cim:UnitSymbol.W        unit:MegaW                 )
         (cim:ActivePowerChangeRate     cim:UnitMultiplier.M     cim:UnitSymbol.WPers    unit:MegaW-PER-SEC         )
         (cim:ActivePowerPerCurrentFlow cim:UnitMultiplier.M     cim:UnitSymbol.WPerA    unit:MegaW-PER-A           )
         (cim:ActivePowerPerFrequency   cim:UnitMultiplier.M     cim:UnitSymbol.WPerHz   unit:MegaW-PER-HZ          )
         (cim:AngleDegrees              cim:UnitMultiplier.none  cim:UnitSymbol.deg      unit:DEG                   )
         (cim:AngleRadians              cim:UnitMultiplier.none  cim:UnitSymbol.rad      unit:RAD                   )
         (cim:ApparentPower             cim:UnitMultiplier.M     cim:UnitSymbol.VA       unit:MegaV-A               )
         (cim:Area                      cim:UnitMultiplier.none  cim:UnitSymbol.m2       unit:M2                    )
         (cim:Capacitance               cim:UnitMultiplier.none  cim:UnitSymbol.F        unit:FARAD                 )
         (cim:Conductance               cim:UnitMultiplier.none  cim:UnitSymbol.S        unit:S                     )
         (cim:CurrentFlow               cim:UnitMultiplier.none  cim:UnitSymbol.A        unit:A                     )
         (cim:Frequency                 cim:UnitMultiplier.none  cim:UnitSymbol.Hz       unit:HZ                    )
         (cim:Impedance                 cim:UnitMultiplier.none  cim:UnitSymbol.ohm      unit:OHM                   )
         (cim:Length                    cim:UnitMultiplier.k     cim:UnitSymbol.m        unit:KiloM                 )
         (cim:PerCent                   cim:UnitMultiplier.none  cim:UnitSymbol.none     unit:PERCENT               )
         (cim:Pressure                  cim:UnitMultiplier.k     cim:UnitSymbol.Pa       unit:KiloPA                )
         (cim:Reactance                 cim:UnitMultiplier.none  cim:UnitSymbol.ohm      unit:OHM                   )
         (cim:ReactivePower             cim:UnitMultiplier.M     cim:UnitSymbol.VAr      unit:MegaV-A_Reactive      )
         (cim:RealEnergy                cim:UnitMultiplier.M     cim:UnitSymbol.Wh       unit:MegaW-HR              )
         (cim:Resistance                cim:UnitMultiplier.none  cim:UnitSymbol.ohm      unit:OHM                   )
         (cim:RotationSpeed             cim:UnitMultiplier.none  cim:UnitSymbol.Hz       unit:REV-PER-SEC           )
         (cim:Seconds                   cim:UnitMultiplier.none  cim:UnitSymbol.s        unit:SEC                   )
         (cim:Susceptance               cim:UnitMultiplier.none  cim:UnitSymbol.S        unit:S                     )
         (cim:Temperature               cim:UnitMultiplier.none  cim:UnitSymbol.degC     unit:DEG_C                 )
         (cim:Voltage                   cim:UnitMultiplier.k     cim:UnitSymbol.V        unit:KiloV                 )
         (cim:VoltagePerReactivePower   cim:UnitMultiplier.k     cim:UnitSymbol.VPerVAr  unit:KiloV-PER-V-A_Reactive)
         (cim:VolumeFlowRate            cim:UnitMultiplier.none  cim:UnitSymbol.m3Pers   unit:M3-PER-SEC            )
  }
  ?prop
    qudt:hasQuantityKind ?qk;
    cim:unitMultiplier   ?multiplier;
    cim:unitSymbol       ?unit
};


