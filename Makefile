.PHONY : test clean

clean:
		git clean -dxf

test:
		./test/run.sh
