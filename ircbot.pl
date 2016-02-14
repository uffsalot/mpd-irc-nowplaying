#!/usr/bin/perl -w
# irc.pl
# A simple IRC MPD adapter. Display the current playing song, if somebody writes !song.
# Usage: perl ircbot.pl

use strict;

# We will use a raw socket to connect to the IRC server.
use IO::Socket;

# The server to connect to and our details.
my $server = "server.brand";
my $nick = "mpd_bot";
my $login = "mpd_bot";

my $mpd_host = "server.brand";
my $mpd_port = "6600";

# The channel which the bot will join.
my $channel = "#lan";

# Connect to the IRC server.
my $sock = new IO::Socket::INET(PeerAddr => $server,
                                PeerPort => 6667,
                                Proto => 'tcp') or
                                    die "Can't connect\n";

# Log on to the server.
print $sock "NICK $nick\r\n";
print $sock "USER $login 8 * :MPD-Now Playing Bot\r\n";

# Read lines from the server until it tells us we have connected.
while (my $input = <$sock>) {
    # Check the numerical responses from the server.
    if ($input =~ /004/) {
        # We are now logged in.
        last;
    }
    elsif ($input =~ /433/) {
        die "Nickname is already in use.";
    }
}

# Join the channel.
print $sock "JOIN $channel\r\n";

# Keep reading lines from the server.
while (my $input = <$sock>) {
    	chop $input;
    	if ($input =~ /^PING(.*)$/i) {
        	# We must respond to PINGs to avoid being disconnected.
       		print $sock "PONG $1\r\n";
  	}
	if ($input =~ /!Song/i) {
		current_song();
	}
   	else {
	        # Print the raw line received by the bot.
       		print "$input\n";
	}
}

sub current_song {
my $ans = "";
my $song = "";
my $artist = "";
my $album = "";
my $current = "";
my $socket = new IO::Socket::INET(PeerAddr => $mpd_host,
                                        PeerPort => $mpd_port,
                                        Proto => "tcp",
                                        timeout => 5);
        printf "Could not create socket: $!\n" unless $socket;
        if ( not $socket->getline() =~ /^OK MPD*/ ) {
                print"Could not connect: $!\n";
        } else {
                print $socket "currentsong\n";
                while ( not $ans =~ /^(OK|ACK)/ ) {
                        $ans = <$socket>;
                        if ( $ans =~ s/^Artist: //) {
                                $artist = $ans;
                                chomp $artist;                          
                        }
                        if ( $ans =~ s/^Title: //) {
                                $song = $ans;
                                chomp $song;
                        }
                        if ( $ans =~ s/^Album: //) {
                                $album = $ans;
                                chomp $album;
                        }
                        $current = "♫ ${artist} - ${song} (${album})\r\n";
                }
                close($socket);
		print $sock "PRIVMSG ${channel} :${current}";
	}
}
