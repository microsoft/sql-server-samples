'''
     Pipeline implementation


'''



import numpy as np
import pandas as pd
import time
from sklearn.base import BaseEstimator, TransformerMixin,  ClassifierMixin
from sklearn.preprocessing import StandardScaler
from revoscalepy.functions.RxLogit import rx_logit_ex
from revoscalepy.functions.RxPredict import rx_predict_ex


#=========================

#  Features engineering

#=========================

class OutliersHandler(BaseEstimator, TransformerMixin):
    """Handle outliers"""

    def fit(self, x, y = None):
        return self

    def transform(self, df):

        df.availablebikes = np.where(df.availablebikes > df.bikestands, df.bikestands, df.availablebikes)
        return df

class LabelDefiner(BaseEstimator, TransformerMixin):
    """

        Defines target variable
        Binary label 0 empty station, 1 otherwise

    """

    def __init__(self, availability_threshold = 1):
        self.threshold = availability_threshold

    def fit(self, x, y = None):
        return self

    def transform(self, df):

        df['label'] = np.where(df.availablebikes < self.threshold, 0, 1)
        return df



class DateTimeFeaturesExtractor(BaseEstimator, TransformerMixin):
    """Extract Datetime features"""

    def fit(self, x, y = None):
        return self

    def transform(self, df):
        df['lastupdate']= pd.to_datetime(df['lastupdate'])
        df['day'] = df.lastupdate.dt.day.astype(int)
        df['month'] = df.lastupdate.dt.month.astype(int)
        df['hour']= df.lastupdate.dt.hour.astype(int)
        df['minute']= df.lastupdate.dt.minute.astype(int)
        df['isweekend'] = np.where(df['lastupdate'].dt.dayofweek > 4, 1, 0)
        df.sort_values(by='lastupdate', inplace = True)
        return df



class TSFeaturesExtractor(BaseEstimator, TransformerMixin):
    """Extract time series related features"""

    def __init__(self, max_lags = 4):
        self.__max_lags = max_lags

    def fit(self, x, y=None):
        return self

    def transform(self, df):


        df.sort_values(['lastupdate','stationid'], ascending = [True, True])

        for i in range(self.__max_lags):
            df['lag'  + str(i)] = df.groupby(['stationid'])['availablebikes'].shift(i + 1)


        df['1st_derivative'] = df.groupby('stationid')['lag0'].transform(lambda x: np.gradient(x))
        df['2nd_derivative'] = df.groupby('stationid')['1st_derivative'].transform(lambda x: np.gradient(x))
        df['fft_max_coeff'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].transform(lambda x: np.amax(np.abs(np.fft.rfft(x))))
        df['fft_energy'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].transform(lambda x: np.sum((np.abs(np.fft.rfft(x))) ** 2))

        return df





class StatisticalFeaturesExtractor(BaseEstimator, TransformerMixin):
    """Extract statistical related features"""

    def __init__(self, max_lags = 4):
        self.__max_lags = max_lags

    def fit(self, x, y=None):
        return self

    def transform(self, df):

        df['var'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].transform('var')
        df['cumrelfreq'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].cumsum() / self.__max_lags
        df['mad'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].transform('mad')
        df['idxmax'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].transform(\
                                lambda x: np.argmax(x.ravel()))
        df['idxmin'] = df.groupby(['stationid', 'month', 'day', 'hour'])['lag0'].transform(\
                                lambda x: np.argmin(x.ravel()))
        return df




class FeaturesExcluder(BaseEstimator, TransformerMixin):
    """features to  exclude"""

    def __init__(self, features = ['availablebikes', 'bikestands','lastupdate', 'zipcode','month', 'day']):
        self.__exclusionlist = features

    def fit(self, X, y = None):
        return self

    def transform(self, df):

        df.drop(self.__exclusionlist, axis = 1, inplace = True)
        return df


class FeaturesScaler(BaseEstimator, TransformerMixin):

    """Z-score scaler """



    def fit(self, X, y = None):
        return self

    def transform(self, df):

        if df.isnull().any().any():
            df.dropna(inplace = True)
        cols = df.columns.tolist()
        excluded_cols = ['stationid', 'label','hour', 'minute', 'isweekend']

        X = StandardScaler().fit_transform(df.drop(excluded_cols, axis=1, inplace = False))
        X = np.concatenate((df.loc[:, excluded_cols].as_matrix(), X), axis = 1)

        df_out = pd.DataFrame(X, columns = cols)

        return df_out


class RxClassifier(BaseEstimator, ClassifierMixin):

    """  Revoscalerpy logisitic regression binary classifier wrapped in sklearn estimator """

    def __init__(self, computecontext):

        self.__computecontext = computecontext


    def fit(self, X, y = None):


        """Fit model to training data


            Args:
                X (pandas DataFrame): training data.
                y (None): Not used  the target variable is passed in X.

            return: coefficients (pandas DataFrame)

            """

        formula = "label ~ F(stationid) + F(hour) + F(minute) + isweekend + lag0 +  \
                    lag1 + lag2 +  lag3 +  1st_derivative + 2nd_derivative\
                     + fft_max_coeff + fft_energy +  var +  cumrelfreq + mad + idxmax + idxmin"

        start = time.time()
        self.__clf = rx_logit_ex(formula, data = X, compute_context = self.__computecontext,  report_progress = 3, verbose = 1)
        end = time.time()

        print("Training time duration: %.2f seconds" % (end - start))
        return self.__clf.coefficients


    def predict(self, X):
        """
            Perform classification on X

            Args:
               X (pandas DataFrame): prediction input dataset

            return: prediction results vector (numpy array)
         """
        if self.__clf is None:
            raise RuntimeError("Data must be fitted before calling predict!")

        predict = rx_predict_ex(self.__clf, data = X,  compute_context = self.__computecontext)
        predictions = np.where(predict._results['label_Pred'] == 1, 1, 0)

        return predictions


