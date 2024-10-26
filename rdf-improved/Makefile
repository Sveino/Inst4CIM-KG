test_rdf    = $(wildcard test/rdf/*)
test_trig   = $(patsubst test/rdf/%.xml, test/trig/%.trig, $(RDF))

nordic_source  = ../../../Nordic44/Instances
nordic_target  = instances/Nordic44
nordic_ignore  = ./CDPSM_2_0/Nordic44_CPSM_01_MF.xml ./CDPSM_2_0/Nordic44_03_inc.xml ./CGMES_2_4/Nordic44_CGM_36f_MF.xml ./CGMES_2_4/Nordic44_CGM_38_CO.xml
nordic_ignore2 = $(subst ./, $(nordic_source), $(nordic_ignore))
nordic_rdf     = $(filter-out $(nordic_ignore2), $(wildcard $(nordic_source)/*_2_*/*.xml))
nordic_trig    = $(subst .xml,.trig, $(subst $(nordic_source),$(nordic_target), $(nordic_rdf))

entsoe_source  = ../../CGMES-SHACL/ENTSO-E_Test_Configurations_v3.0.2/v3.0
entsoe_target  = instances/ENTSO-E_Test_Configurations_v3.0.2
entsoe_rdf     = $(wildcard $(entsoe_source)/*/*/*/*.xml) $(wildcard $(entsoe_source)/*/*/*/*/*.xml)
entsoe_trig    = $(subst .xml,.trig, $(subst $(entsoe_source),$(entsoe_target), $(entsoe_rdf))

all::
	 @echo "targets: test, nordic, entsoe, rm-test, rm-nordic, rm-entsoe
all: $(TRIG)

test/trig/%.trig: cim-trig.pl test/rdf/%.xml
	perl $^ $@
