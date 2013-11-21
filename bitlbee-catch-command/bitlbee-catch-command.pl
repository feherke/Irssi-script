use strict;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION='0.2';
%IRSSI=(
  authors=>'Feherke',
  contact=>'nope',
  name=>'BitlBee-CatchCommand',
  description=>'Catch BitlBee commands sent accidentally to other channels.',
  license=>'Use it healthy.',
  url=>'http://feherke.github.io/perl/irssi/bitlbee-catch-command.html',
  changed=>'2012-02-22',
);

Irssi::theme_register [
  'bitlbee-catchcommand_format'=>'[%r%8BB%NCC] $*',
];

Irssi::settings_add_bool 'bitlbee-catchcommand','bitlbee-catchcommand_active',1;
Irssi::settings_add_int 'bitlbee-catchcommand','bitlbee-catchcommand_timeout',3;
Irssi::settings_add_str 'bitlbee-catchcommand','bitlbee-catchcommand_command','account add allow blist block channel chat drop group help identify info no otr qlist register remove rename save set transfer yes';
Irssi::settings_add_str 'bitlbee-catchcommand','bitlbee-catchcommand_channel','&bitlbee';

my ($lastmessage,$lastchannel,$lasttime);


sub bitlbeecatchcommand_help
{
  my ($topic)=@_;

  return unless $topic eq 'bb-catch';

  print 'BitlBee - Catch Command

Catches BitlBee commands typed outside the &bitlbee control channel. Commands repeated within the specified timeout are let to pass.

Current settings :
 - active - '.Irssi::settings_get_bool('bitlbee-catchcommand_active').'
 - timeout - '.Irssi::settings_get_int('bitlbee-catchcommand_timeout').'
 - command - '.Irssi::settings_get_str('bitlbee-catchcommand_command').'
 - channel - '.Irssi::settings_get_str('bitlbee-catchcommand_channel');
}

sub bitlbeecatchcommand_event
{
  my ($message,$server,$channel)=@_;

  return unless $channel;

  return unless Irssi::settings_get_bool 'bitlbee-catchcommand_active';

  my @channel=split / +/,Irssi::settings_get_str 'bitlbee-catchcommand_channel';
  return if ${$channel}{name}~~@channel;

  my @message=split / +/,$message;
  my @command=split / +/,Irssi::settings_get_str 'bitlbee-catchcommand_command';
  return unless $message[0]~~@command;

  my $timeout=Irssi::settings_get_int 'bitlbee-catchcommand_timeout';
  return if $lastmessage eq $message && $lastchannel eq ${$channel}{name} && time-$lasttime<$timeout;

  Irssi::printformat MSGLEVEL_CLIENTCRAP,'bitlbee-catchcommand_format',"BitlBee command '$message[0]' caught on channel ${$channel}{name}.";
  $channel->printformat(MSGLEVEL_CLIENTCRAP,'bitlbee-catchcommand_format',"BitlBee command '$message[0]' caught, repeat in $timeout seconds.");
  Irssi::signal_stop;

  $lastmessage=$message;
  $lastchannel=${$channel}{name};
  $lasttime=time;
}


Irssi::signal_add 'send text'=>\&bitlbeecatchcommand_event;
Irssi::command_bind 'help'=>\&bitlbeecatchcommand_help;
