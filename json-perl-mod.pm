#package ZWIN_JSON; #use this with &main::Xmyrequire( 'json-perl-mod.pm', undef );
## october 29 2016. jimt/zeus/wjs

## january 11, 2011.

# january 11, 2011, jimt/zeus/bill.
#
#   &ZWIN_XML::transact_https_xml( 'SOAP', $xml_to_transmit );
#
# 2 arguments:
#       1. [ 'SOAP' | 'DT' ]  := Arkona, or DealerTrackXML  Must be all UPPER Case.
#           Note, DT-XML requires further passwords, to be passed. (1/11/2011)
#       2. a scalar containing 'xml' to be sent, as ascii text.
#
# returns: receipt data, literally - from the server being contacted.
#
#
#  All subs below having 'cata' in their name are to the bottom of this code, and
#   manage the use of the  DLL.
#
#
## Note for Arkona --- Jan 11; Server's URL hardcoded below.
##                      It could possibly come from a dealer-file.
##
# October: 20th ----- this file is meant to support DT-XML && Arkona-SOAP
#                     it depends on DLL> cshtpav6.DLL
#                     the DLL should be in the ZWIN Root folder.
##
#**************************************************************************************

use Win32::API;
use MIME::Base64 qw( encode_base64 );


my $buf = 'API@chicagocarcorner:Welcome#1';
$json_cred2=encode_base64($buf);



$jHOST1="https://$json_cred2" . '@' . "staging-api.omnique.com";
#$jHOST2="https://staging-api.omnique.com";
#$json_cred='API@chicagocarcorner Welcome#1';

$jURL="https://staging-api.omnique.com/api/universal/Appointment/GetAppointments";
#$jURL="https://staging-api.omnique.com/api/universal/Appointment/AddAppointment";
#$jURL="https://staging-api.omnique.com/api/Universal/Appointment/GetAppointmentStatuses";


print "\n HelloCred's: [$json_cred2]\n\n";

transact_https_json( $jHOST1, $jURL, 'omniq' );

# ===========================================================================
sub transact_https_json
{
    my ($json_host, $json_url_part, $json_txz_file_name) = @_;

    ## initiate our link to the DLL.    
    my $res1 = &open_cata_http();
    my $res2 = &open_cata_time();

 #       print "\nJSON-36 After open HTTP/dll: [$res1] ... Time/DLL: [$res2]\n";

    my $recv_json = do_all_work( $json_host, $json_url_part, $json_txz_file_name);
    
    ## close our link to the DLL.
    &close_cata_http();
    #&close_cata_time();

        #print "ARK-43 recv_xml=$recv_xml\n";

    return( $recv_json );
}

