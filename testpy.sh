#!/system/bin/sh
export PATH=$(pwd)/usr/bin:$PATH
export LD_LIBRARY_PATH=$(pwd)/lib:$(pwd)/usr/lib
export PYTHONHOME=$(pwd)/usr
export PYTHONPATH=$(pwd)/assets/python3.7:$(pwd)/assets/python3.7/lib-dynload:$(pwd)/assets:/data/app/org.beeware.minimal-1.apk/assets/python3.7
export PYTHONCOERCECLOCALE=1

# test_builtin: test_import test_input_no_stdout_fileno test_input_tty test_input_tty_non_ascii test_input_tty_non_ascii_unicode_errors

#FIXME
# test__locale: test_float_parsing
#       from _locale import *
#       >>> localeconv()['decimal_point']

#FIXME
# test_bytes: PyBytes_from_format missing from ctypes

# test_asyncio:  test_create_connection_ip_addr test_create_connection_ipv6_scope test_create_connection_no_inet_pton
#                test_create_connection_service_name test_create_datagram_endpoint_sockopts test_create_server_ipv6
#                test_create_server_reuse_port test_env_var_debug

# test_c_locale_coercion: test_PYTHONCOERCECLOCALE_set_to_zero

# test_cmd_line: not written for android ?

# test_code :  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_code.py", line 270, in <module>
#    RequestCodeExtraIndex = py._PyEval_RequestCodeExtraIndex
#  File "/data/app/org.beeware.minimal-1.apk/assets/python3.7/ctypes/__init__.py", line 377, in __getattr__
#    func = self.__getitem__(name)
#  File "/data/app/org.beeware.minimal-1.apk/assets/python3.7/ctypes/__init__.py", line 382, in __getitem__
#    func = self._FuncPtr((name_or_ordinal, self))
# AttributeError: undefined symbol: _PyEval_RequestCodeExtraIndex

# test_compileall : total fail, not suitable for android ?

# test_hashlib : test_gil (test.test_hashlib.HashLibTestCase) ... Fatal Python error: Bus error

# test_fractions: testMixedArithmetic
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_fractions.py", line 419, in testMixedArithmetic
#    self.assertTypedEquals(0.1, F(1, 10) ** 1.0)
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_fractions.py", line 118, in assertTypedEquals
#    self.assertEqual(expected, actual)
# AssertionError: 0.1 != 0.09999999999999999

# test_decimal : test_invalid_override
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_decimal.py", line 5360, in test_invalid_override
#    invalid_grouping, 'g')
# AssertionError: ValueError not raised by get_fmt


# test_distutils : not suitable for stdlib zipimport
# NotADirectoryError: [Errno 20] Not a directory: '/data/app/org.beeware.minimal-1.apk/assets/python3.7/distutils/tests'

# test_locale : test_setlocale_category
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_locale.py", line 553, in test_setlocale_category
#    self.assertRaises(locale.Error, locale.setlocale, 12345)
# AssertionError: ValueError not raised by setlocale

# test_imp : not suitable for stdlib zipimport
#            test_issue1267 test_load_from_source test_multiple_calls_to_get_data


# test_logging : test_post_fork_child_no_deadlock
# Ensure child logging locks are not held; bpo-6721 & bpo-36533.
#   File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_logging.py", line 757, in test_post_fork_child_no_deadlock
#    self.fail("child process deadlocked.")
# AssertionError: child process deadlocked.

# test_ctypes : not suitable for stdlib zipimport
# ImportError: Start directory is not importable: '/data/app/org.beeware.minimal-1.apk/assets/python3.7/ctypes/test'

# test_fork1 : test_threaded_import_lock_fork
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_fork1.py", line 68, in test_threaded_import_lock_fork
#    self.wait_impl(pid)
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_fork1.py", line 31, in wait_impl
#    self.assertEqual(spid, cpid)
# AssertionError: 0 != 6236

#TODO: ask expert
# test_statistics : test_doc_tests test_shift_data_exact test_shift_data_exact
#    FAIL: test_doc_tests (test.test_statistics.DocTests)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_statistics.py", line 676, in test_doc_tests
#        self.assertEqual(failed, 0)
#    AssertionError: 4 != 0
#
#    ======================================================================
#    FAIL: test_shift_data_exact (test.test_statistics.TestStdev)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_statistics.py", line 1868, in test_shift_data_exact
#        self.assertEqual(self.func(data), expected)
#    AssertionError: 4.605552204797066 != 4.605552204797065
#
#    ======================================================================
#    FAIL: test_shift_data_exact (test.test_statistics.TestVariance)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_statistics.py", line 1868, in test_shift_data_exact
#        self.assertEqual(self.func(data), expected)
#    AssertionError: 21.211111111111112 != 21.21111111111111

#FIXME/EASY
# test_shutil : not suitable for toybox/busybox
#   test_unzip_zipfile unzip: invalid option -- 't'

