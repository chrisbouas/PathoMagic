%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pf2mi.tab.h"
%}

%%

"\r\n"|\n|\r	{ return T_NL; }

"\t"		{ return T_TAB; }

"//"		{ return T_DOUBLESLASH; }

[^\t\r\n]+	{
		    yylval.str = strdup(yytext);
		    if (yylval.str == NULL) {
			fprintf(stderr, "Lexical error: memory allocation failed.\n");
			exit(1);
		    }
		    return T_ID;
		}

%%

int yywrap()
{
    return 1;
}
