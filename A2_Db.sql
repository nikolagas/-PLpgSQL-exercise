drop table if exists delivery_slot cascade;
drop table if exists warehouse_item cascade;
drop table if exists store cascade;
drop table if exists transact cascade;
drop table if exists product cascade;
drop table if exists customer cascade;


create table customer
(customer_id varchar(3) not null primary key,
 customer_sname varchar(20),
 customer_fname varchar(20), 
 customer_street_address varchar(25) not null,
 customer_city varchar(20) not null,
 customer_postcode varchar(8) not null,
 customer_bank varchar(20),
 customer_bank_address varchar(20),
 customer_bank_sortcode varchar(20) not null,
 customer_acc_number varchar(20) not null
);

create table product 
(product_id smallint not null primary key,
 product_type varchar(20) not null,
 product_name varchar(40) not null,
 product_cost decimal not null,
 product_quantity smallint not null,
 product_numAvailable smallint not null
);

create table transact 
(transaction_id varchar(10) not null primary key,
 customer_id varchar(3),
 product_id smallint,
 payment_date timestamp,
 
 constraint fk_customer_id
    foreign key(customer_id)
        references customer(customer_id) 
            on delete restrict,
 
 constraint fk_product_id
    foreign key(product_id)
        references product(product_id)
            on delete restrict

);

create table store 
(store_id smallint not null primary key,
 store_street_address varchar(20) not null,
 store_city varchar(20) not null,
 store_postcode varchar(12) not null
);


create table warehouse_item
(warehouse_item_id smallint not null primary key,
 warehouse_item_quantity smallint not null,
 store_id smallint,
 product_id smallint,
 
 constraint fk_store_id
    foreign key(store_id)
        references store(store_id)
            on delete restrict,
 
 constraint fk_product_id
    foreign key(product_id)
        references product(product_id)
            on delete restrict
);

create table delivery_slot(
daysInWeek varchar(30) primary key,
dayStartTime Time,
dayEndTime Time
);

create or replace procedure register_customer
(custr_id varchar(3),
 custr_sname varchar(20),
 custr_fname varchar(20), 
 custr_street_address varchar(25),
 custr_city varchar(20),
 custr_postcode varchar(8),
 custr_bank varchar(20),
 custr_bank_address varchar(20),
 custr_bank_sortcode varchar(20),
 custr_acc_number varchar(20)
)
language plpgsql as
$$
begin
    insert into customer(customer_id, customer_sname, customer_fname,
                        customer_street_address, customer_city, customer_postcode,
                        customer_bank, customer_bank_address,
                        customer_bank_sortcode, customer_acc_number)
                         values 
                         (custr_id,
                          custr_sname,
                          custr_fname,
                          custr_street_address,
                          custr_city,
                          custr_postcode,
                          custr_bank,
                          custr_bank_address,
                          custr_bank_sortcode,
                          custr_acc_number
                         ) returning customer_id into custr_id;
end
$$;


call register_customer('103', 'Nikola', 'Todorov', 'Ul. Ivan Dobrev', 'Sofia',
                       '1220', 'Unicredit Bulbank', 'Sofia Centrum', 
                       '123456789', '1234-1234-1234-1234'
                      );
                      
call register_customer('113', 'Martin', 'Todorov', 'Bul. Lomsko Shose', 'Sofia',
                       '1660', 'Unicredit Bulbank', 'Sofia Centrum', 
                       '123456788', '1233-1234-1234-1234'
                      );
                      
call register_customer('123', 'Yana', 'Arsenova', 'Bul. Cherni Vruh', 'Sofia',
                       '1000', 'Unicredit Bulbank', 'Sofia Centrum', 
                       '123456787', '1232-1234-1234-1234'
                      ); 