# ===========================================================================
#####################################################################
#####################################################################
# ===========================================================================
sub do_all_work
{
    my ($json_host, $json_url_part, $json_txz_file_name) = @_;
    
    my $return_value='';
    
    my $the_timeout=20;
    
    my $json_to_send = &fetch_json_text_from_proto( $json_txz_file_name, $json_url_part );

#    my $raw_ascii_json = eval( $json_to_send );
    my $raw_ascii_json = $json_to_send;
#    $raw_ascii_json =~ s/<needs utc>/get_utc_from_localtime( time )/;
    
    my $json_sendable_ascii='';
    
#        print "ARK-120\n";
	&open_cata_https_socket( $json_host, $the_timeout );
    
    #&authenticate_cata_basic( (split(/ /,$json_cred))[0], (split(/ /,$json_cred))[1] );
    
        print "ARK-122\n";
        $json_host =~ s/\n//;
        my $header_part = &get_header_for_json( $json_host, $json_url_part);
        $json_sendable_ascii = &get_transmit_data_for_json( $header_part, $raw_ascii_json );
#        print "ARK-126\n";
        &write_cata_data( $json_sendable_ascii );
                                            ## jan 11th - would print transcript of 'sent'
                                            open( TEMPOK, ">mytemp.txt");
                                            print TEMPOK "$json_sendable_ascii";
                                            close TEMPOK;
 #       print "ARK-135\n";
        $return_value = &read_cata_data("10"); # ($the_timeout);
#$Q=substr($return_value.' 'x50,0,50);
#print "ARK-138 1st 50 of return_value=$Q\n\n";

        &disconnect_cata_socket();
    
    my $len_resu = length( $return_value );
#print "ARK-183 data length: [$len_resu]\n";
    	open( TEMPTHANG, '>receipt.txt' );
        print TEMPTHANG $return_value . "\n";
        close TEMPTHANG;


    my $best = &get_best( 1, $return_value );
    print "\n\n\n\n '1' ..: $best\n";
    
    $best = &get_best( 2, $return_value );
    print "\n\n\n\n '2'..: $best\n";
    
    return( $return_value );
}
# $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
sub get_best
{
    my ($ApptWant,$reply_thing)=@_;


    $reply_thing =~ s/\n//g;
    $reply_thing =~ s/\r//g;
###############################
    $reply_thing =~ s/,(\s*)"/;$1"/g;
    $reply_thing =~ s/"(\w+)":/\$$1=/g;
    $reply_thing =~ s/null/"null"/g;
    $reply_thing =~ s/false/"false"/g;
    $reply_thing =~ s/true/"true"/g;

#print "\n[..[$reply_thing]..]\n";
    $mywant="AppointmentId";
    @appts = $reply_thing =~ m/$mywant=\d+/g;
#print @appts;

    my $stopit='';
    my $tot_appts = @appts;
    if ($tot_appts == $ApptWant)
    {
        #$stopit = "\];\$Request";
        $reply_thing =~ s/];\$Request.*//;
    }
    else
    {
        $stopit = $appts[ $ApptWant ];
        $reply_thing =~ s/,\{\$($stopit.*)//;
    }
                         
    my $junk = $1;
#print "\n stopit:$stopit//\n junk:\$$junk//\n rplyth:$reply_thing///..........\n";
    my $begin=$appts[ $ApptWant - 1 ];
    $reply_thing =~ s/($begin.*)//;
#print "............/////\n\n Mine--dlr1:{\$$1\n\n$reply_thing\n";

    return( "{\$$1");
}


# ================================
sub get_utc_from_localtime
{
    my $rv='';
    my @temp = localtime( time );
    print @temp, "\n";
    
    $rv = '2016';
    return($rv);
}
# ===========================================================================
#my $json_to_send = &fetch_json_text_from_proto( $json_txz_file_name, $json_url_part );



sub fetch_json_text_from_proto
{
    my ($part_fname,$the_url) = @_;
    my $rv='';
    
    open(READJ, "<$part_fname" . "-json.txz");
    my @joker=<READJ>;
    close(READJ);
    chomp(@joker);
    my $rstate=0;
    foreach my $xlin (@joker)
    {
        if  ($rstate == 0)
        {
            if ($xlin =~ /^URL:/)
            {
                $testurl=$xlin;
                $testurl =~ s/^URL: //;
                if ($testurl eq $the_url)
                {
                    $rstate = 1; next;
                }
            }
        }
        if  ($rstate == 1)
        {
            if ($xlin =~ /END-URL/)
            {
                $rstate= -1; last;
            }
            $rv .= ( $xlin . "\n" );
        }
    }

    
    open  TEMPJ, ">json-send.txt";
    print TEMPJ $rv;
    close(TEMPJ);
    return($rv);
}
# ========================

# ===========================================================================
#        my $header_part = &get_header_for_json();
# ===========================================================================
sub get_header_for_json
{
    my ($js_host,$js_url) = @_;
    my $rv  = "POST $js_url HTTP/1.1\n";
    $rv    .= "Host: $js_host\n";

    $rv .= "Authorization: Basic " . $json_cred2;
    $rv .= "Content-Type: application/json\n";
    $rv .= "Content-Length: ";

    return( $rv );
}

