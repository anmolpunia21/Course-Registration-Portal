CREATE TABLE user_account
(
    username VARCHAR(50) PRIMARY KEY,
    passwd VARCHAR(50) NOT NULL,
    usertype VARCHAR(50) NOT NULL
);
create table student (
    ID 			varchar(20),
    st_name 	varchar(20) not null,
    dept_name 	varchar(20),
    batch_id	varchar(8),
	tot_cred 	numeric(3,0) default 0,
    primary key (ID),
    foreign key (dept_name) references department on delete cascade
);
create table instructor(
    ID          varchar (30),
    inst_name 	varchar (20) not null,
    dept_name 	varchar (20),
    salary 		numeric (8,2) default 10000,
    primary key (ID),
    foreign key (dept_name) references department on delete cascade
);
create table teaches(
	ID 			varchar (30),
	course_id 	varchar (8),
	batch_id 	varchar (8),
	semester 	varchar (6),
	year 		numeric (4,0),
	req_grade   numeric (2,0) default 0,
	primary key (ID, course_id, batch_id, semester, year),
	foreign key (ID) references instructor on delete cascade,
	foreign key (course_id) references course on delete cascade
);
create table takes
	(ID 		varchar(20), 
	 course_id 	varchar(8),
	 batch_id 	varchar(8), 
	 semester 	varchar(6),
	 year 		numeric(4,0),
	 grade 		numeric(2,0) default 0,
	 primary key (ID, course_id, batch_id, semester, year),
	 foreign key (course_id) references course on delete cascade,
	 foreign key (ID) references student (ID) on delete cascade
);
create table ticket
	(ID 		varchar(20), 
	 course_id 	varchar(8),
	 batch_id 	varchar(8), 
	 semester 	varchar(6),
	 year 		numeric(4,0),
	 status 	numeric(1,0) default 0,
	 primary key (ID, course_id, batch_id, semester, year),
	 foreign key (course_id) references course on delete cascade,
	 foreign key (ID) references student (ID) on delete cascade
);
CREATE TABLE temp_prereq (
    course_id varchar(8),
    prereq_id varchar(30),
    primary key (course_id),
    foreign key (course_id) references course on delete cascade
);
-- *******************************************************************************************************
create table course (
    course_id 	varchar(8),
    title 		varchar(50),
    dept_name 	varchar(20),
    credits 	numeric(2,0),
    l_t_p       varchar(10),
	time_slot_id    varchar(4),
    primary key (course_id),
    foreign key (dept_name) references department on delete cascade
);
insert into course values ('CS510', 'Advanced Computer Architecture','CSE','4','3-1-2-6','B');
insert into course values ('CS523', 'Applied Cryptography','CSE','4','3-0-2-7','C1');
insert into course values ('CS516', 'Wire Adhoc Networks','CSE','4','2-0-4-6','D1');

insert into course values ('CS301', 'Introduction to Database ', 'CSE', '4' ,'3-1-2-6','B1');
insert into course values ('CS302', 'Analysis and Design of Algorithms', 'CSE', '3' ,'3-1-0-5','D1');
insert into course values ('CS303', 'Operating Systems', 'CSE', '4' ,'3-1-2-5','A1');
insert into course values ('CS518', 'Computer Vision', 'CSE', '4' ,'3-0-2-7','C1');
insert into course values ('CS507', 'Multimedia Systems', 'CSE', '3' ,'2-0-4-6','D');
insert into course values ('CS529', 'Applies AI','CSE','4','3-0-2-7','B');

insert into course values ('CS201', 'Data Structures', 'CSE', '4' ,'3-1-2-7','B1');
insert into course values ('CS203', 'Digital Logic Design', 'CSE', '4' ,'3-1-2-6','A1');
insert into course values ('CS204', 'Computer Architechture','CSE','4','3-0-3-4','B');

insert into course values ('CS101', 'Discrete Mathematics', 'CSE', '3', '3-0-2-6','A');
insert into course values ('GE103', 'Introduction to computing', 'CSE', '4' , '3-0-2-5','A1');
-- *****************************************************************************************************
create table prereq (
    course_id varchar(8),
    prereq_id varchar(8),
    primary key (course_id,prereq_id),
    foreign key (course_id) references course on delete cascade,
    foreign key (prereq_id) references course on delete cascade
);

insert into prereq values ('CS301', 'CS201');
insert into prereq values ('CS302', 'CS201');
insert into prereq values ('CS302', 'CS101');
insert into prereq values ('CS303', 'CS201');
insert into prereq values ('CS303', 'CS204');
insert into prereq values ('CS510', 'CS204');
insert into prereq values ('CS510', 'CS201');
insert into prereq values ('CS201', 'GE103');
-- ******************************************************************************************************
