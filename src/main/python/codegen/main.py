import sys
f = open(sys.argv[2], "w")
f.write("def {str}():\n    return \"{str}\"".format(str = sys.argv[1]))
f.close()
