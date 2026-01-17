%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mi2pf.tab.h"
%}

%%

","		{ return T_COMMA; }

"\n"		{ return T_NL; }

[\"]		{ return T_QUOTE; }

"\t"		;

([a-zA-Z]|[0-9]|" "|[\+\-\*\/\(\)\[\]\{\}\.\_\:\;\'\^\&\!\@\#\`\<\>\?\~\=\$\|\\])+    { yylval.str = strdup(yytext); return T_ID; }

.		{ printf("Lexical error. Please check your file to see if it includes any non supported special characters.\nThe supported special characters are + - = _ ~ * / \\ | ( ) [ ] { } < > . : ; ' ^ & ! @ # ` ? $ \nas well as commas, new lines, tabs, and double quotes (for fields containing commas).\n"); exit(1); }

%%

int yywrap() {
    return 1;
}