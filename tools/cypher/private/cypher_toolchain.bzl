OFFSETS = [1, 5, 42]

CypherInfo = provider(
  doc = "Information about how to invoke the cypher compiler.",
  fields = [
      "compiler",
      "offset",
  ],
)

def _cypher_toolchain_impl(ctx):
  return [platform_common.ToolchainInfo(
      cypherinfo = CypherInfo(
          compiler = ctx.executable.compiler,
          offset = ctx.attr.offset,
      ),
  )]

cypher_toolchain = rule(
  implementation = _cypher_toolchain_impl,
  attrs = {
      "offset": attr.int(
          mandatory = True,
          doc = "Cypher offset",
      ),
      "compiler": attr.label(
          mandatory = True,
          cfg = "host",
          executable = True,
          doc = "Cypher Compiler",
      ),
  },
  doc = "Defines a Cypher toolchain",
  provides = [platform_common.ToolchainInfo],
)

def declare_toolchains():
  for offset in OFFSETS:
      _declare_toolchain(offset)

def _declare_toolchain(offset):
  toolchain_name = "cypher%s_toolchain" % offset
  impl_name = toolchain_name + "_impl"
  cypher_toolchain(
      name = impl_name,
      offset = offset,
      # select a compiler target based on offset
      # OFFSETS which don't align with targets here will cause issues;
      # As rules authors, it's important to manage this carefully.
      compiler = "//src/main/cpp/cypher:compiler%s" % offset,
  )
  native.toolchain(
      name = toolchain_name,
      toolchain_type = "//tools/cypher:cypher_toolchain",
      target_compatible_with = [
          "//tools/cypher:offset_%s" % offset,
      ],
      toolchain = ":" + impl_name,
  )
