package com.dbs.sg.DTE12.service;

import com.dbs.sg.DTE12.DAO.DictionaryParaUpdateDAO;
import com.dbs.sg.DTE12.common.Logger;

public class DictionaryParameterUpdate {
	/**
	 * Logger
	 */
	private static Logger logger;

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length != 4) {
			System.out
					.println("the usage of DictionaryParameterUpdate is:\n\tjava DictionaryParameterUpdate "
							+ "moudle key value\n\t\tmoudle\t\tbatch id or _all_.\n\t\tkey\t\tname of parameter.\n\t\t"
							+ "value\t\tvalue of parameter.");
			return;
		}
		logger = Logger.getLogger(args[0], DictionaryParameterUpdate.class);
		DictionaryParaUpdateDAO dao = null;
		int ret = -1;
		try {
			dao = new DictionaryParaUpdateDAO(args[0]);
			if (DictionaryParaUpdateDAO.keyBusDate.equalsIgnoreCase(args[2])) {
				ret = dao.updateSystemDate(args[1], args[2], args[3]);
			} else {
				ret = dao.updateDictPara(args[1], args[2], args[3]);
			}
			if (ret > 0) {
				System.out.println("0");
			} else
				System.out.println("1");

		} catch (Exception e) {
			System.out.println("1");
			logger.error("An error occured in DictionaryParameterUpdate.", e);
		} finally {
			if (dao != null) {
				dao.close();
			}
		}

	}

}