# test_repl : test_no_memory
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_repl.py", line 57, in test_no_memory
#    self.assertIn(b'After the exception.', output)
# AssertionError: b'After the exception.' not found in b"Could not find platform independent libraries <prefix>
# Consider setting $PYTHONHOME to <prefix>[:<exec_prefix>]
# Fatal Python error: initfsencoding: Unable to get the locale encoding\nModuleNotFoundError: No module named 'encodings'

# test_pydoc : not suitable for android

# test_pty : not suitable for android (pty.fork)

#FIXME
# test_posix : test should skip
# AttributeError: module 'os' has no attribute 'mkfifo'

#FIXME/EASY
# test_platform :  not suitable for android, not glibc
#  File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_platform.py", line 304, in test_libc_ver
#    ('glibc', '1.23.4'))
# AssertionError: Tuples differ: ('libc', '19-bionic') != ('glibc', '1.23.4')


#FIXME/EASY
# test_sysconfig :
#    FAIL: test_get_makefile_filename (test.test_sysconfig.MakefileTests)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_sysconfig.py", line 430, in test_get_makefile_filename
#        self.assertTrue(os.path.isfile(makefile), makefile)
#    AssertionError: Fa lse is not true : /data/data/org.beeware.minimal/usr/lib/python3.7/config-3.7-armv7a-linux-androideabi/Makefile
#
#    ======================================================================
#    FAIL: test_srcdir (test.test_sysconfig.TestSysConfig)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_sysconfig.py", line 359, in test_srcdir
#        self.assertTrue(os.path.isdir(srcdir), srcdir)
#    AssertionError: False is not true : /data/data/org.beeware.minimal/usr/lib/python3.7/config-3.7-armv7a-linux-androideabi


#FIXME/HARD : test_4_daemon_threads deadlocks, not suitable for zipimport
# test_threading : test_4_daemon_threads test_finalize_runnning_thread


# test_script_regrtest : no suitable for android/zipimport


# test_unicode : test_from_format
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_unicode.py", line 2465, in test_from_format
#        _PyUnicode_FromFormat = getattr(pythonapi, name)
#      File "/data/app/org.beeware.minimal-1.apk/assets/python3.7/ctypes/__init__.py", line 377, in __getattr__
#        func = self.__getitem__(name)
#      File "/data/app/org.beeware.minimal-1.apk/assets/python3.7/ctypes/__init__.py", line 382, in __getitem__
#        func = self._FuncPtr((name_or_ordinal, self))
#    AttributeError: undefined symbol: PyUnicode_FromFormat


# test_venv : test_multiprocessing test_with_pip

#TODO: ask expert
# test_math : testPow testCosh
#    ERROR: testPow (test.test_math.MathTests)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_math.py", line 868, in testPow
#        self.assertEqual(math.pow(0., -0.), 1.)
#    ValueError: math domain error
#
#    ======================================================================
#    FAIL: testCosh (test.test_math.MathTests)
#    ----------------------------------------------------------------------
#    Traceback (most recent call last):
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_math.py", line 467, in testCosh
#        self.ftest('cosh(2)-2*cosh(1)**2', math.cosh(2)-2*math.cosh(1)**2, -1) # Thanks to Lambert
#      File "/data/data/org.beeware.minimal/usr/lib/python3.7/test/test_math.py", line 260, in ftest
#        self.fail("{}: {}".format(name, failure))
#    AssertionError: cosh(2)-2*cosh(1)**2: expected -1.0, got -1.0000000000000018 (error = 1.78e-15 (8 ulps); permitted error = 0 or 5 ulps)
#


#FIXME/HARD
# test_os : 6 failed

#TODO: ask expert
# test_ssl : fix per apk local certs config.

#FIXME: "not a directory"
# test_unittest test_argparse test_ast

MAYFAIL="test_cmd_line_script test_keyword test_lib2to3 test_modulefinder test_marshal"
MAYFAIL="$MAYFAIL test_functools test_unittest test_argparse test_ast test_site test_trace"
MAYFAIL="$MAYFAIL test_faulthandler test_ensurepip test_support test_importlib test_signal"
MAYFAIL="$MAYFAIL test_utf8_mode test_urllib2 test_linecache test_warnings test_threaded_import"

FAILED="$MAYFAIL\
 test_builtin test__locale test_bytes test_asyncio\
 test_c_locale_coercion test_cmd_line test_code test_compileall\
 test_hashlib test_fractions test_decimal test_distutils test_locale\
 test_imp test_logging test_ctypes test_fork1 test_statistics test_shutil\
 test_repl test_pydoc test_pty test_posix test_platform test_sysconfig\
 test_threading test_regrtest test_unicode test_venv\
 test_math test_os test_ssl"

if echo $@|grep testsuite
then
    cmdline=""
    for TEST in $FAILED
    do
        cmdline="$cmdline -x $TEST"
    done
    reset
    echo
    echo "skip list : $cmdline"
    echo
    ./usr/bin/python3.7 -u -B -m test $cmdline
else

    for TEST in $FAILED
    do
        reset
        echo
        echo $TEST
        echo
        ./usr/bin/python3.7 -u -B -m test -v $TEST
        read
    done
fi
