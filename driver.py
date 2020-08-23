from flask import Flask, redirect, url_for, render_template, request, session, jsonify, Response
from db.db import Storage
from db.dbHelper import DbHelper
from mongo.mdb import mongoStorage

app = Flask(__name__, static_url_path='/static')
dbhelper = DbHelper()
mongodbhelper = mongoStorage()


@app.route('/')
def home():
    user = session.get('user')
    if user:
        return render_template('home.html', user=user, usertype=dbhelper.get_usertype(user))
    else:
        return render_template('home.html')


@app.route('/login', methods=['POST', 'GET'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if dbhelper.checkuser(username, password) == 1:
            session['user'] = username
            if dbhelper.get_usertype(username) == 'student':
                return redirect(url_for('student'))
            if dbhelper.get_usertype(username) == 'faculty':
                return redirect(url_for('faculty'))
            if dbhelper.get_usertype(username) == 'advisor':
                return redirect(url_for('advisor'))

        if dbhelper.checkuser(username, password) == 2:
            return render_template('login.html', error="Invalid Password")

        if dbhelper.checkuser(username, password) == 3:
            return render_template('login.html', error="ERROR: User Does Not Exists! PLEASE REGISTER")
    else:
        return render_template('login.html')


@app.route('/register/student', methods=['POST', 'GET'])
def register_student():
    if request.method == 'POST':

        username = request.form['username']
        passwd = request.form['password']
        name = request.form['name']
        department = request.form['dept_name']
        batch_id = request.form['batch_id']
        email = request.form['email']
        phone = request.form['phone']
        usertype = 'student'

        result = dbhelper.insertUser(
            username, passwd, name, department, usertype, batch_id)

        if result:
            mongodbhelper.insert(username, usertype, name,
                                 department, phone, email)
            return redirect(url_for('login'))
        else:
            return render_template('register_student.html', error="ERROR: User Already Exists!")
    else:
        return render_template('register_student.html')


@app.route('/register/faculty', methods=['POST', 'GET'])
def register_faculty():
    if request.method == 'POST':
        username = request.form['username']
        passwd = request.form['password']
        name = request.form['name']
        department = request.form['dept_name']
        sec_id = None
        email = request.form['email']
        phone = request.form['phone']
        usertype = 'faculty'
        result = dbhelper.insertUser(
            username, passwd, name, department, usertype, sec_id)
        if result:
            mongodbhelper.insert(username, usertype, name,
                                 department, phone, email)
            return redirect(url_for('login'))
        else:
            return render_template('register_faculty.html', error="ERROR: User Already Exists!")
    else:
        return render_template('register_faculty.html')


@app.route('/register/faculty_advisor', methods=['POST', 'GET'])
def register_faculty_advisor():
    if request.method == 'POST':
        username = request.form['username']
        passwd = request.form['password']
        name = request.form['name']
        department = request.form['dept_name']
        sec_id = None
        email = request.form['email']
        phone = request.form['phone']
        usertype = 'advisor'
        result = dbhelper.insertUser(
            username, passwd, name, department, usertype, sec_id)
        if result:
            mongodbhelper.insert(username, usertype, name,
                                 department, phone, email)
            return redirect(url_for('login'))
        else:
            return render_template('register_advisor.html', error="ERROR: User Already Exists!")
    else:
        return render_template('register_advisor.html')


@app.route('/faculty', methods=['POST', 'GET'])
def faculty():
    user = session.get('user')
    if user:
        if request.method == 'POST':
            info = request.get_json()
            print(info['project'])
            if info:
                mongodbhelper.update(user, info)
            resp = jsonify(success=True)
            return resp
        else:
            x=1
            info = mongodbhelper.get_info(user)
            return render_template('faculty.html', user=user, usertype=info['usertype'],
                                   name=info['name'], email=info['email'], department=info['department'],
                                   phone=info['phone'], project=info['projects'], research=info['research'],x=x)
    else:
        return redirect(url_for('login'))


@app.route('/advisor', methods=['POST', 'GET'])
def advisor():
    user = session.get('user')
    if user:
        if request.method == 'POST':
            info = request.get_json()
            print(info['project'])
            if info:
                mongodbhelper.update(user, info)
            resp = jsonify(success=True)
            return resp
        else:
            info = mongodbhelper.get_info(user)
            return render_template('advisor.html', user=user, usertype=info['usertype'],
                                   name=info['name'], email=info['email'], department=info['department'], phone=info['phone'], project=info['projects'], research=info['research'])
    else:
        return redirect(url_for('login'))


@app.route('/faculty/edit_profile', methods=['POST', 'GET'])
def edit_profile():
    user = session.get('user')
    if user:
        if request.method == 'POST':
            info = request.get_json()
            print(info['project'])
            if info:
                mongodbhelper.update(user, info)
            resp = jsonify(success=True)
            return resp
        else:
            info = mongodbhelper.get_info(user)
            return render_template('edit_profile.html', project=info['projects'], research=info['research'])
    else:
        return redirect(url_for('login'))


@app.route('/faculty/offer_course', methods=['POST', 'GET'])
def offer_course():
    user = session.get('user')
    if user:
        if request.method == 'POST':
            course_id = request.form['course_id']
            batch_id = request.form['batch_id']
            grade = request.form['cgpa']
            if course_id:
                if dbhelper.insert_in_teaches(user, course_id, batch_id, grade):
                    return render_template('offer_course.html',error="Course Offered")
                else:
                    return render_template('offer_course.html', error="Can't offer this Course")
        else:
            return render_template('offer_course.html')
    else:
        return redirect(url_for('login'))


@app.route('/faculty/enter_grade', methods=['POST', 'GET'])
def enter_grade():
    user = session.get('user')
    if user:
        if request.method == 'POST':
            course_id = request.form['course_id']
            ID = request.form['s_id']
            batch_id = request.form['batch_id']
            grade = request.form['grade']
            if dbhelper.update_grade(ID, course_id, batch_id, grade) == 1:
                return render_template('enter_grade.html', error='Updated')
            else:
                return render_template('enter_grade.html', error='Invalid Details')
        else:
            return render_template('enter_grade.html')
    else:
        return redirect(url_for('login'))


@app.route('/student/course_registration', methods=['POST', 'GET'])
def course_registration():
    user = session.get('user')
    if request.method == 'POST':
        info = request.get_json()
        result = dbhelper.check_course_registration(user, info['course_id'])

        if result == 'course be registered':
            max_credit = dbhelper.get_max_credit(user)
            user_credit = dbhelper.get_credit(user, info['course_id'])
            if user_credit > max_credit:
                result = 'Credit limit exceeded ,TICKET generated by the system'
                dbhelper.generate_ticket(user, info['course_id'])
                return result
            else:
                result = 'Coursed Registered'
                dbhelper.add_course(user, info['course_id'])
            return result
        if result == 'can not register for the course no time slot':
            resp = 'can not register for the course no time slot'
            return resp
        if result == 'can not register for the course no prereq':
            resp = 'can not register for the course , Prerequisite is not cleared'
            return resp
        if result == 'LESS CGPA':
            resp = 'can not register for the course ,LESS CGPA '
            return resp
    else:
        user = session.get('user')
        course = dbhelper.get_floated_course(user)
        return render_template('course_registration.html', course=course)


@app.route('/advisor/ticket_approval', methods=['POST', 'GET'])
def ticket_approval():
    if request.method == 'POST':
        info = request.get_json()
        print(info)
        if info['status'] == 'add':
            status = 1
            dbhelper.add_course(info['id'], info['course_id'])
            dbhelper.remove_ticket(info['id'], info['course_id'], status)
            print('hello')
            return 'Approved'
        else:
            status = 2
            dbhelper.remove_ticket(info['id'], info['course_id'], status)
            return 'Rejected'
    else:
        course = dbhelper.get_all_ticket_details()
        return render_template('ticket_approval.html', course=course)


@app.route('/student/ticket_status', methods=['POST', 'GET'])
def ticket_status():
    if request.method == 'POST':
        info = request.get_json()
        # result = dbhelper.checkcourse_registration(info[])
        print(info['course_id'])
        resp = jsonify(success=True)
        return resp
    else:
        user = session.get('user')
        course = dbhelper.get_ticket_details(user)
        return render_template('ticket_status.html', course=course)


@app.route('/student', methods=['POST', 'GET'])
def student():
    user = session.get('user')
    info = mongodbhelper.get_info(user)
    course = dbhelper.get_student_courses(user)
    cgpa = dbhelper.get_cgpa(user)
    print(cgpa)
    return render_template('student.html', user=user, usertype=info['usertype'],
                           name=info['name'], email=info['email'], department=info['department'],
                           phone=info['phone'], course=course, cgpa=round(cgpa, 2))


@app.route('/courses')
def courses():
    course = dbhelper.get_courses()
    try:
        return render_template('courses.html', usertype=dbhelper.get_usertype(session['user']), course=course)
    except Exception:
        return render_template('courses.html', usertype='guest', course=course)


@app.route('/student/course_offering')
def course_offering():
    course = dbhelper.get_course_offering()
    print(course)
    return render_template('course_offering.html', course=course)


@app.route('/faculty/profile/<id>')
def profile(id):
    try:
        x=0
        info = mongodbhelper.get_info(id)
        return render_template('faculty.html', user=id, usertype=info['usertype'],
                           name=info['name'], email=info['email'], department=info['department'],
                           phone=info['phone'], project=info['projects'], research=info['research'],x=x)
    except Exception :
        return "Invalid Username!"


@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect(url_for('home'))


if __name__ == '__main__':
    app.secret_key = '32f607a8a551499b9fda0bb8175cbdbc'
    app.run(debug=True, host='0.0.0.0')
