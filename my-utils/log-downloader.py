#!/usr/bin/env python3

import os, subprocess
from pathlib import Path

LOG_FILE='/tmp/debian-containers.log'
LOG_FILE='/tmp/ubuntu-containers.log'
LOG_FILE='/tmp/yum-containers.log'
LOG_FILE='/tmp/yum-sandbox.log'

YUM_REPOS='base updates extras epel'

def execute_cmd(args):
    """
    Execute command with subprocess but without shell=true
    Args:
      args list of command and parameters
    Return: Tuple of
      status of the command
      output of the command
    """
    output = ''
    ok = False
    try:
        if args:
            output = subprocess.check_output(args, stderr=subprocess.STDOUT)
            ok = True
    except subprocess.CalledProcessError as e:
        output = e.output
        if 'File exists' in output:
            ok = True
        else:
            ok = False

    return ok, output

def apt_dl(pkg):
    print('apt downloading ' + pkg + ' ...')
    execute_cmd(['apt', 'download', pkg])

def yum_dl(pkg):
    print('yum downloading ' + pkg + ' ...')
    execute_cmd(['yumdownloader', pkg])

def downloader(pkgs, curdir):
    for pkg in pkgs:
        folder = pkgs[pkg]
        Path(folder).mkdir(parents=True, exist_ok=True)
        print('chdir ' + folder)
        os.chdir(folder)
        if folder is 'ubuntu' or folder is 'debian':
            apt_dl(pkg)
        else:
            yum_dl(pkg)
        os.chdir(curdir)

def log_parser(log_file):
    pkgs = dict()
    with open(log_file, 'r') as f:
        line = f.readline()
        while line != '':
            words = line.split()
            pkg = None
            location = None
            if words:
                if 'Get:' in words[0]:
                    if 'debian' in words[1]:
                        location = 'debian'
                    else:
                        location = 'ubuntu'
                    pkg = words[4]
                else:
                    if words[3] in YUM_REPOS:
                        location = words[3]
                        pkg = words[0] + '.' + words[1]
            if pkg and location:
                if pkg in pkgs:
                    if pkgs[pkg] != location:
                        print('oops location change from %s to %s' % (pkgs[pkg], location))
                pkgs[pkg] = location
            line = f.readline()
    return pkgs

def main():
    pkgs = log_parser(LOG_FILE)
    curdir = os.getcwd()
    downloader(pkgs, curdir)

if __name__ == '__main__':
    main()
