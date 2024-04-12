import psutil
import subprocess
import smtplib
from email.message import EmailMessage
import datetime
import os

alert_email = "aTestEmail225@gmail.com"
high_load_threshold = 0.75
critical_path = "/var/log/auth.log"
failed_login_threshold = 3

def send_alert(subject, message):
    msg = EmailMessage()
    msg.set_content(message)
    msg['Subject'] = subject
    msg['From'] = "System Alert"
    msg['To'] = alert_email

    server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    server.login("email", "password")
    server.send_message(msg)
    server.quit()

def log_message(message):
    with open(critical_path, "a") as log_file:
        log_file.write(f"{datetime.datetime.now()} - {message}\n")

def system_info():
    try:
        hostname = subprocess.getoutput("hostname")
        os_info = subprocess.getoutput("lsb_release -d").split(":")[1].strip()
    except IndexError:
        with open("/etc/os-release") as f:
            lines = f.readlines()
        os_info_line = next((line for line in lines if line.startswith("PRETTY_NAME")), "PRETTY_NAME=Unknown")
        os_info = os_info_line.split("=")[1].strip().strip('"')

    kernel = subprocess.getoutput("uname -r")
    uptime = subprocess.getoutput("uptime -p")
    return hostname, os_info, kernel, uptime


def cpu_load():
    load1, load5, load15 = os.getloadavg()
    cpu_usage = (load1/os.cpu_count()) * 100
    if cpu_usage > high_load_threshold:
        send_alert("High CPU Load Alert", f"CPU Load is high: {cpu_usage}%")
    return load1, load5, load15, cpu_usage

def disk_usage():
    usage = psutil.disk_usage('/')
    return usage.percent

def memory_usage():
    memory = psutil.virtual_memory()
    return memory.total, memory.used, memory.free, memory.percent

def main():
    hostname, os_info, kernel, uptime = system_info()
    print(f"Hostname: {hostname}\nOS: {os_info}\nKernel: {kernel}\nUptime: {uptime}")
    
    load1, load5, load15, cpu_usage = cpu_load()
    print(f"CPU Load (1/5/15 min): {load1}, {load5}, {load15} - Usage: {cpu_usage}%")
    
    disk_percent = disk_usage()
    print(f"Disk Usage: {disk_percent}%")
    
    total_mem, used_mem, free_mem, mem_usage = memory_usage()
    print(f"Memory Total: {total_mem} - Used: {used_mem} - Free: {free_mem} - Usage: {mem_usage}%")

if __name__ == "__main__":
    main()
