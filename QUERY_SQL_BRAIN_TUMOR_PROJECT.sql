use mini_project;
show tables; 
select * from brain_tumor_treatments;
select * from brain_tumor_genomics;
select * from brain_tumor_imaging;
select * from brain_tumor_patients;
select * from brain_tumor_trials;
-- link -----
-- brain_tumor_treatments -------- treatment_id (pk)  , patient_id(fk)
-- brain_tumor_genomics-----------speciman _id(pk)  , patient_id(fk)
-- brain_tumor_imaging---------- study_id(pk) , patient_id(fk)
-- brain_tumor_patients--------patient_id(pk)
-- brain_tumor_trials --------- trialrecord_id(pk) , patient_id(fk)


-- Domain: Brain Tumour Healthcare & Research Analytics Queries--

-- 1.For each tumor type, rank patients by survival_months in descending order.Display patient_id,
-- tumor_type, survival_months, and RANK().
select
 patient_id, tumor_type, survival_months, rank_patient 
from(
select
 p.patient_id,
 p.tumor_type,
 t.survival_months,
 rank() over (partition by p.tumor_type order by survival_months DESC) as rank_patient
 from brain_tumor_patients  p 
 join brain_tumor_treatments t on p.patient_id = t.patient_id
 ) t;

-- 2.	Identify the top 3 patients per tumor type based on survival using DENSE_RANK().
select 
patient_id,tumor_type,survival_months 
from(
select
p.patient_id,
p.tumor_type,
t.survival_months,
dense_rank() over (partition by p.tumor_type order by t.survival_months ) dense_rank_patient
 from brain_tumor_patients  p 
 join brain_tumor_treatments t on p.patient_id = t.patient_id 
) temp
where dense_rank_patient<= 3;

-- 3. For each hospital, assign a sequential number to patients based on diagnosis_date using ROW_NUMBER().
select
 patient_id, hospital , diagnosis_date ,
row_number() over (partition by hospital order by diagnosis_date) as sequential_number
from brain_tumor_patients;

-- 4 .Divide patients into quartiles (NTILE 4) based on radiomic_score and show which
-- quartile each patient falls into.
 select
 patient_id , radiomic_score,
 ntile(4)over (order by radiomic_score DESC) AS quartiles
 from brain_tumor_imaging;
 
-- 5 .Compute the average survival_months per tumor type, but also show each patient’s survival alongside
-- that average using AVG() OVER (PARTITION BY ...).
select 
patient_id,tumor_type,survival_months ,average_survival_months 
from(
select
 p.patient_id,
 p.tumor_type,
 t.survival_months,
avg(survival_months) over (partition by tumor_type ) as average_survival_months 
from  brain_tumor_patients  p 
join brain_tumor_treatments t 
on p.patient_id = t.patient_id ) t;

-- Section B – GROUP BY vs PARTITION BY (Clear Contrast)--

-- 6.	Using GROUP BY, calculate the average tumor volume per tumor type.Then rewrite the query using AVG() 
-- OVER (PARTITION BY tumor_type) to retain patient-level rows. using group by

select
p.tumor_type ,
avg(i.tumor_volume_cc) as avg_tumor_volume
from brain_tumor_patients  p 
join brain_tumor_imaging i on  p.patient_id = i.patient_id
group by p.tumor_type; 

-- using partition by --
select tumor_type , tumor_volume , avg_tumor_volume
from (
select
p.tumor_type ,
i.tumor_volume_cc as tumor_volume,
avg(i.tumor_volume_cc) over (partition by p.tumor_type ) as avg_tumor_volume
from brain_tumor_patients  p 
join brain_tumor_imaging i on  p.patient_id = i.patient_id) t;

-- 7.	For each patient, display:
-- o	tumor_type
-- o	survival_months
-- o	maximum survival within the same tumor type (using window function)

