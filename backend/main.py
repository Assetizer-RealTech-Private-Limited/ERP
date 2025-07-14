from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pymongo import MongoClient
from datetime import datetime, timedelta
import requests
import urllib.parse
import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Database setup
username = "appuser"
password = urllib.parse.quote_plus("appuser123")
uri = f"mongodb+srv://{username}:{password}@mongodb.yqlyram.mongodb.net/attendance_db?retryWrites=true&w=majority"


client = MongoClient(uri)
db = client["attendance_db"]
employee_collection = db["employees"]
log_collection = db["logs"]
request_collection = db["requests"]

# Pydantic models
class EmployeeLogin(BaseModel):
    email: str
    password: str

class CheckRequest(BaseModel):
    emp_id: str

class AddEmployee(BaseModel):
    name: str
    email: str
    password: str

class ChangePasswordRequest(BaseModel):
    emp_id: str
    new_password: str

class ForgotPassword(BaseModel):
    email: str

class VerifyOTP(BaseModel):
    email: str
    otp: str

class ResetPassword(BaseModel):
    email: str
    new_password: str

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_location_from_ip(ip):
    try:
        response = requests.get(f"http://ip-api.com/json/{ip}")
        data = response.json()
        if data["status"] == "success":
            return f"{data['city']}, {data['regionName']}, {data['country']}"
    except:
        pass
    return "Unknown"

@app.post("/login")
def login(data: EmployeeLogin):
    user = employee_collection.find_one({"email": data.email})
    if not user or user["password"] != data.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {
        "message": "Login successful", 
        "emp_id": user["emp_id"],
        "role": user["role"],
        "name": user["name"]
    }

@app.post("/checkin")
def checkin(data: CheckRequest, request: Request):
    ip_address = request.client.host
    location = get_location_from_ip(ip_address)
    
    # Check if user already checked in today
    today = datetime.now().strftime("%Y-%m-%d")
    existing_log = log_collection.find_one({
        "emp_id": data.emp_id,
        "date": today,
        "action": "checkin"
    })
    
    if existing_log:
        return {"message": "Already checked in today", "ip": ip_address, "location": location}
    
    log_collection.insert_one({
        "emp_id": data.emp_id,
        "action": "checkin",
        "timestamp": datetime.now(),
        "date": today,
        "ip_address": ip_address,
        "location": location
    })
    return {"message": "Check-in recorded", "ip": ip_address, "location": location}

@app.post("/checkout")
def checkout(data: CheckRequest, request: Request):
    ip_address = request.client.host
    location = get_location_from_ip(ip_address)
    
    # Check if user already checked out today
    today = datetime.now().strftime("%Y-%m-%d")
    existing_checkout = log_collection.find_one({
        "emp_id": data.emp_id,
        "date": today,
        "action": "checkout"
    })
    
    if existing_checkout:
        return {"message": "Already checked out today", "ip": ip_address, "location": location}
    
    log_collection.insert_one({
        "emp_id": data.emp_id,
        "action": "checkout",
        "timestamp": datetime.now(),
        "date": today,
        "ip_address": ip_address,
        "location": location
    })
    return {"message": "Check-out recorded", "ip": ip_address, "location": location}

@app.get("/attendance/{emp_id}")
def get_attendance(emp_id: str):
    # Get last 30 days attendance
    thirty_days_ago = datetime.now() - timedelta(days=30)
    
    logs = list(log_collection.find({
        "emp_id": emp_id,
        "timestamp": {"$gte": thirty_days_ago}
    }).sort("timestamp", -1))
    
    # Group by date
    attendance_records = {}
    for log in logs:
        date = log.get("date", "Unknown Date")
        if date not in attendance_records:
            attendance_records[date] = {
                "date": date,
                "check_in": None,
                "check_out": None,
                "location": None,
                "ip_address": None
            }
        
        if log["action"] == "checkin":
            attendance_records[date]["check_in"] = log["timestamp"].strftime("%H:%M:%S")
            attendance_records[date]["location"] = log["location"]
            attendance_records[date]["ip_address"] = log["ip_address"]
        elif log["action"] == "checkout":
            attendance_records[date]["check_out"] = log["timestamp"].strftime("%H:%M:%S")
    
    return {"records": list(attendance_records.values())}

@app.get("/employees")
def get_employees():
    employees = list(employee_collection.find({}, {"password": 0}))
    for emp in employees:
        emp["_id"] = str(emp["_id"])
    return {"employees": employees}

