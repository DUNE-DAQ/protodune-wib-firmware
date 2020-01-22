SRC_PATH=../../src
IPCORE_PATH=../../cores
SRC_FILES=$(shell find $(SRC_PATH) | grep -e "\.v")
IPCORE_FILES=$(shell find $(IPCORE_PATH) | grep -e "\.v") 



.PHONY: doc svn clean

all: doc

clean:
	@echo "Cleaning up"
	@git rm -r --force ./html > /dev/null 2>&1

svn : $(SRC_FILES) $(IPCORE_FILES)
	@git rm -r --force ./html 2> /dev/null
	@echo "Generating doxygen"
	@./doxygen-patched ./WIB_doc.cfg
	@git add ./html  > /dev/null 2>&1

doc : $(SRC_FILES) $(IPCORE_FILES)
	@echo "Generating doxygen"
	@./doxygen-patched ./WIB_doc.cfg


