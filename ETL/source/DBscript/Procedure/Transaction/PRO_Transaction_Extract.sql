DELIMITER //
CREATE PROCEDURE PRO_Transaction_Extract()
BEGIN

  truncate table WRK_tmail_firstseason;

  insert into WRK_tmail_firstseason
  select * from TEMP_tmail_firstseason
  where visit_datetime > '2013-06-01';

END
//
DELIMITER ;
