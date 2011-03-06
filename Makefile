all:
	ghc --make -hidir build -odir build Main -o sol

clean:
	rm -rf build sol
