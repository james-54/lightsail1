package JSON_PAGE;
# dec. 24 2016 jimt/zeus --------- headibg twd's awsightsail !!!
# december 13, 2016 jim/zeus/wjs.
# omniq-json_pm.pm



# ths file> omniq-json.txz

#jimt/zeus/wjs. november 17, 2016.
# omnique json proto fract's



#URL: https://staging-api.omnique.com/api/universal/Appointment/GetAppointments
$thing_to_send = '
{    "RequestHeader":
    
    {   "CompanyId": $Company_Number,
        "RequestDateUtc": &getmy_utc_time(time()),
        "RequestKey": "key",
        "RequestingApp": "test app"
    },
    
    "RequestBody":
        
        {  "ShopNumber": $Shop_Number,  "StartTime": $Start_Time,  "EndTime": $End_Time }
}';
#END-URL.

#SUGGESTED-REPLY.
$reply_thing = '
{  "ApiAppointment": 
[
{"AppointmentId":350865,"Description":"Come See Us!","Status":null,
"StartTime":"2016-10-08T11:00:00","EndTime":"2016-10-08T11:30:00","UseAlternateContact":false,
"Customer":null,"Vehicle":null}
,
{"AppointmentId":350866,"Description":"Go AWAY !!!  Come See Us!","Status":null,
"StartTime":"2016-10-09T14:00:00","EndTime":"2016-10-09T18:30:00","UseAlternateContact":false,
"Customer":null,"Vehicle":null}
],
    "RequestHeader":
    {
        "RequestKey": "key",
        "RequestingApp": "test app",
        "RequestDateUtc": "2015-09-24T23:34:26.972Z",
        "CompanyId": 1
    },
    "ResponseMessage": null
}';


$reply_thing =~ s/\n//g;
$reply_thing =~ s/\r//g;
###############################
$reply_thing =~ s/,(\s*)"/;$1"/g;
$reply_thing =~ s/"(\w+)":/\$$1=/g;
$reply_thing =~ s/null/"null"/g;
$reply_thing =~ s/false/"false"/g;
$reply_thing =~ s/true/"true"/g;

print "\n[..[$reply_thing]..]\n";



$mywant="AppointmentId";
@appts = $reply_thing =~ m/$mywant=\d+/g;
print @appts;

my $stopit=$appts[1]; 

$reply_thing =~ s/,\{\$($stopit.*)//;
my $junk = $1;
print "\n stopit:$stopit//\n junk:\$$junk//\n rplyth:$reply_thing///..........\n";
my $begin=$appts[0];
$reply_thing =~ s/($begin.*)//;
print "............/////\n\n Mine--dlr1:{\$$1\n\n$reply_thing\n";

=pod
Add Appointment
URL : https://staging-api.omnique.com/api/universal/Appointment/AddAppointment
The Add Appointment API call inserts a new appointment into a shop's appointment book.
Parameters:
Appointment: A JSON Object containing the required elements for an appointment.
roperties of this object listed below.
ShopNumber: Int Required - The shop that the appointment will be created for.
StartTime: Datetime Required - The start time of the appointment.
EndTime: Datetime Required - The end time of the appointment.
Description: String (100) Optional - A short description of the appointment.
CustomerId: Int Optional - The customer on the appointment.
VehicleId: Int Optional - The vehicle on the appointment. If this is supplied a Vehicle must also be supplied.
StatusId: Int Required - The status for the appointment.
[Check the GetAppointmentStatuses API for valid values.
UseAlternateContact - Bool Optional - Whether the appointment is for the primary or alternate contact.
]
=cut


#URL: https://staging-api.omnique.com/api/universal/Appointment/AddAppointment
$thing_to_send = '
{    "RequestHeader":

    {
        "CompanyId": 907100,
        "RequestDateUtc": "2016-12-05T12:51:26.001Z",
        "RequestKey": "key",
        "RequestingApp": "test app"
    },
    "RequestBody":
    {
        "Appointment":
        {
            "ShopNumber": 1,
            "StartTime": "2016-10-09 2:00PM",
            "EndTime": "2016-10-09 6:30PM",
            "StatusID": 33055,
            "Description": "Go AWAY !!!  Come See Us!",
            "CustomerId": null,
            "VehicleId": null,
            "UseAlternateContact": null
        }
    }
}';
#END-URL.

#URL: https://staging-api.omnique.com/api/Universal/Appointment/GetAppointmentStatuses
$thing_to_send = '
{
    "RequestHeader":
    {
    "CompanyId": 907100,
    "RequestDateUtc": "2016-12-05T12:34:26.972Z",
    "RequestKey": "key",
    "RequestingApp": "test app"
    }
}';
#END-URL,
1;