select 
tumor_type , survival_months , maximum_survival 
from (
select 
p.tumor_type ,
t.survival_months , 
max(t.survival_months) over (partition by p.tumor_type) as maximum_survival
from  brain_tumor_patients  p 
join brain_tumor_treatments t 
on p.patient_id = t.patient_id ) t;

-- 8.	Show the total number of patients per hospital using GROUP BY, and alongside each row show the overall
-- patient count using COUNT() OVER().
-- group by -- 
select
 hospital, count(*) as total_patient
from brain_tumor_patients
group by hospital ;

-- partition by -- 
select 
count(*) over (partition by hospital ) as hospitals_total_pasents
from brain_tumor_patients;

-- Section C – JOINs + Window Functions (Core Analytical Skills)--

-- 9.	Join patients, treatments, and genomics tables.
-- Rank patients within each tumor type by immune_biomarker_score.

select 
patient_id , tumor_type , immune_biomarker_score, Rank_of_patient
from(
select 
t.patient_id,
p.tumor_type ,
g.immune_biomarker_score,
RANK() OVER(PARTITION BY p.tumor_type ORDER BY g.immune_biomarker_score) AS  Rank_of_patient
FROM brain_tumor_patients p 
join brain_tumor_treatments t  on p.patient_id = t.patient_id
join brain_tumor_genomics g on p.patient_id = g.patient_id)t;

-- 10.	Join patients and imaging tables.
-- For each tumor type, calculate the average radiomic_score and show each patient’s deviation from it.

SELECT
    p.tumor_type,
    i.radiomic_score,
    AVG(i.radiomic_score) OVER (PARTITION BY p.tumor_type) AS avg_radiomic_score,
    i.radiomic_score 
      - AVG(i.radiomic_score) OVER (PARTITION BY p.tumor_type) AS deviation_score
FROM brain_tumor_patients p
JOIN brain_tumor_imaging i
    ON p.patient_id = i.patient_id;
    
-- 11.	Using patients + treatments, find the latest treatment per patient using ROW_NUMBER().
select 
patient_id ,
treatment_date , 
treatment_type,
row_num
from
(
	select 
	p.patient_id,
	t.end_date as treatment_date , 
	t.treatment_type , 
	row_number() over(partition by p.patient_id  order by t.end_date DESC) AS row_num
	from  brain_tumor_patients p
	JOIN brain_tumor_treatments t
    ON p.patient_id = t.patient_id)t 
where row_num = 1;

-- 12.	Join patients + clinical_trials and rank patients by trial phase priority within each tumor type.
select 
patient_id ,
tumor_type ,
trial_phase,
dense_rank() over (partition by tumor_type order by priority DESC) AS rank_of_patient
from
(
	select
	p.patient_id,
	p.tumor_type ,
	t.trial_phase ,
	case 
	when t.trial_phase = 'Phase I' then 1
	when t.trial_phase = 'Phase II' then 2
	when t.trial_phase = 'Phase III' then 3
	when t.trial_phase = 'Phase IV' then 4
	ELSE 0
	end as priority
	from  brain_tumor_patients p
	JOIN brain_tumor_trials t
		ON p.patient_id = t.patient_id)t;
    
 select trial_phase , count(*) as total  from brain_tumor_trials group by  trial_phase; 
 
 -- Section D – Time-based & Research-oriented Analysis--
 
 
 -- 13.	Using JOINs, calculate the cumulative survival_months per tumor type ordered by diagnosis_date.
 
 
 select 
 p.tumor_type ,
 p.diagnosis_date ,
 sum(t.survival_months) over (partition by  p.tumor_type order by p.diagnosis_date ) AS cumulative_survival_months
 from  brain_tumor_patients p
JOIN brain_tumor_treatments t
    ON p.patient_id = t.patient_id; 
    
    
