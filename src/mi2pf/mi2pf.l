%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mi2pf.tab.h"

static char* quotedField = NULL;
static size_t quotedFieldLength = 0;
static size_t quotedFieldCapacity = 0;
static int atFieldStart = 1;
static int afterQuotedField = 0;
static int needEmptyFieldAtEOF = 0;

static void csvLexError(const char* message);
static void resetQuotedField(void);
static void appendQuotedText(const char* text, size_t length);
%}

%x QUOTED

%%

","		{
		    if (atFieldStart) {
			atFieldStart = 0;
			yyless(0);
			return T_EMPTY;
		    }
		    atFieldStart = 1;
		    afterQuotedField = 0;
		    needEmptyFieldAtEOF = 1;
		    return T_COMMA;
		}

"\r\n"|\n|\r	{
		    if (atFieldStart) {
			atFieldStart = 0;
			afterQuotedField = 0;
			needEmptyFieldAtEOF = 0;
			yyless(0);
			return T_EMPTY;
		    }
		    atFieldStart = 1;
		    afterQuotedField = 0;
		    needEmptyFieldAtEOF = 0;
		    return T_NL;
		}

"\""		{
		    if (!atFieldStart || afterQuotedField) {
			csvLexError("Lexical error: unexpected quote in CSV field.\n");
		    }
		    resetQuotedField();
		    BEGIN(QUOTED);
		}

[^\t,\r\n"]+	{
		    if (afterQuotedField) {
			csvLexError("Lexical error: unexpected characters after closing quoted CSV field.\n");
		    }
		    atFieldStart = 0;
		    needEmptyFieldAtEOF = 0;
		    yylval.str = strdup(yytext);
		    if (yylval.str == NULL) {
			csvLexError("Lexical error: memory allocation failed.\n");
		    }
		    return T_ID;
		}

<QUOTED>\"\"	{ appendQuotedText("\"", 1); }

<QUOTED>\"	{
		    BEGIN(INITIAL);
		    atFieldStart = 0;
		    afterQuotedField = 1;
		    needEmptyFieldAtEOF = 0;
		    yylval.str = strdup(quotedField != NULL ? quotedField : "");
		    if (yylval.str == NULL) {
			csvLexError("Lexical error: memory allocation failed.\n");
		    }
		    return T_QFIELD;
		}

<QUOTED>\r\n	{ csvLexError("Lexical error: quoted CSV fields cannot contain new lines.\n"); }

<QUOTED>\n	{ csvLexError("Lexical error: quoted CSV fields cannot contain new lines.\n"); }

<QUOTED>\r	{ csvLexError("Lexical error: quoted CSV fields cannot contain new lines.\n"); }

<QUOTED>[^"\r\n]+	{ appendQuotedText(yytext, yyleng); }

<<EOF>>		{
		    if (needEmptyFieldAtEOF) {
			atFieldStart = 0;
			needEmptyFieldAtEOF = 0;
			return T_EMPTY;
		    }
		    return 0;
		}

%%

static void csvLexError(const char* message)
{
    fprintf(stderr, "%s", message);
    exit(1);
}

static void resetQuotedField(void)
{
    quotedFieldLength = 0;
    if (quotedFieldCapacity == 0) {
	quotedFieldCapacity = 256;
	quotedField = malloc(quotedFieldCapacity);
	if (quotedField == NULL) {
	    csvLexError("Lexical error: memory allocation failed.\n");
	}
    }
    quotedField[0] = '\0';
}

static void appendQuotedText(const char* text, size_t length)
{
    char* resized;
    size_t needed = quotedFieldLength + length + 1;

    if (quotedField == NULL) {
	resetQuotedField();
    }
    if (needed > quotedFieldCapacity) {
	while (needed > quotedFieldCapacity) {
	    quotedFieldCapacity *= 2;
	}
	resized = realloc(quotedField, quotedFieldCapacity);
	if (resized == NULL) {
	    csvLexError("Lexical error: memory allocation failed.\n");
	}
	quotedField = resized;
    }

    memcpy(quotedField + quotedFieldLength, text, length);
    quotedFieldLength += length;
    quotedField[quotedFieldLength] = '\0';
}

int yywrap()
{
    if (YY_START == QUOTED) {
        csvLexError("Lexical error: unterminated quoted CSV field.\n");
    }
    return 1;
}
