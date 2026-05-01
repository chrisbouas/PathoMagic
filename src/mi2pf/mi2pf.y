%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEBUG 0

void yyerror(const char*);
int yyparse();
int yylex();

FILE* pf;
char* filename;
int numOfColumns = 20;
int blocks = 0;
int idx = 0;
int idx2 = 0;
int maxIdx = 0;
char** titles;
char** cells;

void cleanupResources();
void setSlot(char** slot, char* value);
void clearCells();
void emitCellRecords(const char* title, const char* cell);
int parsePositiveInt(const char* value, const char* name);
%}

%union {
    char* str;
}

%token <str> T_ID
%token <str> T_QFIELD
%token T_EMPTY
%token T_COMMA
%token T_NL

%%

S
    : Titles T_NL Lines
      {
      }
    | Titles T_NL Lines T_NL
      {
      }
    ;

Titles
    : TitleFields
      {
          maxIdx = idx;
      }
    ;

Lines
    : Line
      {
      }
    | Lines T_NL Line
      {
      }
    ;

Line
    : Fields
      {
          blocks++;
          if (blocks > 1) {
              fprintf(pf, "\n");
          }
          for (int i = 0; i < maxIdx; i++) {
              if (cells[i] && cells[i][0] != '\0') {
                  emitCellRecords(titles[i], cells[i]);
              }
          }
          fprintf(pf, "//");
          clearCells();
          idx2 = 0;
      }
    ;

TitleFields
    : TitleField
      {
      }
    | TitleFields T_COMMA TitleField
      {
      }
    ;

TitleField
    : T_ID
      {
          if (idx >= numOfColumns) {
              yyerror("Too many title columns. Consider increasing the number of columns by adding a second argument when using mi2pf.");
          }
          setSlot(&titles[idx], $1);
          idx++;
      }
    | T_QFIELD
      {
          if (idx >= numOfColumns) {
              yyerror("Too many title columns. Consider increasing the number of columns by adding a second argument when using mi2pf.");
          }
          setSlot(&titles[idx], $1);
          idx++;
      }
    ;

Fields
    : Field
      {
      }
    | Fields T_COMMA Field
      {
      }
    ;

Field
    : T_ID
      {
          if (idx2 >= numOfColumns) {
              yyerror("Too many fields in a row. Consider increasing the number of columns by adding a second argument when using mi2pf.");
          }
          setSlot(&cells[idx2], $1);
          idx2++;
      }
    | T_QFIELD
      {
          if (idx2 >= numOfColumns) {
              yyerror("Too many fields in a row. Consider increasing the number of columns by adding a second argument when using mi2pf.");
          }
          setSlot(&cells[idx2], $1);
          idx2++;
      }
    | T_EMPTY
      {
          if (idx2 >= numOfColumns) {
              yyerror("Too many fields in a row. Consider increasing the number of columns by adding a second argument when using mi2pf.");
          }
          setSlot(&cells[idx2], strdup(""));
          idx2++;
      }
    ;

%%

void yyerror(const char* msg)
{
    cleanupResources();
    fprintf(stderr, "Parsing error: %s\n", msg);
    exit(1);
}

void setSlot(char** slot, char* value)
{
    if (value == NULL) {
        yyerror("Memory allocation failed.");
    }
    free(*slot);
    *slot = value;
}

void clearCells()
{
    for (int i = 0; i < numOfColumns; i++) {
        free(cells[i]);
        cells[i] = NULL;
    }
}

void emitCellRecords(const char* title, const char* cell)
{
    const char* segmentStart = cell;
    const char* cursor = cell;

    while (1) {
        if (*cursor == '|' || *cursor == '\0') {
            size_t segmentLength = (size_t)(cursor - segmentStart);
            if (segmentLength > 0) {
                fprintf(pf, "%s\t", title);
                fwrite(segmentStart, sizeof(char), segmentLength, pf);
                fputc('\n', pf);
            }
            if (*cursor == '\0') {
                return;
            }
            segmentStart = cursor + 1;
        }
        cursor++;
    }
}

// Initialises variables and allocates memory.
void initialise()
{
    blocks = 0;
    idx = 0;
    idx2 = 0;
    maxIdx = 0;

    titles = malloc(numOfColumns * sizeof(char*));
    cells = malloc(numOfColumns * sizeof(char*));
    if (titles == NULL || cells == NULL) {
        yyerror("Memory allocation failed.");
    }
    for (int i = 0; i < numOfColumns; i++) {
        titles[i] = NULL;
        cells[i] = NULL;
    }
}

void cleanupResources()
{
    if (pf != NULL) {
        fclose(pf);
        pf = NULL;
    }

    if (titles != NULL) {
        for (int i = 0; i < numOfColumns; i++) {
            free(titles[i]);
        }
        free(titles);
        titles = NULL;
    }

    if (cells != NULL) {
        for (int i = 0; i < numOfColumns; i++) {
            free(cells[i]);
        }
        free(cells);
        cells = NULL;
    }

    free(filename);
    filename = NULL;
}

int parsePositiveInt(const char* value, const char* name)
{
    char* endptr;
    long parsed = strtol(value, &endptr, 10);

    if (endptr == value || *endptr != '\0' || parsed <= 0) {
        char message[128];
        snprintf(message, sizeof(message), "Invalid %s. Please provide a positive integer.", name);
        yyerror(message);
    }

    return (int)parsed;
}

int main(int argc, char* argv[])
{
    if (argc == 1) {
        yyerror("Please specify the output file name.\n\nHelp: mi2pf needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of CSV columns of your input.\n\nAcceptable commands are:\n mi2pf {output_file}.pf < {input_file}.csv\n mi2pf {output_file}.pf {number of columns of CSV input} < {input_file}.csv\nThe default value is 20 for the columns.");
    } else if (argc == 2) {
        filename = strdup(argv[1]);
    } else if (argc == 3) {
        filename = strdup(argv[1]);
        numOfColumns = parsePositiveInt(argv[2], "column count");
    } else {
        yyerror("Too many input arguments.\n\nHelp: mi2pf needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of CSV columns of your input.\n\nAcceptable commands are:\n mi2pf {output_file}.pf < {input_file}.csv\n mi2pf {output_file}.pf {number of columns of CSV input} < {input_file}.csv\nThe default value is 20 for the columns.");
    }

    if (filename == NULL) {
        yyerror("Memory allocation failed.");
    }

    initialise();
    pf = fopen(filename, "w");
    if (pf == NULL) {
        yyerror("Failed to open output file.");
    }

    yyparse();
    printf("File parsed successfully. Output saved to %s!\n", filename);
    cleanupResources();
    return 0;
}