# ===========================================================================
# my $transmit_data = &get_transmit_data_for_json( $header_part, $json_orig_ascii );
# ===========================================================================
sub get_transmit_data_for_json
{
    my ($part1,$final)=@_;
    my $rv='';
    
    my $contents_length = length( $final );
    
    $rv = $part1 . $contents_length . "\n\n";
    
    $rv .= $final;
    
    return( $rv );
}
        

########################################################
########################################################


=pod
sub ascii_to_urlencoded  ##not used now, but may be of use later.
{
    my ($its_ascii)=@_;
    my $rv = '';
    
    $rv = &uri_cata_escape( $its_ascii );  #this func inside 'cata_http.pm'
    
    return( $rv );
    
}
=cut

# ///////////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////
# ///////////////////////////////////////////////////////////////////////

####################################################################
####################################################################
######## January 11th, 2011 > the following sub's used by the above.
########                    > this code handles the 'mess' of interfacing
########                    > with: [ CSHTPAV6.DLL ]
########                    > (the DLL is in the root of zwin.
########
########                    > the Perl (new) subs are from: WIN32-API.PM
########                    > loaded with a 'use' inside the main .p module
########

# ORIGINALLY cata-http.pm  11 July '10  jimt/zeus/William.
##  NOW, included inside this file:  {xml-perl.pm}
##  part of 'zeus-xml-cata.pm' ............
##  first used for transmitting XML, over [ HTTPS POST ],
##     Dealer Track project.....


sub open_cata_time
{return('todo');}
#1    &open_cata_http();
# ===========================================================================
sub open_cata_http
{
    $cata_http = 'cshtpav6';
    
    InitCatalyst( $cata_http ); ## Just-below...
}
    
#2    &close_cata_http();
# ===========================================================================
sub close_cata_http
{
    close_http_lib_now(); ## below.
}


#=======================================================================
sub InitCatalyst
{
        ($dll_name) = @_;

        print "loading catalyst dll [$dll_name] now.\n";

    ## the following set of Win32::API's set up our api-objects; Used Below.
    ## load/open dll-connection.
    ## passes (our) priority, catalyst-provided password.
        $thang = new Win32::API(
                $dll_name, "HttpInitialize", "PI", "I" );

	$ethang = new Win32::API(
                $dll_name, "HttpGetLastError", [], 'I' );

        ## use with dealer track xml
        $TIconnect = new Win32::API(
                $dll_name, "HttpConnect", [P,I,I,N,N,P], "I" );
		
        ## use with arkona-soap-xml
        $TIconnect_url = new Win32::API(
                $dll_name, "HttpConnectURL", [P,I,N], "I" );
		


        $TI_ask_connected = new Win32::API(
                $dll_name, "HttpIsConnected", [I], "I" );

        $TI_disconnect = new Win32::API(
                $dll_name, "HttpDisconnect", [I], I );
        
        ## used w/ dt-xml; provides URL-Encoding
        $TI_set_encoding_type = new Win32::API(
                $dll_name, "HttpSetEncodingType", [I,I], I );


        ## dt-xml performs HTTPS/POST transaction
        $TI_send_post_data = new Win32::API(
                $dll_name, "HttpPostData", [I,P,P,N,P,P,N], I  );

        
        $TI_set_header_value = new Win32::API(
                $dll_name, "HttpSetRequestHeader", [I,P,P], I );

        ## performs 'basic-authentication'  -> dt-xml only
        $TI_basic_authenticate = new Win32::API(
                $dll_name, "HttpAuthenticate", [I,I,P,P], I );

        $TI_get_error_number = new Win32::API(
                $dll_name, "HttpGetLastError", [], N );

        $TI_get_error_text_scalar = new Win32::API(
                $dll_name, "HttpGetErrorString", [N,P,I], I );

        ## after this call, DLL is no longer in use.
	$TIdrop = new Win32::API(
                $dll_name, "HttpUninitialize", [], V );

#        $TI_set_option = new Win32::API(  ###   not used jan 11, 2011
#                $dll_name, "HttpSetOption", [I,N,I], I );

        ## arkona
        $TI_is_readable = new Win32::API(
                 $dll_name, "HttpIsReadable", [I,I,P], I );

        ## arkona
        $TI_read = new Win32::API(
                 $dll_name, "HttpRead", [I,P,I], I );

        ## arkona
        $TI_write = new Win32::API(
                 $dll_name, "HttpWrite", [I,P,I], I );


        print "About to Open/Initialize our DLL.\n";
        
        $clkey = '';

        #$clkey = "SKKLLKHSISMBMTNT";  ### key w/ cata v 3.6 ( ADP )
        $clkey = "DKELQKFUMOHBMVSC";   ### key w/ cata v 6.0

        if ( ! $thang )
        {
            print "\nHELP!!!\n Unable to load CATALYST HTTP DLL [$dll_name].DLL\n\n";
            
            return('Unable to Load/Open our DLL, should be in (Current) root zwin folder!');
        }

	$joke = $thang->Call( $clkey, 0 );
        $joke2 = $ethang->Call(); # last-error.

        print "Catalyst--Init...";
        print "  These should read ' 1, 0 ' they are:  [$joke], [$joke2]\n";
        return( 'ok' );

}

