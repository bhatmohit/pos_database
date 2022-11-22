use pos;
-- 2,3) perform steps 2 and 3
alter table orderLine 
add column unitPrice decimal(6,2),
add column lineTotal decimal(7,2) generated always as (quantity * unitPrice) virtual;

-- 4)
alter table `order` 
add column orderTotal decimal(8,2);

-- 5)
alter table customer 
drop column phone;

-- 6)
--show create table `order`;
ALTER TABLE `order` DROP FOREIGN KEY order_ibfk_1;
ALTER TABLE `order` DROP FOREIGN KEY order_ibfk_2;
ALTER TABLE `order`
ADD FOREIGN KEY (customerID) REFERENCES customer(ID);
alter table `order` drop column status; 
drop table status;

-- 7)
delimiter //
create or replace procedure proc_FillUnitPrice()
begin
update orderLine ol
set unitPrice = (select currentPrice from product prod where prod.ID = ol.productID)
where ol.unitPrice is NULL;  
end//

-- 8) 
create or replace procedure proc_FillOrderTotal()
begin 
update `order` ord set orderTotal = (select sum(lineTotal) from orderLine ol where ord.ID = ol.orderID group by ol.orderID);
end//

-- 9) 
create or replace procedure proc_FillMVCustomerPurchases()
begin 
delete from mv_CustomerPurchases;
insert into mv_CustomerPurchases select * from v_CustomerPurchases;
end//
delimiter ;







