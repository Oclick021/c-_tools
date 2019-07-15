-- 
-- Set character set the client will use to send SQL statements to the server
--
SET NAMES 'utf8';

--
-- Set default database
--
USE nameofyourdatabase;

DELIMITER $$

--
-- Create procedure `GenCSharpModel`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE GenCSharpModel (IN pTableName varchar(255))
BEGIN
  DECLARE vClassName varchar(255);
  DECLARE vClassCode mediumtext;
  DECLARE v_codeChunk varchar(1024);
  DECLARE v_finished integer DEFAULT 0;
  DECLARE code_cursor CURSOR FOR
  SELECT
    code
  FROM temp1;

  DECLARE CONTINUE HANDLER
  FOR NOT FOUND SET v_finished = 1;

  SET vClassCode = '';
  /* Make class name*/
  SELECT
    (CASE WHEN col1 = col2 THEN col1 ELSE CONCAT(col1, col2) END) INTO vClassName
  FROM (SELECT
      CONCAT(UCASE(MID(ColumnName1, 1, 1)), LCASE(MID(ColumnName1, 2))) AS col1,
      CONCAT(UCASE(MID(ColumnName2, 1, 1)), LCASE(MID(ColumnName2, 2))) AS col2
    FROM (SELECT
        SUBSTRING_INDEX(pTableName, '_', -1) AS ColumnName2,
        SUBSTRING_INDEX(pTableName, '_', 1) AS ColumnName1) A) B;

  /*store all properties into temp table*/
  CREATE TEMPORARY TABLE IF NOT EXISTS temp1 ENGINE = MYISAM
  AS (SELECT
      CONCAT('public ', ColumnType, ' ', FieldName, ' { get; set; }') code
    FROM (SELECT
        (CASE WHEN col1 = col2 THEN col1 ELSE CONCAT(col1, col2) END) AS FieldName,
        CASE DATA_TYPE WHEN 'bigint' THEN 'long' WHEN 'binary' THEN 'byte[]' WHEN 'bit' THEN 'bool' WHEN 'char' THEN 'string' WHEN 'date' THEN 'DateTime' WHEN 'datetime' THEN 'DateTime' WHEN 'datetime2' THEN 'DateTime' WHEN 'datetimeoffset' THEN 'DateTimeOffset' WHEN 'decimal' THEN 'decimal' WHEN 'float' THEN 'float' WHEN 'image' THEN 'byte[]' WHEN 'int' THEN 'int' WHEN 'money' THEN 'decimal' WHEN 'nchar' THEN 'char' WHEN 'ntext' THEN 'string' WHEN 'numeric' THEN 'decimal' WHEN 'nvarchar' THEN 'string' WHEN 'real' THEN 'double' WHEN 'smalldatetime' THEN 'DateTime' WHEN 'smallint' THEN 'short' WHEN 'mediumint' THEN 'INT' WHEN 'smallmoney' THEN 'decimal' WHEN 'text' THEN 'string' WHEN 'time' THEN 'TimeSpan' WHEN 'timestamp' THEN 'DateTime' WHEN 'tinyint' THEN 'byte' WHEN 'uniqueidentifier' THEN 'Guid' WHEN 'varbinary' THEN 'byte[]' WHEN 'varchar' THEN 'string' WHEN 'year' THEN 'UINT' ELSE 'UNKNOWN_' + DATA_TYPE END ColumnType
      FROM (SELECT
          CONCAT(UCASE(MID(ColumnName1, 1, 1)), LCASE(MID(ColumnName1, 2))) AS col1,
          CONCAT(UCASE(MID(ColumnName2, 1, 1)), LCASE(MID(ColumnName2, 2))) AS col2,
          DATA_TYPE
        FROM (SELECT
            SUBSTRING_INDEX(COLUMN_NAME, '_', -1) AS ColumnName2,
            SUBSTRING_INDEX(COLUMN_NAME, '_', 1) AS ColumnName1,
            DATA_TYPE,
            COLUMN_TYPE
          FROM INFORMATION_SCHEMA.COLUMNS
          WHERE table_name = pTableName) A) B) C);

  SET vClassCode = '';
  /* concat all properties*/
  OPEN code_cursor;

get_code:
  LOOP

    FETCH code_cursor INTO v_codeChunk;

    IF v_finished = 1 THEN
      LEAVE get_code;
    END IF;

    -- build code
    SELECT
      CONCAT(vClassCode, '\r\n', v_codeChunk) INTO vClassCode;

  END LOOP get_code;

  CLOSE code_cursor;

  DROP TABLE temp1;
  /*make class*/
  SELECT
    CONCAT('public class ', vClassName, '\r\n{', vClassCode, '\r\n}');
END
$$

DELIMITER ;