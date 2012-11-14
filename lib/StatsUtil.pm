package StatsUtil;

#### DEBUG
#our $DEBUG = 1;
our $DEBUG = 0;

#### STRICT
use strict;

#### EXTERNAL MODULES
use Data::Dumper;

=head2

	SUBROUTINE		gapped_column
	
	PURPOSE
	
		PRINT .TSV COLUMNS WITH GAPS IF THE PARTICULAR COLUMN INDEX
		
		IS MISSING FROM THE INPUT ORDERED ARRAY OF INDICES.
		
		PRINT COLUMN NAME IF column_name IS DEFINED. OTHERWISE,
		
		PRINT '1'. THE INDICES ARE NUMBERED FROM 1 UPWARDS AND
		
		THE MAXIMUM INDEX IS LESS THAN OR EQUAL TO THE NUMBER OF
		
		DATABASES.
		
	INPUT
	
		1. database_indices, E.G., [ 1, 4, 5 ]
		
		2. databases, E.G. [ GENE3D,SUPERFAMILY,PANTHER,PFAM,COILS ]
		
		3. column_name. IF DEFINED, PRINT NAME (E.G., 'GENE3D'), ELSE PRINT '1'
		
	OUTPUT
	
		1. GAPPED COLUMNS, WITH COLUMN NAMES E.G., "GENE3D\t\t\tPFAM\tCOILS\t"
		
			OR WITHOUT COLUMN NAMES, E.G., "1\t\\t\t1\t1\t"
			
=cut

sub gapped_column
{
	my $column_indices		=	shift;
	my $column_names		=	shift;
	my $column_name			=	shift;
	
	if ( not defined $column_name )	{	$column_name = 0;	}
	
	my $gapped_column;
	my $column_counter = 1;
	for ( my $i = 0; $i < @$column_indices; $i++ )
	{
		my $index = $$column_indices[$i];
		#print "Index: $index\n";
		
		while ( $index > $column_counter )
		{
			#print "Index ($index) > column_counter ($column_counter)...Gapping column $column_counter\n";
			$gapped_column .= "\t";
			$column_counter++;
		}
		
		if ( $column_name )
		{
			$gapped_column .= "$$column_names[$index - 1]\t";
		}
		else
		{
			$gapped_column .= "1\t";
		}	
		
		$column_counter++;
	}

	#### IF MAX column_indices VALUE IS LESS THAN THE MAX NUMBER OF COLUMN
	#### NAMES, PRINT OUT THE REST OF THE COLUMN NAMES (OR '1's) AT THE END
	#### OF THE .TSV LINE
	my $max_column_indices = $$column_indices[@$column_indices - 1];
	#print "Max column indices: $max_column_indices\n";
	
	if ( $max_column_indices < scalar(@$column_names) )
	{
		for ( my $i = $max_column_indices; $i < @$column_names; $i++ )
		{
			$gapped_column .= "\t";
		}
	}

	return $gapped_column;
}


=head2

	SUBROUTINE		cumulative_combinations
	
	PURPOSE
	
		GET ALL CUMULATIVE COMBINATIONS OF NUMBERS (I.E., PAIRS, TRIPLETS,
		
		QUADRUPLETS, ETC.) OF NUMBERS FROM 1 TO THE INPUT NUMBER
	
	INPUT
		
		1. INPUT NUMBER
		
		2. size (E.G., 1 FOR PAIRS, 2 FOR TRIPLETS, ETC.)

	NOTES

		E.G.,
		
		1 TO 3:
		
			1
			1.2
			1.3
			1.2.3
			2
			2.3
			3

		1 TO 4:
		
			1
			1.2
			1.3
			1.4
			1.2.3
			1.3.4
			1.2.3.4
			2
			2.3
			2.4
			2.3.4
			3
			3.4

		I.E., all the unique noncumulatives from singlets to quadruplets:

			1
			2
			3
			4
			1.2
			1.3
			1.4
			2.3
			2.4
			3.4
			1.2.3
			1.2.4
			1.3.4
			2.3.4
			1.2.3.4

