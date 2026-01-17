%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pf2mi.tab.h"
%}

%%

"\n"		{ return T_NL; }

"\t"		{ return T_TAB; }

"//"		{ return T_DOUBLESLASH; }

([a-zA-Z]|[0-9]|" "|[\+\-\*\/\(\)\[\]\{\}\.\,\_\:\;\'\^\&\!\@\#\`\<\>\?\~\=\$\|\\])+    { yylval.str = strdup(yytext); return T_ID; }

.		{ printf("Lexical error. Please check your file to see if it includes any non supported special characters.\nThe supported special characters are + - = _ ~ * / \\ | ( ) [ ] { } < > . , : ; ' ^ & ! @ # ` ? $ \nas well as new lines, tabs, and double slashes (for ending PathoLogic Format records).\n"); exit(1); }

%%

int yywrap() {
    return 1;
}