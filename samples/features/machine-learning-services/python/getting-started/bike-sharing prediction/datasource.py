from revoscalepy.computecontext.RxComputeContext import RxComputeContext
from revoscalepy.computecontext.RxInSqlServer import RxInSqlServer
from revoscalepy.computecontext.RxInSqlServer import RxSqlServerData
from revoscalepy.etl.RxImport import rx_import_datasource


class DataSource():

    def __init__(self, connectionstring):

         """Data source remote compute context


                Args:
                    connectionstring: connection string to the SQL server.


          """
         self.__connectionstring = connectionstring



    def loaddata(self):
        dataSource = RxSqlServerData(sqlQuery = "select * from dbo.trainingdata", verbose=True, reportProgress =True,
                                     connectionString = self.__connectionstring)

        self.__computeContext = RxInSqlServer(connectionString = self.__connectionstring, autoCleanup = True)
        data = rx_import_datasource(dataSource)

        return data

    def getcomputecontext(self):

        if self.__computeContext is None:
            raise RuntimeError("Data must be loaded before requesting computecontext!")

        return self.__computeContext

