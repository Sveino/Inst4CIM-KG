RDF  = $(wildcard test/rdf/*)
TRIG = $(patsubst test/rdf/%.xml, test/trig/%.trig, $(RDF))

all: $(TRIG)

test/trig/%.trig: cim-trig.pl test/rdf/%.xml
	perl $^ $@
