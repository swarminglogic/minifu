# minifu
minifu - A css|js minimizer utility for automatic code replacements and hash-versioning

```
Utility that versions css|js minifaction replacements in code.

USAGE
    minifu  [--css|--js] -k KEY -p PREFIX -d OUT_DIR FILE_1 [..FILE_N]
    minifu  [--css|--js] -k KEY -p PREFIX -d OUT_DIR FILE_1 [..FILE_N] [-s SRC_DIR]

    Minifies input files to:
        OUT_DIR/KEY.<MD5>.min.{js|css}
    Where <MD5> is a shortened md5-hash of the generated minimized file.

    Performs code manipulation within SRC_DIR. See: CODE_REPLACEMENT

OPTIONS
    -h, --help              show this help text
    -v, --verbose           verbose output
    --js|--css              use either option depending on compression type
    -k, --key=KEY           replacement target for generated file.
    -p, --prefix=PREFIX     replacement prefix (e.g path as used in replacement)
    -o, --outdir=OUT_DIR    output directory to place minified file
    FILE_i                  list of files to process as input files.
                            Regular unix globs are possible, but you might want to
                            control specific ordering.

OPTIONALS
    -s,--src-dir=SRC_DIR    directory from where to recursively search and perform code
                            manipulation. Defaults to CWD if unset.
    --only-create           skips code manipulation process alltogether.

CODE_REPLACEMENT
    The following code manipulation is done for all files within OUT_DIR:

    When using --css flag:
        - Lines containing '{{ minifu:remove:css:KEY }}' are deleted
        - Lines containing '{{ minifu:add:css:KEY }}' is replaced with:
        <link rel="stylesheet" href="PREFIX/KEY.<MD5>.min.css">

    When using --js flag:
        - Lines containing '{{ minifu:remove:js:KEY }}' are deleted
        - Lines containing '{{ minifu:add:js:KEY }}' is replaced with:
        <script src="PREFIX/KEY.<MD5>.min.js"></script>

EXAMPLE
    minifu --css -k styles -p /css -d web/css src/css/*.css -s web

    This combines and minifies all *.css files in src/css/ into a single file
    file in e.g: ./css/styles.b7ef6cae.min.css,
    using the md5sum of the minified data. If no changes are made, the filename
    will remain unchanged.

    Additionally, it will replace all occurences of {{ minifu:add:css:KEY }} with
    <link rel="stylesheet" href="web/css/styles.b7ef6cae.min.css">

REQUIREMENTS:
    yui-compressor (http://yui.github.io/yuicompressor/)

Author:     Roald Fernandez (contact@swarminglogic.com)
Version:    0.1.1 (2018-01-30)
License:    MIT
```
