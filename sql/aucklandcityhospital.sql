CREATE TABLE aucklanddoctors
(
	DoctorID INT,
	Name VARCHAR(100),
	Speciality VARCHAR(100),
	Department VARCHAR(50),
	ExperienceYears INT,
	City VARCHAR(50),
	Town VARCHAR(50)
)

SELECT * FROM aucklanddoctors

CREATE TABLE aucklandpatients
	(
		PatientID INT,
		Name VARCHAR(100),
		Gender VARCHAR(20),
		DOB DATE,
		Age INT,
		City VARCHAR(100),
		Town VARCHAR(50),
		TownCategory VARCHAR(50),
		Insurance VARCHAR(20),
		BloodType VARCHAR(10),
		ChronicCondition VARCHAR(50),
		RegistrationDate DATE
	)


CREATE TABLE aucklandvisits
	(
		PatientID INT,
		DoctorID INT,
		FollowUpDoctorID INT NULL,
		Town VARCHAR(100),
		TownCategory VARCHAR(100),
		Symptom VARCHAR(100),
		Diagnosis VARCHAR(100),
		VisitDate DATE,
		VisitType VARCHAR(100),
		BillingAmount FLOAT,
		InsuranceUsed VARCHAR(100),
		PaymentMethod VARCHAR(100),
		PrescriptionGiven VARCHAR(100),
		FollowUpRequired VARCHAR(100),
		ReadmissionFlag VARCHAR(100),
		VisitDurationMinutes INT,
		VisitID INT
		)


SELECT * FROM aucklanddoctors


SELECT * FROM aucklandpatients

SELECT * FROM aucklandvisits




SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'aucklandvisits'
