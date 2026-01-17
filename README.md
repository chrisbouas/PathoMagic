# PathoMagic: Minimum annotated genomic information in CSV

## Introduction

PathoMagic is a CLI tool which converts annotated genomic information stored in CSV to the PathoLogic Format (PF) and back. PathoMagic consists of two fast parsers, built using flex/yacc:

- `mi2pf` parses CSV files and outputs files in the PathoLogic Format
- `pf2mi` parses PF files outputting CSV

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

The parsers read input from **standard input (stdin)**, so input files are provided using shell redirection (`<`). This works the same way on **Linux, macOS, and Windows (Command Prompt, PowerShell, Git Bash, WSL)**.

For example, to convert `test_in.csv` to a PathoLogic Format file `test_out.pf`, run:

`mi2pf test_out.pf < test_in.csv`

### mi2pf usage

The **supported special characters** are `+ - = _ ~ * / \ | ( ) [ ] { } < > . : ; ' ^ & ! @ # `` ? $` as well as commas, new lines, tabs, and double quotes (for fields containing commas).

mi2pf **needs at least one argument** passed to it, the name of the output file. You can also pass the number of CSV columns of your input and the size of the buffer (for fields that have commas). Acceptable commands are:

1. `mi2pf {output_file}.pf < {input_file}.csv`
2. `mi2pf {output_file}.pf {number of columns of CSV input} < {input_file}.csv`
3. `mi2pf {output_file}.pf {number of columns of CSV input} {buffer size} < {input_file}.csv`

The **default values** are `20` for the columns and `256` (characters) for the size of the buffer.

### pf2mi usage

The **supported special characters** are `+ - = _ ~ * / \ | ( ) [ ] { } < > . , : ; ' ^ & ! @ # `` ? $` as well as new lines, tabs, and double slashes (for ending PathoLogic Format records).

pf2mi **needs at least one argument passed to it**, the name of the output file. You can also pass the number of different characteristics present in the PF file (alternatively, CSV columns of your output) and the number of records present in the PF file (alternatively, CSV rows of your output). Acceptable commands are:

1. `pf2mi {output_file}.csv < {input_file}.pf`
2. `pf2mi {output_file}.csv {number of characteristics of PF input} < {input_file}.pf`
3. `pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} < {input_file}.pf`
4. `pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} {buffer size} < {input_file}.pf`

The **default values** are `20` for the characteristics, `5000` for the records, and `256` for the size of the buffer.