#!/bin/sh
cd ../sv-benchmarks/c
make clean
STAT_FOLDER="stats/$(date +"%y-%m-%d")"
OUT_FILE="out-k$(date +"%H%M%S").txt"
mkdir -p $STAT_FOLDER
make CC=vast-front CC.Arch=64 EMIT_MLIR=hl REPORT_CC_FILE=1 -j $(nproc --all) 2>/dev/null | tee ${STAT_FOLDER}/${OUT_FILE}
cd ${STAT_FOLDER}
mkdir -p data
cd data
csplit -z --digits=3 ../${OUT_FILE} /Entering/ {*} 1>/dev/null
for x in xx*; do
    head -n 1 $x | \
    sed -n -e "s;.*'.*\(sv-benchmarks/c/.*\)';\1;p" && echo -n $(cat $x | grep "OK" | wc -l) \
    && echo -n "/" && echo $(cat $x | grep -v "make" | grep -v "OK" | wc -l);
done > ../res.txt
echo "Total" >> ../res.txt; echo $(echo -n $(grep "OK" ../${OUT_FILE} | wc -l); echo -n "/"; grep -v "make.*directory" ../${OUT_FILE} | grep -v "OK" | wc -l) >> ../res.txt
cd ..
rm -rf data
echo "You can find the stats in ../sv-bnechmarks-c/${STAT_FOLDER}/res.txt"