# ===========================================================================
sub close_http_lib_now
{
        $TIdrop->Call();  # done with dll, thanks.
}

######################################################
########### bill, the following {#define} lines are strictly C-code.
###########  the Perl makes only Annotative use of them. See func-below.
######################################################
#define HTTP_VERSION_09         0x00009
#define HTTP_VERSION_10         0x10000
#define HTTP_VERSION_11         0x10001

#define HTTP_OPTION_NONE        0x0000
#define HTTP_OPTION_NOCACHE     0x0001
#define HTTP_OPTION_KEEPALIVE   0x0002
#define HTTP_OPTION_REDIRECT    0x0004
#define HTTP_OPTION_PROXY       0x0008
#define HTTP_OPTION_ERRORDATA	0x0010
#define HTTP_OPTION_TRUSTEDSITE	0x0800
#define HTTP_OPTION_SECURE      0x1000
#define HTTP_OPTION_FREETHREAD	0x8000
#define HTTP_OPTION_DEFAULT     HTTP_OPTION_NONE

#$cata_handle_dealer_track = &open_cata_https_socket( $DT_site );
# ===========================================================================
sub open_cata_https_socket
{
    ($dealer_tr_site, $timeout_seconds) = @_;
    $port_num = 443;  # Port 443 := Default for HTTPS, as '80' is for HTTP.

    $double_int_options = 0 + ( 1 * (256 * 16) );   # set to 'Secure'
    $double_int_http_version = 1 * (256 * 256) + 1; # set to "1.1"
    
    our $cata_handle = $TIconnect->Call(
            $dealer_tr_site, $port_num, $timeout_seconds,
            $double_int_options, $double_int_http_version,
            0
            );
    
    #print "\n site right now is: [$dealer_tr_site]\n";
    
    &get_and_view_error_report(); 
    
print "ARK-394 Right after: Connect-socket...cata-handle = [$cata_handle]\n";
    
    $boolean_connected = $TI_ask_connected->Call( $cata_handle );
    
    if ($boolean_connected)
    {
        #print "\n Hurrah!  Socket is good!!!!!!!\n\n";
    }
    else
    {
        print ".. Socket (DealerTrackXML), creation FAILS.\n";
        return( 'Create of SOCKET fails.' );
    }
    
    return( 'OK' );
}

