%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEBUG 0

void yyerror(char const *);
int yyparse();
int yylex();

FILE *csv;
char* filename;
int numOfColumns = 20;
int numOfRows = 5000;
int bufferSize = 256;
int lines = 0;
int idx = 0;
int idx2 = 0;
char* buffer;
char*** titles;
char*** cells;
char** titlesGuide; // Global index of all titles present in the PF, since we can't be sure how many there are just by looking at the first PF record
%}

%union {
    char *str;
}

%token <str> T_ID
%token T_NL
%token T_TAB
%token T_DOUBLESLASH

%%

S                  : Blocks
                     {
    			int i=0, j, k=0;
    			while (titles[i][0][0] != '\0') {
			    j = 0;
			    while (titles[i][j][0] != '\0') {
	    			if (searchInArray(titles[i][j], titlesGuide, k) == -1) {
				    titlesGuide[k] = strdup(titles[i][j]);
				    k++;
	    			}
	    		   	j++;
			    }
			    i++;
    			}
    			int numOfCols = k;
			printTitlesLine(titlesGuide, numOfCols);
			printLines(titles, cells, titlesGuide, numOfCols);
                     }
                   ;

Blocks             : Block
                     {
                        
                     }
                   | Blocks T_NL Block
                     {
                        
                     }
                   ;

Block              : Entries T_NL T_DOUBLESLASH
                     {
			idx2 = 0;
			idx++;
			if (idx >= numOfRows)
    			    yyerror("Too many PF records. Increase row count.");
                     }
                   ;

Entries            : Entry
                     {
                        
                     }
                   | Entries T_NL Entry
                     {
                        
                     }
                   ;

Entry              : T_ID T_TAB T_ID
                     {
			if (idx2 >= numOfColumns)
                            yyerror("Too many entries in PF record. Increase column count (2nd argument).");
			free(titles[idx][idx2]);
			free(cells[idx][idx2]);
			cells[idx][idx2] = strdup($3);
		        titles[idx][idx2] = strdup($1);
			free($1);
			free($3);
			idx2++;
                     }
		   | T_ID T_TAB
		     {
			if (idx2 >= numOfColumns)
                            yyerror("Too many entries in PF record. Increase column count (2nd argument).");
			free(titles[idx][idx2]);
			free(cells[idx][idx2]);
			titles[idx][idx2] = strdup($1);
			cells[idx][idx2] = strdup("");
			free($1);
			idx2++;
		     }
                   ;
%%

int searchInArray(char* element, char** t_guide, int N)
{
    for (int i=0; i<N; i++) {
	if (strcmp(t_guide[i], element) == 0) {
	    return i;
	}
    }
    return -1;
}

void printTitlesLine(char** guide, int N)
{
    for (int i=0; i<N; i++) {
	fprintf(csv, "%s", guide[i]);
	if (i != N-1) {
	    fprintf(csv, ",");
	}
	else {
	    fprintf(csv, "\n");
	}
    }
}

void printLines(char*** t_titles, char*** t_cells, char** titlesGuide, int N)
{
    int i, j, k, s, z, pos, positions[numOfColumns], encloseInQuotes;
    char* tempStr;

    i = 0;
    while (t_titles[i][0][0] != '\0') {
	for (k=0; k<N; k++) {
	    pos = -1;
	    s = 0;
	    j = 0;
	    while (t_titles[i][j][0] != '\0') {
		if (strcmp(t_titles[i][j], titlesGuide[k]) == 0) {
		    pos = j;
		    positions[s] = j;
		    s++;
		}
		j++;
	    }

	    if (pos == -1) { // title k not found in block
		fprintf(csv, "");
	    }
	    else {
		buffer[0] = '\0';
		encloseInQuotes = 0;
		for (z=0; z<s; z++) {
		    snprintf(buffer, bufferSize, "%s%s", buffer, t_cells[i][positions[z]]);
		    if (strstr(t_cells[i][positions[z]], ",") != NULL) {
			encloseInQuotes = 1;
		    }
		    if (z != s-1) {
			tempStr = strdup(buffer);
			snprintf(buffer, bufferSize, "%s/", tempStr);
			free(tempStr);
		    }
		}
		if (encloseInQuotes) {
		    tempStr = strdup(buffer);
		    snprintf(buffer, bufferSize, "\"%s\"", tempStr);
		    free(tempStr);
		}
		fprintf(csv, "%s", buffer);
	    }
    	    if (k != N-1) {
    	    	fprintf(csv, ",");
    	    }
    	    else {
	    	fprintf(csv, "\n");
    	    }
	}
	i++;
    }
}

