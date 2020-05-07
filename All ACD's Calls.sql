select insq.sessionid 'Session ID',
case when insq.contactdisposition = 2 then 'yes' else 'no' end 'Complete?',
insq.originatordn 'Calling',
insq.callednumber 'Called',
insq.startdatetime 'Date Time',
insq.connecttime 'Ring Time',
contactroutingdetail.queuetime 'Queue Time',
insq.applicationname 'ACD'

from (
	select
		*,
		case
			when datepart(dw, contactcalldetail.startdatetime) between 2 and 5 then
				case
					when datepart(hour, contactcalldetail.startdatetime) between 9 and 17 then 1 else
						case
							when datepart(hour, contactcalldetail.startdatetime) = 18 and 
							datepart(mi, contactcalldetail.startdatetime) <= 0 then 1 else 0
						end
				end
			when datepart(dw, contactcalldetail.startdatetime) = 6 then
				case
					when datepart(hour, contactcalldetail.startdatetime) between 9 and 15 then 1 else
						case
							when datepart(hour, contactcalldetail.startdatetime) = 16 and 
							datepart(mi, contactcalldetail.startdatetime) <= 45 then 1 else 0
						end
				end
		end as IsRecordInDOWTime
	from
		contactcalldetail
	where contactcalldetail.startdatetime >= '2017-05-05 09:00:00.000'
	and contactcalldetail.startdatetime <= '2017-05-05 18:20:00.000') insq

inner join contactroutingdetail
on contactroutingdetail.sessionid = insq.sessionid
and contactroutingdetail.sessionseqnum = insq.sessionseqnum
and contactroutingdetail.nodeid = insq.nodeid
and contactroutingdetail.profileid = insq.profileid
inner join contactqueuedetail
on contactqueuedetail.sessionid = insq.sessionid
and contactqueuedetail.sessionseqnum = insq.sessionseqnum
and contactqueuedetail.nodeid = insq.nodeid
and contactqueuedetail.profileid = insq.profileid


where IsRecordInDOWTime = 1
and (insq.contacttype = 1 or insq.contacttype = 3)
and insq.destinationtype = 2

order by insq.sessionid