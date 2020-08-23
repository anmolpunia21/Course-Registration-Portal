import pymongo

class mongoStorage:
    def __init__(self):
        self.connect()

    def connect(self):
        try:
            myclient=pymongo.MongoClient("mongodb://localhost:27017/")
            self.mydb = myclient["faculty_project"]
            print("mongo connected")
        except Exception as err:
            print(err)
       
        
    def insert(self, username, usertype, name, department, phone, email):
        users = self.mydb["userinfo"]
        mydict = { "username":username,"usertype": usertype,"name":name,"department":department,"phone":phone,"email":email,"projects": '',"research":''}
        users.delete_one({"username":username})
        users.insert_one(mydict)

    def update(self,_username,info):
        users = self.mydb["userinfo"]
        users.update_one({'username':_username},{ "$set": {'projects' : info['project']}})
        users.update_one({'username':_username},{ "$set": {'research':info['research']}})

    def get_info(self,_username):
        users = self.mydb["userinfo"]
        info = users.find_one({"username":_username})
        return info