create trigger timeslot check1 after insert on section
referencing new row as nrow
for each row
when (nrow.time slot id not in (
select time slot id
from time slot)) /* time slot id not present in time slot */
begin
rollback
end;
create trigger timeslot check2 after delete on timeslot
referencing old row as orow
for each row
when (orow.time slot id not in (
select time slot id
from time slot) /* last tuple for time slot id deleted from time slot */
and orow.time slot id in (
select time slot id
from section)) /* and time slot id still referenced from section*/
begin
rollback
end;
--************************************************************************************
create trigger credits earned after update of takes on (grade)
referencing new row as nrow
referencing old row as orow
for each row
when nrow.grade <> ’F’ and nrow.grade is not null
and (orow.grade = ’F’ or orow.grade is null)
begin atomic
update student
set tot cred= tot cred+
(select credits
from course
where course.course id= nrow.course id)
where student.id = nrow.id;
end;
--*************************************************************************************


--***********************************************************************************
(select username from user_account LIMIT 1)
(select passwd from user_account LIMIT 1)
--***********************************************************************************
