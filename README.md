# PathoMagic: Minimum annotated genomic information in CSV

## Introduction

PathoMagic is a CLI tool which converts annotated genomic information stored in CSV to the PathoLogic Format (PF) and back. PathoMagic consists of two fast parsers, built using flex/yacc:

- `mi2pf` parses CSV files and outputs files in the PathoLogic Format
- `pf2mi` parses PF files outputting CSV

<img src="PathoMagic_overview.png" alt="PathoMagic Overview" width="800">

## Requirements

The following tools are required:

- **Flex** (lexical analyzer generator)
- **Bison** (parser generator, yacc-compatible)
- **A C compiler** (such as GCC or Clang)

## Building the parsers

To build a parser and get the binary:

1. `bison -d {parser}.y`
2. `flex {parser}.l`
3. `gcc {parser}.tab.c lex.yy.c -o {parser}`

Where `{parser}` is either `mi2pf` or `pf2mi`.

## Using the parsers

The parsers read input from standard input (stdin), so input files are provided using shell redirection (`<`). This works directly in Linux, macOS, Windows Command Prompt, Git Bash, and WSL. In PowerShell, use `cmd /c` if you want shell redirection, for example `cmd /c "mi2pf test_out.pf < test_in.csv"`.

For example, to convert `test_in.csv` to a PathoLogic Format file `test_out.pf`, run:

`mi2pf test_out.pf < test_in.csv`

### mi2pf usage

mi2pf accepts ordinary CSV fields as well as quoted CSV fields. Quoted fields may contain commas, and embedded double quotes inside a quoted field must be written as `""`. Quoted CSV fields containing embedded new lines are not supported because PF records are line-oriented.

mi2pf needs at least one argument passed to it, the name of the output file. You can also pass the number of CSV columns of your input. Acceptable commands are:

1. `mi2pf {output_file}.pf < {input_file}.csv`
2. `mi2pf {output_file}.pf {number of columns of CSV input} < {input_file}.csv`
The default value is `20` for the columns.

When a CSV field contains multiple values that should become repeated PF entries under the same title, separate those values with `|`.

### pf2mi usage

pf2mi reads PF entries structurally rather than through a fixed supported-character whitelist. Repeated PF entries with the same title are joined into a single CSV field using `|`, and CSV fields are quoted when needed.

Because `|` is reserved as the CSV multi-value separator, literal `|` characters are not allowed inside PF values.

pf2mi needs at least one argument passed to it, the name of the output file. You can also pass the number of different characteristics present in the PF file (alternatively, CSV columns of your output) and the number of records present in the PF file (alternatively, CSV rows of your output). Acceptable commands are:

1. `pf2mi {output_file}.csv < {input_file}.pf`
2. `pf2mi {output_file}.csv {number of characteristics of PF input} < {input_file}.pf`
3. `pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} < {input_file}.pf`
The default values are `20` for the characteristics and `5000` for the records.

Repeated PF entries with the same title are joined back into a single CSV field using `|`.
