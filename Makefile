
doc:
	stack exec ./run.sh

clean:
	stack exec ./run.sh clean

fix:
	rm Thesis.aux

.PHONY: clean
