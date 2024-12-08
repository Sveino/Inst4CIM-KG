test_rdf           = $(wildcard test/rdf/*)
test_trig          = $(patsubst test/rdf/%.xml, test/trig/%.trig,     $(test_rdf))
test_jsonld        = $(patsubst test/rdf/%.xml, test/jsonld/%.jsonld, $(test_rdf))

nordic_source      = ../../../Nordic44/Instances
nordic_dirs       != /usr/bin/find $(nordic_source) -type d
nordic_target      = instances/Nordic44
nordic_target_dirs = $(subst $(nordic_source),$(nordic_target),$(nordic_dirs))
nordic_ignore      = CDPSM_2_0/Nordic44_CPSM_01_MF.xml CDPSM_2_0/Nordic44_03_inc.xml CGMES_2_4/Nordic44_CGM_36f_MF.xml CGMES_2_4/Nordic44_CGM_38_CO.xml
nordic_ignore2     = $(patsubst %, $(nordic_source)/%, $(nordic_ignore))
nordic_rdf         = $(filter-out $(nordic_ignore2), $(wildcard $(nordic_source)/*_2_*/*.xml))
nordic_trig        = $(subst .xml,.trig, $(subst $(nordic_source),$(nordic_target), $(nordic_rdf)))

entsoe_source      = ../../../CGMES-SHACL/ENTSO-E_Test_Configurations_v3.0.2/v3.0
entsoe_dirs       != /usr/bin/find $(entsoe_source) -type d
entsoe_target      = instances/ENTSO-E_Test_Configurations_v3.0.2
entsoe_target_dirs = $(subst $(entsoe_source),$(entsoe_target),$(entsoe_dirs))
entsoe_rdf         = $(wildcard $(entsoe_source)/*/*/*.xml) $(wildcard $(entsoe_source)/*/*/*/*.xml)
entsoe_trig        = $(subst .xml,.trig, $(subst $(entsoe_source),$(entsoe_target), $(entsoe_rdf)))

multiplied_source  = ../../instance-multiplied
multiplied_target  = instances/multiplied
multiplied_rdf     = $(wildcard $(multiplied_source)/*.xml)
multiplied_trig    = $(subst .xml,.trig, $(subst $(multiplied_source),$(multiplied_target), $(multiplied_rdf)))

zip                = ../../instance-zipped

all:
	@echo targets: context, dirs, zips, test, jsonld, nordic, entsoe, multiplied, rm-test, rm-jsonld, rm-nordic, rm-entsoe, rm-multiplied, clean
	#@echo $(nordic_trig)

context: cim-context-old.jsonld cim-context-new.jsonld
cim-context-%.jsonld: cim-context-%.txt cim-context-common.txt
	cat $^ > $@

dirs:
	-mkdir instances $(nordic_target) $(entsoe_target) $(multiplied_target) $(nordic_target_dirs) $(entsoe_target_dirs)
	touch $(patsubst %, %/.gitkeep, $(multiplied_target) $(nordic_target_dirs) $(entsoe_target_dirs))

zips:
	zip -r -m $(patsubst instances/%, $(zip)/%.zip, $(nordic_target))     $(nordic_target)     -x "*/.gitkeep"
	zip -r -m $(patsubst instances/%, $(zip)/%.zip, $(entsoe_target))     $(entsoe_target)	   -x "*/.gitkeep"
	zip -r -m $(patsubst instances/%, $(zip)/%.zip, $(multiplied_target)) $(multiplied_target) -x "*/.gitkeep"

clean:
	find instances test -type f -size 0 -exec rm {} \;

test: $(test_trig)
rm-test:
	rm -f $(test_trig)
test/trig/%.trig: test/rdf/%.xml | cim-trig.pl
	perl cim-trig.pl -r $^ > temp.trig
	update.bat --update=fix-datatypes-old.ru --data=temp.trig --dump > $@
	rm temp.trig

jsonld: $(test_jsonld)
rm-jsonld:
	rm -f $(test_jsonld)
test/jsonld/%.jsonld: test/trig/%.trig
	riot.bat -formatted jsonld $^ | jsonld compact -c https://rawgit2.com/Sveino/Inst4CIM-KG/develop/rdf-improved/cim-context-old.jsonld > $@

nordic: $(nordic_trig)
rm-nordic:
	rm -f $(nordic_trig)
$(nordic_target)/%.trig: $(nordic_source)/%.xml | cim-trig.pl
	perl cim-trig.pl -r $^ > temp.trig
	update.bat --update=fix-datatypes-old.ru --data=temp.trig --dump > $@
	rm temp.trig

entsoe: $(entsoe_trig)
rm-entsoe:
	rm -f $(entsoe_trig)
$(entsoe_target)/%.trig: $(entsoe_source)/%.xml | cim-trig.pl
	perl cim-trig.pl -r $^ > temp.trig
	update.bat --update=fix-datatypes-old.ru --data=temp.trig --dump > $@
	rm temp.trig

multiplied: $(multiplied_trig)
rm-multiplied:
	rm -f $(multiplied_trig)
# update.bat cannot fit in my RAM for such large files
$(multiplied_target)/%.trig: $(multiplied_source)/%.xml | cim-trig.pl
	perl cim-trig.pl -r $^ > $@
