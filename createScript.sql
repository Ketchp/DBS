-- Remove conflicting tables
-- remove function for removing tables and sequences
DROP FUNCTION IF EXISTS remove_all();

-- create function for removing tables and sequences
CREATE or replace FUNCTION remove_all() RETURNS void AS $$
DECLARE
    rec RECORD;
    cmd text;
BEGIN
    cmd := '';

    FOR rec IN SELECT
            'DROP SEQUENCE ' || quote_ident(n.nspname) || '.'
                || quote_ident(c.relname) || ' CASCADE;' AS name
        FROM
            pg_catalog.pg_class AS c
        LEFT JOIN
            pg_catalog.pg_namespace AS n
        ON
            n.oid = c.relnamespace
        WHERE
            relkind = 'S' AND
            n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
            pg_catalog.pg_table_is_visible(c.oid)
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    FOR rec IN SELECT
            'DROP TABLE ' || quote_ident(n.nspname) || '.'
                || quote_ident(c.relname) || ' CASCADE;' AS name
        FROM
            pg_catalog.pg_class AS c
        LEFT JOIN
            pg_catalog.pg_namespace AS n
        ON
            n.oid = c.relnamespace WHERE relkind = 'r' AND
            n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
            pg_catalog.pg_table_is_visible(c.oid)
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    EXECUTE cmd;
    RETURN;
END;
$$ LANGUAGE plpgsql;

select remove_all();
-- End of removing

CREATE TABLE biomass_power_plant (
    id_biomass SERIAL NOT NULL,
    power DECIMAL(10, 2)
);
ALTER TABLE biomass_power_plant ADD CONSTRAINT pk_biomass_power_plant PRIMARY KEY (id_biomass);

CREATE TABLE fuel (
    id_fuel SERIAL NOT NULL,
    name VARCHAR(32) NOT NULL,
    price REAL,
    energy_density REAL
);
ALTER TABLE fuel ADD CONSTRAINT pk_fuel PRIMARY KEY (id_fuel);

CREATE TABLE grid_connection (
    id_connection SERIAL NOT NULL,
    id_hydro INTEGER,
    id_solar INTEGER,
    id_wind INTEGER,
    id_biomass INTEGER,
    max_power DECIMAL(12, 2) NOT NULL,
    start_up_time SMALLINT NOT NULL
);
ALTER TABLE grid_connection ADD CONSTRAINT pk_grid_connection PRIMARY KEY (id_connection);
ALTER TABLE grid_connection ADD CONSTRAINT u_fk_grid_connection_hydro_power UNIQUE (id_hydro);
ALTER TABLE grid_connection ADD CONSTRAINT u_fk_grid_connection_solar_power UNIQUE (id_solar);
ALTER TABLE grid_connection ADD CONSTRAINT u_fk_grid_connection_wind_power UNIQUE (id_wind);
ALTER TABLE grid_connection ADD CONSTRAINT u_fk_grid_connection_biomass_power UNIQUE (id_biomass);

CREATE TABLE hydro_power_plant (
    id_hydro SERIAL NOT NULL,
    id_river INTEGER NOT NULL,
    head DECIMAL(6, 2)
);
ALTER TABLE hydro_power_plant ADD CONSTRAINT pk_hydro_power_plant PRIMARY KEY (id_hydro);

CREATE TABLE location (
    id_location SERIAL NOT NULL,
    longitude DECIMAL(9, 6) NOT NULL,
    latitude DECIMAL(8, 6) NOT NULL,
    solar_constant DECIMAL(6, 2),
    wind_speed DECIMAL(4, 2),
    name VARCHAR(64)
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id_location);

CREATE TABLE reservoir (
    id_reservoir SERIAL NOT NULL,
    id_river INTEGER NOT NULL,
    capacity BIGINT
);
ALTER TABLE reservoir ADD CONSTRAINT pk_reservoir PRIMARY KEY (id_reservoir, id_river);

CREATE TABLE river (
    id_river SERIAL NOT NULL,
    river_id_river INTEGER,
    lowest_point DECIMAL(6, 2) NOT NULL,
    flow_rate DECIMAL(8, 2)
);
ALTER TABLE river ADD CONSTRAINT pk_river PRIMARY KEY (id_river);

CREATE TABLE solar_panel (
    panel_number SERIAL NOT NULL,
    id_solar INTEGER NOT NULL,
    panel_power DECIMAL(6, 2),
    panel_size DECIMAL(8, 4)
);
ALTER TABLE solar_panel ADD CONSTRAINT pk_solar_panel PRIMARY KEY (panel_number, id_solar);

CREATE TABLE solar_power_plant (
    id_solar SERIAL NOT NULL,
    id_location INTEGER NOT NULL,
    solar_type VARCHAR(32) NOT NULL,
    total_area DECIMAL(6, 2) NOT NULL
);
ALTER TABLE solar_power_plant ADD CONSTRAINT pk_solar_power_plant PRIMARY KEY (id_solar);
ALTER TABLE solar_power_plant ADD CONSTRAINT u_fk_solar_power_plant_location UNIQUE (id_location);

CREATE TABLE turbine (
    hydro_turbine_number SERIAL NOT NULL,
    id_hydro INTEGER NOT NULL,
    hydro_turbine_power DECIMAL(8, 2),
    turbine_type VARCHAR(32)
);
ALTER TABLE turbine ADD CONSTRAINT pk_turbine PRIMARY KEY (hydro_turbine_number, id_hydro);