=cut


sub cumulative_combinations
{
	my $number		=	shift;
	
	my $combinations = [];
	for ( my $size = 1; $size < $number + 1; $size++ )
	#for ( my $size = 2; $size < 3; $size++ )
	{
		my $noncumulative_combinations = noncumulative_combinations($number, $size);
		print "\n\n[][][][][][][][][][][][][][][][][][][][]\n\n" if $DEBUG;
		@$combinations = (@$combinations, @$noncumulative_combinations);
	}
	
	return $combinations;
}


=head2

	SUBROUTINE		noncumulative_combinations
	
	PURPOSE
	
		GET ALL NONCUMULATIVE COMBINATIONS OF PAIRS, TRIPLETS, OR QUADRUPLETS, ETC
		
		OF NUMBERS FROM 1 TO THE INPUT NUMBER
	
	INPUT
		
		1. INPUT NUMBER
		
		2. size (E.G., 1 FOR PAIRS, 2 FOR TRIPLETS, ETC.)

	NOTES
		
		E.G.,
		
		1 TO 3, PAIRS:
		
			1.2
			1.3
			2.3

		1 TO 4, TRIPLETS:
		
			1.2.3
			1.2.4
			1.3.4
			2.3.4
	
=cut

sub noncumulative_combinations
{
	my $number		=	shift;
	my $size		=	shift;

	if ( not defined $size )	{	$size = 2;	}
	if ( $size > $number )	{	return;	}
	
	print "++++ noncumulative(number, size)\n" if $DEBUG;
	print "number: $number\n" if $DEBUG;
	print "size: $size\n" if $DEBUG;
	
	#### INITIALISE ARRAY OF LENGTH size
	my $array;
	for ( my $i = 0; $i < $size; $i++ )
	{
		$$array[$i] = $i + 1;	
	}
	
	my $combinations = [];
	$combinations = recurse_combinations($combinations, $array, $number);
	
	return $combinations;
}


=head2

	SUBROUTINE		recurse_combinations
	
	PURPOSE
	
		RECURSIVELY GO THROUGH ALL COMBINATIONS OF NUMBERS FROM
		
		1 TO THE INPUT NUMBER
	
	INPUT
		
		1. COMBINATIONS RETURNED BY PREVIOUS RECURSIONS
		
		2. ARRAY OF LENGTH size (E.G., 1 FOR PAIRS, 2 FOR TRIPLETS, ETC.)

		3. INPUT NUMBER
		
		4. INDEX 
		
	NOTES
		
		E.G.,
		
		1 TO 3, PAIRS:
		
			1
			1.2
			1.3
			2.3

		1 TO 4, TRIPLETS:
		
			1.2.3
			1.2.4
			1.3.4
			2.3.4
	
=cut


