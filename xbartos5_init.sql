--/*
DROP TABLE xbartos5.device_dimension CASCADE;
DROP TABLE xbartos5.app_dimension CASCADE;
DROP TABLE xbartos5.date_dimension CASCADE;
DROP TABLE xbartos5.sim_dimension CASCADE; 
DROP TABLE xbartos5.car_dimension CASCADE;
DROP TABLE xbartos5.report_fact CASCADE;
--*/

CREATE TABLE xbartos5.device_dimension(
    device_key BIGINT GENERATED ALWAYS AS IDENTITY,
    pda_imei VARCHAR(20),
    name TEXT,
    tracking_mode TEXT,
    PRIMARY KEY(device_key)
);

CREATE TABLE xbartos5.app_dimension(
    app_key BIGINT GENERATED ALWAYS AS IDENTITY,
    program_ver VARCHAR(6),
    PRIMARY KEY(app_key)
);

CREATE TABLE xbartos5.date_dimension(
    date_key BIGINT GENERATED ALWAYS AS IDENTITY,
    full_date TEXT,
    day_of_week NUMERIC(1,0),
    year SMALLINT,
    month NUMERIC(2,0),
    day NUMERIC(2,0),
    time_zone TEXT,
    PRIMARY KEY(date_key)
);

CREATE TABLE xbartos5.sim_dimension(
    sim_key BIGINT GENERATED ALWAYS AS IDENTITY,
    sim_imsi CHARACTER(15),
    gsmnet_id VARCHAR(6),
    PRIMARY KEY(sim_key)
);

CREATE TABLE xbartos5.car_dimension(
    car_key BIGINT NOT NULL UNIQUE,
    spz TEXT,
    make VARCHAR(50),
    color VARCHAR(50),
    tonnage NUMERIC(4,1),
    PRIMARY KEY(car_key)
);

CREATE TABLE xbartos5.report_fact(
    report_key BIGINT GENERATED ALWAYS AS IDENTITY,

    device_key BIGINT,
    app_key BIGINT,
    date_key BIGINT,
    car_key BIGINT,
    sim_key BIGINT,

    battery_level TEXT,
    app_run_time NUMERIC(6,2),
    pda_run_time NUMERIC(10,2),
    method CHARACTER(1),

    PRIMARY KEY(report_key),

    CONSTRAINT fk_device_key
        FOREIGN KEY(device_key)
            REFERENCES xbartos5.device_dimension(device_key),
    
    CONSTRAINT fk_app_key
        FOREIGN KEY(app_key)
            REFERENCES xbartos5.app_dimension(app_key),

    CONSTRAINT fk_date_key
        FOREIGN KEY(date_key)
            REFERENCES xbartos5.date_dimension(date_key),

    CONSTRAINT fk_car_key
        FOREIGN KEY(car_key)
            REFERENCES xbartos5.car_dimension(car_key),

    CONSTRAINT fk_sim_key
        FOREIGN KEY(sim_key)
            REFERENCES xbartos5.sim_dimension(sim_key)
);

INSERT INTO xbartos5.device_dimension(pda_imei,name,tracking_mode)(
    SELECT DISTINCT pda_imei,device,tracking_mode from xdohnal.pa220ha1dataseptoct
);

INSERT INTO xbartos5.app_dimension(program_ver)(
    SELECT DISTINCT program_ver from xdohnal.pa220ha1dataseptoct
);

-- DATE DIMENSION!!!

INSERT INTO xbartos5.sim_dimension(sim_imsi,gsmnet_id)(
    SELECT DISTINCT sim_imsi,gsmnet_id from xdohnal.pa220ha1dataseptoct
);

INSERT INTO xbartos5.car_dimension(car_key, spz, make, color, tonnage)(
    SELECT DISTINCT car_key, spz, make, color, tonnage from xdohnal.car_info
);

INSERT INTO xbartos5.report_fact(device_key,
                                app_key,
                                car_key,
                                sim_key,
                                battery_level,
                                app_run_time,
                                pda_run_time,method)(
    SELECT DISTINCT dev.device_key,
        app.app_key,
        car.car_key,
        sim.sim_key,
        base.battery_level,
        base.app_run_time,
        base.pda_run_time,
        base.method

    FROM xdohnal.pa220ha1dataseptoct AS base
    LEFT JOIN xbartos5.device_dimension AS dev ON base.pda_imei = dev.pda_imei 
        AND base.device=dev.name 
        AND base.tracking_mode = dev.tracking_mode
    LEFT JOIN xbartos5.app_dimension AS app ON base.program_ver = app.program_ver
    LEFT JOIN xbartos5.car_dimension AS car ON base.car_key = car.car_key
    LEFT JOIN xbartos5.sim_dimension AS sim ON base.sim_imsi = sim.sim_imsi 
        AND base.gsmnet_id = sim.gsmnet_id
);