insert into product values
    ('0000', 'Electric guitar', 'Morgan Guitars GPST271 Black HSH', '249','2', '15'),
    ('1111', 'Electric guitar', 'Fender Player Stratocaster MN Black', '709', '1', '5'),
    ('2222', 'Snare drums','Soho SD204 Coated Steel Shell', '229', '1', '9'),
    ('3333', 'Snare drums', 'Pearl EXX1455S/C Export Jet Black', '90', '3', '20'),
    ('4444', 'Home keyboard', 'Yamaha NP-12 Piaggero Black', '319', '1', '2');
    
insert into delivery_slot values 
    ( 'Monday', '09:00:00', '19:00:00' ),
    ( 'Tuesday', '09:00:00', '19:00:00' ),
    ( 'Wednesday', '09:00:00', '19:00:00' ),
    ( 'Thursday', '09:00:00', '19:00:00' ),
    ( 'Friday', '09:00:00', '19:00:00' );
    

create or replace procedure purchase_product (
    custr_id varchar(3), 
    purchase_product_id smallint, 
    delivery_date_time TIMESTAMP)
language plpgsql as
$$

DECLARE 
	vCustomerExist smallint;
	vProductExist smallint;
	vtransid smallint;
	vdayNameAndTimeSlotExist smallint;
	vdayName varchar(15);
	vtimeSlot varchar(15);
	isValidDate float8;
begin

	--1. Verify customer exists
	--2. Verify the product is available
	--3. Validate the date time
	--4. Verify the time slot is available.
	--5. Insert the data in transaction
    --6. Commit
	

	Select count(*) into vCustomerExist
	From customer
	Where customer_id = custr_id;


	if vCustomerExist = 0 Then
		raise notice 'Invalid Customer ID, Customer does not exist with ID: %', custr_id;
	end if;
	
	
	Select count(*) into vProductExist
	From product
	Where product_id = purchase_product_id;

	
	if vProductExist = 0 Then
		raise notice 'Invalid Product ID, Product does not exist with ID: % and qty', purchase_product_id;
	end if;

	
	isValidDate = EXTRACT(EPOCH FROM (delivery_date_time - NOW()));
	
	
	if isValidDate <= 0 Then
		raise notice 'Invalid date, Delivery date time is not valid';
	end if;
	
	
	vdayName = REPLACE (to_char(DATE(delivery_date_time), 'Day'), ' ', '') ;
	
	
	vtimeSlot = delivery_date_time::time;

	
	Select count(*) into vdayNameAndTimeSlotExist
	From delivery_slot
	Where daysInWeek = vdayName AND vtimeSlot::time BETWEEN dayStartTime AND dayEndTime;
		
	
	if vdayNameAndTimeSlotExist = 0 Then
		raise notice 'Invalid day name and time slot, delivery date is not valid: %', delivery_date_time;
	end if;
	
	if vCustomerExist > 0 AND vProductExist > 0 AND isValidDate > 0 AND vdayNameAndTimeSlotExist > 0 Then	
	
		
		Select CASE WHEN Max(transaction_id) IS NULL THEN 1::text ELSE  Max(transaction_id) END into vtransId
		From transact;
				
		vtransId = vtransId + 1;
		
		
		insert into transact(transaction_id, customer_id, product_id)
    	values (vtransId, custr_id, purchase_product_id);
		raise notice 'Product successfully purchased with transaction id %', vtransId;
        
	else
	
		raise notice 'Product cannot be purchased with invalid data';		
	
	end if;

exception when others then
    raise notice 'Invalid parameters provided, please pass correct match the data type';

commit;
end
$$;

--Test case 01: Product and customer id not valid and invalid date time
--call purchase_product('102', '5555', '2014-04-03 12:34:00');

--Test case 02: Product id is not valid and invalid date time
--call purchase_product('103', '5555', '2014-04-03 12:34:00');

--Test case 03: Customer id is not valid and invalid date time
--call purchase_product('102', '1111', '2014-04-03 12:34:00');

--Test case 04: Customer id and product id is valid and invalid date time
--call purchase_product('103', '1111', '2014-04-03 12:34:00');

--Test case 05: When customer id and product id is valid and valid date time
--call purchase_product('103', '2222', '2022-09-01 11:34:00');
