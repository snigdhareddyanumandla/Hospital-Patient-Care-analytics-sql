create database hospital_analytics;
use hospital_analytics;

CREATE TABLE patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    patient_name VARCHAR(100),
    age INT,
    gender VARCHAR(20),
    city VARCHAR(50),
    patient_type VARCHAR(30),
    preferred_time_slot VARCHAR(30),
    registration_date DATE
);

CREATE TABLE doctors (
    doctor_id VARCHAR(10) PRIMARY KEY,
    doctor_name VARCHAR(100),
    specialty VARCHAR(100),
    hire_date DATE,
    rating DECIMAL(3,2),
    employment_type VARCHAR(30),
    is_active VARCHAR(10)
);

CREATE TABLE rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    room_type VARCHAR(50),
    floor INT,
    equipment_type VARCHAR(50),
    capacity INT,
    last_maintenance_date DATE,
    is_available VARCHAR(10)
);

CREATE TABLE appointments (
    appointment_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    appointment_date DATE,
    doctor_id VARCHAR(10),
    service_type VARCHAR(50),
    priority VARCHAR(30),
    estimated_cost DECIMAL(10,2),
    booking_channel VARCHAR(30),

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id),

    FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
);

CREATE TABLE treatments (
    treatment_id VARCHAR(10) PRIMARY KEY,
    appointment_id VARCHAR(10),
    doctor_id VARCHAR(10),
    room_id VARCHAR(10),
    actual_treatment_date DATE,
    status VARCHAR(30),
    treatment_attempt INT,
    treatment_duration_min INT,
    waiting_time_min INT,
    treatment_cost DECIMAL(10,2),

    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id),

    FOREIGN KEY (room_id)
        REFERENCES rooms(room_id)
);

show tables;

-- Basic Analysis / Data Exploration
-- 1. What is the total number of patients?
select count(*) as total_patients from patients;

-- 2. What is the total number of appointments?
select count(*) as total_appoinments from appointments;

-- 3. What is the total number of treatment records?
select count(*) as total_treatments from treatments;

-- 4. What are the different medical service types?
select distinct service_type from appointments;

-- 5. How many doctors are currently active?
select count(*) is_active
from doctors
where is_active = 'yes';

-- 6. What are the different room types?
select distinct room_type from rooms;

-- 7. What is the total estimated appointment value?
select sum(estimated_cost)
from appointments;

-- 8. What is the average treatment duration?
select avg(treatment_duration_min) as treatment_duration
from treatments;

-- Sprint 4: Objective-Based Analysis
-- 4.1 Understand Patient and Appointment Demand
-- Compare appointment volume across cities.

select 
p.city,
count(a.appointment_id) as appointment_count
from patients p
join appointments a
on p.patient_id = a.patient_id
group by city
order by appointment_count desc;

-- Compare appointments across service types and priorities.
select 
service_type,
count(appointment_id) as appointment_count
from appointments
group by service_type
order by appointment_count desc;

select 
priority,
count(appointment_id) as appointment_count
from appointments
group by priority
order by appointment_count desc;

-- Examine appointment volume over time.
select
appointment_date,
count(appointment_id) as appointment_count
from appointments
group by appointment_date
order by appointment_date;

-- Compare estimated appointment value across patient types.
SELECT
    p.patient_type,
    SUM(a.estimated_cost) AS total_estimated_value
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.patient_type
ORDER BY total_estimated_value DESC;

-- Examine booking channels and their contribution to demand.
SELECT
    booking_channel,
    COUNT(appointment_id) AS appointment_count
FROM appointments
GROUP BY booking_channel
ORDER BY appointment_count DESC;

/* INSIGHT:
Overall, the analysis highlights differences in patient demand across cities,
 medical services, priority levels, time periods, patient types, and booking channels.
 These findings can help hospital management improve resource allocation, staffing, scheduling,
 and appointment capacity based on actual demand patterns.
 */

-- 4.2 Understand Patient Appointment Behaviour
-- Compare patients by number of appointments.
SELECT
    patient_id,
    COUNT(appointment_id) AS appointment_count
