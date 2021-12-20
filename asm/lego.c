#define _POSIX_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

// Print an error and kill the program.
void fatal( char * msg )
{
	fprintf( stderr, "fatal: %s\n", msg );
	exit( 1 );
}

// Print an error and the line number and kill the program.
static int fatal_line = -1;
void fatalline( char * msg )
{
	fprintf( stderr, "fatal: line %d: %s\n", fatal_line, msg );
	exit( 1 );
}

// Return whether two strings are identical.
bool streq( const char * a, const char * b )
{
	return strcmp( a, b ) == 0;
}

// Return `b`'s binary representation as a string.
char * bstring( uint32_t b )
{
	static char buf[ 33 ] = { '\0' };
	for ( int i = 0; i < 32; i ++ )
	{
		buf[ i ] = b & 0x80000000 ? '1' : '0';
		b <<= 1;
	}
	return buf;
}

// Internal instruction representation.
struct op
{
	bool valid;
	char format;
	unsigned int code, a, b, c;
	char * fromlabel, * tolabel;
};

// Internal data representation.
struct datum
{
	bool valid;
	uint64_t addr, value;
};

// Convert a <=32-bit hex, dec, or binary unsigned immediate string into an integer.
uint32_t imm2i( char * imm )
{
	if ( imm[ 0 ] == '0' && imm[ 1 ] == 'x' ) return strtol( imm + 2, NULL, 16 );
	if ( imm[ 0 ] == '0' && imm[ 1 ] == 'b' ) return strtol( imm + 2, NULL, 2 );
	return strtol( imm, NULL, 10 );
	// TODO: error handling
}

// Convert a <=64-bit hex, dec, or binary signed immediate string into an integer.
int64_t imml2i( char * imm )
{
	int64_t sign = 1;
	if ( imm[ 0 ] == '-' )
	{
		sign = -1;
		imm ++;
	}
	if ( imm[ 0 ] == '0' && imm[ 1 ] == 'x' ) return sign * strtoll( imm + 2, NULL, 16 );
	if ( imm[ 0 ] == '0' && imm[ 1 ] == 'b' ) return sign * strtoll( imm + 2, NULL, 2 );
	return sign * strtoll( imm, NULL, 10 );
	// TODO: error handling
}

// Convert a register name string into an integer.
uint32_t reg2i( char * reg )
{
	if ( *reg != 'x' ) fatalline( "invalid register" );
	reg ++;
	if ( streq( reg, "zr" ) ) return 31;
	uint32_t r = atoi( reg );
	if ( r > 31 ) fatalline( "invalid register" );
	return r;
}

// Encode internal operations into instructions.
uint32_t encode( struct op op )
{
	switch ( op.format )
	{
	case 'R': return ( op.code << 21 ) | ( op.c << 16 ) | ( op.b << 5 ) | op.a;
	case 'S': return ( op.code << 21 ) | ( op.c << 10 ) | ( op.b << 5 ) | op.a;
	case 'I': return ( op.code << 22 ) | ( op.c << 10 ) | ( op.b << 5 ) | op.a;
	case 'D': return ( op.code << 21 ) | ( op.c << 12 ) | ( op.b << 5 ) | op.a;
	case 'B': return ( op.code << 26 ) | op.a;
	case 'C': return ( op.code << 24 ) | ( op.b << 5 ) | op.a;
	case 'N': return 0;
	default: fatalline( "encoding error" );
	}
};

// Strip comments from `line` and lowercase it.
void strip_and_lower( char * line )
{
	for ( bool found = false; *line; line ++ ) 
	{
		if ( *line == '#' || *line == '/' || *line == ';' ) found = true;
		if ( found ) *line = ' ';
		else *line = tolower( *line );
	}
}

