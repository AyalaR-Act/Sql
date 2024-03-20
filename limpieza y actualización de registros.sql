use clean;
DELIMITER //
CREATE PROCEDURE alldata()
BEGIN
select * from dataorganization;
END //
DELIMITER ;
call alldata(); 
set sql_safe_updates = 0;
-- Renombramos las columnas de la tabla
alter table dataorganization change column `﻿COD` id_cliente int not null;
ALTER TABLE dataorganization
CHANGE COLUMN `Primer apellido` last_name1 VARCHAR(50) NULL;
ALTER TABLE dataorganization
CHANGE COLUMN `Segundo apellido` last_name2 VARCHAR(50) NULL;
ALTER TABLE dataorganization change column `Género` gender VARCHAR(50) NULL;
ALTER TABLE dataorganization change column `Departamento` department varchar(50) null;
alter table dataorganization change column `Salario` salary varchar(50) null;
alter table dataorganization change column `Fecha inicio` start_date text null;
alter table dataorganization change column `Tiempo` time text null;
alter table dataorganization change column `País de origen` country varchar(50) null;
alter table dataorganization change column `Tipo de contrato` contract varchar(50) null;

-- Revisemos si existen espacios en los registros
call alldata();
Select nombres from dataorganization 
where nombres regexp '\\s{2,}';
Select nombres, trim(regexp_replace(nombres,'\\s+', ' ')) as ensayo from dataorganization;
update dataorganization set nombres = trim(regexp_replace(nombres,'\\s+', ' '));
Select last_name1, trim(regexp_replace(last_name1,'\\s+', ' ')) as ensayo from dataorganization;
update dataorganization set last_name1 = trim(regexp_replace(last_name1,'\\s+', ' '));
Select last_name2, trim(regexp_replace(last_name2,'\\s+', ' ')) as ensayo from dataorganization;
update dataorganization set last_name2 = trim(regexp_replace(last_name2,'\\s+', ' '));
Select department, trim(regexp_replace(department,'\\s+', ' ')) as ensayo from dataorganization;
update dataorganization set department = trim(regexp_replace(department,'\\s+', ' '));
-- Modifiquemos la columna de start_date para que tenga el formato de date aceptado en sql
-- Hacemos un ensayo antes de realizar la carga 
select start_date, case 
when start_date like '%/%' then  date_format(str_to_date(start_date, '%m/%d/%Y'), '%Y-%m-%d')
when start_date like '%-%' then  date_format(str_to_date(start_date, '%m-%d-%Y'), '%Y-%m-%d')
else null
end as new_date
from dataorganization;
-- aplicamos la actualización
UPDATE dataorganization
SET start_date = CASE 
                     WHEN start_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%m/%d/%Y'), '%Y-%m-%d')
                     WHEN start_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%m-%d-%Y'), '%Y-%m-%d')
                     ELSE NULL
                 END;
                 alter table dataorganization modify column start_date date;
-- observemos ahora los cambios realizados
call alldata();
describe dataorganization;                 
-- Eliminemos ahora los duplicados de la tabla 
-- Ubiquemos si existen duplicados realizando una consulta donde se visualizan los identificadores
select id_cliente, count(*) as cantidad_duplicados
from dataorganization
group by id_cliente
having count(*) > 1;
-- Contabilicemos el numero total de duplicados en la tabla
select count(*) as cantidad_duplicados 
from (
select id_cliente, count(*) as cantidad_duplicados
from dataorganization
group by id_cliente
having count(*) > 1
) as subquery;
-- Observamos un total de 20 duplicados
-- Renombramos nuestra tabla original, ahora se llamara duplicados con la finalidad de tener una copia de seguridad
rename table dataorganization to duplicados;
-- creación de una tabla temporal que almacenará las filas sin duplicación
create temporary table temp_data as 
select distinct * from duplicados;
-- Contabilicemos los datos que contiene cada tabla para verificar la eliminación de duplicados
select count(*) as original from duplicados;
select count(*) as original from temp_data;
-- Notemos que sólo se eliminaron 17 registros de 20 verifiquemos si existen duplicados nuevamente
create table dataorganization as select * from temp_data;
-- realizamos consulta de duplicados
select id_cliente, count(*) as cantidad_duplicados
from dataorganization
group by id_cliente
having count(*) > 1;
-- Notemos que los duplicados son los que tienen el identificador 
-- 4412, 2189, 2376, 7540
-- un total de 4 duplicados evaluemos la causa raíz realizamos la consulta
SELECT *
FROM dataorganization
WHERE id_cliente IN (9977);
-- Observamos que el problema es que existe una misma asignación de Id para distintas personas, esto causará problemas
-- dado que el id_cliente es el identificador unico (llave primaria)
-- Generamos  un nuevo número de id_cliente que no esté en uso
SET @nuevo_id := (SELECT MAX(id_cliente) + 1 FROM dataorganization);
-- Actualizamos el registro duplicado con el nuevo número de id_cliente 
call alldata();
UPDATE dataorganization
SET id_cliente = @nuevo_id
WHERE nombres = 'grantley boatwright';
update dataorganization set id_cliente =@nuevo_id 
where nombres ='cindelyn weight';

update dataorganization set id_cliente = @nuevo_id
where nombres = 'misty shoreson';

update dataorganization set id_cliente = @nuevo_id
where nombres = 'joyce gozney';

-- Ahora que ya realizamos la actalización y a cada persona tiene asignado un único identificador 
-- Evaluemos nuevamente si existen duplicados
select id_cliente, count(*) as cantidad_duplicados
from dataorganization
group by id_cliente
having count(*) > 1;
-- Contabilicemos  nuevamente el numero total de duplicados en la tabla
select count(*) as cantidad_duplicados 
from (
select id_cliente, count(*) as cantidad_duplicados
from dataorganization
group by id_cliente
having count(*) > 1
) as subquery;
-- Al realizar la consulta notamos que ya no existen duplicados en la tabla 
call alldata();
-- Asignar nulos en cuadros vacios
UPDATE dataorganization 
SET salary = NULL
WHERE salary IS NULL OR salary = '' OR TRIM(salary) = '';
select salary,  cast(trim(replace(replace (salary, '$', ''), ',','')) as decimal (15, 2)) as salary1 from dataorganization;
UPDATE dataorganization 
SET salary = CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2))
WHERE salary IS NOT NULL;
alter table dataorganization modify column salary int;
-- Elaboremos de manera masiva cuentas de correo electrónico
-- realizamos una visualización 
SELECT 
    CONCAT(SUBSTRING_INDEX(Nombres, ' ', 1),
            '_',
            SUBSTRING(last_name1, 1, 2),
            
            '@consultoria.com') AS email
FROM
    dataorganization;
UPDATE dataorganization 
SET email = CONCAT(SUBSTRING_INDEX(Nombres, ' ', 1),
                   '_',
                   SUBSTRING(last_name1, 1, 2),
                   '@consultoria.com');
-- Visualicemos las actualización
call alldata();
describe dataorganization;
-- Asignamos ahora la llave primaria a id_cliente
ALTER TABLE dataorganization
ADD PRIMARY KEY (id_cliente);
