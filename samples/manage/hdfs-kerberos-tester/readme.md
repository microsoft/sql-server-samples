# HDFS Kerberos Tester
Use the HDFS Kerberos tester to troubleshoot HDFS Kerberos connections for PolyBase, when you experience HDFS Kerberos failure while creating an external table in a Kerberos secured HDFS cluster.

This tool will assist in ruling out non-SQL Server issues, to help you concentrate on resolving HDFS Kerberos setup issues, namely identifying the following issues:
- Username/password misconfigurations
- Cluster Kerberos setup misconfigurations

## Prerequisites
This tool is completely independent from SQL Server. It is available as a Jupyter Notebook, and requires:

- A Hadoop cluster (Cloudera or Hortonworks) secured with Kerberos (Active Directory or MIT)
- [Azure Data Studio](https://docs.microsoft.com/sql/azure-data-studio/download)
- Around 40 MB of hard disk space

## Instructions
1. Download all the content in this location to your local machine. Please make sure all these files are co-located in same folder.

2. Open Azure Data Studio.

3. In Azure Data studio click the **File** top menu -> **Open File** -> and navigate to the folder where you saved the `hdfs-kerberos-tester.ipynb` file. Choose the `hdfs-kerberos-tester.ipynb` file and click open.

4. After the Notebook has loaded, choose **Python3** as kernel. For more information on using Notebooks with the Python kernel, see [Configure Python for Notebooks](https://docs.microsoft.com/sql/azure-data-studio/sql-notebooks#configure-python-for-notebooks).

5. Click on all **RunCells** button in the Notebook and follow instruction in the Notebook.
