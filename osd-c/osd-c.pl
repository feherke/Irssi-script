use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use Text::Wrap;
use IO::Handle;

$VERSION='0.1';
%IRSSI=(
  authors=>'Feherke',
  contact=>'nope',
  name=>'OSD Chain',
  description=>'OSD display controlled with chained conditions.',
  license=>'Use it healthy.',
  url=>'http://feherke.github.com/perl/irssi/osd-c.html',
  changed=>'2008-08-13'
);

Irssi::theme_register [
  'osd-chain_format'=>'[OSD] $*'
];

Irssi::settings_add_str 'osd-chain','osd-chain_parameter','--pos=bottom --offset=50 --align=center --indent=0 --font="-misc-dejavu sans-*-r-*-*-*-*-*-*-*-*-*-*" --colour=black --outline=3 --outlinecolour=white --age=10 --lines=5 --delay=10';
Irssi::settings_add_int 'osd-chain','osd-chain_wrap',0;
Irssi::settings_add_str 'osd-chain','osd-chain_rule','';

my @rule;

$Text::Wrap::huge='overflow';

my @list=split /\|/,Irssi::settings_get_str('osd-chain_rule');
foreach (@list) {
  push @rule,[split /:/];
}


sub osd_chain_help
{
  my ($topic)=@_;

  return unless $topic eq 'osd-c';

  print 'OSD Chain - OSD notification with rule chain

Syntax :
  osd-c [command]

Available commands :
 - add rule  - add a new rule to the end of rule chain
 - put id rule  - insert a new rule in position id of the rule chain
 - set [id] rule  - change the rule identified by its id or add it
 - delete id  - delete an existing rule
 - move id newid  - move an existing rule to a new position in the chain
 - list  - list the rules currently in the chain
 - restart  - restart the osd_cat, useful after modifying the parameter setting
 - test [text] - output a test message

rule   := %9set%9 type [%9on%9 channel] [%9from%9 nick] status [%9final%9]
type   := %9public%9|%9private%9|%9hilite%9|%9invite%9|%9move%9
status := %9on%9|%9off%9

Without command displays the current rules.

Available aliases :
 - add - append
 - put - insert
 - set - let
 - delete - remove, unset, del, rm
 - move - mv
 - list - ls
 - restart - reload, refresh, re
 - test - try, demo, show

Current settings :
 - parameter - '.Irssi::settings_get_str('osd-chain_parameter').'
 - wrap - '.Irssi::settings_get_int('osd-chain_wrap').'
 - rule - '.scalar @rule.' set';
}

