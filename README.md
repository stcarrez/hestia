# Hestia Heat Controller on a STM32F746

[![Build Status](https://img.shields.io/jenkins/s/http/jenkins.vacs.fr/hestia.svg)](http://jenkins.vacs.fr/job/hestia/)
[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)](LICENSE)
![Commits](https://img.shields.io/github/commits-since/stcarrez/hestia/1.0.0.svg)

Hestia is a heat controller application to control the home heat system.
It runs on a STM32F746 board.

Hestia uses the following two GitHub projects:

* Ada_Drivers_Library   https://github.com/AdaCore/Ada_Drivers_Library.git

* Ada Embedded Network  https://github.com/stcarrez/ada-enet.git

You need the source of these two projects to buid Hestia.
To help, these GitHub projects are registered as Git submodules and
the Makefile provides a target to perform the checkout.  Just run:

  make checkout

You will also need the GNAT Ada compiler for ARM available at http://libre.adacore.com/
(the GNAT ARM 2017 is used).

# Build

Run the command:

  make

to build the application and get the Hestia image 'hestia.bin'.
Then, flash the image with:

  st-flash write hestia.bin 0x8000000

or just

  make flash

