DROP TABLE xbartos5.device_dimension CASCADE;
DROP TABLE xbartos5.app_dimension CASCADE;
DROP TABLE xbartos5.date_dimension CASCADE;
DROP TABLE xbartos5.sim_dimension CASCADE; 
DROP TABLE xbartos5.gsm_network_dimension CASCADE; 
DROP TABLE xbartos5.car_dimension CASCADE;
DROP TABLE xbartos5.report_fact CASCADE;

CREATE TABLE xbartos5.device_dimension(
    device_key BIGINT GENERATED ALWAYS AS IDENTITY,
    pda_imei VARCHAR(20),
    name TEXT,
    effective_date TIMESTAMP,
    is_current BOOLEAN DEFAULT false,
    PRIMARY KEY(device_key)
);

CREATE TABLE xbartos5.app_dimension(
    app_key BIGINT GENERATED ALWAYS AS IDENTITY,
    program_ver VARCHAR(6),
    PRIMARY KEY(app_key)
);

CREATE TABLE xbartos5.date_dimension(
    date_key BIGINT GENERATED ALWAYS AS IDENTITY,
    timestamp_full TIMESTAMP with time zone,
    week_day TEXT NOT NULL,
    year SMALLINT NOT NULL check(year > -1),
    month NUMERIC(2,0) NOT NULL check(month > 0 AND month < 13),
    day NUMERIC(2,0) NOT NULL check(day > 0 AND day < 32),
    hour NUMERIC(2,0) NOT NULL check(hour > -1 AND hour < 25),
    minute NUMERIC(2,0) NOT NULL check(minute > -1 AND minute < 60),
    PRIMARY KEY(date_key),
    
    CONSTRAINT date_unique
        UNIQUE (week_day, year, month, day, hour, minute)
);

CREATE TABLE xbartos5.sim_dimension(
    sim_key BIGINT GENERATED ALWAYS AS IDENTITY,
    sim_imsi CHARACTER(15),
    
    PRIMARY KEY(sim_key)
);

CREATE TABLE xbartos5.gsm_network_dimension(
    gsm_key BIGINT GENERATED ALWAYS AS IDENTITY,
    gsmnet_id VARCHAR(6),
    isp_country TEXT,

    PRIMARY KEY(gsm_key)
);

CREATE TABLE xbartos5.car_dimension(
    car_key BIGINT NOT NULL UNIQUE,
    spz TEXT UNIQUE,
    make VARCHAR(50),
    color VARCHAR(50),
    tonnage NUMERIC(4,1),
    PRIMARY KEY(car_key)
);

CREATE TABLE xbartos5.report_fact(
    report_key BIGINT GENERATED ALWAYS AS IDENTITY,

    device_key BIGINT,
    app_key BIGINT,
    date_conn_key BIGINT,
    date_service_key BIGINT,
    car_key BIGINT,
    sim_key BIGINT,
    gsm_key BIGINT,

    app_run_time NUMERIC(6,2),
    pda_run_time NUMERIC(10,2),
    battery_level TEXT,
    tracking_mode TEXT,
    method CHARACTER(1),

    PRIMARY KEY(report_key),

    CONSTRAINT fk_device_key
        FOREIGN KEY(device_key)
            REFERENCES xbartos5.device_dimension(device_key),
    
    CONSTRAINT fk_app_key
        FOREIGN KEY(app_key)
            REFERENCES xbartos5.app_dimension(app_key),

    CONSTRAINT fk_date_conn_key
        FOREIGN KEY(date_conn_key)
            REFERENCES xbartos5.date_dimension(date_key),

    CONSTRAINT fk_date_service_key
        FOREIGN KEY(date_service_key)
            REFERENCES xbartos5.date_dimension(date_key),

    CONSTRAINT fk_car_key
        FOREIGN KEY(car_key)
            REFERENCES xbartos5.car_dimension(car_key),

    CONSTRAINT fk_sim_key
        FOREIGN KEY(sim_key)
            REFERENCES xbartos5.sim_dimension(sim_key),

    CONSTRAINT fk_gsm_key
        FOREIGN KEY(gsm_key)
            REFERENCES xbartos5.gsm_network_dimension(gsm_key)
);

INSERT INTO xbartos5.device_dimension(pda_imei, name, effective_date)(
    SELECT DISTINCT ON(pda_imei, device) pda_imei, device, sl_time from xdohnal.pa220ha1dataseptoct
);

UPDATE xbartos5.device_dimension
SET is_current=true
WHERE device_key = ANY (SELECT DISTINCT ON (pda_imei) device_key 
                        FROM xbartos5.device_dimension 
                        ORDER BY pda_imei, effective_date DESC);


INSERT INTO xbartos5.app_dimension(program_ver)(
    SELECT DISTINCT program_ver from xdohnal.pa220ha1dataseptoct
);

INSERT INTO xbartos5.date_dimension(timestamp_full, week_day, year, month, day, hour, minute)(
    SELECT DISTINCT ON(dat.t) dat.t,
        TO_CHAR(dat.t, 'Day'),
        DATE_PART('year', dat.t),
        DATE_PART('month', dat.t),
        DATE_PART('day', dat.t),
        DATE_PART('hour', dat.t),
        DATE_PART('minute', dat.t)

    FROM (SELECT DISTINCT sl_time as t FROM xdohnal.pa220ha1dataseptoct 
            UNION SELECT DISTINCT cl_time as t FROM xdohnal.pa220ha1dataseptoct) dat
    GROUP BY dat.t
);

INSERT INTO xbartos5.sim_dimension(sim_imsi)(
    SELECT DISTINCT sim_imsi from xdohnal.pa220ha1dataseptoct
);

INSERT INTO xbartos5.gsm_network_dimension(gsmnet_id)(
    SELECT DISTINCT ON(gsmnet_id) gsmnet_id from xdohnal.pa220ha1dataseptoct
);

INSERT INTO xbartos5.car_dimension(car_key, spz, make, color, tonnage)(
    SELECT DISTINCT ON (car_key) car_key, spz, make, color, tonnage from xdohnal.car_info
);

INSERT INTO xbartos5.report_fact(device_key,
                                app_key,
                                date_conn_key,
                                date_service_key,
                                car_key,
                                sim_key,
                                gsm_key,
                                app_run_time,
                                pda_run_time,
                                battery_level,
                                tracking_mode,
                                method )(
    SELECT DISTINCT dev.device_key,
        app.app_key,
        date_conn.date_key,
        date_service.date_key,
        car.car_key,
        sim.sim_key,
        gsm.gsm_key,
        base.app_run_time,
        base.pda_run_time,
        base.battery_level,
        base.tracking_mode,
        base.method

    FROM xdohnal.pa220ha1dataseptoct AS base
    INNER JOIN xbartos5.device_dimension AS dev ON base.pda_imei = dev.pda_imei 
        AND base.device=dev.name 
    INNER JOIN xbartos5.app_dimension AS app ON base.program_ver = app.program_ver
    INNER JOIN xbartos5.car_dimension AS car ON base.car_key = car.car_key
    INNER JOIN xbartos5.sim_dimension AS sim ON base.sim_imsi = sim.sim_imsi 
    INNER JOIN xbartos5.gsm_network_dimension as gsm ON base.gsmnet_id = gsm.gsmnet_id
    INNER JOIN xbartos5.date_dimension as date_conn ON base.cl_time = date_conn.timestamp_full
    INNER JOIN xbartos5.date_dimension as date_service ON base.sl_time = date_service.timestamp_full
);