sub recurse_combinations
{
	my $combinations	=	shift;
	my $array			=	shift;
	my $number			=	shift;
	
	print "\n++++ recurse_combinations(array, number)\n" if $DEBUG;
	my $array_string = join "][", @$array;
	$array_string = "[" . $array_string . "]";
	print "\tArray: $array_string\n" if $DEBUG;
	
	#### GET COMBINATION FOR THIS RECURSION
	my $combination = join ".", @$array;
	print "\tCombination for this recursion: $combination\n" if $DEBUG;
	push @$combinations, $combination;

	#### CHECK IF HAVE TO RESET VALUES OF ARRAY. IF MAX VALUE IS FOUND:
	#### 	1.	IF INDEX == 0, EXIT RECURSION 
	#### 	2.	OTHERWISE, INCREMENT VALUE AT PRECEDING INDEX
	####	3. 	RESET THE VALUES AT THE SUBSEQUENT INDICES TO THEIR MINIMUMS

	print "\tChecking if have to reset values of array...\n" if $DEBUG;
	my $index;
	my $index_max;
	for ( $index = 0; $index < @$array; $index++ )
	{	
		$index_max = $number - scalar(@$array) + $index + 1;
		
		print "\tChecking if array[$index] ($$array[$index]) == $index_max ...\n" if $DEBUG;
		if ( $$array[$index] == $index_max )
		{
			print "\n\t\$\$array[$index] VALUE ($$array[$index]) IS EQUAL TO \$index_max ($index_max)\n" if $DEBUG;
			
			#### 	1.	IF INDEX == 0, EXIT RECURSION 
			if ( $index == 0 )
			{
				print "\nCOMPLETED RECURSIONS (Reached max value ($index_max) at array[0])\n" if $DEBUG;
				#print "Returning combinations: @$combinations\n" if $DEBUG;
				return $combinations;
			}
			
			print "\t***RESETTING ARRAY from index ", $index - 1, " onwards...\n" if $DEBUG;

			#### PRINT ARRAY (BEFORE)	
			my $array_string_before = join "][", @$array;
			$array_string_before = "[" . $array_string_before . "]";
	
			#### 	2.	OTHERWISE, INCREMENT VALUE AT PRECEDING INDEX
			$$array[$index - 1]++;
			#print "\tNew value of array[", $index - 1, "]: $$array[$index - 1]\n";
	
			####	3. 	RESET THE VALUES AT THE SUBSEQUENT INDICES TO THEIR MINIMUMS
			my $value = $$array[$index - 1];
			$value++;
			for ( my $i = $index; $i < @$array; $i++ )
			{
				$$array[$i] = $value;
				#print "\tNew value of array[$i]: $$array[$i]\n";
				$value++;
			}

			#### PRINT ARRAY (AFTER)
			my $array_string_after = join "][", @$array;
			$array_string_after = "[" . $array_string_after . "]";
			print "\tReset values of array from $array_string_before to $array_string_after\n" if $DEBUG;

			#my $combination = join ".", @$array;
			#push @$combinations, $combination;
			
			$combinations = recurse_combinations($combinations, $array, $number);
			
			$index++;
			last;
		}
		
		###### 	4.	RUN THIS RECURSION ON THE NEW ARRAY
		#print "Running recursion (combinations: @$combinations, array: $array_string, number: $number, index: $index)\n" if $DEBUG;
		#$combinations = recurse_combinations($combinations, $array, $number, $index);
		#
		##### 	2.	QUIT THE LOOP
		#
		#last;
	}

	#### DECREMENT INDEX
	$index-- ;

	##### GET INDEX OF 
	#print "Index: $index\n";
	#if ( $index == -1 )
	#{
	#	$index = @$array - 1;
	#}

	print "\n\t>>>Index: $index\n" if $DEBUG;

	#### IF THE ARRAY ELEMENT AT THIS INDEX HAS NOT REACHED 
	#### ITS MAX VALUE, INCREMENT ITS VALUE AND END THE LOOP
	print "\tindex max = \$number - scalar(\@\$array) + \$index + 1 = $number - ", scalar(@$array) , " + $index + 1 = $index_max\n" if $DEBUG;

	while ( $$array[$index] < $index_max )
	{
		print "\t\$\$array[$index] VALUE ($$array[$index]) IS LESS THAN \$index_max ($index_max)\n" if $DEBUG;
		$$array[$index]++;
		print "\tIncremented value at \$\$array[$index]: $$array[$index]\n" if $DEBUG;

		my $array_string = join "][", @$array;
		$array_string = "[" . $array_string . "]";
		print "\tRunning recursion (combinations: @$combinations, array: $array_string, number: $number)\n" if $DEBUG;
		$combinations = recurse_combinations($combinations, $array, $number);
	}

	#print "array[$index] ($$array[$index]) == index_max ($index_max)\n";

#print "Combinations: \n";
#print Dumper $combinations;

	return $combinations;
}



