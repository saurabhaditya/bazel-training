# from tmp.test import test
#
# if __name__ == '__main__':
#     print("*** %s ***" % test())
#

from tmp.test import test
from repo_gen.foo import foo
from repo_gen.bar import bar
from repo_gen.baz import baz
from repo_gen.bat import bat

print("*** %s ***" % test())
print("*** %s ***" % foo())
print("*** %s ***" % bar())
print("*** %s ***" % baz())
print("*** %s ***" % bat())