// Tokenize the program, reading each instruction into an internal representation.
void populate( char * file, int nlines, struct op * ops, struct datum * datums )
{
	char * filestate;
	for ( char * line = strtok_r( file, "\n\r", &filestate ); line; line = strtok_r( NULL, "\n\r", &filestate ) )
	{
		fatal_line ++;

		strip_and_lower( line );

		const char * white = "\n\r\t ,[](){}";
		char * linestate;
		char * tok = strtok_r( line, white, &linestate );

		if ( tok == NULL ) continue;
		ops->valid = true;

		if ( streq( tok, "nop" ) ) { ops->format = 'N'; }

		else if ( streq( tok, "add" ) ) { ops->code = 0x458; ops->format = 'R'; }
		else if ( streq( tok, "sub" ) ) { ops->code = 0x658; ops->format = 'R'; }
		else if ( streq( tok, "and" ) ) { ops->code = 0x450; ops->format = 'R'; }
		else if ( streq( tok, "orr" ) ) { ops->code = 0x550; ops->format = 'R'; }
		else if ( streq( tok, "or"  ) ) { ops->code = 0x550; ops->format = 'R'; }
		else if ( streq( tok, "eor" ) ) { ops->code = 0x650; ops->format = 'R'; }
		else if ( streq( tok, "xor" ) ) { ops->code = 0x650; ops->format = 'R'; }
	
		// TODO: clean opcodes
		else if ( streq( tok, "addi" ) ) { ops->code = 0x488>>1; ops->format = 'I'; }
		else if ( streq( tok, "subi" ) ) { ops->code = 0x688>>1; ops->format = 'I'; }
		else if ( streq( tok, "andi" ) ) { ops->code = 0x490>>1; ops->format = 'I'; }
		else if ( streq( tok, "orri" ) ) { ops->code = 0x590>>1; ops->format = 'I'; }
		else if ( streq( tok, "ori"  ) ) { ops->code = 0x590>>1; ops->format = 'I'; }
		else if ( streq( tok, "eori" ) ) { ops->code = 0x690>>1; ops->format = 'I'; }
		else if ( streq( tok, "xori" ) ) { ops->code = 0x690>>1; ops->format = 'I'; }

		else if ( streq( tok, "lsl" ) ) { ops->code = 0x69B; ops->format = 'S'; }
		else if ( streq( tok, "lsr" ) ) { ops->code = 0x69A; ops->format = 'S'; }

		else if ( streq( tok, "ldur" ) ) { ops->code = 0x7C2; ops->format = 'D'; }
		else if ( streq( tok, "stur" ) ) { ops->code = 0x7C0; ops->format = 'D'; }

		else if ( streq( tok, "b" ) ) { ops->code = 0x5; ops->format = 'B'; }

		else if ( streq( tok, "cbz"  ) ) { ops->code = 0xB4; ops->format = 'C'; }
		else if ( streq( tok, "cbnz" ) ) { ops->code = 0xB5; ops->format = 'C'; }

		else if ( streq( tok, "data" ) )
		{
			ops->valid = false;
			datums->valid = true;
			datums->addr  = imml2i( strtok_r( NULL, white, &linestate ) );
			datums->value = imml2i( strtok_r( NULL, white, &linestate ) );

			datums ++;
			continue;
		}

		else if ( strchr( tok, ':' ) != NULL ) // TODO: bugs, error handling, nonsubsequent instructions
		{
			char * colon = strchr( tok, ':' );
			*colon = '\0';
			ops->fromlabel = tok;
			continue;
		}

		else fatalline( "invalid opcode" );

		if ( ops->format == 'R' )
		{
			ops->a = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->b = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->c = reg2i( strtok_r( NULL, white, &linestate ) );
		}
		else if ( ops->format == 'I' )
		{
			ops->a = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->b = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->c = imm2i( strtok_r( NULL, white, &linestate ) );
		}
		else if ( ops->format == 'S' )
		{
			ops->a = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->b = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->c = imm2i( strtok_r( NULL, white, &linestate ) );
		}
		else if ( ops->format == 'D' )
		{
			ops->a = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->b = reg2i( strtok_r( NULL, white, &linestate ) );
			ops->c = imm2i( strtok_r( NULL, white, &linestate ) );
		}
		else if ( ops->format == 'B' )
		{
			char * target = strtok_r( NULL, white, &linestate );
			if ( isdigit( *target ) || *target == '-' ) 
			{
				ops->a = imml2i( target ) & 0x03FFFFFF;
			}
			else
			{
				ops->tolabel = target;
			}
		}
		else if ( ops->format == 'C' )
		{
			ops->a = reg2i( strtok_r( NULL, white, &linestate ) );
			char * target = strtok_r( NULL, white, &linestate );
			if ( isdigit( *target ) || *target == '-' ) 
			{
				ops->b = imml2i( target ) & 0x0007FFFF;
			}
			else
			{
				ops->tolabel = target;
			}
		}

		ops ++;
	}
}

// Turn labels and label references into branch offsets.
void compute_targets( struct op * ops )
{
	for ( int pc = 0; ops[ pc ].valid; pc ++ )
	{
		if ( ops[ pc ].tolabel != NULL )
		{
			for ( int pcb = 0; ops[ pcb ].valid; pcb ++ )
			{
				if ( ops[ pcb ].fromlabel != NULL && streq( ops[ pc ].tolabel, ops[ pcb ].fromlabel ) )
				{
					if ( ops[ pc ].format == 'B' ) ops[ pc ].a = ( pcb - pc ) & 0x03FFFFFF;
					else ops[ pc ].b = ( pcb - pc ) & 0x0007FFFF;
				}
			}
		}
	}
}

int main( int argc, char * * argv )
{
	if ( argc != 2 ) fatal( "please specify one input file" );

	// Map the file into memory, figuring out its size and line count.
	int fd = open( argv[ 1 ], O_RDONLY );
	if ( fd == -1 ) fatal( "unable to open file" );
	int fsize = lseek( fd, 0, SEEK_END );
	char * file = mmap( NULL, fsize, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0 );
	int nlines = 0;
	for ( char * c = file; *c; c ++ ) if ( *c == '\n' ) nlines ++;

	// Allocate operations and datums, which will be zeroed and thus invalid.
	struct op * ops = calloc( nlines + 1, sizeof( struct op ) );
	struct datum * datums = calloc( nlines + 1, sizeof( struct datum ) );

	// Assemble!
	populate( file, nlines, ops, datums );
	compute_targets( ops );

	// Print instructions (if any).
	if ( ops->valid ) printf( "Instructions:\n" );
	for ( struct op * op = ops; op->valid; op ++ )
	{
		//printf( "%X\t(%c)\t%d\t%d\t%d\t%X\n", op->code, op->format, op->a, op->b, op->c, encode( *op ) );
		printf( "%s\n", bstring( encode( *op ) ) );
	}

	// Print data (if any).
	if ( datums->valid ) printf( "Data:\n" );
	for ( struct datum * datum = datums; datum->valid; datum ++ )
	{
		printf( "%X\t%X\n", datum->addr, datum->value );
	}

	// Cleanup.
	munmap( file, fsize );
	close( fd );
	free( ops );
	free( datums );
}