# ===========================================================================
## 1-11-2011 Arkona socket, or portal
# ===========================================================================
sub open_cata_url_socket
{
    ($dealer_tr_site, $timeout_seconds) = @_;

    $double_int_options = 0 + ( 1 * (256 * 16) );   # set to 'Secure'
    ###$double_int_http_version = 1 * (256 * 256) + 1; # set to "1.1"

    our $cata_handle = $TIconnect_url->Call(
            $dealer_tr_site,
            $timeout_seconds,
            $double_int_options
            );
    
    #print "\n site right now is: [$dealer_tr_site]\n";
    
    &get_and_view_error_report(); 
print "ARK-429 Right after: Connect-socket...cata-handle = [$cata_handle]\n";
    $boolean_connected = $TI_ask_connected->Call( $cata_handle );
    
    if ($boolean_connected)
    {
        #print "\n Hurrah! ARKONA Socket is good!!!!!!!\n\n";
    }
    else
    {
        print "ARK-438 .. Socket (Arknoa) creation FAILS.\n";
        return( 'Create of SOCKET fails.' );
    }
    
    return( 'OK' );
}

# ===========================================================================
##############################
# ===========================================================================
sub disconnect_cata_socket
{
    $disco = $TI_disconnect->Call( $cata_handle );
    print "Result from socket-disconnect [$disco], should be Zero!!!\n";
    return( $disco );
}

# ===========================================================================
        #&authenticate_cata_basic( $DT_user, $DT_pswd );
        ## dt-xml only
# ===========================================================================
sub authenticate_cata_basic
{
    ($userx, $pswdx) = @_;
    $auth_options = 1;     #  '1' := calls for 'Basic'
    
    print "setting cata - basic - authenticate! ";
    print "... user: [$userx], pswd: [$pswdx]\n";
    
    $TI_basic_authenticate->Call(
        $cata_handle, $auth_options, $userx, $pswdx );
    
    &get_and_view_error_report();
}

# ===========================================================================
###################### 1-11-2001
###################### used by neither arkona / dtxml
        ###set_create_header_cata( 'SOAPAction', $Arko_Soap_Action );
# ===========================================================================
sub set_create_header_cata
{
    my ($header_name,$hdr_value)=@_;
    
    my $hdr = $TI_set_header_value->Call( $cata_handle, $header_name, $hdr_value );

    &get_and_view_error_report();
    print "ARK-485 Result is: [$hdr], should be ONE\n";
    return( $enco );

}

# ===========================================================================
#############write_cata_data( $transmit_data );
## arkona. takes the place of the dt's use of "HTTPS-POST"
# ===========================================================================
sub write_cata_data
{
    my ($xfr_data)=@_;
    my $xfr_len = length( $xfr_data );

    my $written = $TI_write->Call( $cata_handle, $xfr_data, $xfr_len );

    &get_and_view_error_report();
    
print "ARK-503 Result is: [$written], should be [$xfr_len]\n";
    return( $enco );
}

# ===========================================================================
############$my_post_reply = read_cata_data();
## ARKONA,  directly follows use of (above), writing the XML-SOAP request
# ===========================================================================
sub read_cata_data
{
    my ($the_timeout_seconds) = @_; 
    my $five_seconds = 1;

    my $data_has='';
    #$complete = 'NO';

    my $my_result_data = ''; 
    my $recharge = $the_timeout_seconds;

print "ARK-522 We are now inside the 'cata' read sub\n.\n";
    
    ## Note, TCP/IP often sends in blocks of about 16KB data; repeatedly, re-inventory
    while( $the_timeout_seconds > 0 )
    {
        my $xbuff = chr(0) x 409600;
        my $len_buff =       400000;
	
	$data_has = '';

        my $data_is_ready = $TI_is_readable->Call($cata_handle, $five_seconds, 0);

        #if ( $data_is_ready == 0 )
        #{
            #$data_is_ready = $TI_is_readable->Call($cata_handle, $five_seconds, 0);
print "ARK-537 data is ready=$data_is_ready\n";

            #$the_timeout_seconds -= $five_seconds; next;
        #}

        my $reply = $TI_read->Call( $cata_handle, $xbuff, $len_buff );
print "ARK-542 reply=$reply\n";
        $data_has = substr( $xbuff, 0, $reply );
        $lofdata=length($data_has);
print "ARK-545 datahaslength=$lofdata\n";

	$my_result_data .= $data_has;
        #print "ARK-data_has=$data_has\n\n";
        ##
        ##Note> in this 'if' we are testng for close of [ </soap:Envelope>/i ] (caseless)
        ##
        if ($my_result_data =~ /\/soap:Body><\/soap:Envelope>/i) {last;}

print "\ntemp: november 22, 2016 jimt....\n";
if (length($my_result_data) > 123) {last;}



	if (uc($my_result_data) =~ "BAD REQUEST") 
	{
                #$my_result_data = "BAD DATA";
		last;
	}
                                  #  123456789

	$the_timeout_seconds = $recharge;
    }
print "\n\nARK-564 my_result_data=$my_result_data\n";


    #if ($complete eq 'NO') {$my_result_data = 'NO';}
    return( $my_result_data );
    
}

