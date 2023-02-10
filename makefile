all: draft-ietf-pim-assert-packing.txt

draft-ietf-pim-assert-packing.txt: draft-ietf-pim-assert-packing.xml
	xml2rfc draft-ietf-pim-assert-packing.xml

draft-ietf-pim-assert-packing.xml: draft-ietf-pim-assert-packing.md
	kramdown-rfc2629 draft-ietf-pim-assert-packing.md > draft-ietf-pim-assert-packing.xml
