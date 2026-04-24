options (readsize=2048000,bindsize=1600000, rows=100000, silent=(header, feedback) )
load data
infile 'inventory.csv' "str '\r\n'"
append
into table SALES.INVENTORY
fields terminated by '|'
OPTIONALLY ENCLOSED BY '"' AND '"'
trailing nullcols
           ( INV_DATE,
             INV_ITEM,
             INV_WAREHOUSE,
             INV_QUANTITY_ON_HAND
           )