CREATE TABLE wind_power_plant (
    id_wind SERIAL NOT NULL,
    id_location INTEGER NOT NULL,
    total_area DECIMAL(6, 2)
);
ALTER TABLE wind_power_plant ADD CONSTRAINT pk_wind_power_plant PRIMARY KEY (id_wind);
ALTER TABLE wind_power_plant ADD CONSTRAINT u_fk_wind_power_plant_location UNIQUE (id_location);

CREATE TABLE wind_turbine (
    wind_turbine_number SERIAL NOT NULL,
    id_wind INTEGER NOT NULL,
    wind_turbine_power DECIMAL(6, 2),
    height DECIMAL(5, 2)
);
ALTER TABLE wind_turbine ADD CONSTRAINT pk_wind_turbine PRIMARY KEY (wind_turbine_number, id_wind);

CREATE TABLE fuel_biomass_power_plant (
    id_fuel INTEGER NOT NULL,
    id_biomass INTEGER NOT NULL
);
ALTER TABLE fuel_biomass_power_plant ADD CONSTRAINT pk_fuel_biomass_power_plant PRIMARY KEY (id_fuel, id_biomass);


ALTER TABLE grid_connection ADD CONSTRAINT fk_grid_connection_hydro_power_plant FOREIGN KEY (id_hydro) REFERENCES hydro_power_plant (id_hydro) ON DELETE CASCADE;
ALTER TABLE grid_connection ADD CONSTRAINT fk_grid_connection_solar_power_plant FOREIGN KEY (id_solar) REFERENCES solar_power_plant (id_solar) ON DELETE CASCADE;
ALTER TABLE grid_connection ADD CONSTRAINT fk_grid_connection_wind_power_plant FOREIGN KEY (id_wind) REFERENCES wind_power_plant (id_wind) ON DELETE CASCADE;
ALTER TABLE grid_connection ADD CONSTRAINT fk_grid_connection_biomass_power_plant FOREIGN KEY (id_biomass) REFERENCES biomass_power_plant (id_biomass) ON DELETE CASCADE;

ALTER TABLE hydro_power_plant ADD CONSTRAINT fk_hydro_power_plant_river FOREIGN KEY (id_river) REFERENCES river (id_river) ON DELETE CASCADE;

ALTER TABLE reservoir ADD CONSTRAINT fk_reservoir_river FOREIGN KEY (id_river) REFERENCES river (id_river) ON DELETE CASCADE;

ALTER TABLE river ADD CONSTRAINT fk_river_river FOREIGN KEY (river_id_river) REFERENCES river (id_river) ON DELETE CASCADE;

ALTER TABLE solar_panel ADD CONSTRAINT fk_solar_panel_solar_power_plant FOREIGN KEY (id_solar) REFERENCES solar_power_plant (id_solar) ON DELETE CASCADE;

ALTER TABLE solar_power_plant ADD CONSTRAINT fk_solar_power_plant_location FOREIGN KEY (id_location) REFERENCES location (id_location) ON DELETE CASCADE;

ALTER TABLE turbine ADD CONSTRAINT fk_turbine_hydro_power_plant FOREIGN KEY (id_hydro) REFERENCES hydro_power_plant (id_hydro) ON DELETE CASCADE;

ALTER TABLE wind_power_plant ADD CONSTRAINT fk_wind_power_plant_location FOREIGN KEY (id_location) REFERENCES location (id_location) ON DELETE CASCADE;

ALTER TABLE wind_turbine ADD CONSTRAINT fk_wind_turbine_wind_power_plant FOREIGN KEY (id_wind) REFERENCES wind_power_plant (id_wind) ON DELETE CASCADE;

ALTER TABLE fuel_biomass_power_plant ADD CONSTRAINT fk_fuel_biomass_power_plant_fuel FOREIGN KEY (id_fuel) REFERENCES fuel (id_fuel) ON DELETE CASCADE;
ALTER TABLE fuel_biomass_power_plant ADD CONSTRAINT fk_fuel_biomass_power_plant_biomass FOREIGN KEY (id_biomass) REFERENCES biomass_power_plant (id_biomass) ON DELETE CASCADE;

ALTER TABLE grid_connection ADD CONSTRAINT xc_grid_connection_id_hydro_id_
    CHECK ((id_hydro IS NOT NULL AND id_solar IS NULL AND id_wind IS NULL AND id_biomass IS NULL)
            OR
           (id_hydro IS NULL AND id_solar IS NOT NULL AND id_wind IS NULL AND id_biomass IS NULL)
            OR
           (id_hydro IS NULL AND id_solar IS NULL AND id_wind IS NOT NULL AND id_biomass IS NULL)
            OR
           (id_hydro IS NULL AND id_solar IS NULL AND id_wind IS NULL AND id_biomass IS NOT NULL));

create or replace function checkRivers() returns trigger
language plpgsql as
$$begin
    if ( select count(*)
        from river source join river sink on ( source.river_id_river = sink.id_river )
        where source.lowest_point <= sink.lowest_point ) > 0
    then
        raise exception 'River IO violated.';
    end if;
    return null;
end;$$;

DROP TRIGGER IF EXISTS river_low_river ON river;

create constraint trigger river_low_river
    after insert or delete or update of river_id_river, lowest_point
    on river
    for each row
    execute procedure checkRivers();