FROM appointments
GROUP BY patient_id
ORDER BY appointment_count DESC; 

-- Identify patients with higher cumulative estimated appointment value.

SELECT
    patient_id,
    SUM(estimated_cost) AS cumulative_estimated_value
FROM appointments
GROUP BY patient_id
ORDER BY cumulative_estimated_value DESC;

-- Compare patient activity across cities.
SELECT
    p.city,
    COUNT(a.appointment_id) AS appointment_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.city
ORDER BY appointment_count DESC;

-- Compare General, Corporate, and Insurance patients.
SELECT
    p.patient_type,
    COUNT(a.appointment_id) AS appointment_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
WHERE p.patient_type IN ('General', 'Corporate', 'Insurance')
GROUP BY p.patient_type
ORDER BY appointment_count DESC;

-- Examine patient booking patterns over time.
SELECT
    YEAR(appointment_date) AS year,
    MONTH(appointment_date) AS month,
    COUNT(appointment_id) AS appointment_count
FROM appointments
GROUP BY
    YEAR(appointment_date),
    MONTH(appointment_date)
ORDER BY
    year,
    month;

/* INSIGHT:
Overall, patient behaviour analysis helps identify highly active patients,
 high-value patient segments, geographic differences, and changes in booking behaviour over time. 
 These insights can support patient engagement, scheduling, and service planning decisions.
 */
    
-- 4.3 Evaluate Treatment Performance
-- Compare treatment outcomes across cities.
SELECT
    p.city,
    t.status,
    COUNT(t.treatment_id) AS treatment_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY
    p.city,
    t.status
ORDER BY
    p.city,
    treatment_count DESC;
    
-- Examine treatment duration and waiting time.
SELECT
    a.service_type,
    ROUND(AVG(t.treatment_duration_min), 2)
        AS avg_treatment_duration,
    ROUND(AVG(t.waiting_time_min), 2)
        AS avg_waiting_time
FROM appointments a
JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY a.service_type
ORDER BY avg_waiting_time DESC;

-- Compare Completed, Cancelled, No-Show, Rescheduled, and In Progress outcomes.
SELECT
    status,
    COUNT(treatment_id) AS treatment_count
FROM treatments
GROUP BY status
ORDER BY treatment_count DESC;

-- Identify areas with higher treatment activity or poorer outcomes.
SELECT
    p.city,
    COUNT(t.treatment_id) AS total_treatments,
    SUM(
        CASE
            WHEN t.status IN ('Cancelled', 'No-Show', 'Rescheduled')
            THEN 1
            ELSE 0
        END
    ) AS problem_treatments
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY p.city
ORDER BY problem_treatments DESC;

-- Compare treatment performance over time.
SELECT
    YEAR(actual_treatment_date) AS year,
    MONTH(actual_treatment_date) AS month,
    COUNT(treatment_id) AS treatment_count
FROM treatments
GROUP BY
    YEAR(actual_treatment_date),
    MONTH(actual_treatment_date)
ORDER BY
    year,
    month;
-- Add treatment outcomes
SELECT
    YEAR(actual_treatment_date) AS year,
    MONTH(actual_treatment_date) AS month,
    status,
    COUNT(treatment_id) AS treatment_count
FROM treatments
GROUP BY
    YEAR(actual_treatment_date),
    MONTH(actual_treatment_date),
    status
ORDER BY
    year,
    month,
    status;

/* INSIGHT:
Overall,treatment performance analysis helps the hospital understand treatment outcomes,
 waiting times, treatment duration, geographic differences, and changes in performance over time.
 These findings can support improvements in scheduling, staffing, and treatment operations.
 */

    
-- 4.4 Understand Doctor and Room Performance
-- Compare the number of treatments handled by doctors.
SELECT
    d.doctor_id,
    d.doctor_name,
    COUNT(t.treatment_id) AS treatment_count
FROM doctors d
JOIN treatments t
    ON d.doctor_id = t.doctor_id
