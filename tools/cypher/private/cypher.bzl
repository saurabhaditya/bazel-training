def _cypher_library_impl(ctx):
   info = ctx.toolchains["//tools/cypher:cypher_toolchain"].cypherinfo
   srcs = ctx.attr.srcs
   src_paths = []
   src_files = []
   outputs = []

   args = ctx.actions.args()
   args.add(ctx.bin_dir.path)

   for s in srcs:
       sfiles = s.files.to_list()
       for sfile in sfiles:
           src_files.append(sfile)
           args.add(sfile.path)
           outputs.append(
               ctx.actions.declare_file(
                   sfile.basename.replace(".cy", ".cb"),
               ),
           )

   ctx.actions.run(
       inputs = src_files,
       outputs = outputs,
       arguments = [args],
       progress_message =
           "Cypher%s Compiling %s source files" %
           (info.offset, len(srcs)),
       executable = info.compiler,
   )
   return DefaultInfo(
       files = depset(outputs),
   )

cypher_library = rule(
  implementation = _cypher_library_impl,
  attrs = {
      "srcs": attr.label_list(allow_files = True),
  },
  toolchains = ["//tools/cypher:cypher_toolchain"],
)
