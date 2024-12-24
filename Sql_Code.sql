use role accountadmin;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from
(SELECT 
 'DORA_IS_WORKING' as step
 ,(select 123 ) as actual
 ,123 as expected
 ,'Dora is working!' as description
); 

create or replace table util_db.public.my_data_types
(
  my_number number
, my_text varchar(10)
, my_bool boolean
, my_float float
, my_date date
, my_timestamp timestamp_tz
, my_variant variant
, my_array array
, my_object object
, my_geography geography
, my_geometry geometry
, my_vector vector(int,16)
);

-- Step 1: Use the ACCOUNTADMIN role to ensure you have sufficient permissions
USE ROLE ACCOUNTADMIN;

-- Step 2: Create the ZENAS_ATHLEISURE_DB database and assign ownership to SYSADMIN
CREATE DATABASE IF NOT EXISTS ZENAS_ATHLEISURE_DB;
GRANT OWNERSHIP ON DATABASE ZENAS_ATHLEISURE_DB TO ROLE SYSADMIN REVOKE CURRENT GRANTS;

-- Step 3: Drop the PUBLIC schema if it exists
DROP SCHEMA IF EXISTS ZENAS_ATHLEISURE_DB.PUBLIC CASCADE;

-- Step 4: Create the PRODUCTS schema and assign ownership to SYSADMIN
CREATE SCHEMA IF NOT EXISTS ZENAS_ATHLEISURE_DB.PRODUCTS;
GRANT OWNERSHIP ON SCHEMA ZENAS_ATHLEISURE_DB.PRODUCTS TO ROLE SYSADMIN REVOKE CURRENT GRANTS;

-- Optional Step: Verify the changes
SHOW DATABASES LIKE 'ZENAS_ATHLEISURE_DB';
SHOW SCHEMAS IN DATABASE ZENAS_ATHLEISURE_DB;

list @zenas_athleisure_db.products.product_metadata;

-- creating file formats
create or replace file format zmd_file_format_1
RECORD_DELIMITER = ';'
TRIM_SPACE = True;

create or replace file format zmd_file_format_2
FIELD_DELIMITER = '|'
RECORD_DELIMITER = ';'
TRIM_SPACE = True;  

create or replace file format zmd_file_format_3
FIELD_DELIMITER = '='
RECORD_DELIMITER = '^'
TRIM_SPACE = True;


-- creating views
create view zenas_athleisure_db.products.sweatsuit_sizes as 
select REPLACE($1, concat(chr(13),chr(10))) as sizes_available
from @product_metadata/sweatsuit_sizes.txt
(file_format => zmd_file_format_1 );

create or replace view zenas_athleisure_db.products.SWEATBAND_PRODUCT_LINE as 
select REPLACE($1,  chr(13)||chr(10)) as PRODUCT_CODE , $2 as HEADBAND_DESCRIPTION, $3 as WRISTBAND_DESCRIPTION
from @product_metadata/swt_product_line.txt
(file_format => zmd_file_format_2);


create or replace view zenas_athleisure_db.products.SWEATBAND_COORDINATION as 
select REPLACE($1,  chr(13)||chr(10)) as PRODUCT_CODE,$2 as HAS_MATCHING_SWEATSUIT 
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_3);

LIST @product_metadata/sweatsuits;
select $1
from @sweatsuits/purple_sweatsuit.png;

select metadata$filename, metadata$file_row_number
from @sweatsuits/purple_sweatsuit.png;

select metadata$filename, count(metadata$filename)
from @sweatsuits/purple_sweatsuit.png
GROUP BY metadata$filename;

select * 
from directory(@sweatsuits);

select REPLACE(relative_path, '_', ' ') as no_underscores_filename
, REPLACE(no_underscores_filename, '.png') as just_words_filename
, INITCAP(just_words_filename) as product_name
from directory(@sweatsuits);

SELECT INITCAP(REPLACE(REPLACE(relative_path, '_', ' '), '.png', '')) AS PRODUCT_NAME
FROM DIRECTORY(@sweatsuits);

create or replace table zenas_athleisure_db.products.sweatsuits (
	color_or_style varchar(25),
	file_name varchar(50),
	price number(5,2)
);

insert into  zenas_athleisure_db.products.sweatsuits 
          (color_or_style, file_name, price)
values
 ('Burgundy', 'burgundy_sweatsuit.png',65)
,('Charcoal Grey', 'charcoal_grey_sweatsuit.png',65)
,('Forest Green', 'forest_green_sweatsuit.png',64)
,('Navy Blue', 'navy_blue_sweatsuit.png',65)
,('Orange', 'orange_sweatsuit.png',65)
,('Pink', 'pink_sweatsuit.png',63)
,('Purple', 'purple_sweatsuit.png',64)
,('Red', 'red_sweatsuit.png',68)
,('Royal Blue',	'royal_blue_sweatsuit.png',65)
,('Yellow', 'yellow_sweatsuit.png',67);

select *
from DIRECTORY(@sweatsuits);

select * 
from sweatsuits;

create view product_list as
select INITCAP(REPLACE (REPLACE (relative_path,'-',' '), '.png')) as product_name, FILE_NAME,COLOR_OR_STYLE, PRICE,
FILE_URL
from directory (@sweatsuits) d
join sweatsuits s
on d.RELATIVE_PATH =s.FILE_NAME;


select COLOR_OR_STYLE, Size 
from directory (@sweatsuits) d
cross join sweatsuits s;


create view catalog as
select * 
from product_list p
cross join sweatsuit_sizes
WHERE sizes_available != '';

-- Add a table to map the sweatsuits to the sweat band sets
create table zenas_athleisure_db.products.upsell_mapping
(
sweatsuit_color_or_style varchar(25)
,upsell_product_code varchar(10)
);

--populate the upsell table
insert into zenas_athleisure_db.products.upsell_mapping
(
sweatsuit_color_or_style
,upsell_product_code 
)
VALUES
('Charcoal Grey','SWT_GRY')
,('Forest Green','SWT_FGN')
,('Orange','SWT_ORG')
,('Pink', 'SWT_PNK')
,('Red','SWT_RED')
,('Yellow', 'SWT_YLW');


 DROP view catalog_for_website;
-- Zena needs a single view she can query for her website prototype
create view catalog_for_website as 
select distinct(color_or_style)
,price
,file_name
, get_presigned_url(@sweatsuits, file_name, 3600) as file_url
,size_list
,coalesce('Consider: ' ||  headband_description || ' & ' || wristband_description, 'Consider: White, Black or Grey Sweat Accessories')  as upsell_product_desc
from
(   select color_or_style, price, file_name
    ,listagg(sizes_available, ' | ') within group (order by sizes_available) as size_list
    from catalog
    group by color_or_style, price, file_name
) c
left join upsell_mapping u
on u.sweatsuit_color_or_style = c.color_or_style
left join sweatband_coordination sc
on sc.product_code = u.upsell_product_code
left join sweatband_product_line spl
on spl.product_code = sc.product_code;



select *
from sweatband_coordination;

select * 
from sweatband_product_line;
