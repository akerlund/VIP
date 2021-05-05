if [ "$#" -lt 1 ]; then
  echo "ERROR [summary_report] Provide the rundir"
else
  rundir=$1
fi

cd $rundir/vivado
rm -f summary.log

# Header
echo "Testcase                        Result | Warnings | Errors | Failures | Time" > summary.log

# Last line from each TC's log file
for log in $(ls -1 tc_*.log); do
  tail -n 1 $log >> summary.log
done

# The result is appended by the xsim.sh script
sed -n -e '/Failed/{q1}' summary.log
