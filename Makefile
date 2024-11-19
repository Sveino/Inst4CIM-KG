issues:
	gh issue ls -s all -L 1000 --json url,title -q 'sort_by(.url) | .[] | [.url, .title] | @tsv' > issues-all.tsv
	perl -ne 'print "$$1\n" while m{(https://github.com/Sveino/Inst4CIM-KG/issues/\d+)}g' README.md */README.md | sort | uniq > issues-README.txt
	d2u issues-README.txt
	cut -f1 issues-all.tsv | comm -3 - issues-README.txt | join - issues-all.tsv > issues-missing.tsv
	wc -l issues-*