@app.post("/add_employee")
def add_employee(data: AddEmployee):
    # Generate employee ID
    last_emp = employee_collection.find().sort("emp_id", -1).limit(1)
    last_emp_list = list(last_emp)
    
    if last_emp_list:
        last_id = int(last_emp_list[0]["emp_id"][1:])
        new_id = f"E{last_id + 1:03d}"
    else:
        new_id = "E001"
    
    employee_collection.insert_one({
        "emp_id": new_id,
        "name": data.name,
        "email": data.email,
        "password": data.password,
        "role": "employee"
    })
    
    return {"message": "Employee added successfully", "emp_id": new_id}

@app.get("/requests")
def get_requests():
    requests = list(request_collection.find({}))
    for req in requests:
        req["_id"] = str(req["_id"])
    return {"requests": requests}

@app.post("/admin/change_password")
def admin_change_password(data: ChangePasswordRequest):
    user = employee_collection.find_one({"emp_id": data.emp_id})
    if not user:
        raise HTTPException(status_code=404, detail="Employee not found")
    
    employee_collection.update_one(
        {"emp_id": data.emp_id},
        {"$set": {"password": data.new_password}}
    )
    
    return {"message": "Password changed successfully by admin"}

# Store OTPs temporarily (in production, use Redis or database)
otp_storage = {}

def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

def send_otp_email(to_email: str, otp: str):
    try:
        # Email configuration
        from_email = "tiwariyash999@gmail.com"
        from_password = "your_app_password"  # Use App Password for Gmail
        
        # Create message
        msg = MIMEMultipart()
        msg['From'] = from_email
        msg['To'] = to_email
        msg['Subject'] = "Password Reset OTP - Assetizer Realtech"
        
        # Email body
        body = f"""
        Dear Employee,
        
        Your OTP for password reset is: {otp}
        
        This OTP is valid for 10 minutes only.
        
        If you did not request this OTP, please ignore this email.
        
        Best regards,
        Assetizer Realtech Team
        """
        
        msg.attach(MIMEText(body, 'plain'))
        
        # Gmail SMTP configuration
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(from_email, from_password)
        text = msg.as_string()
        server.sendmail(from_email, to_email, text)
        server.quit()
        
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

@app.post("/forgot_password")
def forgot_password(data: ForgotPassword):
    user = employee_collection.find_one({"email": data.email})
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    
    # Generate OTP
    otp = generate_otp()
    
    # Store OTP with email (expires in 10 minutes)
    otp_storage[data.email] = {
        "otp": otp,
        "expires": datetime.now() + timedelta(minutes=10)
    }
    
    # Send OTP via email
    email_sent = send_otp_email(data.email, otp)
    
    if email_sent:
        return {"message": "OTP sent to your email address"}
    else:
        # Fallback for development - show OTP in response if email fails
        return {"message": "OTP generated (email failed)", "otp": otp}

@app.post("/verify_otp")
def verify_otp(data: VerifyOTP):
    if data.email not in otp_storage:
        raise HTTPException(status_code=400, detail="No OTP found for this email")
    
    stored_otp = otp_storage[data.email]
    
    # Check if OTP expired
    if datetime.now() > stored_otp["expires"]:
        del otp_storage[data.email]
        raise HTTPException(status_code=400, detail="OTP expired")
    
    # Check if OTP matches
    if data.otp != stored_otp["otp"]:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    
    # OTP is valid
    return {"message": "OTP verified successfully"}

@app.post("/reset_password")
def reset_password(data: ResetPassword):
    user = employee_collection.find_one({"email": data.email})
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    
    # Update password
    employee_collection.update_one(
        {"email": data.email},
        {"$set": {"password": data.new_password}}
    )
    
    # Clear OTP storage for this email
    if data.email in otp_storage:
        del otp_storage[data.email]
    
    return {"message": "Password reset successfully"}

@app.delete("/remove_employee/{emp_id}")
def remove_employee(emp_id: str):
    # Check if employee exists
    user = employee_collection.find_one({"emp_id": emp_id})
    if not user:
        raise HTTPException(status_code=404, detail="Employee not found")
    
    # Don't allow removing admin users
    if user.get("role") == "admin":
        raise HTTPException(status_code=403, detail="Cannot remove admin user")
    
    # Remove employee
    employee_collection.delete_one({"emp_id": emp_id})
    
    # Optionally remove their attendance logs
    # log_collection.delete_many({"emp_id": emp_id})
    
    return {"message": "Employee removed successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
