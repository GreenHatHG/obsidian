# Database-Storage2

## Data Representation

A **data representation** scheme is how a DBMS stores the bytes for a value.

### Integers

- Most DBMSs store integers using their “native” C/C++ types as specified by the IEEE-754 standard.These values are fixed length.
- Examples: `INTEGER`, `BIGINT`, `SMALLINT`, `TINYINT`.

### Variable Precision(*精度*) Numbers

- Inexact(*不精确*), variable-precision(*可变精度*) numeric type that uses the “native” C/C++ types specified by IEEE-754 standard. These values are also fixed length.
- Variable-precision numbers are faster to compute than arbitrary precision(*任意精度*) numbers because the CPU can execute instructions on them directly.
- Examples: `FLOAT`, `REAL`(*实数*).

### Fixed Point Precision Numbers

- 这些是具有任意精度和小数位数的数值数据类型。它们通常存储在精确的、可变长度的二进制表示中，并带有附加的元数据，这些元数据将告诉系统小数应该在哪里等信息。
- 当舍入误差不可接受时使用这些数据类型，但 DBMS 为获得这种准确性付出了性能损失。
- Example: `NUMERIC`, `DECIMAL`.

### Variable Length Data

- An array of bytes of arbitrary length.
- Has a header that keeps track of the length of the string to make it easy to jump to the next value.
- 大多数 DBMS 不允许tuple超过单个page的大小，因此它们通过将值写入overflow(*溢出*) page并让tuple包含对该page的引用来解决此问题。如果一个overflow page不够则再指向另外一个。
  ![png](CMU445-Database-Storage2/04-storage2_21.JPG)

- Some systems will let you store these large values in an external file, and then the tuple will contain a pointer to that file.
  - For example, if our database is storing photo information, we can store the photos in the external files rather than having them take up large amounts of space in the DBMS.
  - One downside(*缺点*) of this is that the DBMS cannot manipulate(*操作*) the contents of this file.
    ![png](CMU445-Database-Storage2/04-storage2_22.JPG)
- Example: `VARCHAR`, `VARBINARY`, `TEXT`, `BLOB`.

### Dates and Times

- Usually, these are represented as the number of (micro/milli)seconds since the unix epoch(从1970-01-01开始).
- Example: `TIME`, `DATE`, `TIMESTAMP`.

## System catalog

- In order for the DBMS to be able to read these values, it maintains an internal **catalog** to tell it meta-data about the databases. 
  - Tables, columns, indexes, views, users, permissions, internal statistics(多少个唯一值等)
  - 很多数据库系统都会将它们的Catalog用另一张表来保存
- You can query the DBMS’s internal **INFORMATION_SCHEMA** catalog to get info about the database.
  - ANSI standard set of read-only views that provide info about all of the tables, views, columns, and procedures in a database.
  - DBMSs also have non-standard shortcuts to retrieve(*检索*) this information.
  ![png](CMU445-Database-Storage2/04-storage2_26.JPG)
  ![png](CMU445-Database-Storage2/04-storage2_27.JPG)
