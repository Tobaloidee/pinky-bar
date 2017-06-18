dnl 10/24/2016

dnl This program is free software; you can redistribute it and/or modify
dnl it under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 2 of the License, or
dnl (at your option) any later version.

dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
dnl GNU General Public License for more details.

dnl You should have received a copy of the GNU General Public License
dnl along with this program; if not, write to the Free Software
dnl Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
dnl MA 02110-1301, USA.

dnl TEST_PERL() function in configure.ac
dnl
dnl Substitute perl related linker and
dnl cflags to the variables PERL_CF and
dnl PERL_LZ if the user enabled the
dnl --with-perl switch
AC_DEFUN([TEST_PERL],[
  PERL_LZ=""
  PERL_CF=""
  WITH_PERL=0

  AC_ARG_WITH([perl],
    AS_HELP_STRING([--with-perl],
      [Extend the program via perl scripts]),
    [],
    [with_perl=no]
  )

  AS_IF([test "x$with_perl" = "xyes"], [
    CHECK_CFLAGZ([-O0])

    AC_PATH_PROG(perlcf,perl,no)
    AS_IF([test "x$perlcf" = "xno"], [
      ERR([Couldnt find perl.])
    ])

    PERL_LZ=`$perlcf -MExtUtils::Embed -e ldopts`
    PERL_CF=`$perlcf -MExtUtils::Embed -e ccopts`

    dnl m4_foreach([LiB], [
    dnl     perl_construct,
    dnl     perl_parse,
    dnl     perl_run,
    dnl     perl_destruct,
    dnl     perl_alloc,
    dnl     perl_free
    dnl   ],[
    dnl     AC_CHECK_LIB(perl,LiB,[],[
    dnl       MISSING_FUNC()
    dnl     ])
    dnl ])

    WITH_PERL=1
  ])

  AC_SUBST(PERL_LZ)
  AC_SUBST(PERL_CF)
  AC_DEFINE_UNQUOTED([WITH_PERL],[$WITH_PERL],[Extend the program via perl scripts])

  dnl AS_IF([test "x$with_perl" = "xyes"], [
  dnl   AC_LINK_IFELSE([
  dnl     AC_LANG_SOURCE([[
  dnl       #include <stdio.h>
  dnl       #include <string.h>
  dnl       #include <EXTERN.h>
  dnl       #include <perl.h>
  dnl       int main(void) {
  dnl         static PerlInterpreter *my_perl = NULL;
  dnl         PERL_SYS_INIT3((int *)NULL, (char ***)NULL, (char ***)NULL);
  dnl         my_perl = perl_alloc();
  dnl         if (NULL == my_perl) {
  dnl           PERL_SYS_TERM();
  dnl           return -1;
  dnl         }
  dnl         perl_construct(my_perl);
  dnl         perl_parse(my_perl, NULL, 0, (char **)NULL, (char **)NULL);
  dnl         PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
  dnl         perl_run(my_perl);
  dnl         perl_destruct(my_perl);
  dnl         perl_free(my_perl);
  dnl         PERL_SYS_TERM();
  dnl         return 0;
  dnl       }
  dnl     ]])
  dnl   ],[],[
  dnl       LINK_FAILED([perl])
  dnl     ]
  dnl   )
  dnl ])

])


