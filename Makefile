all:
	ghc -threaded -rtsopts -O2 --make -hidir build -odir build Main -o sol

clean:
	rm -rf build sol
