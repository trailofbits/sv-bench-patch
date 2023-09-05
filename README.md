# SV-Comp C Benchmarks helper for MLIR generating tools

This a simple patch and runner for SV-Comp benchmarks that helps to compile the benchmarks with [VAST](https://github.com/trailofbits/vast) and probably other tools that generate mlir.
The main purpose is to be used as a test of how many files can be succesfully compiled/translated to a dialect.

## Usage
To apply the patch you can run the apply script with the path to the root of the [sv-benchmarks repository](https://gitlab.com/sosy-lab/benchmarking/sv-benchmarks)(tested commi hash: `3d65c76d8521ef5bc79077a31e7b7e41dd077309`):
```./apply <path-to-sv-benchmarks-folder>```
Afterwards you can use several options (with defaults set-up for [VAST](https://github.com/trailofbits/vast)) to run the sv-benchmarks makefile with your compiler:
```
CC=<your tool>
MLIR_COMPILER=<base-name of your tool>
MLIR_OPTION=<what CLI-option your tool uses to set the output mlir dialect>
EMIT_MLIR=<value for the MLIR option>
REPORT_CC_FILE=1
```
For example:
```
make CC=/home/user/src/vast/build/bin/vast-front \
CC.Arch=64 \
MLIR_COMPILER=vast-front \
MLIR_OPTION=-vast-emit-mlir \
EMIT_MLIR=hl \
REPORT_CC_FILE=1
```
It is necessary to use the `MLIR_COMPILER` variable to circumvent a compiler check in the default makefile.
The `REPORT_CC_FILE=1` also tells the makefile to output `OK` for succesfully compiled benchmarks.

There is also a runner script which attempts to compile all the benchmarks and creates some basic statistics out of it:\
TODO: Make the runner script more universal (right now it's hard-wired for VAST and expects the same parent directory as the `sv-benchmarks` repostiory)
```
sh compile-all.sh
```
