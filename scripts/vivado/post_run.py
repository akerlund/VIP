#!/usr/bin/env python3

import sys, re, subprocess, os, shutil
import argparse
import datetime
from distutils.dir_util import copy_tree


def post_run(rundir, waiver_path):

  print("--------------------------------------------------------------------------------")
  print("INFO [post_run] Analyzing Vivado run")
  print("--------------------------------------------------------------------------------")

  _ret = 0

  _log_path    = rundir + "/vivado.log"
  _report_path = rundir + "/reports"
  _timing_path = rundir + "/reports/post_synth_timing_summary.rpt"

  # Reading the log
  with open(_log_path) as _f:
    _log = _f.read()

  # Reading the waivers
  if not waiver_path == None:
    with open(waiver_path) as _f:
      _waivers = _f.readlines()
  else:
    _waivers = []

  # Reading the timing report
  with open(_timing_path) as _f:
    _timing = _f.read()

  # Waiving
  for _wre in _waivers:
    _re  = re.compile(_wre.rstrip(), re.MULTILINE)
    _log = _re.sub('', _log, 0)

  # Reporting warnings
  _re      = r'^WARNING:.*$'
  _matches = re.findall(_re, _log, re.MULTILINE)
  if len(_matches):
    _ret       = -1
    _warnings0 = len(re.findall(_re, _log, re.MULTILINE))
    print("ERROR [post_run] Detected (%d) new warnings:" % _warnings0)
    for _m in _matches:
      print(_m)
  else:
    print("INFO [post_run] No warnings")

  # Reporting errors
  _re      = r'^ERROR:.*$'
  _matches = re.findall(_re, _log, re.MULTILINE)
  if len(_matches):
    _ret     = -1
    _errors0 = len(re.findall(_re, _log, re.MULTILINE))
    print("ERROR [post_run] Detected (%d) new errors:" % _errors0)
    for _m in _matches:
      print(_m)
  else:
    print("INFO [post_run] No errors")

  # Reporting critical warnings
  _re      = r'^CRITICAL WARNING:.*$'
  _matches = re.findall(_re, _log, re.MULTILINE)
  if len(_matches):
    _ret        = -1
    _criticals0 = len(re.findall(_re, _log, re.MULTILINE))
    print("ERROR [post_run] Detected (%d) new critical warnings:" % _criticals0)
    for _m in _matches:
      print(_m)
  else:
    print("INFO [post_run] No critical warnings")

  # Reporting timing
  _re      = r'^Timing constraints are not met\.$'
  _matches = re.findall(_re, _timing, re.MULTILINE)
  if len(_matches):
    _ret = -1
    print("ERROR [post_run] Timing constraints are not met")

  # Exit
  if _ret == 0:
    print("INFO [post_run] PASS")
  sys.exit(_ret)

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument("-d", "--directory", type = str, help = "Path to the run directory", metavar=' ')
  parser.add_argument("-w", "--waiver",    type = str, help = "Path to the waiver file",   metavar=' ')
  args = parser.parse_args()

  # Rundir
  if args.directory:
    _rundir = args.directory
    if _rundir[-1] == '/':
      _rundir = _rundir[:-1]
  else:
    print("ERROR [psv] The run directory must be provided (-d)")
    sys.exit(-1)

  # Waiver file
  if args.waiver:
    _waiver_path = args.waiver
  else:
    _waiver_path = None

  post_run(_rundir, _waiver_path)
