# styles setup
DOCBOOK_BASE = /usr/share/sgml/docbook/xsl-stylesheets
STYLE_HTML = $(DOCBOOK_BASE)/html/docbook.xsl
STYLE_XHTML = $(DOCBOOK_BASE)/xhtml/docbook.xsl

all:
	xsltproc \
	--xinclude \
	--output devball.html \
	--stringparam section.autolabel 1 \
	--stringparam section.label.includes.component.label 1 \
	--stringparam use.extensions 0 \
	$(STYLE_HTML) devball.xml

clean:
	@rm -vf devball.html

.PHONY: all clean
.DEFAULT_GOAL: all
