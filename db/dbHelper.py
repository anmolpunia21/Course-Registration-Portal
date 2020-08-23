from db.db import Storage
import math


class DbHelper:
    def __init__(self):
        storage = Storage()
        self.conn = storage.conn

    def insertUser(self, username, passwd, name, dept_name, usertype, batch_id):
        cur = self.conn.cursor()
        result = True
        print(usertype)
        try:
            cur.execute('''INSERT INTO user_account(username,
            passwd,usertype) VALUES (%s,%s,%s)''', (username, passwd, usertype,))
        except Exception as err:
            print(err)
            result = False

        if result:
            if usertype == 'student':
                tot_credit = 0
                cur.execute("INSERT INTO student(ID,st_name,dept_name,batch_id,tot_cred) VALUES(%s,%s,%s,%s,%s)",
                            (username, name, dept_name, batch_id, tot_credit,))
            if usertype == 'faculty':
                salary = 100000
                cur.execute("INSERT INTO instructor(ID,inst_name,dept_name,salary) VALUES(%s,%s,%s,%s)",
                            (username, name, dept_name, salary,))
            if usertype == 'advisor':
                print('hello')

        cur.close()
        self.conn.commit()
        return result

    def insert_in_teaches(self, username, course_id, batch_id, grade):
        cur = self.conn.cursor()
        result = True
        cur.execute("SELECT EXTRACT(year from now())")
        year = cur.fetchone()
        cur.execute("SELECT EXTRACT(month from now())")
        month = cur.fetchone()
        self.conn.commit()
        if grade == "None":
            grade = 0
        if int(month[0]) >= 7:
            semester = 'even'
        else:
            semester = 'odd'
        try:
            cur.execute("INSERT INTO teaches(ID,course_id,batch_id,semester,year,req_grade) VALUES(%s,%s,%s,%s,%s,%s)",
                        (username, course_id, batch_id, semester, year, grade,))
        except Exception as err:
            print(err)
            result = False
        cur.close()
        self.conn.commit()
        return result

    def checkuser(self, _username, passwd):
        cur = self.conn.cursor()
        print(_username)
        cur.execute(
            "SELECT passwd FROM user_account WHERE username=%s", (_username,))
        _passwd = cur.fetchone()
        cur.close()
        if _passwd:
            if _passwd[0] == passwd:
                return 1  # user matches
            else:
                return 2  # password incorrect
        else:
            print("user doesn't exists")
            return 3  # user doesn't exists

    def get_courses(self):
        cur = self.conn.cursor()
        cur.callproc("get_courses_detail")
        courses = cur.fetchall()
        cur.close()
        self.conn.commit()
        return courses

    def get_usertype(self, _username):
        cur = self.conn.cursor()
        cur.execute(
            "SELECT usertype FROM user_account WHERE username=%s", (_username,))
        usertype = cur.fetchone()
        cur.close()
        self.conn.commit()
        return usertype[0]

    def get_course_offering(self):
        cur = self.conn.cursor()
        cur.callproc("get_course_offering_detail")
        courses = cur.fetchall()
        cur.close()
        self.conn.commit()
        return courses

    def get_floated_course(self, username):
        cur = self.conn.cursor()
        cur.callproc("get_floated_course_detail", (username,))
        courses = cur.fetchall()
        cur.close()
        self.conn.commit()
        return courses

    def check_course_registration(self, username, course_ID):
        cur = self.conn.cursor()

        cur.callproc("check_cgpa", (course_ID, username,))
        result = cur.fetchone()
        self.conn.commit()

        if result[0] == 'not allowed':
            result1 = 'LESS CGPA'
            cur.close()
            self.conn.commit()
            return result1
        else:
            cur.callproc("check_course_slot", (course_ID, username,))
            result = cur.fetchone()
            self.conn.commit()

            if result[0] == 'False':
                result1 = 'can not register for the course no time slot'
                cur.close()
                self.conn.commit()
                return result1
            else:
                cur.callproc("check_course_prereq", (course_ID, username,))
                result = cur.fetchone()
                print(result)
                if result[0] == 'False':
                    result1 = 'can not register for the course no prereq'
                    cur.close()
                    self.conn.commit()
                    return result1
                else:
                    cur.close()
                    self.conn.commit()
                    return 'course be registered'

    def add_course(self, username, course_ID):
        cur = self.conn.cursor()
        cur.callproc("add_course", (username, course_ID,))
        cur.close()
        self.conn.commit()
        return

    def get_credit(self, username, course_ID):
        cur = self.conn.cursor()
        cur.callproc("get_credit", (username, course_ID,))
        credit = cur.fetchone()
        cur.close()
        self.conn.commit()
        return credit

    def get_max_credit(self, username):
        cur = self.conn.cursor()
        cur.callproc("get_max_credit", (username,))
        credit = cur.fetchone()
        cur.close()
        self.conn.commit()
        return credit

    def generate_ticket(self, username, course_ID):
        cur = self.conn.cursor()
        cur.callproc("generate_ticket", (username, course_ID,))
        cur.close()
        self.conn.commit()
        return

    def get_ticket_details(self, username):
        cur = self.conn.cursor()
        cur.callproc("get_ticket_detail", (username,))
        courses = cur.fetchall()
        cur.close()
        self.conn.commit()
        return courses

    def get_all_ticket_details(self):
        cur = self.conn.cursor()
        cur.callproc("get_all_ticket_detail")
        courses = cur.fetchall()
        cur.close()
        self.conn.commit()
        return courses

    def get_cgpa(self, username):
        cur = self.conn.cursor()
        cur.callproc("get_cgpa", (username,))
        courses = cur.fetchone()
        cur.close()
        self.conn.commit()
        return courses[0]

    def update_grade(self, ID, course_id, batch_id, grade):
        cur = self.conn.cursor()
        updated_rows = 0
        cur.execute("SELECT EXTRACT(year from now())")
        year = cur.fetchone()
        cur.execute("SELECT EXTRACT(month from now())")
        month = cur.fetchone()
        self.conn.commit()
        if int(month[0]) >= 7:
            semester = 'even'
        else:
            semester = 'odd'
        try:
            cur.execute('''UPDATE takes SET grade=%s WHERE   ID=%s and course_id=%s and batch_id=%s and semester=%s and  year=%s''',
                        (grade, ID, course_id, batch_id, semester, year,))
            updated_rows = cur.rowcount
        except Exception as err:
            print(err)
        cur.close()
        self.conn.commit()
        return updated_rows

    def get_student_courses(self, username):
        cur = self.conn.cursor()
        cur.callproc("get_student_course", (username,))
        courses = cur.fetchall()
        cur.close()
        self.conn.commit()
        return courses

    def remove_ticket(self, username, course_ID, status):
        cur = self.conn.cursor()
        cur.callproc("remove_ticket", (username, course_ID, status,))
        cur.close()
        self.conn.commit()
        return
