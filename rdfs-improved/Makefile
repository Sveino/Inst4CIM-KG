.PHONY: all dirs ttl1 ttl rm-ttl clean fix-all

all::
	 @echo "targets: dirs, clean (zero files), fix-all (concat fix*.ru), ttl1 (for testing), ttl, rm-ttl"

FIX-ALL = $(wildcard fix[0-9]*)

CGMES_RDF    = $(wildcard ../source/CGMES/v3.0/RDFS2020/*)
CGMES_NC_RDF = $(wildcard ../source/CGMES-NC/r2.3/ap-voc/rdf/*)

CGMES_TTL    = $(patsubst ../source/CGMES/v3.0/RDFS2020/%.rdf,      CGMES/ttl/%.ttl,    $(CGMES_RDF))
CGMES_NC_TTL = $(patsubst ../source/CGMES-NC/r2.3/ap-voc/rdf/%.rdf, CGMES-NC/ttl/%.ttl, $(CGMES_NC_RDF))

ONE_RDF      = ../source/CGMES/v3.0/RDFS2020/61970-600-2_Equipment-AP-Voc-RDFS2020_v3-0-0.rdf
ONE_TTL      = $(patsubst ../source/CGMES/v3.0/RDFS2020/%.rdf,      CGMES/ttl/%.ttl,    $(ONE_RDF))

# https://atextor.de/owl-cli/main/snapshot/usage.html#write-command
# Prefix sorting: CIM/CGMES/NC/model/header/meta, CGMES profiles, NC profiles, other (standard prefixes).
_2TTL = owl.bat write --prefixAlign=right --useCommaByDefault \
  --prefixOrder cim							\
  --prefixOrder nc							\
  --prefixOrder cims							\
  --prefixOrder dcat-cim						\
  --prefixOrder dm							\
  --prefixOrder eu							\
  --prefixOrder eumd							\
  --prefixOrder md							\
  --prefixOrder prof							\
  --prefixOrder profcim							\
									\
  --prefixOrder dh							\
  --prefixOrder dl							\
  --prefixOrder dy							\
  --prefixOrder eq							\
  --prefixOrder eqbd							\
  --prefixOrder gl							\
  --prefixOrder op							\
  --prefixOrder sc							\
  --prefixOrder ssh							\
  --prefixOrder sv							\
  --prefixOrder tp							\
									\
  --prefixOrder ae							\
  --prefixOrder as							\
  --prefixOrder co							\
  --prefixOrder er							\
  --prefixOrder gd							\
  --prefixOrder iam							\
  --prefixOrder ma							\
  --prefixOrder or							\
  --prefixOrder ps							\
  --prefixOrder psp							\
  --prefixOrder ra							\
  --prefixOrder ras							\
  --prefixOrder sar							\
  --prefixOrder sm							\
  --prefixOrder sis							\
  --prefixOrder shs							\
  --prefixOrder ssi							\
									\
  --prefixOrder dcat							\
  --prefixOrder dct							\
  --prefixOrder dcterms							\
  --prefixOrder euvoc							\
  --prefixOrder owl							\
  --prefixOrder prov							\
  --prefixOrder rdf							\
  --prefixOrder rdfs							\
  --prefixOrder sh							\
  --prefixOrder skos							\
  --prefixOrder xsd

# Doesn't work yet: https://github.com/atextor/turtle-formatter/issues/22
#  --prefix rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns\#		\
#  --prefix rdfs=http://www.w3.org/2000/01/rdf-schema\#			\
#  --prefix owl=http://www.w3.org/2002/07/owl\#				\
#  --prefix cims=http://iec.ch/TC57/1999/rdf-schema-extensions-19990926\# \
#									\
#  --subjectOrder owl:Ontology						\
#  --subjectOrder cims:ClassCategory					\
#  --subjectOrder rdfs:Class						\
#  --subjectOrder owl:Class						\
#  --subjectOrder rdf:Property						\
#  --subjectOrder owl:ObjectProperty					\
#  --subjectOrder owl:DatatypeProperty					\
#  --subjectOrder owl:AnnotationProperty					\
#  --subjectOrder owl:NamedIndividual


define RDF2FIXTTL
 $(_2TTL) --input=rdfxml $(1) temp1.ttl
 perl fix-namespaces.pl temp1.ttl > temp2.ttl
 update.bat --update=fix-all.ru --data=temp2.ttl --dump > temp3.ttl
 $(_2TTL) temp3.ttl $(2)
 rm temp1.ttl temp2.ttl temp3.ttl
endef

fix-all: fix-all.ru

fix-all.ru: $(FIX-ALL)
	cat $^ > $@
	update.bat --update=$@

ttl1::
	$(call RDF2FIXTTL,$(ONE_RDF),one.ttl)
	TortoiseGitMerge $(ONE_TTL) one.ttl &

ttl: rm-ttl $(CGMES_TTL) $(CGMES_NC_TTL)

rm-ttl::
	rm $(CGMES_TTL) $(CGMES_NC_TTL)

clean::
	find . -type f -size 0 -delete

CGMES/ttl/%.ttl: ../source/CGMES/v3.0/RDFS2020/%.rdf
	$(call RDF2FIXTTL,$^,$@)

CGMES-NC/ttl/%.ttl: ../source/CGMES-NC/r2.3/ap-voc/rdf/%.rdf
	$(call RDF2FIXTTL,$^,$@)

dirs::
	mkdir CGMES CGMES/ttl CGMES-NC CGMES-NC/ttl
