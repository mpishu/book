.PHONY: book blog draft widgets publish clean download lint

FLAGS=

CHAPTERS=$(patsubst book/%.md,%,$(wildcard book/*.md))
WIDGET_LAB_CODE=lab2.js lab3.js lab5.js

book: $(patsubst %,www/%.html,$(CHAPTERS)) www/rss.xml widgets lint
blog: $(patsubst blog/%.md,www/blog/%.html,$(wildcard blog/*.md)) www/rss.xml
draft: $(patsubst %,www/draft/%.html,$(CHAPTERS)) www/onepage.html widgets
widgets: $(patsubst %,www/widgets/%,$(WIDGET_LAB_CODE))

lint: book/*.md src/*.py
	python3 infra/compare.py --config config.json

PANDOC=pandoc --from markdown --to html --lua-filter=infra/filter.lua --fail-if-warnings --metadata-file=config.json $(FLAGS)

www/%.html: book/%.md infra/template.html infra/signup.html infra/filter.lua config.json
	$(PANDOC) --toc --metadata=mode:book --template infra/template.html -c book.css $< -o $@

www/blog/%.html: blog/%.md infra/template.html infra/filter.lua config.json
	$(PANDOC) --metadata=mode:blog --template infra/template.html -c book.css $< -o $@

www/draft/%.html: book/%.md infra/template.html infra/signup.html infra/filter.lua config.json
	$(PANDOC) --toc --metadata=mode:draft --template infra/template.html -c book.css $< -o $@

www/rss.xml: news.yaml infra/rss-template.xml
	pandoc --template infra/rss-template.xml  -f markdown -t html $< -o $@

www/widgets/%.js: src/%.py
	python3 infra/compile.py $< $@ --hints src/$*.hints

www/onepage/%.html: book/%.md infra/chapter.html infra/filter.lua config.json
	$(PANDOC) --toc --metadata=mode:onepage --variable=cur:$* --template infra/chapter.html $< -o $@

www/onepage.html: $(patsubst %,www/onepage/%.html,$(CHAPTERS))
www/onepage.html: book/onepage.md infra/template.html infra/filter.lua config.json
	$(PANDOC) --metadata=mode:onepage --template infra/template.html -c book.css $< -o $@

publish:
	rsync -rtu --exclude=*.pickle --exclude=*.hash www/ server:/home/www/browseng/
	ssh server chmod -Rf a+r /home/www/browseng/ || true
	ssh server sudo systemctl restart browser-engineering.service

download:
	rsync -r 'server:/home/www/browseng/*.pickle' www/
