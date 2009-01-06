#!/usr/bin/perl -w

## set_util.pm

# Is an element in the set
#
# input:  an element and a set
# output: 1 if the element is in the set
#         0 if not
#
sub is_in_set {
  my ($elem, @set, $ref_set);

  $elem = $_[0];
  $ref_set = $_[1];
  @set = @$ref_set;

  foreach ( @set ) {
    if ( $_ == $elem ) {
      return 1;
    }
  }

  return 0;
}

# Compute set intersection
#
# input:  two lists
# output: list of elements found in both
#
sub set_intersection {
  my ( $ref_set_a, $ref_set_b, @set_a, @set_b, $a, $b, @intersection );

  $ref_set_a = $_[0];
  $ref_set_b = $_[1];

  @set_a = @$ref_set_a;
  @set_b = @$ref_set_b;

  foreach $a ( @set_a ) {
    foreach $b ( @set_b ) {
      if ( $a == $b ) {
        push(@intersection,$a);
      }
    }
  }

  return @intersection;
}

# Compute non intersecting elements
#
# input:  two lists
# output: list of elements found in only one list
#
sub set_non_intersection {
  my ( $ref_set_a, $ref_set_b, @set_a, @set_b, $a, $b, @intersection, @non_intersection );

  $ref_set_a = $_[0];
  $ref_set_b = $_[1];

  @set_a = @$ref_set_a;
  @set_b = @$ref_set_b;

  @intersection = &set_intersection(\@set_a,\@set_b);

  foreach $a ( @set_a ) {
    if ( ! &is_in_set($a,\@intersection) ) {
      push( @non_intersection, $a );
    }
  }

  foreach $b ( @set_b ) {
    if ( ! &is_in_set($b,\@intersection) ) {
      push( @non_intersection, $b );
    }
  }

  return @non_intersection;
}

# What has been added to a set
#
# input:  new and old list
# output: list of elements in new but not in old
#
sub set_added {
  my ( $ref_new, $ref_old, @set_new, @set_old, @added );

  $ref_new = $_[0];
  $ref_old = $_[1];

  @set_new = @$ref_new;
  @set_old = @$ref_old;

  foreach ( @set_new ) {
    if ( ! is_in_set($_,\@set_old) ) {
      push( @added, $_);
    }
  }

  return @added;
}

# What has been removed from a set
#
# input:  new and old list
# output: list of elements in old but not in new
#
sub set_removed {
  return &set_added(reverse @_);
}

# Subtract one set from another and return the result
#
# input:  two sets (a and b)
# output: a - b
#         everything in a but not in b
#
sub set_subtract {
  my ($ref_set_a, $ref_set_b, @set_a, @set_b, @intersection);

  $ref_set_a = $_[0];
  $ref_set_b = $_[1];

  @set_a = @$ref_set_a;
  @set_b = @$ref_set_b;

  # compute the intersection of a and b
  @intersection = &set_intersection(\@set_a,\@set_b);

  # if we remove the intersection from a
  # we are left with a - b
  return &set_non_intersection(\@intersection,\@set_a);
}

1;    # use'd files have to return true!
