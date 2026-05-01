%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEBUG 0

void yyerror(const char*);
int yyparse();
int yylex();

FILE* csv;
char* filename;
int numOfColumns = 20;
int numOfRows = 5000;
int idx = 0;
int idx2 = 0;
char*** titles;
char*** cells;
char** titlesGuide; // Global index of all titles present in the PF, since we can't be sure how many there are just by looking at the first PF record.
int* entryCounts;
int parsedRows = 0;

int searchInArray(char* element, char** titleGuide, int N);
void printTitlesLine(char** guide, int N);
void printLines(char** guide, int guideCount);
void cleanupResources();
void setSlot(char** slot, char* value);
void setEntry(int row, int column, char* title, char* value);
void printCombinedField(int row, const char* title);
int parsePositiveInt(const char* value, const char* name);
void validatePFValue(const char* value);
%}

%union {
    char* str;
}

%token <str> T_ID
%token T_NL
%token T_TAB
%token T_DOUBLESLASH

%%

S
    : Blocks
      {
          int j;
          int k = 0;

          for (int i = 0; i < parsedRows; i++) {
              for (j = 0; j < entryCounts[i]; j++) {
                  if (searchInArray(titles[i][j], titlesGuide, k) == -1) {
                      if (k >= numOfColumns) {
                          yyerror("Too many unique PF titles. Increase column count (2nd argument).");
                      }
                      setSlot(&titlesGuide[k], strdup(titles[i][j]));
                      k++;
                  }
              }
          }

          printTitlesLine(titlesGuide, k);
          printLines(titlesGuide, k);
      }
    ;

Blocks
    : Block
      {
      }
    | Blocks T_NL Block
      {
      }
    ;

Block
    : Entries T_NL T_DOUBLESLASH
      {
          entryCounts[idx] = idx2;
          idx++;
          parsedRows++;
          idx2 = 0;
      }
    ;

Entries
    : Entry
      {
      }
    | Entries T_NL Entry
      {
      }
    ;

Entry
    : T_ID T_TAB T_ID
      {
          if (idx >= numOfRows) {
              yyerror("Too many PF records. Increase row count.");
          }
          if (idx2 >= numOfColumns) {
              yyerror("Too many entries in PF record. Increase column count (2nd argument).");
          }
          validatePFValue($3);
          setEntry(idx, idx2, $1, $3);
          idx2++;
      }
    | T_ID T_TAB
      {
          if (idx >= numOfRows) {
              yyerror("Too many PF records. Increase row count.");
          }
          if (idx2 >= numOfColumns) {
              yyerror("Too many entries in PF record. Increase column count (2nd argument).");
          }
          setEntry(idx, idx2, $1, strdup(""));
          idx2++;
      }
    ;

%%

int searchInArray(char* element, char** titleGuide, int N)
{
    for (int i = 0; i < N; i++) {
        if (strcmp(titleGuide[i], element) == 0) {
            return i;
        }
    }
    return -1;
}

void printTitlesLine(char** guide, int N)
{
    for (int i = 0; i < N; i++) {
        fprintf(csv, "%s", guide[i]);
        if (i != N - 1) {
            fprintf(csv, ",");
        } else {
            fprintf(csv, "\n");
        }
    }
}

void printLines(char** guide, int guideCount)
{
    for (int i = 0; i < parsedRows; i++) {
        for (int k = 0; k < guideCount; k++) {
            printCombinedField(i, guide[k]);
            if (k != guideCount - 1) {
                fprintf(csv, ",");
            } else {
                fprintf(csv, "\n");
            }
        }
    }
}

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

void setEntry(int row, int column, char* title, char* value)
{
    if (value == NULL) {
        free(title);
        yyerror("Memory allocation failed.");
    }
    setSlot(&titles[row][column], title);
    setSlot(&cells[row][column], value);
}

void validatePFValue(const char* value)
{
    if (strchr(value, '|') != NULL) {
        yyerror("PF values cannot contain '|'. This character is reserved for joining repeated entries in CSV output.");
    }
}

