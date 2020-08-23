CREATE OR REPLACE FUNCTION check_course_slot(_course_ID varchar,_ID varchar)
RETURNS  text AS $$
DECLARE
    _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
    rec record;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;
    SELECT batch_id INTO _batch_id FROM student WHERE ID=_ID;

    FOR rec in (SELECT course.time_slot_id FROM course  WHERE course.course_id = _course_ID)
    LOOP 
        IF rec.time_slot_id IN (SELECT c.time_slot_id 
                                FROM course  c 
                                WHERE c.course_id IN (  SELECT t.course_id 
                                                        FROM takes  t 
                                                        WHERE   t.batch_id=_batch_id and 
                                                                t.year=_year and 
                                                                t.semester=_semester and 
                                                                t.ID=_ID)                       ) THEN 
            result := 'False';
            RETURN result;
        ELSE
            result := 'True';
            RETURN result;
        END IF;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
--*****************************************************************************************************************
CREATE OR REPLACE FUNCTION check_course_prereq(_course_ID varchar,_ID varchar)
RETURNS  text AS $$
DECLARE
     _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
    a integer;
    rec record;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    SELECT batch_id INTO _batch_id FROM student WHERE ID=_ID;
    IF _month < 7 THEN
        _semester := 'odd';
        FOR rec in (    SELECT prereq.prereq_id 
                        FROM prereq 
                        WHERE prereq.course_id=_course_ID   )
        LOOP
            IF  rec.prereq_id IN (  SELECT course_id   
                                    FROM takes 
                                    WHERE   ID=_ID and 
                                            grade > 4 and 
                                            year<>_year         ) THEN
                a:=0;
            ELSE
                result := 'False';
                RETURN result;
            END IF;
        END LOOP;
        result := 'True';
        return result;
    ELSE
        _semester := 'even';
        FOR rec in (SELECT prereq.prereq_id FROM prereq WHERE prereq.course_id=_course_ID)
        LOOP
            IF  rec.prereq_id IN (SELECT course_id FROM takes WHERE ID=_ID and grade > 4 and year=_year and semester='odd') THEN
                a:=0;
            ELSIF rec.prereq_id IN (SELECT course_id FROM takes WHERE ID=_ID and grade > 4 and year<>_year) THEN
                a:=0;
            ELSE
                result := 'False';
                RETURN result;
            END IF;
        END LOOP;
        result := 'True';
        return result;
    END IF;
END;
$$
LANGUAGE plpgsql;
--******************************************************************************************************************
CREATE or REPLACE FUNCTION add_course(_ID varchar,_course_ID varchar)
RETURNS void AS $$
DECLARE
    _batch_id varchar;
    _year integer;
    _month integer;
    _semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;

    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;
    
    INSERT INTO takes(ID,course_id,batch_id,semester,year,grade) VALUES (_ID,_course_ID,_batch_id,_semester,_year,0);
END;$$
LANGUAGE plpgsql;
--*******************************************************************************************************************
CREATE OR REPLACE FUNCTION get_floated_course_detail(_ID varchar)
   RETURNS TABLE(course_id varchar, title varchar, dept_name varchar, credits numeric(2,0),l_t_p varchar,batch_id varchar) AS
$$
DECLARE
    _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;
    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;

    RETURN QUERY
    SELECT c.course_id , c.title , c.dept_name , c.credits, c.l_t_p, tc.batch_id
    FROM course c,teaches tc
    where   tc.batch_id = _batch_id and 
            c.course_id = tc.course_id and
            tc.course_id NOT IN(SELECT t.course_id 
                                FROM takes  t
                                WHERE t.batch_id=_batch_id and 
                                t.year=_year and 
                                t.semester=_semester and 
                                t.ID=_ID ) and 
            tc.course_id NOT IN(SELECT t.course_id 
                                FROM takes  t
                                WHERE t.batch_id=_batch_id and 
                                t.year=_year and 
                                t.semester='odd' and 
                                t.ID=_ID and
                                grade > 4) and
            tc.course_id NOT IN(SELECT t.course_id 
                                FROM takes  t
                                WHERE t.batch_id=_batch_id and 
                                t.year=_year-1 and 
                                grade > 4 and 
                                t.ID=_ID ) and
            tc.course_id NOT IN(SELECT t.course_id 
                                FROM ticket  t
                                WHERE t.batch_id=_batch_id and 
                                t.year=_year and 
                                t.semester=_semester and 
                                t.ID=_ID );

END; $$
 
LANGUAGE plpgsql;
--******************************************************************************************************************
CREATE OR REPLACE FUNCTION get_course_offering_detail()
    RETURNS TABLE(course_id varchar, sec_id varchar, semester varchar, year numeric(4,0),name varchar,req_grade numeric(2,0)) AS
