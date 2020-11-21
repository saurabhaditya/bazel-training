# Lab 7.2 — Genrules and Macros Bonus Track

## Merge it all

Converting CSV to JSON and back is fun, but what if we could take the best from both formats?

One of our crazy engineers recently invented a special file format just for that — `jsonsv`!

Fortunately, it is pretty easy to produce files in this format: you just need to append JSON contents **in the end** of the CSV file. 

In the form of bash script it would be like:

```bash
cat a.csv b.json > output.jsonsv
```

Your goal is to create `genrule` that will use `//src/main/genrule:csv_sanitized` and `//src/main/genrule:convert_csv` target outputs and produce `jsonsv` file!

Name it `compile_jsonsv`.

Put it in `src/main/jsonsv` package.

Be careful with targets visibility.

Make sure all tests are passing:

```bash
bazel test //src/main/jsonsv:all
```

Note: it is prohibited to modify test targets `//src/main/jsonsv:jsonsv_test` and `//src/main/jsonsv:ext_test` in any way!

<details>
  <summary>Hint</summary>

Bonus track!

No hints this time :-) 

</details>
