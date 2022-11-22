use pos;
call proc_FillUnitPrice();
call proc_FillOrderTotal();

-- 2) create priceChangeLog table
drop table if exists priceChangeLog;
create table priceChangeLog (
ID integer unsigned auto_increment,
oldPrice decimal(6,2),
newPrice decimal(6,2),
changeTimestamp timestamp,
productid integer,
primary key(ID),
foreign key(productid) references product(ID)
);

-- 3) Create one or more triggers on the product table that inserts a new row into priceChangeLog 
-- each time the price of a product is updated. It should NOT insert a row when the name or 
-- quantity available for the product is changed. 

delimiter //
create or replace trigger after_update_priceChangeLog
after update on product
for each row
begin
if old.currentPrice <> new.currentPrice
then insert into priceChangeLog(oldPrice, newPrice, productID)
values (old.currentPrice, new.currentPrice, old.ID);
end if;
end//
delimiter ;

-- 4) Create one or more triggers on the appropriate table(s) to set the unitPrice in orderLine to be 
--    whatever is in the product table as currentPrice. 
-- As a clarification, the trigger to set the unitPrice in orderLine is for additions and updates to orderLines, 
--NOT to any later changes to currentPrice in product.

delimiter //
create or replace trigger before_insert_unitPrice
before insert on orderLine 
for each row 
begin
set new.unitPrice = (select currentPrice from product prod where prod.ID = new.productID);
end//
delimiter ;

delimiter //
create or replace trigger before_update_unitPrice
before update on orderLine 
for each row 
begin
set new.unitPrice = (select currentPrice from product prod where prod.ID = new.productID);
end//
delimiter ;

-- insert into orderLine(orderID, productID, quantity) values(0, 100, 1)//

-- 5. Create one or more triggers on the appropriate table(s) to keep the orderTotal column in order 
-- up-to-date 

delimiter //
create or replace trigger after_insert_orderTotal 
after insert on orderLine 
for each row 
begin
update `order`
set orderTotal = (select sum(lineTotal) from orderLine ol where ol.orderID = new.orderID) where ID= new.orderID ;
end//
delimiter ;

delimiter //
create or replace trigger after_update_orderTotal 
after update on orderLine 
for each row 
begin
update `order`
set orderTotal = (select sum(lineTotal) from orderLine ol where ol.orderID = new.orderID) where ID= new.orderID;
end//
delimiter ;

delimiter //
create or replace trigger after_delete_orderTotal 
after delete on orderLine 
for each row 
begin
update `order`
set orderTotal = (select sum(lineTotal) from orderLine ol where ol.orderID = old.orderID) where ID= old.orderID;
end//
delimiter ;

-- 6. Create one or more triggers on the appropriate table(s) to keep the two materialized views up-
-- to-date as updates occur. Use the trigger(s) to only update the affected rows in the materialized 
-- view rather than regenerating the entire table. These will be eager updates. HINT: It’s OK to 
-- create a new stored procedure that accepts a customerID or productID as input that updates the 
-- appropriate line in the materialized view. Having extra stored procedures will not harm your 
-- grade in the grading script. And calling a stored procedure in a trigger is pretty easy to do and 
-- cuts down on duplication of SQL code in insert, update, and delete triggers of the same table. 


-- procedure to refresh prod mview
delimiter //
create or replace procedure refresh_prod_mview(IN prodID int)
begin
delete from mv_ProductBuyers where productID = prodID;
insert into mv_ProductBuyers (productID, productName, customers) 
select prod.ID productID, prod.name productName, group_concat(distinct cust.ID , ' ' , cust.firstName , ' ' , cust.lastName order by cust.ID) as customers from
    product prod left join orderLine on prod.ID = orderLine.productID
    left join `order` on orderLine.orderID = `order`.ID
    left join customer cust on cust.ID = `order`.customerID 
    where prod.ID = prodID
    group by prod.ID, prod.name;
end//
delimiter ;

-- insert prod mview
delimiter //
create or replace trigger insert_prod_mview
after insert on orderLine
for each row
begin 
call refresh_prod_mview(new.productID);
end//
delimiter ;