sub osd_chain_command
{
  my ($data,$server,$witem)=@_;
  my ($str,@str,$order);
  my @par=split / +/,$data;

  if ($data=~m/^(?:help|man|rtfm|wtf) */) {
    &osd_chain_help('osd-c');
  } elsif ($data=~m/^(?:add|append)(?: +(public|private|invite|move))?(?: +on ([^ \a\x00\r\n,]+))?(?: +from ([[:alpha:]][[:alnum:]-\[\]\\`^{}_]+))? +(on|off)(?: +(final))? *$/) { # `
    push @rule,[$1,$2,$3,$4,$5];
    &saverule;
  } elsif ($data=~m/^(?:put|insert) +([[:digit:]]+)(?: +(public|private|invite|move))?(?: +on ([^ \a\x00\r\n,]+))?(?: +from ([[:alpha:]][[:alnum:]-\[\]\\`^{}_]+))? +(on|off)(?: +(final))? *$/) { # `
    splice @rule,$1,0,[$2,$3,$4,$5,$6];
    &saverule;
  } elsif ($data=~m/^(?:set|let)(?: +([[:digit:]]+))?(?: +(public|private|invite|move))?(?: +on ([^ \a\x00\r\n,]+))?(?: +from ([[:alpha:]][[:alnum:]-\[\]\\`^{}_]+))? +(on|off)(?: +(final))? *$/) { # `
    if ($1 eq '') { push @rule,[$2,$3,$4,$5,$6] } else { splice @rule,$1,1,[$2,$3,$4,$5,$6] }
    &saverule;
  } elsif ($data=~m/^(?:delete|remove|unset|del|rm) +([[:digit:]]+) */) {
    splice @rule,$1,1;
    &saverule;
  } elsif ($data=~m/^(?:move|mv) +([[:digit:]]+) +([[:digit:]]+) */) {
    splice @rule,$2,0,splice @rule,$1,1;
    &saverule;
  } elsif ($data=~m/^(?:list|ls|^$) */) {
    printf ' %-2s | %-7s | %-15s | %-15s | %-6s | %-5s','id','type','on','from','status','final';
    print '-'x4,'+','-'x9,'+','-'x17,'+','-'x17,'+','-'x8,'+','-'x7;
    for (my $i=0;$i<scalar @rule;$i++) {
      printf ' %2d | %-7s | %-15s | %-15s | %-6s | %-5s',$i,@{$rule[$i]};
    }
  } elsif ($data=~m/^(?:restart|reload|refresh|re) */) {
    close OSDPIPE;
    &osdpipeopen;
  } elsif ($data=~m/^(?:test|try|demo|show)(?: +(.*))? */) {
    my $str=$1?$1:'test';
    &osdmessage($str,$str,$str,$str);
  } else {
  }
}

sub osdpipeopen
{
  open OSDPIPE,'|osd_cat '.Irssi::settings_get_str('osd-chain_parameter')
  or print "The OSD program can't be started, check if you have osd_cat installed AND in your path. ( $! )";
  OSDPIPE->autoflush(1);
}

sub osdmessage
{
  my ($type,$nick,$channel,$msg)=@_;
  &osdpipeopen if ! OSDPIPE->opened;

  my $ok=0;
  foreach my $one (@rule) {
    if ((${$one}[0] eq '' || ${$one}[0] eq $type) && (${$one}[1] eq '' || ${$one}[1] eq $channel) && (${$one}[2] eq '' || ${$one}[2] eq $nick)) {
      $ok=${$one}[3] eq 'on';
      last if ${$one}[4] eq 'final';
    }
  }
  my $str="[ $type ] $nick @ $channel : $msg";
  my $wrap=Irssi::settings_get_int('osd-chain_wrap');
#  $str=~s/(.{5,$wrap})\s/\1\n/g if $wrap;
  if ($wrap) {
    $Text::Wrap::columns=$wrap;
    $str=wrap '','',$str;
  }
  print OSDPIPE "$str\n" if $ok;
  OSDPIPE->flush;
}

sub saverule
{
  my $str='';
  foreach my $one (@rule) { $str.=($str?'|':'').join ':',@$one }
  Irssi::settings_set_str 'osd-chain_rule',$str;
}


# "message public", SERVER_REC, char *msg, char *nick, char *address, char *target
Irssi::signal_add 'message public'=>sub { my ($server,$msg,$nick,$address,$target)=@_; &osdmessage('public',$nick,$target,$msg); };

# "message private", SERVER_REC, char *msg, char *nick, char *address
Irssi::signal_add 'message private'=>sub { my ($server,$msg,$nick,$address)=@_; &osdmessage('private',$nick,'private',$msg); };

# "message join", SERVER_REC, char *channel, char *nick, char *address
Irssi::signal_add 'message join'=>sub { my ($server,$channel,$nick,$address)=@_; &osdmessage('move',$nick,$channel,'join'); };

# "message part", SERVER_REC, char *channel, char *nick, char *address, char *reason
Irssi::signal_add 'message part'=>sub { my ($server,$channel,$nick,$address,$reason)=@_; &osdmessage('move',$nick,$channel,"part ( $reason )"); };

# "message quit", SERVER_REC, char *nick, char *address, char *reason
Irssi::signal_add 'message quit'=>sub { my ($server,$nick,$address,$reason)=@_; &osdmessage('move',$nick,'all',"quit ( $reason )"); };

# "message kick", SERVER_REC, char *channel, char *nick, char *kicker, char *address, char *reason
Irssi::signal_add 'message kick'=>sub { my ($server,$channel,$nick,$kicker,$address,$reason)=@_; &osdmessage('move',$nick,$channel,"kick by $kicker ( $reason )"); };

# "message invite", SERVER_REC, char *channel, char *nick, char *address
Irssi::signal_add 'message invite'=>sub { my ($server,$channel,$nick,$address)=@_; &osdmessage('invite',$nick,$channel,'invite'); };

Irssi::command_bind 'osd-c'=>\&osd_chain_command;
Irssi::command_bind 'help'=>\&osd_chain_help;


&osdpipeopen;
