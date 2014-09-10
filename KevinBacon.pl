#!/usr/bin/perl
use v5.10;
#Partners: Jeffrey Li and Rachel Wong


#Step 1: Start by reading in files from the IMDB database
#******************************************************************#
#----------------Reading the files from database-------------------#

print "\n\n|----------------------------------------------------------|\n";
print "|            Reading in files from the database            |\n";
print "|    This process will only consider \"real\" movies         |\n";
print "|  This entire process will take roughly 1 to 2 minutes.   |\n";
print "|----------------------------------------------------------|\n";
print "|                       Please Wait                        |\n";
print "|                         Loading                          |\n";
print "|----------------------------------------------------------|\n\n";

#******************************************************************#

# define global hash variables.
our %actor_nodes;
our %movie_edges;

foreach $arg (@ARGV){
    open my $IM_Database, "-|", "zcat $arg";
    
    my $current_actor;
    while(<$IM_Database>){
        
        #Get the necessary regexes
        #regex for checking for correct year
        my $year_annotation = "[0-9]+";
        #Check for roman numerals in the name: I, II, III, etc, etc.
        my $grp_same_title_list = "(?:\/[IVXL]+)";
        #Check for TV series indicated by double quotes: ""
        my $quotes = '"';
        #Check for nonreal movies, account for TV, VG, V, and archive footage
        my $ignore_vg_tv_v_string = "(?:VG|TV|V|archive footage)";
        
        #match only the movie and year annotation while ignoring all that have the same title
        if (/\t+(?'movie'.*\s\($year_annotation $grp_same_title_list?\))/px){
        }else{
            next;
        };
        
        #NTS: use PREMATCH, which matches everything prior to matched string
        #NTS: use POSTMATCH, which matches everything after the matched string
        my ($movie, $actor) = ($+{movie}, ${^PREMATCH});
        
        if ($actor){ #does the actor exist?
            $current_actor = $actor;
        };
        
        $check_for_quotes = substr($movie, 0, 1); #check the first character, and look for quotes
        
        if ($check_for_quotes eq $quotes){ #check for tv series
            next; #move onto the next record if a tv series if found
        };
        if(${^POSTMATCH} =~ /\($ignore_vg_tv_v_string\)/){ #check for VG, TV, or V
            next; #move onto the next record if a VG, TV, or V is found
        };
        
        if(!$movie_edges{$current_actor}){
            $movie_edges{$current_actor} = [];
        };
        if(!$actor_nodes{$movie}){
            $actor_nodes{$movie} = [];
        };
        push $movie_edges{$current_actor}, $movie; #$current_actor(string), $movie_edges(hash): create a hash of an array
        push $actor_nodes{$movie}, $current_actor; #$movie(string), $actor_nodes(hash): create a hash of an array.
    }
}

#"If the user input does not match an actor, then it should be interpreted as a list of keywords"
sub keyword_match{
    $actor = shift;
    for $key (@_){
        if(!($actor =~ /\b\Q$key\E\b/i)){
            return 0;
        }
    }
    return 1;
}

print "|----------------------------------------------------------|\n";
print "|          Please enter a name: LAST, FIRST name           |\n";
print "|----------------------------------------------------------|\n\n";

my $kevin_bacon = "Bacon, Kevin";

while(<STDIN>){
    chomp;
    if(!$_){
        print "Exiting Program\n";
        exit;
    };
    my @keywords = split(/[,\s]+/,$_);
    
    if (exists $movie_edges{$_}){
        find_actor($_);
        print "Please enter your actor/actress's name. [Hit Enter to exit]\n";
        next;
    }
    
    my @matched_names;
    
    print "|----------------------------------------------------------|\n";
    print "|                       Searching...                       |\n";
    print "|----------------------------------------------------------|\n\n";
    
    for $actor (keys %movie_edges){
        if (keyword_match($actor, @keywords)){
            push @matched_names, $actor;
        }
    }
    
    my $num_matched_names = scalar @matched_names;
    if ($num_matched_names == 1){
        print "There was $num_matched_names possible match found\n";
    } else {
        print "There were $num_matched_names possible matches found\n";
    }
    if ($num_matched_names == 0){
        print "Sorry! Check your spelling and try again\n";
    } elsif ($num_matched_names == 1){
        print "I hope you meant $matched_names[0]!\n";
        find_actor($matched_names[0]);
    } else {
        print "I hope you meant one of these names!\n";
        @sorted_matched_names = sort (@matched_names);
        foreach $_ (@sorted_matched_names){
            print ($_);
            print "\n";
        }
    }
    print "Want to search for another actor/actress? [Hit Enter to exit]\n";
}

