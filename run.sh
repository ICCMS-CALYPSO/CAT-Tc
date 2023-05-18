#!/bin/bash
#SBATCH  --job-name=qe.stable
#SBATCH  --error=err
#SBATCH  --partition=normal
#SBATCH  --nodes=1
#SBATCH  --ntasks=64
#SBATCH  --ntasks-per-node=64

source /public/env/apps_anaconda3-2021.05.sh
source /public/env/compiler_intel-compiler-2021.3.0.sh
source /public/env/mpi_intelmpi-2021.3.0.sh
VASPBIN="/public/home/wangyanchao/vasp.6.1.0/bin"
QEBIN="/public/home/wangyanchao/workplace/xiezh/software/QE_MC/QE/bin"
MPIRUN="mpirun -n 64 $QEBIN"

cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/opt
$MPIRUN/pw.x -npool 4 < opt.in.1 > opt.out.1
while ! grep -q "JOB DONE." opt.out.1
do
        echo "opt1_UNDERTAKING"
done

cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/opt
cp opt.in.template opt.in.2
last_cell_1=$(grep -n -E -o "CELL_PARAMETERS \(angstrom\)" opt.out.1 | tail -1 | cut -f1 -d:)
end_coordinates_1=$(grep -n -E -o "End final coordinates" opt.out.1 | tail -1 | cut -f1 -d:)
sed -n "$last_cell_1,$((end_coordinates_1 - 1))p" opt.out.1 >> opt.in.2

$MPIRUN/pw.x -npool 4 < opt.in.2 > opt.out.2
while !  grep -q "JOB DONE." opt.out.2
do
        echo "opt2_UNDERTAKING"
done

cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/opt
cp opt.in.template opt.in.3
last_cell_2=$(grep -n -E -o "CELL_PARAMETERS \(angstrom\)" opt.out.2 | tail -1 | cut -f1 -d:)
end_coordinates_2=$(grep -n -E -o "End final coordinates" opt.out.2 | tail -1 | cut -f1 -d:)
sed -n "$last_cell_2,$((end_coordinates_2 - 1))p" opt.out.2 >> opt.in.3

$MPIRUN/pw.x -npool 4 < opt.in.3 > opt.out.3
while !  grep -q "JOB DONE." opt.out.3
do
    echo "opt3_UNDERTAKING"
done

cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/opt
last_cell_3=$(grep -n -E -o "CELL_PARAMETERS \(angstrom\)" opt.out.3 | tail -1 | cut -f1 -d:)
end_coordinates_3=$(grep -n -E -o "End final coordinates" opt.out.3 | tail -1 | cut -f1 -d:)
sed -n "$last_cell_3,$((end_coordinates_3 - 1))p" opt.out.3 >> ../ph/0/scf.fit.in
sed -n "$last_cell_3,$((end_coordinates_3 - 1))p" opt.out.3 >> ../ph/0/scf.in
sed -n "$last_cell_3,$((end_coordinates_3 - 1))p" opt.out.3 >> ../ph/template/scf.fit.in
sed -n "$last_cell_3,$((end_coordinates_3 - 1))p" opt.out.3 >> ../ph/template/scf.in



cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/ph/0
$MPIRUN/pw.x -npool 4 < scf.fit.in > scf.fit.out
$MPIRUN/pw.x -npool 4 < scf.in > scf.out

while ! grep -q "JOB DONE." scf.out || ! grep -q "JOB DONE." scf.fit.out
do
  echo "scf_UNDERTAKING"
done
$MPIRUN/ph.x -npool 4 < ph.in > ph.out &

cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/ph/0
while true
do
  if [ -e "./gamma2GPa.dyn0" ];then
    echo "find_out"
    break
  else
    echo "keep_find"
    sleep 1
  fi
done
for i in `ps aux | grep ph.x | awk '{print $2}'`
do
kill ${i}
done
# /usr/bin/killall -9 ph.x

cd /public/home/wangyanchao/workplace/lihl/Bi4Br4/tc/test_1/ph/0
python job_run.py

cd ./1
$MPIRUN/pw.x -npool 4 < scf.fit.in > scf.fit.out
$MPIRUN/pw.x -npool 4 < scf.in > scf.out
$MPIRUN/ph.x -npool 4 < ph.in > ph.out
