Python Android Support
======================

This is a meta-package for building a version of CPython that can be embedded
into an Android project.

It works by downloading, patching, and building CPython and selected pre-
requisites, and packaging them as linkable dynamic libraries.

The binaries support armeabi-v7a, arm64-v8a, x86 and x86_64. This should enable
the code to run on most modern Android devices.

The master branch of this repository has no content; there is an
independent branch for each supported version of Python. The following
Python versions are supported:

* `Python 3.6 <https://github.com/beeware/Python-Android-support/tree/3.6>`__


* `Python 3.7 <https://github.com/pmp-p/Python-Android-support/tree/3.7>`__

armeabi-v7a : running testsuite on h3droid 1.3.6pre / orange pi pc+

```
323 tests OK.

40 tests skipped:
    test_asdl_parser test_clinic test_concurrent_futures test_crypt
    test_curses test_dbm_gnu test_dbm_ndbm test_devpoll test_gdb
    test_grp test_idle test_kqueue test_msilib
    test_multiprocessing_fork test_multiprocessing_forkserver
    test_multiprocessing_main_handling test_multiprocessing_spawn
    test_nis test_ossaudiodev test_readline test_smtpnet
    test_socketserver test_spwd test_sqlite test_startfile test_tcl
    test_timeout test_tix test_tk test_ttk_guionly test_ttk_textonly
    test_turtle test_urllib2net test_urllibnet test_wait3
    test_winconsoleio test_winreg test_winsound test_xmlrpc_net
    test_zipfile64

Total duration: 1 hour 11 min
```

more details in testpy.sh