-- 14.	For each hospital, compute a running total of enrolled clinical trial patients over time.
SELECT 
hospital ,
sum(exact_enroll) over (partition by hospital order by enroll_date ) as running_total_enrolled
from
(
	select
	p.hospital,
	t.enroll_date,
	case 
	when t.enrolled = 'TRUE' THEN 1
	ELSE 0
	END AS exact_enroll
	from brain_tumor_patients p
	JOIN brain_tumor_trials t
    ON p.patient_id = t.patient_id) t; 
    
    
-- 15.	Compare average survival of patients enrolled in trials vs not enrolled, grouped by tumor type.
select
p.tumor_type,
avg(CASE when t.enrolled = 'TRUE' THEN r.survival_months END ) AS avg_survival_trial,
avg(case when t.enrolled = 'FALSE' then r.survival_months end) as avg_survival_nontrial
 from brain_tumor_patients p
JOIN brain_tumor_trials t
    ON p.patient_id = t.patient_id
JOIN brain_tumor_treatments r
    ON p.patient_id = r.patient_id
group by p.tumor_type;


-- Section E – Views & Reusable Research Insights--


-- 16.	Create a VIEW showing only Glioblastoma (GBM) patients who received Immunotherapy or Targeted Therapy,
--  including survival and biomarker details.
CREATE VIEW gbm_patient as 
select
p.tumor_type ,
t.treatment_type ,
t.survival_months,
g.immune_biomarker_score 
from brain_tumor_patients p
JOIN brain_tumor_genomics g
    ON p.patient_id = g.patient_id
JOIN brain_tumor_treatments t
    ON p.patient_id = t.patient_id
where p.tumor_type = 'Glioblastoma (GBM)' and t.treatment_type in ('Immunotherapy' , 'Targeted Therapy');
-- drop view gbm_patient;
select * from gbm_patient;


-- 17.	Replace the above VIEW to include radiomic_score and tumor volume from imaging data.
create or replace view gbm_patient as 
select
p.tumor_type ,
t.treatment_type ,
t.survival_months,
g.immune_biomarker_score ,
i.radiomic_score,
i.tumor_volume_cc
from brain_tumor_patients p
JOIN brain_tumor_genomics g
    ON p.patient_id = g.patient_id
JOIN brain_tumor_treatments t
    ON p.patient_id = t.patient_id
JOIN brain_tumor_imaging i
    ON p.patient_id = i.patient_id
where p.tumor_type = 'Glioblastoma (GBM)' and t.treatment_type in ('Immunotherapy' , 'Targeted Therapy');
select * from gbm_patient;
-- 18.	Drop the view once analysis is complete.
drop view gbm_patient;

-- Section F – Advanced Ranking & Decision Support--


-- 19.	For each tumor type, identify the best performing treatment based on average survival using RANK().
select 
tumor_type ,
treatment_type,
rank()over (partition by tumor_type order by avg_survival) as rank_treatment,
avg_survival
from
(
	select 
	p.tumor_type ,
	t.treatment_type ,
	avg(t.survival_months) as avg_survival
	from  brain_tumor_patients p

	JOIN brain_tumor_treatments t
    ON p.patient_id = t.patient_id
    group by 
    p.tumor_type,
    t.treatment_type)t;
    
    
-- 20.	Using JOINs across patients, genomics, treatments, classify patients into High / Medium / Low survival risk
-- groups using NTILE(3) based on survival_months.
select
patient_id ,
survival_months,
survival_risk,
bucket 
from(
	select
	patient_id ,
	survival_months,
	bucket,
	case 
	when bucket = 1 then 'HIGH'
	WHEN bucket = 2 then 'MEDIUM'
	when bucket = 3 then 'low'
	end as survival_risk
	from
	(
		SELECT
		g.patient_id ,
		t.survival_months,
		NTILE(3) over (order by t.survival_months desc) as bucket
		from  brain_tumor_patients p
		JOIN brain_tumor_treatments t
		ON p.patient_id = t.patient_id
		JOIN brain_tumor_genomics g
		ON p.patient_id = g.patient_id)t
											)u;
                                            
                                            -- END -- 
    