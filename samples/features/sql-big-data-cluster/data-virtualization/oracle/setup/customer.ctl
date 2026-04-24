options (readsize=2048000,bindsize=1600000, rows=100000, silent=(header, feedback) )
load data
infile 'customer.csv' "str '\r\n'"
append
into table SALES.CUSTOMER
fields terminated by '|'
OPTIONALLY ENCLOSED BY '"' AND '"'
trailing nullcols
           ( C_CUSTOMER_SK,
             C_CUSTOMER_ID CHAR(16),
             C_CURRENT_CDEMO_SK,
             C_CURRENT_HDEMO_SK,
             C_CURRENT_ADDR_SK,
             C_FIRST_SHIPTO_DATE_SK,
             C_FIRST_SALES_DATE_SK,
             C_SALUTATION CHAR(10),
             C_FIRST_NAME CHAR(20),
             C_LAST_NAME CHAR(30),
             C_PREFERRED_CUST_FLAG CHAR(1),
             C_BIRTH_DAY,
             C_BIRTH_MONTH,
             C_BIRTH_YEAR,
             C_BIRTH_COUNTRY CHAR(20),
             C_LOGIN CHAR(13),
             C_EMAIL_ADDRESS CHAR(50),
             C_LAST_REVIEW_DATE CHAR(10)
           )
