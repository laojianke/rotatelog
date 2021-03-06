#/usr/bin/perl -w
use strict;
use File::stat;

my $params;
my $defaultLogfile="/var/adm/info";
$params -> {LOGNAME} = defined $ARGV[0]?$ARGV[0]:$defaultLogfile;
$params -> {MAXLOGSIZE} = 100000000;
$params -> {MAXFILENUM} = 9;
if($^O eq "linux") {
    $params -> {SVCCMD} = "service rsyslog restart";
}
elsif($^O eq "sunos") {
    $params -> {SVCCMD} = "svcadm refresh system-log";
}
else {
    $params -> {SVCCMD} = "";
}

sub rotateLog($) {
    my ($params) = @_;
    my 	$LOGREF = $params->{LOGNAME};
    my  $MAXLOGSIZE = $params->{MAXLOGSIZE};
    my  $MAXFILENUM = $params->{MAXFILENUM};
    my  $SVCCMD = $params->{SVCCMD};
    foreach my $LOGNAME( @{$LOGREF} ) {
    my $logSize = ( -f $LOGNAME ) ? (-s $LOGNAME):0;
    if ( $logSize >= $MAXLOGSIZE ) {
        my $fileId = 0;
        my @fileList = glob( $LOGNAME . '*' );
        while (<@fileList>) {
            if (/\.(\d+)$/) {
                if ( $1 > $fileId ) {
                    $fileId = $1;
                }
            }
        }
        while ( $fileId >= 0 ) {
   		if($fileId >= $MAXFILENUM) {
    			unlink $LOGNAME.".".$fileId if( -e $LOGNAME.".".$fileId);	
    		}
    		else {
    			my ($oldFileName, $newFileName);
	    		$oldFileName = $LOGNAME . "." . $fileId;
	    		$newFileName = $LOGNAME . "." . ( $fileId + 1 );
	    		rename($oldFileName,$newFileName) if ( -f $oldFileName );
	    	}
	    	$fileId--;	
        }
	rename($LOGNAME,$LOGNAME.".0");
	#Let syslog process refresh file handler. If not syslog, please change $SVCCMD to you command to refresh process.
	system($SVCCMD);
        }
    }
}
  #main
rotateLog($params);