dnl TEST_python() function in configure.ac
dnl
dnl Substitute python related linker and
dnl cflags to the variables PYTHON_CF and
dnl PYTHON_LZ if the user enabled the
dnl --with-python switch
AC_DEFUN([TEST_PYTHON],[
  PYTHON_LZ=""
  PYTHON_CF=""
  WITH_PYTHON2=0
  WITH_PYTHON=0
  curpycfver="none"

  AC_ARG_WITH([python2],
    AS_HELP_STRING([--with-python2],
      [Extend the program via python scripts]),
    [],
    [with_python2=no]
  )

  AC_ARG_WITH([python3],
    AS_HELP_STRING([--with-python3],
      [Extend the program via python scripts]),
    [],
    [with_python3=no]
  )

  AS_IF([test "x$with_python2" = "xyes" || test "x$with_python3" = "xyes"], [
    CHECK_CFLAGZ([-O0])

    AS_IF([test "x$with_python2" = "xyes"], [
      AM_PATH_PYTHON([2],[
      ],[
        ERR([Couldnt find any python 2 version.])
      ])
      WITH_PYTHON2=1
    ])

    AS_IF([test "x$with_python3" = "xyes"], [
      AM_PATH_PYTHON([3],[
      ],[
        ERR([Couldnt find any python 3 version.])
      ])
    ])

    dnl What a python versioning mess.
    dnl We have to check back and forth different scenarious
    dnl to make sure we can find appropriate CFLAGS and LDFLAGS
    dnl for the requested python version.
    dnl When there is only 1 python version installed the file
    dnl naming is one, when there are 2 or more different
    dnl python version installed, the file naming is other.
    dnl Still reading or get bored ?
    m4_define([testveR],[python$PYTHON_VERSION])
    m4_define([testveR2],[python-config-$PYTHON_VERSION])

    dnl First check whether python and python-9.9 exist
    AC_PATH_PROG(pyvf1,testveR,no)
    AC_PATH_PROG(pyvf2,python,no)

    dnl Next check whether python-config and python-config-9.9 exist
    AC_PATH_PROG(pycf1,testveR2,no)
    AC_PATH_PROG(pycf2,python-config,no)

    dnl Check whether any of the python versions was found
    AS_IF([test "x$pyvf1" = "xno" && test "x$pyvf2" = "xno"], [
      ERR([Couldnt find python])
    ])

    dnl Check whether any of the python-config versions was found
    AS_IF([test "x$pycf1" = "xno" && test "x$pycf2" = "xno"], [
      ERR([Couldnt find python-config])
    ])

    dnl We firts check for the python-config-9.9 version
    AS_IF([test "x$pycf1" != "xno"], [
      curpycfver="${pycf1}"
    ])

    dnl We now know that python-config is the only version available
    AS_IF([test "x$pycf2" != "xno" && test "x$curpycfver" = "xnone"], [
      curpycfver="${pycf2}"
    ])

    WITH_PYTHON=1
    PYTHON_LZ=`${curpycfver} --ldflags`
    PYTHON_CF=`${curpycfver} --cflags`

    dnl m4_foreach([LiB], [
    dnl     Py_GetPath,
    dnl     Py_Initialize,
    dnl     PyImport_Import,
    dnl     PyObject_GetAttrString,
    dnl     PyCallable_Check,
    dnl     PyObject_CallObject,
    dnl     Py_Finalize
    dnl   ],[
    dnl     AC_CHECK_LIB(testveR,LiB,[],[
    dnl       MISSING_FUNC()
    dnl     ])
    dnl ])

  ])


  AC_SUBST(PYTHON_LZ)
  AC_SUBST(PYTHON_CF)
  AC_DEFINE_UNQUOTED([WITH_PYTHON],[$WITH_PYTHON],[Extend the program via python scripts])
  AC_DEFINE_UNQUOTED([WITH_PYTHON2],[$WITH_PYTHON2],[Extend the program via python scripts])

  dnl AS_IF([test "x$with_python2" = "xyes" || test "x$with_python3" = "xyes"], [
  dnl   AC_CHECK_HEADERS([testveR/Python.h],[],[
  dnl     MISSING_HEADER()
  dnl   ])
  dnl   AC_LINK_IFELSE([
  dnl     AC_LANG_SOURCE([[
  dnl       #include <stdio.h>
  dnl       #include <string.h>
  dnl       #include <Python.h>
  dnl       int main(void) {
  dnl         Py_Initialize();
  dnl         PyRun_SimpleString("from time import time,ctime\n"
  dnl                            "print(ctime(time()))\n");
  dnl         Py_Finalize();
  dnl         return 0;
  dnl       }
  dnl     ]])
  dnl   ],[],[
  dnl       LINK_FAILED([python])
  dnl     ]
  dnl   )
  dnl ])

])