void yyerror(const char* msg)
{
    fprintf(stderr, "Parsing error: %s\n", msg);
    exit(1);
}

// Initialises variables, allocates memory
void initialise()
{
    lines = 0;
    idx = 0;
    idx2 = 0;
    int i, j;
    buffer = malloc((bufferSize+1) * sizeof(char));
    buffer[0] = '\0';

    titles = malloc(numOfRows * sizeof(char**));
    cells = malloc(numOfRows * sizeof(char**));
    if (titles == NULL || cells == NULL) {
	yyerror("Memory allocation failed.");
    }
    for (i=0; i<numOfRows; i++) {
	titles[i] = malloc(numOfColumns * sizeof(char*));
	cells[i] = malloc(numOfColumns * sizeof(char*));
    	if (titles[i] == NULL || cells[i] == NULL) {
	    yyerror("Memory allocation failed.");
	}
	for (j=0; j<numOfColumns; j++) {
            titles[i][j] = malloc(1 * sizeof(char)); // will be overwritten for fields that have values
	    cells[i][j] = malloc(1 * sizeof(char));
    	    if (titles[i][j] == NULL || cells[i][j] == NULL) {
	    	yyerror("Memory allocation failed.");
	    }
	    titles[i][j][0] = '\0';
	    cells[i][j][0] = '\0';
    	}
    }
    titlesGuide = malloc(numOfColumns * sizeof(char*));
    if (titlesGuide == NULL) {
	yyerror("Memory allocation failed.");
    }
    for (i=0; i<numOfColumns; i++) {
	titlesGuide[i] = malloc((bufferSize+1) * sizeof(char));
    	if (titlesGuide[i] == NULL) {
	    yyerror("Memory allocation failed.");
	}
	titlesGuide[i][0] = '\0';
    }
}

int main(int argc, char* argv[])
{
    if (argc == 1) { // Only the name of the program was given
	yyerror("Please specify the output file name.\n\nHelp: pf2mi needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of different characteristics present in the PF file (alternatively, CSV columns of your output) and the number of records present in the PF file (alternatively, CSV rows of your output).\n\nAcceptable commands are:\n pf2mi {output_file}.csv < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} {buffer size} < {input_file}.pf\nThe default values are 20 for the characteristics, 5000 for the records, and 256 for the size of the buffer.");
    }
    else if (argc == 2) { // Output file
	filename = strdup(argv[1]);
    }
    else if (argc == 4) { // Output file | Number of characteristics (columns of CSV) | Number of records (rows of CSV)
	filename = strdup(argv[1]);
	numOfColumns = atoi(argv[2]);
	numOfRows = atoi(argv[3]);
    }
    else if (argc == 5) { // Output file | Number of characteristics (columns of CSV) | Number of records (rows of CSV) | Size of the buffer
	filename = strdup(argv[1]);
	numOfColumns = atoi(argv[2]);
	numOfRows = atoi(argv[3]);
	bufferSize = atoi(argv[4]);
    }
    else {
	yyerror("Invalid number of arguments.\n\nHelp: pf2mi needs at least one argument passed to it, the name of the output file.\nYou can also pass the number of different characteristics present in the PF file (alternatively, CSV columns of your output) and the number of records present in the PF file (alternatively, CSV rows of your output).\n\nAcceptable commands are:\n pf2mi {output_file}.csv < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} < {input_file}.pf\n pf2mi {output_file}.csv {number of characteristics of PF input} {number of records of PF input} {buffer size} < {input_file}.pf\nThe default values are 20 for the characteristics, 5000 for the records, and 256 for the size of the buffer.");
    }

    initialise();
    csv = fopen(filename, "w");
    yyparse();
    printf("File parsed successfully. Output saved to %s!\n", filename);
    fclose(csv);

    for (int i=0; i<numOfRows; i++) {
	for (int j=0; j<numOfColumns; j++) {
	    free(titles[i][j]);
	    free(cells[i][j]);
	}
	free(titles[i]);
	free(cells[i]);
    }
    free(titles);
    free(cells);
    for (int i=0; i<numOfColumns; i++) {
	free(titlesGuide[i]);
    }
    free(titlesGuide);
    free(filename);
    free(buffer);
    return 0;
}