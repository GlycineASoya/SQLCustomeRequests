use db_cra

select subq.rn as 'Agent name',
subq.ext as 'Agent number',
count(subq.rn) as 'Total calls',
sum(case when subq.tt <> 0 then 1 else 0 end) as 'Complete calls',
case when round(avg(subq.tt), 0) is null then 0 else
round(avg(subq.tt), 0) end as 'Average talk time',
case when round(max(subq.tt), 0) is null then 0 else
round(max(subq.tt), 0) end as 'Maximum talk time',
sum(case when subq.tt = 0 then 1 else 0 end) as 'Incomplete calls',
case when round(avg(subq.rt), 0) is null then 0 else
round(avg(subq.rt), 0) end as 'Average ring time',
case when round(max(subq.rt), 0) is null then 0 else
round(max(subq.rt), 0) end as 'Maximum ring time'

from (
	select insq.sessionid 'sid',
		max(insq.sessionseqnum) 'seq',
		case when max(agentconnectiondetail.ringtime) is null then 0
		else max(agentconnectiondetail.ringtime) end 'rt',
		case when max(agentconnectiondetail.talktime) is null then 0
		else max(agentconnectiondetail.talktime) end 'tt',
		resource.resourcename 'rn',
		resource.extension 'ext'

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
		and contactcalldetail.startdatetime <= '2017-05-05 17:00:00.000'
	) insq
	
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
	group by insq.sessionid, insq.sessionseqnum, resource.resourcename, resource.extension) subq

inner join contactcalldetail
on contactcalldetail.sessionid = subq.sid
and contactcalldetail.sessionseqnum = subq.seq
group by subq.rn, subq.ext


