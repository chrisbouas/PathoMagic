%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEBUG 0

void yyerror(char const *);
int yyparse();
int yylex();

FILE *pf;
char* filename;
int numOfColumns = 20;
int bufferSize = 256;
int blocks = 0;
int idx = 0;
int idx2 = 0;
int maxIdx = 0;
char* currentCommaField = NULL;
char* buffer;
char** titles;
char** cells;
%}

%union {
    char *str;
}

%token <str> T_ID
%token T_COMMA
%token T_QUOTE
%token T_NL

%%

S                  : Titles T_NL Lines
                     {

                     }
		   | Titles T_NL Lines T_NL
		     {

		     }
                   ;

Titles             : TitleFields
                     {
			maxIdx = idx;
                     }
                   ;

Lines              : Line
                     {

                     }
                   | Lines T_NL Line
                     {

                     }
                   ;

Line               : Fields
                     {
			idx2 = 0;
			blocks++;
			if (blocks > 1) {
			    fprintf(pf, "\n");
			}
			for (int i=0; i<maxIdx; i++) {
			    if (cells[i] && strcmp(cells[i], "") != 0) {
        			char *tmp = strdup(cells[i]);
        			char *tok = strtok(tmp, "/");
			        while (tok != NULL) {
            			    fprintf(pf, "%s\t%s\n", titles[i], tok);
				    tok = strtok(NULL, "/");
       				}
				free(tmp);
    			    }
			}
			fprintf(pf, "//");
                     }
                   ;

TitleFields        : TitleField
		     {

		     }
		   | TitleFields T_COMMA TitleField
                     {

                     }
                   ;

TitleField         : T_ID
                     {
			if (idx >= numOfColumns)
    			    yyerror("Too many title columns. Consider increasing the number of columns by adding a second argument when using mi2pf.");
			titles[idx] = strdup($1);
			free($1);
			idx++;
                     }
                   ;

Fields             : Field
		     {

		     }
		   | Fields T_COMMA Field
                     {

                     }
                   ;

Field              : T_ID
                     {
			if (idx2 >= numOfColumns)
    			    yyerror("Too many fields in a row. Consider increasing the number of columns by adding a second argument when using mi2pf.");
			cells[idx2] = strdup($1);
			free($1);
			idx2++;
                     }
		   | T_QUOTE CommaField T_QUOTE
		     {

		     }
		   | 
		     {
			if (idx2 >= numOfColumns)
    			    yyerror("Too many fields in a row. Consider increasing the number of columns by adding a second argument when using mi2pf.");
			cells[idx2] = strdup("");
			idx2++;
		     }
                   ;

CommaField         : CommaSubFields
		     {
			if (idx2 >= numOfColumns)
    			    yyerror("Too many fields in a row. Consider increasing the number of columns by adding a second argument when using mi2pf.");
			cells[idx2] = strdup(currentCommaField);
			free(currentCommaField);
			currentCommaField = NULL;
			idx2++;
		     }

CommaSubFields 	   : FirstCommaSubField
                     {

                     }
		   | CommaSubFields T_COMMA RestCommaSubField
		     {

		     }
                   ;

FirstCommaSubField : T_ID
                     {
			currentCommaField = strdup($1);
			free($1);
                     }
                   ;

RestCommaSubField  : T_ID
                     {
			char *old = currentCommaField;
			snprintf(buffer, bufferSize, "%s,%s", currentCommaField, $1);
			currentCommaField = strdup(buffer);
			free(old);
			free($1);
                     }
                   ;


%%

void yyerror(const char* msg)
{
    fprintf(stderr, "Parsing error: %s\n", msg);
    exit(1);
}

// Initialises variables, allocates memory
void initialise()
{
    blocks = 0;
    idx = 0;
    idx2 = 0;
    maxIdx = 0;
    buffer = malloc((bufferSize+1) * sizeof(char));
    buffer[0] = '\0';

    titles = malloc(numOfColumns * sizeof(char*));
    cells = malloc(numOfColumns * sizeof(char*));
    if (titles == NULL || cells == NULL) {
	yyerror("Memory allocation failed.");
    }
    for (int i=0; i<numOfColumns; i++) {
    	titles[i] = NULL;
    	cells[i]  = NULL;
    }
}

int main(int argc, char* argv[])
{
    if (argc == 1) { // Only the name of the program was given
	yyerror("Please specify the output file name.\n\nHelp: mi2pf needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of CSV columns of your input and the size of the buffer (for fields that have commas).\n\nAcceptable commands are:\n mi2pf {output_file}.pf < {input_file}.csv\n mi2pf {output_file}.pf {number of columns of CSV input} < {input_file}.csv\n mi2pf {output_file}.pf {number of columns of CSV input} {buffer size} < {input_file}.csv\nThe default values are 20 for the columns and 256 (characters) for the size of the buffer.");
    }
    else if (argc == 2) { // Output file
	filename = strdup(argv[1]);
    }
    else if (argc == 3) { // Output file | titles and cells array sizes
	filename = strdup(argv[1]);
	numOfColumns = atoi(argv[2]);
    }
    else if (argc == 4) { // Output file | titles and cells array sizes | Size of the buffer
	filename = strdup(argv[1]);
	numOfColumns = atoi(argv[2]);
	bufferSize = atoi(argv[3]);
    }
    else {
	yyerror("Too many input arguments.\n\nHelp: mi2pf needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of CSV columns of your input and the size of the buffer (for fields that have commas).\n\nAcceptable commands are:\n mi2pf {output_file}.pf < {input_file}.csv\n mi2pf {output_file}.pf {number of columns of CSV input} < {input_file}.csv\n mi2pf {output_file}.pf {number of columns of CSV input} {buffer size} < {input_file}.csv\nThe default values are 20 for the columns and 256 (characters) for the size of the buffer.");
    }

    initialise();
    pf = fopen(filename, "w");
    yyparse();
    printf("File parsed successfully. Output saved to %s!\n", filename);
    fclose(pf);

    for (int i=0; i<numOfColumns; i++) {
	free(titles[i]);
	free(cells[i]);
    }
    free(titles);
    free(cells);
    free(filename);
    if (currentCommaField) free(currentCommaField);
    free(buffer);
    return 0;
}