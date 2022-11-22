use pos;

--products view
create or replace view v_products as
select ord.ID, json_arrayagg(

    json_object('Product Name', prod.name, 'Quantity', ol.quantity, 'Price', ol.unitPrice, 'Date Placed', ord.datePlaced)
    
) as products from
customer cust left join `order` ord on ord.customerID = cust.ID
join orderLine ol on ol.orderID = ord.ID
join product prod on ol.productID = prod.ID 
group by ord.ID;

--final view
create or replace view v_finalresult as
(
select json_object(
'Name', concat(cust.firstName, ' ', cust.lastName), 
'email', cust.email,
'Address', CONCAT_WS(", ", cust.address1, ifnull(cust.address2, ' '), cust.zip),
'Orders', 
json_arrayagg(
    distinct
    json_object
    (
        'Order Number', ord.ID, 'Products', 
        (    
            v_products.products
        )
    )
)
)
from customer cust left join `order` ord on ord.customerID = cust.ID
join orderLine ol on ol.orderID = ord.ID
-- join product prod on ol.productID = prod.ID 
join v_products on v_products.ID = ord.ID
group by cust.ID
);

--output file
select * from v_finalresult into outfile 'outputfile.json';