=head2

	SUBROUTINE		cumulative_permutations
	
	PURPOSE
	
		GET ALL PERMUTATIONS (I.E., COMBINATIONS THAT ARE INDEPENDENT
		
		OF NUMBER ORDER) OF SIZE 1 TO THE MAX SIZE USING A FIXED SET OF 
		
		NUMBERS (I.E., FROM 1 TO INPUT NUMBER)
		
	INPUT
		
		1. INPUT NUMBER
		
		2. SIZE

	NOTES

		NUMBERS = {1,2,3}, SIZE = 2:
		
			1.2
			1.3

			2.1
			2.3

			3.1
			3.2

		NUMBERS = {1,2,3}, SIZE = 3:
		
			1.2.3
			1.3.2

			2.1.3
			2.3.1
			
			3.1.2
			3.2.1

		NUMBERS = {1,2,3,4}, SIZE = 2:
		
			1.2
			1.3
			1.4
			
			2.1
			2.3
			2.4
			
			3.1
			3.2
			3.4
			
			4.1
			4.2
			4.3

		NUMBERS = {1,2,3,4}, SIZE = 3:

			1.2.3
			1.2.4
			1.3.2
			1.3.4
			1.4.2
			1.4.3
			
			2.1.3
			2.1.4
			2.3.1
			2.3.4
			2.4.1
			2.4.3

			3.1.2
			3.1.4
			...

		NUMBERS = {1,2,3,4}, SIZE = 4:
		
			1.2.3.4
			1.2.4.3
			1.3.2.4
			1.3.4.2
			1.4.2.3
			1.4.3.2

			2.1.3.4
			2.1.4.3
			2.3.1.4
			2.3.4.1
			2.4.1.3
			2.4.3.1

			3.1.2.4
			3.1.4.2
			3.2.1.4
			3.2.4.1
			3.4.1.2
			3.4.2.1

			4.1.2.3
			4.1.3.2
			4.2.1.3
			4.2.3.1
			4.3.1.2
			4.3.2.1

=cut


sub cumulative_permutations
{
	my $number		=	shift;
	my $max_size	=	shift;
	
	my $permutations = [];
	for ( my $size = 1; $size < $max_size + 1; $size++ )
	#for ( my $size = $max_size; $size < $max_size + 1; $size++ )
	{
		my $noncumulative_permutations = noncumulative_permutations($number, $size);
		print "\n\n[][][][][][][][][][][][][][][][][][][][]\n\n" if $DEBUG;
		@$permutations = (@$permutations, @$noncumulative_permutations);
	}
	
	return $permutations;
}


=head2

	SUBROUTINE		noncumulative_permutations
	
	PURPOSE
	
		GET ALL PERMUTATIONS OF A FIXED SIZE USING A FIXED SET OF NUMBERS
		
		(I.E., FROM 1 TO INPUT NUMBER)
	
	INPUT
		
		1. INPUT NUMBER (INTEGER, GREATER THAN 0)
		
		2. size (INTEGER, GREATER THAN 0)

	NOTES
		
	ALGORITHM
	
		1. GET ALL OF THE PERMUTATIONS STARTING WITH 1
		
		2. PERMUTE THESE PERMUTATIONS N - 1 TIMES, WHERE
		
			N = SIZE OF NUMBER SET):
			
			1. SWAP THE CURRENT  NUMBER (1 FOR FIRST
			
				ITERATION) WITH THE NEXT VALUE (I.E., 2 FOR
				
				FIRST ITERATION)
				
			2. INCREMENT THE CURRENT NUMBER BY 1 (CURRENT NUMBER = 2
			
				AT END OF FIRST ITERATION)
				
			3. REPEAT UNTIL CURRENT NUMBER = LAST NUMBER
			
		
		NUMBER = 3, SIZE = 1:
		
			1
			2
			3
			
		NUMBER = 3, SIZE = 2:
		
			1.2
			1.3
			2.1
			2.3
			3.1
			3.2
	
