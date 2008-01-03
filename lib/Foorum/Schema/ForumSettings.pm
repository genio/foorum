package Foorum::Schema::ForumSettings;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("forum_settings");
__PACKAGE__->add_columns(
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 48,
  },
  "value",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 48,
  },
);
__PACKAGE__->set_primary_key("forum_id", "type");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-03 14:28:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fBHZfjUiq84ctFtRB+moOw


# You can replace this text with custom content, and it will be preserved on regeneration
1;