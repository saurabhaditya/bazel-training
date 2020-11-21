load(
    "//tools/cypher/private:cypher_toolchain.bzl",
    "declare_toolchains",
    _OFFSETS = "OFFSETS"
)
OFFSETS = _OFFSETS

def declare_cypher_toolchains():
    native.constraint_setting(
        name = "offset",
    )
    for offset in _OFFSETS:
      native.constraint_value(
        name = "offset_%s" % offset,
        constraint_setting = ":offset",
      )
      native.platform(
         name = "cypher%s" % offset,
         constraint_values = [
             ":offset_%s" % offset,
         ],
      )
    declare_toolchains()
