package com.dbs.sg.DTE12.DAO;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;
public class DictionaryParaUpdateDAO extends BaseTableDAO {
	/**
	 * Logger
	 */
	private static String updateSql = "update tblgcs_dictionary set value=? where appid=? and key=?";
	private static String selectSql = "select value from tblgcs_dictionary where appid=? and key=?";
	public static String keyBusDate = "BUS_DATE";
	public static String keyBusDate_1 = "BUS_DATE-1";
	public static String keyBusDate_2 = "BUS_DATE-2";
	public DictionaryParaUpdateDAO(String configPath) throws SQLException {
		super(configPath);
	}

	public String getDictPara(String moudle,String key) throws SQLException{
		String value = null;
		super.initialize();
		super.prepareStatement(selectSql);
		super.setStringArgument(1, moudle);
		super.setStringArgument(2, key);
		super.executeStatement();
		if (super.resultSet != null & super.resultSet.next()){
			value = super.resultSet.getString(1);
		}
		return value;
	}
	
	public int updateSystemDate(String moudle,String key,String value) throws SQLException{
		int retval = 0;
		retval += this.updateDictPara(moudle, keyBusDate_2, this.getDictPara(moudle, keyBusDate_1));
		retval += this.updateDictPara(moudle, keyBusDate_1, this.getDictPara(moudle, keyBusDate));
		retval += this.updateDictPara(moudle, keyBusDate, value);
		return retval;
	}
	
	public int updateSystemDate(String value) throws SQLException{
		this.initialize();
		CallableStatement cst = super.dbConnection.prepareCall("{?= call UPD_BUSDATE(?)}");
		cst.registerOutParameter(1, Types.VARCHAR);
		cst.setString(2, value);
		cst.execute();
		String res = cst.getString(1);
		cst.close();
		if (res.equals("0"))
			return 0;
		else
			return 1;
	}
	
	public int updateDictPara(String moudle,String key,String value) throws SQLException{
		logger.info("updateDictPara(moudle=" + moudle +",key=" + key + ",value=" + value +") - begin.");
		this.initialize();
		prepareStatement(updateSql);
		setStringArgument(1, value);
		setStringArgument(2, moudle);
		setStringArgument(3, key);
		int ret = prepStatement.executeUpdate();
		this.commit();
		this.cleanUp();
		logger.info("updateDictPara(moudle=" + moudle +",key=" + key + ",value=" + value +") - return=" + ret);
		return ret;
	}
	/**
	 * @param args
	 */
	public static void main(String[] args) {

	}

}
