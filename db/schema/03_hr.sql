-- ============================================================
-- 03_hr.sql : org chart, payroll, shifts
-- Drives recursive CTE, gaps-and-islands and self-join practice.
-- ============================================================
SET search_path = hr, shop, practice, public;

CREATE TABLE hr.departments (
  department_id int PRIMARY KEY,
  name          text NOT NULL UNIQUE,
  parent_department_id int REFERENCES hr.departments(department_id),
  cost_center   text NOT NULL,
  country_code  char(2) NOT NULL REFERENCES shop.countries(country_code)
);

CREATE TABLE hr.job_titles (
  job_id     int PRIMARY KEY,
  title      text NOT NULL UNIQUE,
  job_family text NOT NULL,          -- eng / ops / support / sales / finance
  level      smallint NOT NULL,      -- 1..8
  min_salary numeric(12,2) NOT NULL,
  max_salary numeric(12,2) NOT NULL,
  CHECK (max_salary >= min_salary)
);

CREATE TABLE hr.employees (
  employee_id   int PRIMARY KEY,
  manager_id    int REFERENCES hr.employees(employee_id),  -- NULL => CEO
  department_id int NOT NULL REFERENCES hr.departments(department_id),
  job_id        int NOT NULL REFERENCES hr.job_titles(job_id),
  first_name    text NOT NULL,
  last_name     text NOT NULL,
  email         text NOT NULL UNIQUE,
  hired_on      date NOT NULL,
  terminated_on date,                                      -- NULL => active
  salary        numeric(12,2) NOT NULL,
  bonus_pct     numeric(5,4),
  country_code  char(2) NOT NULL REFERENCES shop.countries(country_code),
  is_manager    boolean NOT NULL DEFAULT false,
  CHECK (terminated_on IS NULL OR terminated_on >= hired_on)
);

-- temporal history: salary changes, one open row per employee
CREATE TABLE hr.salary_history (
  history_id  bigserial PRIMARY KEY,
  employee_id int NOT NULL REFERENCES hr.employees(employee_id),
  salary      numeric(12,2) NOT NULL,
  effective_from date NOT NULL,
  effective_to   date,
  reason      text NOT NULL,
  EXCLUDE USING gist (employee_id WITH =, daterange(effective_from, effective_to, '[)') WITH &&)
);

-- shift table: consecutive-day streaks => gaps and islands
CREATE TABLE hr.shifts (
  shift_id    bigserial PRIMARY KEY,
  employee_id int NOT NULL REFERENCES hr.employees(employee_id),
  shift_date  date NOT NULL,
  started_at  timestamptz NOT NULL,
  ended_at    timestamptz NOT NULL,
  role        text NOT NULL,
  warehouse_id int REFERENCES shop.warehouses(warehouse_id),
  UNIQUE (employee_id, shift_date, started_at),
  CHECK (ended_at > started_at)
);

CREATE TABLE hr.time_off (
  request_id  bigserial PRIMARY KEY,
  employee_id int NOT NULL REFERENCES hr.employees(employee_id),
  kind        text NOT NULL CHECK (kind IN ('vacation','sick','parental','unpaid')),
  period      daterange NOT NULL,
  approved_by int REFERENCES hr.employees(employee_id),
  status      text NOT NULL CHECK (status IN ('requested','approved','rejected','cancelled'))
);

-- deferred FKs from shop -> hr
ALTER TABLE shop.support_tickets
  ADD CONSTRAINT support_tickets_agent_fk
  FOREIGN KEY (assigned_to) REFERENCES hr.employees(employee_id);

ALTER TABLE shop.refunds
  ADD CONSTRAINT refunds_approver_fk
  FOREIGN KEY (approved_by) REFERENCES hr.employees(employee_id);
