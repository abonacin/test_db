--  Sample employee database
--  See changelog table for details
--  Copyright (C) 2007,2008, MySQL AB
--
--  Original data created by Fusheng Wang and Carlo Zaniolo
--  http://www.cs.aau.dk/TimeCenter/software.htm
--  http://www.cs.aau.dk/TimeCenter/Data/employeeTemporalDataSet.zip
--
--  Current schema by Giuseppe Maxia
--  Data conversion from XML to relational by Patrick Crews
--
-- This work is licensed under the
-- Creative Commons Attribution-Share Alike 3.0 Unported License.
-- To view a copy of this license, visit
-- http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to
-- Creative Commons, 171 Second Street, Suite 300, San Francisco,
-- California, 94105, USA.
--
--  DISCLAIMER
--  To the best of our knowledge, this data is fabricated, and
--  it does not correspond to real people.
--  Any similarity to existing people is purely coincidental.
--

DROP DATABASE IF EXISTS company;
CREATE DATABASE IF NOT EXISTS company;
USE company;

SELECT 'CREATING DATABASE STRUCTURE' as 'INFO';

DROP TABLE IF EXISTS dept_emp,
                     dept_manager,
                     titles,
                     salaries,
                     employees,
                     departments;

/*!50503 set default_storage_engine = InnoDB */;
/*!50503 select CONCAT('storage engine: ', @@default_storage_engine) as INFO */;

-- Employees
CREATE TABLE employees (
    emp_no      INT             NOT NULL,
    birth_date  DATE            NOT NULL,
    first_name  VARCHAR(14)     NOT NULL,
    last_name   VARCHAR(16)     NOT NULL,
    gender      ENUM ('M','F')  NOT NULL,
    hire_date   DATE            NOT NULL,
    dat_modif   DATETIME                ,
    PRIMARY KEY (emp_no)
);

DROP TRIGGER IF EXISTS tr_bi_employees;
DROP TRIGGER IF EXISTS tr_bu_employees;

DELIMITER $$

CREATE TRIGGER tr_bi_employees
BEFORE INSERT ON employees
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

CREATE TRIGGER tr_bu_employees
BEFORE UPDATE ON employees
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

DELIMITER ;


-- Departments
CREATE TABLE departments (
    dept_no     CHAR(4)         NOT NULL,
    dept_name   VARCHAR(40)     NOT NULL,
    dat_modif   DATETIME                ,
    PRIMARY KEY (dept_no),
    UNIQUE  KEY (dept_name)
);

DROP TRIGGER IF EXISTS tr_bi_departments;
DROP TRIGGER IF EXISTS tr_bu_departments;

DELIMITER $$

CREATE TRIGGER tr_bi_departments
BEFORE INSERT ON departments
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

CREATE TRIGGER tr_bu_departments
BEFORE UPDATE ON departments
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

DELIMITER;


-- Dept Manager
CREATE TABLE dept_manager (
   emp_no       INT             NOT NULL,
   dept_no      CHAR(4)         NOT NULL,
   from_date    DATE            NOT NULL,
   to_date      DATE            NOT NULL,
   dat_modif    DATETIME                ,
   FOREIGN KEY (emp_no)  REFERENCES employees (emp_no)    ON DELETE CASCADE,
   FOREIGN KEY (dept_no) REFERENCES departments (dept_no) ON DELETE CASCADE,
   PRIMARY KEY (emp_no,dept_no)
);

DROP TRIGGER IF EXISTS tr_bi_dept_manager;
DROP TRIGGER IF EXISTS tr_bu_dept_manager;

DELIMITER $$

CREATE TRIGGER tr_bi_dept_manager
BEFORE INSERT ON dept_manager
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

CREATE TRIGGER tr_bu_dept_manager
BEFORE UPDATE ON dept_manager
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

DELIMITER;


-- Dept Emp
CREATE TABLE dept_emp (
    emp_no      INT             NOT NULL,
    dept_no     CHAR(4)         NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE            NOT NULL,
    dat_modif   DATETIME                ,
    FOREIGN KEY (emp_no)  REFERENCES employees   (emp_no)  ON DELETE CASCADE,
    FOREIGN KEY (dept_no) REFERENCES departments (dept_no) ON DELETE CASCADE,
    PRIMARY KEY (emp_no,dept_no)
);

DROP TRIGGER IF EXISTS tr_bi_dept_emp;
DROP TRIGGER IF EXISTS tr_bu_dept_emp;

DELIMITER $$

CREATE TRIGGER tr_bi_dept_emp
BEFORE INSERT ON dept_emp
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

CREATE TRIGGER tr_bu_dept_emp
BEFORE UPDATE ON dept_emp
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

DELIMITER;




CREATE TABLE titles (
    emp_no      INT             NOT NULL,
    title       VARCHAR(50)     NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE,
    dat_modif   DATETIME                ,
    FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE,
    PRIMARY KEY (emp_no,title, from_date)
);

DROP TRIGGER IF EXISTS tr_bi_titles;
DROP TRIGGER IF EXISTS tr_bu_titles;


DELIMITER $$

CREATE TRIGGER tr_bi_titles
BEFORE INSERT ON titles
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

CREATE TRIGGER tr_bu_titles
BEFORE UPDATE ON titles
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$


DELIMITER;

CREATE TABLE salaries (
    emp_no      INT             NOT NULL,
    salary      INT             NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE            NOT NULL,
    dat_modif   DATETIME                ,
    FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE,
    PRIMARY KEY (emp_no, from_date)
);

DROP TRIGGER IF EXISTS tr_bi_salaries;
DROP TRIGGER IF EXISTS tr_bu_salaries;

DELIMITER $$

CREATE TRIGGER tr_bi_salaries
BEFORE INSERT ON salaries
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

CREATE TRIGGER tr_bu_salaries
BEFORE UPDATE ON salaries
    FOR EACH ROW
BEGIN
    SET new.dat_modif = CURTIME();
END $$

DELIMITER;


CREATE OR REPLACE VIEW dept_emp_latest_date AS
    SELECT emp_no, MAX(from_date) AS from_date, MAX(to_date) AS to_date
    FROM dept_emp
    GROUP BY emp_no;

# shows only the current department for each employee
CREATE OR REPLACE VIEW current_dept_emp AS
    SELECT l.emp_no, dept_no, l.from_date, l.to_date
    FROM dept_emp d
        INNER JOIN dept_emp_latest_date l
        ON d.emp_no=l.emp_no AND d.from_date=l.from_date AND l.to_date = d.to_date;

flush /*!50503 binary */ logs;

SELECT 'LOADING departments' as 'INFO';
source load_departments.dump ;
SELECT 'LOADING employees' as 'INFO';
source load_employees.dump ;
SELECT 'LOADING dept_emp' as 'INFO';
source load_dept_emp.dump ;
SELECT 'LOADING dept_manager' as 'INFO';
source load_dept_manager.dump ;
SELECT 'LOADING titles' as 'INFO';
source load_titles.dump ;
SELECT 'LOADING salaries' as 'INFO';
source load_salaries1.dump ;
source load_salaries2.dump ;
source load_salaries3.dump ;

source show_elapsed.sql ;
