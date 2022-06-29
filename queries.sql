-- Q1. Hydro-power plant with largest power.
create temp view hydro_power as (
    select hpp.*, sum(tur.hydro_turbine_power) as power
    from hydro_power_plant hpp natural join turbine tur
    group by id_hydro
);

select *
from hydro_power
where power >= all(
    select power
    from hydro_power
    where power is not null
);


-- Q2. River with biggest flow-rate.
select *
from river
where flow_rate = ( select max(flow_rate) from river );

select *
from river
where flow_rate >= all(
    select flow_rate
    from river
    where flow_rate is not null
);

select *
from river
where flow_rate is not null
order by flow_rate desc limit 1;


-- Q3. All reservoirs on river with biggest flow.( Rivers without reservoir ignored. )
select res.*
from reservoir res join river riv on( res.id_river = riv.id_river )
where flow_rate =
(
    select max(flow_rate)
    from river natural join reservoir
)
order by capacity desc;


-- Q4. Power plant which uses all types of fuel.
select base.*
from biomass_power_plant base left join (
    select id_biomass
    from (
        select id_biomass, name
        from biomass_power_plant cross join (
            select distinct name
            from fuel
        ) y
        except
        select id_biomass, name
        from fuel_biomass_power_plant join fuel using( id_fuel )
    ) x
) elim on ( base.id_biomass = elim.id_biomass )
where elim.id_biomass is null;


-- Q5. All power plants on rivers without reservoir.
select hpp.*
from hydro_power_plant hpp natural join (
    select riv.id_river
    from river riv full outer join reservoir res on( riv.id_river = res.id_river )
    where id_reservoir is null
) x;


-- Q6. All solar-panels on certain place.
select solar_panel.*
from solar_panel join solar_power_plant using( id_solar )
                join location using( id_location )
where location.name = 'Pingtang';


-- Q7. Solar power plants and their power.
select *, (select sum(panel_power) from solar_panel sp where sp.id_solar = spp.id_solar ) as total_power
from solar_power_plant spp;


-- Q8. Hydro power plant with smallest start-time.
select hydro_power_plant.*, start_up_time
from grid_connection join hydro_power_plant using( id_hydro )
where start_up_time = (
    select max(start_up_time)
    from grid_connection
);


-- Q9. Rivers which flow to lowest river.
select river.*
from river
where river_id_river in
(
    select id_river
    from river
    where lowest_point =
    (
        select min(lowest_point)
        from river
    )
);


-- Q10. Rivers on river without hydro power plant.
select reservoir.*
from reservoir left join (
    select id_river
    from river natural join hydro_power_plant
) riv_with_plant on( reservoir.id_river = riv_with_plant.id_river)
where riv_with_plant is null;


-- Q11. Hydro power plants only with Kaplan turbines.
(
    select hydro_power_plant.*
    from hydro_power_plant join turbine using( id_hydro )
    where turbine_type = 'Kaplan'
)
except
(
    select hydro_power_plant.*
    from hydro_power_plant join turbine using( id_hydro )
    where turbine_type != 'Kaplan'
);


-- Q12. Hydro power plants count.
select count(*) from hydro_power_plant;


-- Q13. Locations with solar or wind power plant.
(
    select location.*
    from location natural join wind_power_plant
)
union
(
    select location.*
    from location natural join solar_power_plant
);


-- Q14. Hydro power plants without turbine.
select *
from hydro_power_plant hpp
where not exists(
    select 1
    from turbine tur
    where tur.id_hydro = hpp.id_hydro
);


-- Q15. Hydro power plants( id_hydro ), distinct turbine type count, turbine count
-- on plants with head at >500m, power >100kW, >two turbine types, sorted by turbine count.
select id_hydro, count( distinct turbine_type ) as distinct_turbine_types, count( hydro_turbine_number ) as turbine_count
from hydro_power_plant natural join turbine
where head > 500
group by id_hydro
having sum( hydro_turbine_power ) > 100000 and count( distinct turbine_type ) > 0
order by count( hydro_turbine_number ) desc;


-- Q16. Plants which uses all coal types.
select id_biomass
from fuel_biomass_power_plant natural join fuel
where name = 'Charcoal'

    intersect

select id_biomass
from fuel_biomass_power_plant natural join fuel
where name = 'Black coal'

    intersect

select id_biomass
from fuel_biomass_power_plant natural join fuel
where name = 'Brown coal';


-- Q17. Control of Q4 result.
select id_biomass, count(name)
from fuel_biomass_power_plant join fuel using(id_fuel)
where id_biomass in (
    select base.id_biomass
    from biomass_power_plant base left join (
        select id_biomass
        from (
            select id_biomass
            from biomass_power_plant cross join (
                select distinct name
                from fuel
            ) y
            except
            select id_biomass
            from fuel_biomass_power_plant join fuel using( id_fuel )
        ) x
    ) elim on ( base.id_biomass = elim.id_biomass )
    where elim.id_biomass is null
)
group by id_biomass
having count( distinct fuel.name ) != ( select count(distinct name) from fuel );


-- Q18. All combinations of Biomass power plant and biofuel. ( Include plant which uses no fuel, and fuel that is not used. )
begin;

insert into fuel values( default, 'Water', 332, 492 );
insert into biomass_power_plant values( default, 5000 );

select id_biomass, name
from fuel left join fuel_biomass_power_plant using( id_fuel )
        full join biomass_power_plant using( id_biomass );

rollback;


-- Q19. Insert hydro power plant on river without power plant.
begin;

select count(*) from hydro_power_plant;

insert into hydro_power_plant (id_river, head)
select id_river, null as head
from river left join hydro_power_plant using(id_river)
where id_hydro is null
limit 1;

select count(*) from hydro_power_plant;

rollback;


-- Q20. Increase price of imported coal.
begin;

select name, avg(price) from fuel group by name;

update fuel
set price = price + 50
where name like '%coal%' and name != 'Charcoal';

select name, avg(price) from fuel group by name;

rollback;


-- Q21. Decrease start up time on hydro power plants with reservoir.
begin;

select id_connection, id_hydro, start_up_time
from grid_connection join hydro_power_plant using(id_hydro)
order by id_connection;


update grid_connection
set start_up_time = start_up_time - 60
where id_hydro in (
    select id_hydro
    from hydro_power_plant join river using(id_river)
                            join reservoir using(id_river)
);

select id_connection, id_hydro, start_up_time
from grid_connection join hydro_power_plant using(id_hydro)
order by id_connection;

rollback;


-- Q22. Delete turbines from wind power plants where wind speed is not known.
begin;

select distinct id_wind, (select count(*) from wind_turbine wt where wt.id_wind = wpp.id_wind)
from wind_power_plant wpp
order by id_wind;


delete from wind_turbine
where id_wind in (
    select id_wind
    from wind_power_plant join location using(id_location)
    where wind_speed is null
);

select distinct id_wind, (select count(*) from wind_turbine wt where wt.id_wind = wpp.id_wind)
from wind_power_plant wpp
order by id_wind;

rollback;


-- Q23. Power plants which burn coal and outputs >8.5MW.
select distinct biomass_power_plant.*
from biomass_power_plant natural join fuel_biomass_power_plant
                            natural join fuel
where name in ( 'Black coal', 'Brown coal' ) and power > 8500000;


-- Q24. Turbine types on power plants with head <2m.
select distinct turbine_type
from hydro_power_plant natural join turbine
where head < 20;


-- Q25. Biomass power plant with largest power.
select id_biomass
from biomass_power_plant
where power = ( select max(power) from biomass_power_plant);