dnl TEST_LUA() function in configure.ac
dnl
dnl Substitute lua related linker and
dnl cflags to the variables LUA_LIBS
dnl if the user enabled the --with-lua switch
AC_DEFUN([TEST_LUA],[
  LUA_LIBS=""
  WITH_LUA=0

  AC_ARG_WITH([lua],
    AS_HELP_STRING([--with-lua],
      [Extend the program via lua scripts]),
    [],
    [with_lua=no]
  )

  AS_IF([test "x$with_lua" = "xyes"], [
    CHECK_CFLAGZ([-O0])

    LUA_LIBS="-llua"
    WITH_LUA=1
  ])

  AC_SUBST(LUA_LIBS)
  AC_DEFINE_UNQUOTED([WITH_LUA],[$WITH_LUA],[Extend the program via lua scripts])
])


dnl TEST_RUBY() function in configure.ac
dnl
dnl Substitute ruby related linker and
dnl cflags to the variables RUBY_CF and
dnl RUBY_LZ if the user enabled the
dnl --with-ruby switch
AC_DEFUN([TEST_RUBY],[
  RUBY_LZ=""
  RUBY_CF=""
  WITH_RUBY=0

  AC_ARG_WITH([ruby],
    AS_HELP_STRING([--with-ruby],
      [Extend the program via ruby scripts]),
    [],
    [with_ruby=no]
  )

  AS_IF([test "x$with_ruby" = "xyes"], [
    CHECK_CFLAGZ([-O0])

    m4_ifndef([PKG_PROG_PKG_CONFIG], [
      AC_MSG_ERROR([Either you dont have pkg-config installed, or pkg.m4 is not in 'ls /usr/share/aclocal | grep pkg', if thats so try exporting the following env var: execute 'aclocal --print-ac-dir' without quotes, then: 'export ACLOCAL_PATH=/tmp' where /tmp is the directory printed from the previous command.])
    ])
    PKG_PROG_PKG_CONFIG()

    PKG_CHECK_MODULES([RUBY], [ruby-2.0 >= 2.0], [
      dnl AC_CHECK_LIB(ruby_init,[],[
      dnl   MISSING_FUNC()
      dnl ])

    ],[
      AC_MSG_ERROR([Your ruby version is too old, consider upgrade.])

    ])
    RUBY_CF=$RUBY_CFLAGS
    RUBY_LZ=$RUBY_LIBS
    WITH_RUBY=1

  ])

  AC_SUBST(RUBY_LZ)
  AC_SUBST(RUBY_CF)
  AC_DEFINE_UNQUOTED([WITH_RUBY],[$WITH_RUBY],[Extend the program via ruby scripts])
])


dnl TEST_R() function in configure.ac
dnl
dnl Substitute R related linker and
dnl cflags to the variables R_CF and
dnl R_LZ if the user enabled the
dnl --with-r switch
AC_DEFUN([TEST_R],[
  R_LZ=""
  R_CF=""
  WITH_R=0

  AC_ARG_WITH([r],
    AS_HELP_STRING([--with-r],
      [Extend the program via R scripts]),
    [],
    [with_r=no]
  )

  dnl For some reason libR is not
  dnl detected by PKG_CHECK_MODULES(),
  dnl but pkg-config manages to return
  dnl correct cflags and libs for it.
  AS_IF([test "x$with_r" = "xyes"], [
    CHECK_CFLAGZ([-O0])

    R_CF="-I/usr/lib64/R/include"
    R_LZ="-L/usr/lib64/R/lib -lR"
    WITH_R=1

  ])

  AC_SUBST(R_LZ)
  AC_SUBST(R_CF)
  AC_DEFINE_UNQUOTED([WITH_R],[$WITH_R],[Extend the program via R scripts])
])


dnl TEST_ASSEMBLY() function in configure.ac
dnl
dnl Check if the user enabled the
dnl --with-assembly switch
AC_DEFUN([TEST_ASSEMBLY],[
  WITH_ASSEMBLY=0

  AC_ARG_WITH([assembly],
    AS_HELP_STRING([--with-assembly],
      [Extend the program via assembly]),
    [],
    [with_assembly=no]
  )

  AS_IF([test "x$with_assembly" = "xyes"], [
    WITH_ASSEMBLY=1

  ])

  AC_DEFINE_UNQUOTED([WITH_ASSEMBLY],[$WITH_ASSEMBLY],[Extend the program via assembly])
])
