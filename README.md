# pos_database
A database configured for a Point-of-Sale system

etl.sql  
1) loads data from the csv files to the database management system
2) Transforms data during the loading process
3) Implements the schema using an ER Diagram

views.sql
1) Has a view v_CustomerPurchases that contains a list of products the buyer has purchased
2) Has a view v_ProductBuyers that contains list of buyers for each product
3) Contains views v_CustomerNames and v_Customers for customer details
4) Contains materialized views v_ProductBuyers and v_CustomerPurchases 
5) Contains indexes idx_CustomerEmail and idx_ProductName for faster searching

proc.sql
1) Adds a column unitPrice in the orderLine table
2) creates a virtual column lineTotal, made up of quantity * unitPrice
3) Alters the order table to have a column called orderTotal
4) Has procedures to perform operations such as filling the unitPrice from product table, 
   filling the orderTotal column by summing the linetotal of each order. 
5) It also has a procedure to refresh the mview

trig.sql
1) Creates triggers to keep columns such as orderTotal and unitPrice up-to-date
2) Has trigger to handle quantity aspects in the orderLine table. If an order is placed, 
   the qtyOnHand should be updated accordingly for the respective product.