$$
BEGIN
    RETURN QUERY
 
    SELECT t.course_id , t.sec_id , t.semester , t.year , i.inst_name, t.req_grade
    FROM teaches t
    LEFT JOIN instructor i on t.ID = i.ID;
END; $$
 
LANGUAGE plpgsql;
--******************************************************************************************************************
CREATE OR REPLACE FUNCTION get_max_credit(_ID varchar)
   RETURNS integer AS
$$
DECLARE
    _year integer;
    _month integer;
    rec record;
	credit1 integer;
	credit2 integer;
	pre_sem text;
	pre2pre_sem text;
	pre_year integer;
	pre2pre_year integer;
	max_credit integer;
	no_sem integer default 0;
	temp integer default 0;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
		pre_year=_year - 1;
		pre_sem = 'even';
		pre2pre_year = _year - 1;
		pre2pre_sem = 'odd';
    ELSE
		pre_year=_year ;
		pre_sem = 'odd';
		pre2pre_year = _year - 1;
		pre2pre_sem = 'even'; 
    END IF;

	FOR rec IN( SELECT takes.course_id FROM takes WHERE takes.ID = _ID AND takes.year = pre_year AND takes.semester = pre_sem AND takes.grade > 4)
	LOOP
		SELECT course.credits INTO temp FROM course WHERE course.course_id = rec.course_id;
		credit1 := credit1 + temp;
	END LOOP;

	FOR rec IN( SELECT takes.course_id FROM takes WHERE takes.ID = _ID AND takes.year = pre2pre_year AND takes.semester = pre2pre_sem AND takes.grade > 4)
	LOOP
		SELECT course.credits INTO temp FROM course WHERE course.course_id = rec.course_id;
		credit2 := credit2 + temp;
	END LOOP;

	IF credit1 > 0 THEN
		no_sem := no_sem + 1;
	END IF;
	IF credit2 > 0 THEN
		no_sem := no_sem + 1;
	END IF;
	IF no_sem = 0 THEN
		max_credit := 12;
	ELSE
		max_credit :=  1.25*(credit1+credit2/no_sem);
	END IF;
	RETURN max_credit;
END; $$
LANGUAGE plpgsql;
--*******************************************************************************************************************
CREATE OR REPLACE FUNCTION get_credit(_ID varchar,_course_ID varchar)
   RETURNS integer AS
$$
DECLARE
    _year integer;
    _month integer;
    rec record;
	credit1 integer default 0;
	_semester text;
	temp integer default 0;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
		_semester = 'odd';
    ELSE
		_semester = 'even'; 
    END IF;

	FOR rec IN( SELECT takes.course_id FROM takes WHERE takes.ID = _ID AND takes.year = _year AND takes.semester = _semester )
	LOOP
		SELECT course.credits INTO temp FROM course WHERE course.course_id = rec.course_id;
		credit1 := credit1 + temp;
	END LOOP;

    SELECT course.credits INTO temp FROM course WHERE course.course_id = _course_ID;

	RETURN credit1+temp;
END; $$
LANGUAGE plpgsql;
--********************************************************************************************************
CREATE OR REPLACE FUNCTION generate_ticket(_ID varchar,_course_ID varchar)
   RETURNS void AS
$$
DECLARE
    _batch_id varchar;
    _year integer;
    _month integer;
	_semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
		_semester = 'odd';
    ELSE
		_semester = 'even'; 
    END IF;
    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;

    INSERT INTO ticket VALUES (_ID,_course_ID,_batch_id,_semester,_year);
	
	RETURN ;
END; $$
LANGUAGE plpgsql;
--********************************************************************************************************
CREATE OR REPLACE FUNCTION get_ticket_detail(_ID varchar)
   RETURNS TABLE(course_id varchar, title varchar, dept_name varchar, credits numeric(2,0),l_t_p varchar,batch_id varchar,status numeric(2,0)) AS
$$
DECLARE
    _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;
    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;

    RETURN QUERY
    SELECT c.course_id , c.title , c.dept_name , c.credits, c.l_t_p, tc.batch_id, tc.status
    FROM course c,ticket tc
    where   tc.batch_id = _batch_id and 
            tc.course_id = c.course_id and
			tc.year=_year and 
			tc.semester=_semester and 
			tc.ID=_ID ; 

END; $$
 
LANGUAGE plpgsql;
--*******************************************************************************************************************
CREATE OR REPLACE FUNCTION get_all_ticket_detail()
   RETURNS TABLE(course_id varchar, title varchar, ID varchar,batch_id varchar) AS
$$
DECLARE
    _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;

    RETURN QUERY
    SELECT c.course_id , c.title ,tc.ID, tc.batch_id
    FROM course c,ticket tc
    where   tc.course_id = c.course_id and
			tc.year=_year and 
			tc.semester=_semester and 
            tc.status = 0; 