#NTS: keep a record, for each node searched, the parent node that allowed you to reach that node.
sub find_actor {
    my $target_actor = shift;
    my $current_depth = 0; #current depth level is set to 0.
    #These indices are used to find the parent nodes and connecting movie edges
    my $safety_quit = 15; #just in case the separation from Kevin Bacon gets too high
    my $queue_index;
    my $actor_index;
    my $movie_index;
    my %visited_movie_edges; #remember which edges we've seen
    my %visited_actor_nodes; #remember which actors we've seen
    my @previous_level; #previous depth level
    my @current_level; #the current depth level. Search for actors on this level
    my @next_level; #a reference to the next depth level
    
    #check if the user input is Kevin Bacon, return early
    if ($target_actor eq $kevin_bacon){
        print "$kevin_bacon is on level $current_depth\n"; #kevin bacon's on level 0.
        print "Let's try looking for another person\n";
        return;
    }
    $visited_actor_nodes{$kevin_bacon} = 1; #value of Kevin Bacon inside the hash is: 1
    
    @current_level = (["null", "null", "null", $kevin_bacon]);
    
    print "\n|----------------------------------------------------------|\n";
    print "|                       Searching...                       |\n";
    print "|----------------------------------------------------------|\n\n";

    while(@current_level){
        $queue_index = -1;
        foreach $actor_group (@current_level){
            $queue_index += 1;
            $actor_index = 2;
            
            foreach $actor (@$actor_group[3..@$actor_group-1]){
                $actor_index += 1;
                
                if ($actor eq $target_actor){
                    print "We found a $kevin_bacon match on level $current_depth!\n\n";
                    my $current_degrees = $current_depth;
                    my $current_actor = $actor;
                    
                    $queue_index = $actor_group->[0];
                    $actor_index = $actor_group->[1];
                    $movie_index = $actor_group->[2];
                    
                    for ($counter = $current_degrees; $counter > 0; $counter--){
                        my $actor_matrix = $previous_level[$counter-1]->[$queue_index];
                        my $parent_node = $actor_matrix->[$actor_index];
                        my $connecting_movie = ${$movie_edges{$parent_node}}[$movie_index];
                        
                        $queue_index = $actor_matrix->[0];
                        $actor_index = $actor_matrix->[1];
                        $movie_index = $actor_matrix->[2];
                        print "$current_actor\n";
                        print "\t$connecting_movie\n";
                        $current_actor = $parent_node; #set the current actor to the parent
                    }
                    print "$kevin_bacon\n";
                    return;
                }
                $movie_index = -1;
                foreach $movie (@{$movie_edges{$actor}}){
                    $movie_index += 1;
                    
                    if (exists $visited_movie_edges{$movie}){
                        #print "visited movie $movie\n";
                        next;
                    }
                    $visited_movie_edges{$movie} = 1;
                    
                    my @actor_array = ($queue_index, $actor_index, $movie_index);
                    
                    foreach $next_actor (@{$actor_nodes{$movie}}){
                        #print "next_actor = $next_actor\n";
                        if (!(exists $visited_actor_nodes{$next_actor})){
                            push @actor_array, $next_actor;
                            $visited_actor_nodes{$next_actor} = 1;
                        }
                    }
                    push @next_level, \@actor_array;
                }
            }
        }
        push @previous_level, [@current_level];
        @current_level = @next_level; #set the current level to the next
        @next_level = [];
        $current_depth += 1;
        #account for possible errors. even though I shouldn't limit the program to 6 degrees of separation, there should be a stopping point when a situation like this arises.
        if ($current_depth == 7){ #The degree of separation is getting kinda high...
            print "Degree of Separation is currently $current_depth\n";
            print "Do you want to continue searching? [y/n]\n";
            while (<STDIN>){
                if($_ eq 'y'){
                    last;
                }else{
                    return;
                }
            }
        }
        if ($current_depth == 15){ #The degree of separation is too high. Exiting program
            print "Degree of Separation is currently $current_depth\n";
            print "Exiting program\n";
            exit;
        }
        print "Searching through current level: $current_depth\n";
    }
}
