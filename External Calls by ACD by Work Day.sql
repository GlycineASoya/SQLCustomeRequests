use db_cra

select subq.applicationname as 'Queue',
count(subq.applicationname) as 'Total calls',
sum(case when subq.contactdisposition = 2 then 1 else 0 end) as 'Complete calls',
round(avg(subq.connecttime), 0) as 'Average connection time',
round(max(subq.connecttime), 0) as 'Maximum connection time',
sum(case when subq.contactdisposition <> 2 then 1 else 0 end) as 'Incomplete calls',
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
							datepart(mi, contactcalldetail.startdatetime) <= 00 then 1 else 0
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
	and contactcalldetail.startdatetime <= '2017-05-05 18:20:00.000'
) subq

inner join contactroutingdetail
on contactroutingdetail.sessionid = subq.sessionid
and contactroutingdetail.sessionseqnum = subq.sessionseqnum
and contactroutingdetail.nodeid = subq.nodeid
and contactroutingdetail.profileid = subq.profileid
inner join contactqueuedetail
on contactqueuedetail.sessionid = subq.sessionid
and contactqueuedetail.sessionseqnum = subq.sessionseqnum
and contactqueuedetail.nodeid = subq.nodeid
and contactqueuedetail.profileid = subq.profileid

where IsRecordInDOWTime = 1
and subq.contacttype = 1
and subq.originatortype = 3
and len(subq.originatordn) > 5
and subq.destinationtype = 2
group by subq.applicationname