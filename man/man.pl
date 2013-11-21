use strict;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION='0.2';
%IRSSI=(
  authors=>'Feherke',
  contact=>'nope',
  name=>'Man',
  description=>'Brief Irssi script developer manual.',
  license=>'Use it healthy.',
  url=>'http://feherke.github.io/perl/irssi/man.html',
  changed=>'2008-07-28'
);

Irssi::settings_add_str 'man','man_path','.irssi/scripts/man';


sub man_help
{
  my ($topic)=@_;
  return unless $topic eq 'man';
  print 'Man - Script developer manual

Syntax :
  man topic

Parameters :
  topic  - topic to display ( '.scalar @{[glob Irssi::settings_get_str('man_path').'/*.txt']}.' available )

Current settings :
  man_path - '.Irssi::settings_get_str('man_path').'';
}

sub man_command
{
  my ($data,$server,$channel)=@_;
  $data=~s/^ +| +$//;

  if ($data eq 'help') {
    &man_help('man');
  } elsif (!$data) {
    print 'What manual page do you want ?';
  } elsif (! -f Irssi::settings_get_str('man_path')."/$data.txt") {
    print "No manual entry for $data";
  } else {
    print  '- ' x ((75-length $data)/2),"man $data";
    open FIL,'<'.Irssi::settings_get_str('man_path')."/$data.txt";
    while (<FIL>) { chomp; ~s/\t/    /g; print }
    close FIL;
  }
}

sub event_complete
{
  my ($complist,$window,$word,$linestart,$want_space)=@_;

  return unless $linestart=~m,/man,i;

  foreach (glob Irssi::settings_get_str('man_path').'/*.txt') {
    ~s/.*\/(.+)\.txt$/\1/;
    next if $word && $_!~m/^\Q$word\E/;
    push @$complist,$_;
  }
}


Irssi::signal_add 'complete word'=>\&event_complete;
Irssi::command_bind 'man'=>\&man_command;
Irssi::command_bind 'help'=>\&man_help;
