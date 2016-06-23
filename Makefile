.PHONY : test clean

test:
		./test/run.sh

clean:
		git clean -dxf

