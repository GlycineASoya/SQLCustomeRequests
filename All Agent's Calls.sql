select insq.sessionid 'Session ID',
case when insq.originatordn = '' then resource.extension else insq.originatordn end 'Calling',
insq.callednumber 'Called',
insq.startdatetime 'Date Time',
case when agentconnectiondetail.startdatetime is null then insq.startdatetime else agentconnectiondetail.startdatetime end 'Date Time for Each Subcall',
case when agentconnectiondetail.ringtime is null then 0 else agentconnectiondetail.ringtime end 'Ring Time',
case when agentconnectiondetail.talktime is null then 0 else agentconnectiondetail.talktime end 'Talk Time',
resource.resourcename 'Agent'

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
left join agentconnectiondetail
on agentconnectiondetail.sessionid = insq.sessionid
and agentconnectiondetail.sessionseqnum = insq.sessionseqnum
and agentconnectiondetail.nodeid = insq.nodeid
and agentconnectiondetail.profileid = insq.profileid
left join resource
on resource.resourceid = agentconnectiondetail.resourceid
and agentconnectiondetail.profileid = resource.profileid
or resource.resourceid = insq.destinationid

where IsRecordInDOWTime = 1 
and resource.resourceid is not null
and (insq.contacttype = 1 or insq.contacttype = 3)

order by insq.sessionid