void printCombinedField(int row, const char* title)
{
    int first = 1;
    int encloseInQuotes = 0;

    for (int j = 0; j < entryCounts[row]; j++) {
        if (strcmp(titles[row][j], title) == 0) {
            if (strpbrk(cells[row][j], ",\"\n\r") != NULL) {
                encloseInQuotes = 1;
            }
        }
    }

    if (encloseInQuotes) {
        fputc('"', csv);
    }

    for (int j = 0; j < entryCounts[row]; j++) {
        if (strcmp(titles[row][j], title) == 0) {
            if (!first) {
                fputc('|', csv);
            }
            for (char* cursor = cells[row][j]; *cursor != '\0'; cursor++) {
                if (*cursor == '"') {
                    fputc('"', csv);
                }
                fputc(*cursor, csv);
            }
            first = 0;
        }
    }

    if (encloseInQuotes) {
        fputc('"', csv);
    }
}

// Initialises parser state and allocates memory.
void initialise()
{
    idx = 0;
    idx2 = 0;
    parsedRows = 0;

    titles = malloc(numOfRows * sizeof(char**));
    cells = malloc(numOfRows * sizeof(char**));
    entryCounts = malloc(numOfRows * sizeof(int));
    if (titles == NULL || cells == NULL || entryCounts == NULL) {
        yyerror("Memory allocation failed.");
    }

    for (int i = 0; i < numOfRows; i++) {
        titles[i] = malloc(numOfColumns * sizeof(char*));
        cells[i] = malloc(numOfColumns * sizeof(char*));
        if (titles[i] == NULL || cells[i] == NULL) {
            yyerror("Memory allocation failed.");
        }
        entryCounts[i] = 0;
        for (int j = 0; j < numOfColumns; j++) {
            titles[i][j] = NULL;
            cells[i][j] = NULL;
        }
    }

    titlesGuide = malloc(numOfColumns * sizeof(char*));
    if (titlesGuide == NULL) {
        yyerror("Memory allocation failed.");
    }
    for (int i = 0; i < numOfColumns; i++) {
        titlesGuide[i] = NULL;
    }
}

void cleanupResources()
{
    if (csv != NULL) {
        fclose(csv);
        csv = NULL;
    }

    if (titles != NULL) {
        for (int i = 0; i < numOfRows; i++) {
            if (titles[i] != NULL) {
                for (int j = 0; j < numOfColumns; j++) {
                    free(titles[i][j]);
                }
                free(titles[i]);
            }
        }
        free(titles);
        titles = NULL;
    }

    if (cells != NULL) {
        for (int i = 0; i < numOfRows; i++) {
            if (cells[i] != NULL) {
                for (int j = 0; j < numOfColumns; j++) {
                    free(cells[i][j]);
                }
                free(cells[i]);
            }
        }
        free(cells);
        cells = NULL;
    }

    if (titlesGuide != NULL) {
        for (int i = 0; i < numOfColumns; i++) {
            free(titlesGuide[i]);
        }
        free(titlesGuide);
        titlesGuide = NULL;
    }

    free(entryCounts);
    entryCounts = NULL;
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
        yyerror("Please specify the output file name.\n\nHelp: pf2mi needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of different characteristics present in the PF file (alternatively, CSV columns of your output) and the number of records present in the PF file (alternatively, CSV rows of your output).\n\nAcceptable commands are:\n pf2mi {output_file}.csv < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} < {input_file}.pf\nThe default values are 20 for the characteristics and 5000 for the records.");
    } else if (argc == 2) {
        filename = strdup(argv[1]);
    } else if (argc == 3) {
        filename = strdup(argv[1]);
        numOfColumns = parsePositiveInt(argv[2], "column count");
    } else if (argc == 4) {
        filename = strdup(argv[1]);
        numOfColumns = parsePositiveInt(argv[2], "column count");
        numOfRows = parsePositiveInt(argv[3], "row count");
    } else {
        yyerror("Invalid number of arguments.\n\nHelp: pf2mi needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of different characteristics present in the PF file (alternatively, CSV columns of your output) and the number of records present in the PF file (alternatively, CSV rows of your output).\n\nAcceptable commands are:\n pf2mi {output_file}.csv < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} < {input_file}.pf\nThe default values are 20 for the characteristics and 5000 for the records.");
    }

    if (filename == NULL) {
        yyerror("Memory allocation failed.");
    }

    initialise();
    csv = fopen(filename, "w");
    if (csv == NULL) {
        yyerror("Failed to open output file.");
    }

    yyparse();
    printf("File parsed successfully. Output saved to %s!\n", filename);
    cleanupResources();
    return 0;
}
