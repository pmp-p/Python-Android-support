Python Android Support
======================

**This repository branch builds a packaged version of Python 3.6.6**.
Other Python versions are available by cloning other branches of the main
repository.

This is a meta-package for building a version of CPython that can be embedded
into an Android project.

It works by downloading, patching, and building CPython and selected pre-
requisites, and packaging them as linkable dynamic libraries.

Quickstart
----------

Pre-built versions of the frameworks `can be downloaded`_ and added to your
project.

Alternatively, to build the frameworks on your own, download/clone this
repository, and then in the root directory, and run `make` (or `make all`)
to build everything.

This should:

1. Download the original source packages
2. Patch them as required for compatibility with the selected OS
3. Build the packages.

The build products will be in the `build` directory; the compiled artefacts
will be in the `dist` directory.

.. _can be downloaded: https://s3-us-west-2.amazonaws.com/pybee-briefcase-support/Python-Android-support/3.6/Python-3.6-Android-support.b1.tar.gz
