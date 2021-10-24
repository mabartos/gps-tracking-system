
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
    timestamp_full timestamp without time zone,
    year SMALLINT,
    month NUMERIC(2,0),
    day NUMERIC(2,0),
    hour NUMERIC(2,0),
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
    date_key BIGINT,
    car_key BIGINT,
    sim_key BIGINT,

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


INSERT INTO xbartos5.date_dimension(timestamp_full,year,month,day,hour)(
    SELECT sl_time,
        DATE_PART('year', sl_time),
        DATE_PART('month', sl_time),
        DATE_PART('day', sl_time),
        DATE_PART('hour', sl_time)
     FROM xdohnal.pa220ha1dataseptoct
);



INSERT INTO xbartos5.sim_dimension(sim_imsi,gsmnet_id)(
    SELECT DISTINCT sim_imsi,gsmnet_id from xdohnal.pa220ha1dataseptoct
);

INSERT INTO xbartos5.car_dimension(car_key, spz, make, color, tonnage)(
    SELECT DISTINCT ON (car_key) car_key, spz, make, color, tonnage from xdohnal.car_info
);


INSERT INTO xbartos5.report_fact(device_key,
                                app_key,
                                car_key,
                                sim_key,
                                date_key,
                                app_run_time,
                                pda_run_time,
                                battery_level,
                                method,
                                tracking_mode)(
    SELECT DISTINCT dev.device_key,
        app.app_key,
        car.car_key,
        sim.sim_key,
        dateDim.date_key,
        base.app_run_time,
        base.pda_run_time,
        base.battery_level,
        base.method,
        base.tracking_mode

    FROM xdohnal.pa220ha1dataseptoct AS base
    INNER JOIN xbartos5.device_dimension AS dev ON base.pda_imei = dev.pda_imei 
        AND base.device=dev.name 
    INNER JOIN xbartos5.app_dimension AS app ON base.program_ver = app.program_ver
    INNER JOIN xbartos5.car_dimension AS car ON base.car_key = car.car_key
    INNER JOIN xbartos5.sim_dimension AS sim ON base.sim_imsi = sim.sim_imsi 
        AND base.gsmnet_id = sim.gsmnet_id
    INNER JOIN xbartos5.date_dimension as dateDim ON base.sl_time = dateDim.timestamp_full
);