GROUP BY
    d.doctor_id,
    d.doctor_name
ORDER BY treatment_count DESC;	

-- Compare doctor performance across treatment outcomes.
SELECT
    d.doctor_name,
    t.status,
    COUNT(t.treatment_id) AS treatment_count
FROM doctors d
JOIN treatments t
    ON d.doctor_id = t.doctor_id
GROUP BY
    d.doctor_name,
    t.status
ORDER BY
    d.doctor_name,
    treatment_count DESC;

-- Examine treatment duration across doctors.
SELECT
    d.doctor_name,
    COUNT(t.treatment_id) AS treatment_count,
    ROUND(AVG(t.treatment_duration_min), 2)
        AS avg_treatment_duration
FROM doctors d
JOIN treatments t
    ON d.doctor_id = t.doctor_id
GROUP BY
    d.doctor_id,
    d.doctor_name
ORDER BY avg_treatment_duration DESC;

-- Compare room usage across room types and equipment types.
SELECT
    r.room_type,
    r.equipment_type,
    COUNT(t.treatment_id) AS treatment_count
FROM rooms r
JOIN treatments t
    ON r.room_id = t.room_id
GROUP BY
    r.room_type,
    r.equipment_type
ORDER BY treatment_count DESC;

-- Evaluate treatment performance across rooms.
SELECT
    r.room_id,
    r.room_type,
    r.equipment_type,
    COUNT(t.treatment_id) AS treatment_count,
    ROUND(AVG(t.treatment_duration_min), 2)
        AS avg_duration,
    ROUND(AVG(t.waiting_time_min), 2)
        AS avg_waiting_time
FROM rooms r
JOIN treatments t
    ON r.room_id = t.room_id
GROUP BY
    r.room_id,
    r.room_type,
    r.equipment_type
ORDER BY treatment_count DESC;

/*  INSIGHT:
Overall, doctor and room analysis highlights differences in workload,
 treatment outcomes, treatment duration, and facility utilization.
 These insights can help hospital management improve workload balancing, 
 room allocation, and resource utilization.
*/ 

-- 4.5 Identify Treatment and Appointment Problems
-- Identify appointments requiring multiple treatment attempts.
SELECT
    appointment_id,
    COUNT(treatment_id) AS treatment_attempts
FROM treatments
GROUP BY appointment_id
HAVING COUNT(treatment_id) > 1
ORDER BY treatment_attempts DESC;

-- Find common problem statuses and patterns.
SELECT
    status,
    COUNT(*) AS status_count
FROM treatments
WHERE status IN
    ('Cancelled', 'No-Show', 'Rescheduled')
GROUP BY status
ORDER BY status_count DESC;

-- Compare waiting time for appointments with multiple attempts.
SELECT
    t.appointment_id,
    COUNT(t.treatment_id) AS treatment_attempts,
    ROUND(AVG(t.waiting_time_min), 2) AS avg_waiting_time
FROM treatments t
GROUP BY t.appointment_id
HAVING COUNT(t.treatment_id) > 1
ORDER BY treatment_attempts DESC;

-- Identify cities or service types with more cancellations, no-shows, or rescheduling.
SELECT
    p.city,
    t.status,
    COUNT(t.treatment_id) AS problem_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
WHERE t.status IN
    ('Cancelled', 'No-Show', 'Rescheduled')
GROUP BY
    p.city,
    t.status
ORDER BY
    problem_count DESC;

-- Investigate whether priority level is associated with waiting time or treatment outcomes.
SELECT
    p.city,
    t.status,
    COUNT(t.treatment_id) AS problem_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
WHERE t.status IN
    ('Cancelled', 'No-Show', 'Rescheduled')
GROUP BY
    p.city,
    t.status
ORDER BY
    problem_count DESC;

/* INSIGHT:
Overall, the problem analysis identifies repeated treatment attempts,
 problematic appointment statuses, waiting-time differences, geographic and 
 service-level issues, and relationships between priority and treatment outcomes. 
 These findings can help hospital management identify operational bottlenecks and areas requiring further investigation.
 */



