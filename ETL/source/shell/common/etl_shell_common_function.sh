#!/bin/ksh
##############################
# Common function
#
# Created By : Eric Li
# Created On : 16 April 2014
#
# Amendment History:
# Amended By     Amended On        Remark
# ---------      ----------        ------------------------------------------
#
##################################################################

SHELL_FILE_PATH=$0
curdir=$(pwd)

#################
# Checking if the interface files are all available.
# batch will go on,otherwise it will return status "1"
# paramters: 1:Batch Name
# return value : "0"--successful  Other -- fail
###############################################################
etl_s0()
{
	#check parameters
	if [ $# -lt 1 ];then
		save_log 'need parameter.' 'etl_s0' 'Error'
		return 1
	fi
    
	# step1 : checking the file is exist or not
	save_log 'Batch '$1' ,Begin checking if the file exists or not, please wait... ' $1'_S0.sh' 'Info'
	
        if [ "$?" != "0" ]; then
		save_log 'Batch '$1' ,not all the files are available. '$? $1'_S0.sh' 'Error'
                return 1
	fi  
  
        save_log 'Batch '$1' ,all the files are available. ' $1'_S0.sh' 'Info' 

	# step2 : copy source files to input folder
	save_log 'Copying source files to input folder...' $1'_S0.sh' 'Info'

	cp -r $STAGING_PATH/$1 $INPUT_PATH
	if [ "$?" != "0" ]; then
		save_log "Failed to copy files from $STAGING_PATH/$1 to $INPUT_PATH/$1" $1'_S0.sh' 'Info'
		return 1
	fi
  
        save_log 'Job complete' $1'_S0.sh' 'Info'
	return 0
}

#################
# clear temporary data in DB and load interface files into DB.
# batch will go on,otherwise it will return status "1"
# paramters: 1:Batch Name
# return value : "0"--successful  Other -- fail
###############################################################
etl_s1()
{
  mysql -u root tmailcontest<"$INPUT_PATH/$1/$1".sql>> "$DB_LOG_PATH"/$1.log
  if [ "$?" != "0" ]; then
    save_log 'Batch '$1' ,load data to database failed.'$? $1'_S1.sh' 'Error' 
    return 1
  fi
  
  save_log 'Batch '$1' ,load data to database successfully.' $1'_S1.sh' 'Info' 
  
  return 0

}

#################
# Call procedure to convert interface to target data.
# batch will go on,otherwise it will return status "1"
# paramters: 1:Batch Name
# return value : "0"--successful  Other -- fail
###############################################################
etl_s2()
{
  
  #Step1:Filter the record.
  save_log 'Batch '$1' ,Begin running record filter procedure, please wait...' $1'_S2.sh' 'Info'
  echo "use tmailcontest;" > "$ETL_SHELL_PATH/$1/$1.sql"
  echo "CALL PRO_$1_Extract();" >> "$ETL_SHELL_PATH/$1/$1.sql"
  
  mysql -u root tmailcontest<"$ETL_SHELL_PATH/$1/$1".sql>> "$DB_LOG_PATH"/$1.log

  if [ "$?" != "0" ]; then
  	save_log 'Batch '$1' ,Filter the record fail.'$? $1'_S2.sh' 'Error'
    if [ -f "$1.sql" ]; then
      rm "$1.sql"
    fi
  	return 1
  fi
  
  save_log 'Batch '$1' ,Filter the record successful.' $1'_S2.sh' 'Info'
  
  #Step2:Data conversion from temp tables to target data. 
  save_log 'Batch '$1' ,Begin running data conversion procedure, please wait...' $1'_S2.sh' 'Info'
  echo "use tmailcontest;" > "$1.sql"  
  echo "CALL PRO_$1_Transform();" >> "$1.sql"

  if [ "$?" != "0" ]; then
    save_log 'Batch '$1' ,Data conversion fail.'$? $1'_S2.sh' 'Error'
   
    if [ -f "$1.sql" ]; then
      rm "$1.sql"
    fi
  	return 1
  fi
  	
  save_log 'Batch '$1' ,Data conversion successful.' $1'_S2.sh' 'Info'
  
  if [ -f "$1.sql" ]; then
    rm "$1.sql"
  fi
  
  return 0
}

#################
# Call procedure to generate Exception reports.
# batch will go on,otherwise it will return status "1"
# paramters: 1:Batch Name
# return value : "0"--successful  Other -- fail
###############################################################
genExpReport()
{
  if [ $# -lt 1 ];then
    save_log "need parameter: batch_name" 'generateExReport' 'Error' 
    return 1
  fi
	
  #########load config data########
	. "$CONFIG_PATH/exception.ini"
  
  #########FUNCTION BODY########
  
  # step1 : generating report
  save_log "EX_$1 ,Begin generating report, please wait..." 'generateExReport' 'Info' 
  echo "$Exp_Header">"$EXP_PATH/$1/header.txt"
  eval echo "\$$1_Exp" | read header
  echo "$header">"$EXP_PATH/$1/tempheader.txt"
  sed 's/@/ /g' "$EXP_PATH/$1/tempheader.txt">>"$EXP_PATH/$1/header.txt"
  save_log "EX_$1 ,Header section generated..." 'generateExReport' 'Info'

  echo "SELECT * INTO OUTFILE '/tmp/body.txt'
        FIELDS TERMINATED BY ','
        FROM EXP_Table
        WHERE APP='$1';">$1.sql
  mysql -u root tmailcontest<"$ETL_SHELL_PATH/$1/$1".sql>> "$DB_LOG_PATH"/$1.log
  touch /tmp/body.txt
  if [ "$?" != "0" ]; then
    save_log "Report body for EX_$1 generation failed." 'generateExReport' 'Error'
    return 1  
  fi 
  save_log "Report body for EX_$1 generated successfully." 'generateExReport' 'Info'

  mv /tmp/body.txt $EXP_PATH/$1
  cat $EXP_PATH/$1/header.txt $EXP_PATH/$1/body.txt>$EXP_PATH/$1/$1.csv

  if [ "$?" != "0" ]; then
    save_log "EX_$1 ,Failed to combine report header and body." 'generateExReport' 'Error'
    return 1
  fi
  save_log "Generate exception report for $1 successfully." 'generateExReport' 'Info'
  
  if [ -f "$EXP_PATH/$1/body.txt" ]; then
    rm "$EXP_PATH/$1/body.txt"
  fi

  if [ -f "$EXP_PATH/$1/header.txt" ]; then
    rm "$EXP_PATH/$1/header.txt"
  fi

  if [ -f "$EXP_PATH/$1/tempheader.txt" ]; then
    rm "$EXP_PATH/$1/tempheader.txt"
  fi
   
  return 0
}
#################
# Backup source file.
# paramters: no need
# return value : "0"--successful  Other -- fail
###############################################################
backup()
{
	save_log 'Copying source files to backup folder...' 'backup.sh' 'Info'
	
        cp -r $STAGING_PATH $BACKUP_PATH/`date '+%Y%m%d'`
	if [ "$?" != "0" ]; then
		save_log "Failed to copy files from $STAGING_PATH to $BACKUP_PATH/`date '+%Y%m%d'`" 'backup.sh' 'Info'
		return 1
	fi
  
        save_log 'Backup source file successfully' 'backup.sh' 'Info'
	return 0
}
#################
# schedule this function to call test cases.
# paramters: no need
# return value : "0"--successful  Other -- fail
###############################################################
autotest()
{
	save_log "AutoTest '$1' Run test case $1..." $1'_AutoTest.sh' 'Info'
	
        echo "use tmailcontest;" > "$ETL_SHELL_PATH/$1/$1_Test.sql"
        echo "CALL PRO_$1_Testcase();" >> "$ETL_SHELL_PATH/$1/$1_Test.sql"
  
        mysql -u root tmailcontest<"$ETL_SHELL_PATH/$1/$1"_Test.sql>> "$DB_LOG_PATH"/$1.log

        if [ "$?" != "0" ]; then
  	   save_log 'AutoTest '$1' ,run test case fail.'$? $1'_AutoTest.sh' 'Error'
           if [ -f "$1_Test.sql" ]; then
                rm "$1_Test.sql"
           fi
  	   return 1
        fi
             
        if [ -f "$1_Test.sql" ]; then
           rm "$1_Test.sql"
        fi

        if [ -f "/tmp/case1.txt" ]; then
           mv /tmp/case1.txt $TESTRESULT_PATH/$1/$1_TestCaseFail.txt
           cat $1_TestCaseFail.txt|mail -s '$1_TestCaseFail' 876478931@126.com
        fi
        echo [`TZ=BJT date`] 'FILENAME: ['$1']' "$1 test OK.">> "$TESTRESULT_PATH/$1/$1_testresult.log"
        save_log "AutoTest '$1' Run test case $1 successfully" $1'_AutoTest.sh' 'Info'
	return 0
}
#################
# save the log
# paramters: 1:Log message, 2:File Name
#            3:Information type
# return value : "0"--successful  "1" -- fail
###############################################################
save_log()
{
	#check log parameters
	if [ $# -lt 1 ];then
		echo 'need log message.' | tee -a $LOG_FILE
		return 0
	fi
	#set paramters
	MESSAGE=$1
	FILE_NAME=$2
	INFO_TYPE=$3
	#log message into logfile
	echo [`TZ=BJT date`] '<'$INFO_TYPE'>' 'FILENAME: ['$FILE_NAME'] '$MESSAGE | tee -a $LOG_FILE
	return 0
}