END; $$
 
LANGUAGE plpgsql;

--*******************************************************************************************************************
CREATE OR REPLACE FUNCTION get_student_course(_ID varchar)
   RETURNS TABLE(course_id varchar) AS
$$
DECLARE
    _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;
    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;

    RETURN QUERY
    SELECT DISTINCT tc.course_id
    FROM takes tc
    where   tc.batch_id = _batch_id and 
			tc.ID=_ID; 

END; $$
 
LANGUAGE plpgsql;
--*****************************************************************************************************************
CREATE or REPLACE FUNCTION get_cgpa(_ID varchar)
RETURNS numeric(3,2) AS $$
DECLARE
    _batch_id varchar;
    _year integer;
    _month integer;
    rec record;
	credit1 integer default 0;
	_semester text;
	temp1 integer default 0;
	temp2 integer default 0;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
		_semester = 'odd';
    ELSE
		_semester = 'even'; 
    END IF;
    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;

	FOR rec IN( SELECT takes.course_id,takes.grade FROM takes WHERE takes.ID = _ID and grade > 4)
	LOOP
		SELECT course.credits INTO temp1 FROM course WHERE course.course_id = rec.course_id;
        temp2 := temp2 + temp1*rec.grade;
		credit1 := credit1 + temp1;
	END LOOP;
    IF credit1 = 0 THEN
        RETURN 0 ;
    ELSE
        RETURN temp2::float/credit1;
    END IF;
END;
$$
LANGUAGE plpgsql;
--***************************************************************************************************************
CREATE or REPLACE FUNCTION remove_ticket(_ID varchar,_course_ID varchar,_status integer)
RETURNS void AS $$
DECLARE
    _batch_id varchar;
    _year integer;
    _month integer;
    _semester text;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;
    SELECT student.batch_id INTO _batch_id FROM student WHERE student.ID=_ID;

    UPDATE ticket SET status = _status WHERE  ID=_ID and
                                        course_id = _course_ID and
                                        batch_id = _batch_id and
                                        semester = _semester and
                                        year = _year and
                                        status = 0;
END;$$
LANGUAGE plpgsql;
--*****************************************************************************************************************
CREATE OR REPLACE FUNCTION get_courses_detail()
    RETURNS TABLE(course_id varchar,title varchar, credits numeric(2,0), l_t_p varchar,prereq_id varchar) AS
$$
BEGIN
    RETURN QUERY 
    SELECT c.course_id , c.title , c.credits , c.l_t_p , p.prereq_id 
    FROM course c
    LEFT JOIN temp_prereq p on c.course_id = p.course_id;
END; $$
LANGUAGE plpgsql;
--*******************************************************************************************************************
CREATE OR REPLACE FUNCTION update_prereq()
  RETURNS trigger AS
$$
DECLARE
    rec record;
    temp text;
BEGIN

    SELECT * INTO rec FROM temp_prereq WHERE temp_prereq.course_id = NEW.course_id;
    IF FOUND THEN
        SELECT concat_ws(',',NEW.prereq_id,rec.prereq_id) INTO temp;
        UPDATE temp_prereq SET prereq_id=temp WHERE temp_prereq.course_id = NEW.course_id;
    ELSE
        INSERT INTO temp_prereq VALUES(NEW.course_id,NEW.prereq_id);
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_temp_prereq_list
  BEFORE INSERT
  ON prereq
  FOR EACH ROW
  EXECUTE PROCEDURE update_prereq();
--*********************************************************************************************************************
CREATE OR REPLACE FUNCTION check_cgpa(_course_ID varchar,_ID varchar)
RETURNS  text AS $$
DECLARE
    _batch_id varchar;
    result text;
    _year integer;
    _month integer;
    _semester text;
    cgpa integer;
    x integer;
BEGIN
    SELECT INTO _year EXTRACT( year FROM now());
    SELECT INTO _month EXTRACT( month FROM now());
    IF _month < 7 THEN
        _semester := 'odd';
    ELSE
        _semester := 'even';
    END IF;
    SELECT batch_id INTO _batch_id FROM student WHERE ID=_ID;

    SELECT get_cgpa(_ID) INTO cgpa;
    SELECT req_grade INTO x FROM teaches WHERE course_id=_course_ID and
                                                semester=_semester and
                                                year = _year;

    IF cgpa = 0 THEN
        result := 'allowed';
        RETURN result;
    END IF;
    IF cgpa >= x THEN
        result := 'allowed';
        RETURN result;
    ELSE
        result := 'not allowed';
        RETURN result;
    END IF;
END;
$$
LANGUAGE plpgsql;