-- update prod mview
delimiter //
create or replace trigger update_prod_mview
after update on orderLine
for each row
begin 
call refresh_prod_mview(new.productID);
end//
delimiter ;

-- delete prod mview
delimiter //
create or replace trigger delete_prod_mview
after delete on orderLine
for each row
begin 
call refresh_prod_mview(old.productID);
end//
delimiter ;

-- procedure to refresh customer mview
delimiter //
create or replace procedure refresh_cust_mview(IN custID int(11))
begin
delete from mv_CustomerPurchases where ID = custID;
insert into mv_CustomerPurchases (ID, firstName, lastName, products) 
select cust.ID, cust.firstName, cust.lastName, group_concat(distinct prod.ID, ' ', prod.name order by prod.ID separator '|') products from 
   (
    customer cust left join `order` on cust.ID = `order`.customerID 
    left join orderLine on `order`.ID = orderLine.orderID
    left join product prod on orderLine.productID = prod.ID
   )
   where cust.ID = custID
   group by cust.ID;
end//
delimiter ;


-- insert cust mview
delimiter //
create or replace trigger insert_cust_mview
after insert on orderLine
for each row
begin 
declare custID int;
set custID = (select customerID from `order` where `order`.ID = new.orderID);
-- insert into debug_trigger values (custID, 'insert');
call refresh_cust_mview(custID);
end//
delimiter ;

-- update cust mview
delimiter //
create or replace trigger update_cust_mview
after update on orderLine
for each row
begin 
declare custID int;
set custID = (select customerID from `order` where `order`.ID = new.orderID);
-- insert into debug_trigger values (custID, 'update');
call refresh_cust_mview(custID);
end//
delimiter ;
 
-- delete cust mview
delimiter //
create or replace trigger delete_cust_mview
after delete on orderLine
for each row
begin 
declare custID int;
set custID = (select customerID from `order` where ID = old.orderID);
-- insert into debug_trigger values (custID, 'delete');
call refresh_cust_mview(custID);
end//
delimiter ;


-- 7. Create one or more triggers on orderLine to handle quantity aspects. First, if it’s null, set the 
-- quantity to 1. Second, keep the qtyOnHand of a product updated each time the orderLine is 
-- created, updated, or removed. If an orderLine adds more of a product than is available, then the 
-- orderLine should be removed completely.  

-- procedure to update quantity
delimiter //
create or replace procedure update_quantity (IN prodID int, IN qty int)
begin 
update product 
set qtyOnHand = qtyOnHand - qty
where ID = prodID; 
end//
delimiter ;

-- insert quantity check
delimiter //
create or replace trigger insert_quantity_check
before insert on orderLine 
for each row 
begin
if (select qtyOnHand from product where ID = new.productID) < new.quantity
then 
signal sqlstate '45000' set message_text = 'Error Message: Not enough inventory';
end if;
if new.quantity is NULL 
then
set new.quantity = 1;
end if;
call update_quantity(new.productID, new.quantity);
end//
delimiter ;

-- update quantity check
delimiter //
create or replace trigger update_quantity_check
before update on orderLine 
for each row 
begin
if (select qtyOnHand from product where ID = new.productID) < (new.quantity - old.quantity)
then 
signal sqlstate '45000' set message_text = 'Error Message: Not enough inventory';
end if;
if new.quantity is NULL 
then
set new.quantity = 1;
end if;
if new.quantity > old.quantity 
then
call update_quantity(new.productID, new.quantity - old.quantity);
else 
update product 
set qtyOnHand = qtyOnHand + (old.quantity - new.quantity);
end if;
end//
delimiter ;

-- delete quantity check
delimiter //
create or replace trigger delete_quantity_check
before delete on orderLine 
for each row 
begin
update product 
set qtyOnHand = qtyOnHand + old.quantity
where ID = old.productID; 
end//
delimiter ;

delimiter //
create or replace trigger bob_update
after update on product 
for each row
begin
update mv_ProductBuyers
set productName = new.name where productID = new.ID; 
end//
delimiter ;