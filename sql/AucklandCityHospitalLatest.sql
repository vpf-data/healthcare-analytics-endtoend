CREATE TABLE aucklandpatientslatest
(
	PatientID INT,
	Name VARCHAR(100),
	Gender VARCHAR(100),
	DOB DATE,
	Age INT,
	City VARCHAR(100),
	Town VARCHAR(100),
	TownCategory VARCHAR(100),
	Insurance VARCHAR(100),
	BloodType VARCHAR(100),
	ChronicCondition VARCHAR(100),
	RegistrationDate DATE
)

SELECT * FROM aucklandpatientslatest
WHERE DOB>RegistrationDate

--fixed

CREATE TABLE aucklanddoctorslatest
	(
		DoctorID INT,
		Name VARCHAR(100),
		Speciality VARCHAR(100),
		Department VARCHAR(100),
		ExperienceYears INT,
		City VARCHAR(100),
		Town VARCHAR(100)
	)

SELECT * FROM aucklanddoctorslatest

CREATE TABLE aucklandvisitslatest
(
				PatientID INT,
                DoctorID INT,
                FollowUpDoctorID INT,
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

SELECT * FROM aucklandvisitslatest av
LEFT JOIN aucklandpatientslatest ap
ON av.PatientID = ap.PatientID
WHERE ap.DOB > av.VisitDate

--fixed 











