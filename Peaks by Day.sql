use db_cra

select datepart(dd, insq.startdatetime) as 'Day',
datepart(mm, insq.startdatetime) as 'Month',
count(datepart(dd, insq.startdatetime)) as 'Total Calls',
sum(case when insq.contactdisposition = 2 then 1 else 0 end) as 'Complete calls',
round(avg(insq.connecttime), 0) as 'Average talk time',
round(max(insq.connecttime), 0) as 'Maximum talk time',
sum(case when insq.contactdisposition <> 2 then 1 else 0 end) as 'Incomplete calls',
round(avg(contactroutingdetail.queuetime), 0) as 'Average wait time',
round(max(contactroutingdetail.queuetime), 0) as 'Maximum wait time',
sum(case when contactqueuedetail.disposition = 5 then 1 else 0 end) as 'By others'

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
	and contactcalldetail.startdatetime <= '2017-05-10 18:20:00.000') insq

left join contactroutingdetail
on contactroutingdetail.sessionid = insq.sessionid
and contactroutingdetail.sessionseqnum = insq.sessionseqnum
and contactroutingdetail.nodeid = insq.nodeid
and contactroutingdetail.profileid = insq.profileid
left join contactqueuedetail
on contactqueuedetail.sessionid = insq.sessionid
and contactqueuedetail.sessionseqnum = insq.sessionseqnum
and contactqueuedetail.nodeid = insq.nodeid
and contactqueuedetail.profileid = insq.profileid

where IsRecordInDOWTime = 1
and insq.contacttype = 1
and insq.originatortype = 3
and len(insq.originatordn) > 5
and insq.destinationtype = 2
group by datepart(dd, insq.startdatetime), datepart(mm, insq.startdatetime)