# ===========================================================================
sub set_cata_url_encoding
{
    print "setting cata url encoding...";
    $one=1;
    $enco = $TI_set_encoding_type->Call( $cata_handle, $one ); #calls for url_encoding.
    &get_and_view_error_report();
print "ARK-552 Result is: [$enco], should be ZERO\n";
    return( $enco );
}

# ===========================================================================
sub uri_cata_escape  ### July 25th:  this I found upon CSPAN!!!
{
    ($text) = @_;
    
    ## for RFC3986, everything other than listed will go to [ %hh ] ...........
    %Unsafe = (
    RFC2732 => qr/[^A-Za-z0-9\-_.!~*'()]/,
    RFC3986 => qr/[^A-Za-z0-9\-\._~"]/,
    );
    
    
    # Build a char->hex map
    for (0..255) {
        $escapes{chr($_)} = sprintf("%%%02X", $_);
    }
        
    $text =~ s/($Unsafe{RFC3986})/$escapes{$1}/g;
    
    return( $text );
}

# ===========================================================================
#($has_posted_xml,$my_post_reply) = &send_cata_post( $xml_data_ascii, $my_resource );
## DT-XML ONLY !!!!!!!!!!!!!!!!!
# ===========================================================================
sub send_cata_post
{
    ($the_xml_ascii,$asp_page_location) = @_;
    @rv = (0,'');  $one=0;
    
    $xml_length = length( $the_xml_ascii );  print "\nthe XML ASCII length: [$xml_length]\n\n";
    
    $xml_result = ' ' x 40960;  ## MUST PRE-DEFINE -- Max possible?????
    
    $max_length_of_resu=40900;

    $post_resu = $TI_send_post_data->Call( $cata_handle, $asp_page_location,
                             $the_xml_ascii, $xml_length, $xml_result, $max_length_of_resu, $one );

print "ARK-594 Result from set send-post-data, [$post_resu], should be ZERO or Greater\n";
print "ARK-595 '200' means: 'OK' \n";

print "ARK-597 Following our Post: "; 
    
    &get_and_view_error_report();
    
    $perl_result_string = $xml_result;
    
    $test_end = " " x 100;
    @temp_ar = split($test_end, $perl_result_string);
    $perl_result_string = $temp_ar[0];
    
    @rv = ($post_resu, $perl_result_string);
    
    return( @rv );
}

sub get_and_view_error_report
{
    $error_num = $TI_get_error_number->Call();
print "ARK-613 Error Reporting: The actual 'error-number' is: [$error_num]\n";
    if ( $error_num == 0 ) {return;}
    ############################################################
    
    $error_text = ' ' x 4096;
    $e_text_length = $TI_get_error_text_scalar->Call(
        $error_num, $error_text, 4000 );
    
    $e_txt = substr( $error_text, 0, $e_text_length );
print "ARK-622 Resulting error descr. is: [$e_txt]\n";
}

1;