=cut

sub noncumulative_permutations
{
	my $number		=	shift;
	my $size		=	shift;

	if ( not defined $size )	{	$size = 2;	}
	if ( $number < 1 )	{	return;	}
	if ( $size < 1 )	{	return;	}
	
	print "++++ permutation(number, size)\n" if $DEBUG;
	print "number: $number\n" if $DEBUG;
	print "size: $size\n" if $DEBUG;
	
	#### 1. GET ALL OF THE PERMUTATIONS STARTING WITH 1
	
	#### INITIALISE ARRAY OF LENGTH size
	my $array;
	my $seed;
	for ( my $i = 0; $i < $size; $i++ )
	{
		$seed .= $i + 1 . ".";	
	}
	$seed =~ s/\.$//;
    print "Seed: $seed\n" if $DEBUG;
	push @$array, $seed;

	my $permutations = [];
	$permutations = recurse_permutations($permutations, $array, $number, $size);
	
	return $permutations;
}


=head2

	SUBROUTINE		recurse_permutations
	
	PURPOSE
	
		RECURSIVELY GO THROUGH ALL PERMUTATIONS (ORDER NOT IMPORTANT)
		
		OF NUMBERS FROM 1 TO THE INPUT NUMBER
	
	INPUT
		
		1. COMBINATIONS RETURNED BY PREVIOUS RECURSIONS
		
		2. ARRAY OF LENGTH size

		3. INPUT NUMBER
		
		4. INDEX START
		
	NOTES
		
		E.G.,
		
		1 TO 3, PAIRS:
		
			1
			1.2
			1.3
			2.3

		1 TO 4, TRIPLETS:
		
			1.2.3
			1.2.4
			1.3.4
			2.3.4
	
=cut


sub recurse_permutations
{
	my $permutations	=	shift;
	my $array			=	shift;
	my $number			=	shift;
	my $index_start		=	shift;
	
	print "\n++++ recurse_permutations(array, number)\n" if $DEBUG;
	#print join "\n", @$array;
	#print "\n";

	if ( $index_start == 0 )
	{
		return $array;
	}
	
	#### DO PERMUTATIONS

	my $swap;
	@$swap = @$array;
	for ( my $i = $index_start; $i < $number; $i++ )
	{
		#### SWAP THE NUMBERS FOR THIS ITERATION
		$swap = swap($swap, $i, $i + 1);
		
		#### ADD swap TO array
		@$array = (@$array, @$swap);
	}
	
	#### DECREMENT INDEX
	$index_start--;
	
	#### DO RECURSION
	$permutations = recurse_permutations($permutations, $array, $number, $index_start);

	return $permutations;
}



sub swap
{
	my $array		=	shift;
	my $from		=	shift;
	my $to			=	shift;

    print "++++ StatsUtil::swap(array, from, to)\n" if $DEBUG;
    print "From: $from, To: $to\n" if $DEBUG;
    print "Array (BEFORE): @$array\n" if $DEBUG;
	
	my $temp = "X";
	for ( my $i = 0; $i < @$array; $i++ )
	{
        my @numbers = split "\\.", $$array[$i];
        foreach my $number ( @numbers )
        {
            if ( $number == $from ) {   $number = $to;  }
            elsif ( $number == $to ) {   $number = $from;  }
        }
		#$$array[$i] =~ s/(\.?)$from(\.?)/$1$temp$2/;
		#$$array[$i] =~ s/(\.?)$to(\.?)/$1$from$2/;
		#$$array[$i] =~ s/$temp/$to/;
        $$array[$i] = join ".", @numbers;
	}
	
    print "Array (AFTER): @$array\n" if $DEBUG;
	return $array;
}

1;
