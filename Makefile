all:
	ghc -threaded -O2 --make -hidir build -odir build Main -o sol

clean:
	rm -rf build sol
